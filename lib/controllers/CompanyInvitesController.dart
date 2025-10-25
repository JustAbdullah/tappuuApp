import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../core/data/model/CompanySummary.dart';
import '../core/data/model/company_invite.dart';

class CompanyInvitesController extends GetxController {
  static const _baseUrl =
      'https://stayinme.arabiagroup.net/lar_stayInMe/public/api';

  // ===================== State =====================
  final invites = <CompanyInvite>[].obs;       // دعوات شركة محددة
  final myInvitesList = <CompanyInvite>[].obs; // دعواتي (حسب بريدي)
  final myCompanies = <CompanySummary>[].obs;  // شركاتي (للاختيار)

  final isLoading = false.obs;
  final isSaving = false.obs;
  final isDeleting = false.obs;

  // ===================== Helpers =====================

  Map<String, String> get _defaultHeaders => {
        'Accept': 'application/json',
        // مبدئيًا form-encoded لأن الـ API مبني عليه في أغلب الأماكن
        'Content-Type': 'application/x-www-form-urlencoded; charset=utf-8',
      };

  Map<String, dynamic> _safeDecode(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {'raw': decoded};
    } catch (_) {
      return {'raw': body};
    }
  }

  String _extractServerMessage(http.Response res) {
    try {
      final m = _safeDecode(res.body);
      return (m['message']?.toString() ??
              m['error']?.toString() ??
              m['errors']?.toString() ??
              res.body)
          .toString();
    } catch (_) {
      return '(${res.statusCode}) ${res.reasonPhrase ?? 'Unknown error'}';
    }
  }

  Future<http.Response> _post(Uri uri, Map<String, String> body) {
    return http.post(uri, headers: _defaultHeaders, body: body);
  }

  Future<http.Response> _put(Uri uri, Map<String, String> body) {
    return http.put(uri, headers: _defaultHeaders, body: body);
  }

  Future<http.Response> _delete(Uri uri, Map<String, String> body) {
    return http.delete(uri, headers: _defaultHeaders, body: body);
  }

  Future<http.Response> _get(Uri uri) {
    return http.get(uri, headers: _defaultHeaders);
  }

  void _toastError(String title, String msg) {
    Get.snackbar(title, msg, snackPosition: SnackPosition.BOTTOM);
  }

  // ===================== Invites (Company scope) =====================

  /// جلب دعوات شركة (تظهر اسم الشركة)
  /// GET /companies/{companyId}/invites
  Future<void> fetchCompanyInvites(int companyId) async {
    isLoading.value = true;
    try {
      final uri = Uri.parse('$_baseUrl/companies/$companyId/invites');
      final res = await _get(uri);

      if (res.statusCode == 200) {
        final body = _safeDecode(res.body);
        if (body['success'] == true && body['data'] is List) {
          final list = (body['data'] as List)
              .map((e) => CompanyInvite.fromJson(e as Map<String, dynamic>))
              .toList();
          invites.assignAll(list);
        } else {
          print('fetchCompanyInvites success=false: ${res.body}');
        }
      } else {
        print('fetchCompanyInvites status ${res.statusCode}: ${res.body}');
        _toastError('تعذّر الجلب', _extractServerMessage(res));
      }
    } catch (e) {
      print('Exception fetchCompanyInvites: $e');
      _toastError('تعذّر الجلب', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  /// إنشاء دعوة — المالك فقط
  /// POST /companies/{companyId}/invites
  Future<bool> createInvite({
    required int companyId,
    required int inviterUserId,
    required String inviteeEmail,
    String role = 'publisher', // publisher | viewer
  }) async {
    isSaving.value = true;
    try {
      final uri = Uri.parse('$_baseUrl/companies/$companyId/invites');
      final res = await _post(uri, {
        'inviter_user_id': inviterUserId.toString(),
        // السيرفر يخزن lowercase — نرسلها جاهزة
        'invitee_email': inviteeEmail.trim().toLowerCase(),
        'role': role,
      });

      if (res.statusCode == 201 || res.statusCode == 200) {
        await fetchCompanyInvites(companyId);
        return true;
      } else {
        print('createInvite status ${res.statusCode}: ${res.body}');
        _toastError('تعذّر الإرسال', _extractServerMessage(res));
      }
    } catch (e) {
      print('Exception createInvite: $e');
      _toastError('تعذّر الإرسال', e.toString());
    } finally {
      isSaving.value = false;
    }
    return false;
  }

  /// تحديث دعوة (المالك فقط) — تغيير الدور/الحالة قبل القبول
  /// PUT /companies/{companyId}/invites/{inviteId}
  Future<bool> updateInvite({
    required int companyId,
    required int inviteId,
    required int actorUserId,
    String? role,   // publisher | viewer
    String? status, // pending | accepted | rejected
  }) async {
    isSaving.value = true;
    try {
      final uri =
          Uri.parse('$_baseUrl/companies/$companyId/invites/$inviteId');
      final body = <String, String>{
        'actor_user_id': actorUserId.toString(),
        if (role != null) 'role': role,
        if (status != null) 'status': status,
      };

      final res = await _put(uri, body);

      if (res.statusCode == 200) {
        await fetchCompanyInvites(companyId);
        return true;
      } else {
        print('updateInvite status ${res.statusCode}: ${res.body}');
        _toastError('تعذّر التحديث', _extractServerMessage(res));
      }
    } catch (e) {
      print('Exception updateInvite: $e');
      _toastError('تعذّر التحديث', e.toString());
    } finally {
      isSaving.value = false;
    }
    return false;
  }

  /// حذف دعوة (المالك فقط)
  /// DELETE /companies/{companyId}/invites/{inviteId}
  Future<bool> deleteInvite({
    required int companyId,
    required int inviteId,
    required int actorUserId,
  }) async {
    isDeleting.value = true;
    try {
      final uri =
          Uri.parse('$_baseUrl/companies/$companyId/invites/$inviteId');
      final res = await _delete(uri, {
        'actor_user_id': actorUserId.toString(),
      });

      if (res.statusCode == 200) {
        invites.removeWhere((i) => i.id == inviteId);
        return true;
      } else {
        print('deleteInvite status ${res.statusCode}: ${res.body}');
        _toastError('تعذّر الحذف', _extractServerMessage(res));
      }
    } catch (e) {
      print('Exception deleteInvite: $e');
      _toastError('تعذّر الحذف', e.toString());
    } finally {
      isDeleting.value = false;
    }
    return false;
  }

  // ===================== My Invites (by my email on server) =====================

  /// دعواتي (حسب إيميل المستخدم في السيرفر) — افتراضي: pending
  /// POST /invites/my
  /// يدعم التصفية بالحالة والصفحات (page, per_page) إن فعّلت pagination في الـ API
  Future<void> fetchMyInvites({
    required int userId,
    String? status, // pending | accepted | rejected
    int? page,
    int? perPage, // 1..100
  }) async {
    isLoading.value = true;
    try {
      final uri = Uri.parse('$_baseUrl/invites/my');
      final body = <String, String>{
        'user_id': userId.toString(),
        if (status != null) 'status': status,
        if (page != null) 'page': page.toString(),
        if (perPage != null) 'per_page': perPage.toString(),
      };

      final res = await _post(uri, body);

      if (res.statusCode == 200) {
        final data = _safeDecode(res.body);
        if (data['success'] == true) {
          final list = (data['data'] as List)
              .map((e) => CompanyInvite.fromJson(e as Map<String, dynamic>))
              .toList();
          myInvitesList.assignAll(list);
          // إن كان فيه meta (ترقيم صفحات) احفظه إن تحتاجه لاحقًا
          // final meta = data['meta'];
        } else {
          print('fetchMyInvites success=false: ${res.body}');
          _toastError('تعذّر الجلب', data['message']?.toString() ?? 'خطأ غير متوقع');
        }
      } else {
        print('fetchMyInvites status ${res.statusCode}: ${res.body}');
        _toastError('تعذّر الجلب', _extractServerMessage(res));
      }
    } catch (e) {
      print('Exception fetchMyInvites: $e');
      _toastError('تعذّر الجلب', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  /// عدّاد سريع للدعوات المعلّقة لدي (عمليًا يجلب ثم يُحصي)
  Future<int> countMyPendingInvites({required int userId}) async {
    try {
      await fetchMyInvites(userId: userId, status: 'pending', perPage: 100);
      return myInvitesList.length;
    } catch (_) {
      return 0;
    }
  }

  /// قبول دعوة → ينشئ/يفعّل عضو تلقائيًا (يدعم avatarUrl اختياريًا)
  /// POST /invites/{inviteId}/accept
  Future<bool> acceptInvite({
    required int inviteId,
    required int userId,
    required String displayName,
    String? contactPhone,
    String? whatsappPhone,
    String? whatsappCallNumber,
    String? avatarUrl, // <-- الجديد
  }) async {
    isSaving.value = true;
    try {
      final uri = Uri.parse('$_baseUrl/invites/$inviteId/accept');
      final body = <String, String>{
        'user_id': userId.toString(),
        'display_name': displayName,
        if (contactPhone != null) 'contact_phone': contactPhone,
        if (whatsappPhone != null) 'whatsapp_phone': whatsappPhone,
        if (whatsappCallNumber != null) 'whatsapp_call_number': whatsappCallNumber,
        if (avatarUrl != null && avatarUrl.isNotEmpty) 'avatar_url': avatarUrl, // <-- أرسلها
      };

      final res = await _post(uri, body);

      if (res.statusCode == 200) {
        await fetchMyInvites(userId: userId, status: 'pending');
        return true;
      } else {
        print('acceptInvite status ${res.statusCode}: ${res.body}');
        _toastError('تعذّر القبول', _extractServerMessage(res));
      }
    } catch (e) {
      print('Exception acceptInvite: $e');
      _toastError('تعذّر القبول', e.toString());
    } finally {
      isSaving.value = false;
    }
    return false;
  }

  /// رفض دعوة
  /// POST /invites/{inviteId}/reject
  Future<bool> rejectInvite({
    required int inviteId,
    required int userId,
  }) async {
    isSaving.value = true;
    try {
      final uri = Uri.parse('$_baseUrl/invites/$inviteId/reject');
      final res = await _post(uri, {
        'user_id': userId.toString(),
      });

      if (res.statusCode == 200) {
        await fetchMyInvites(userId: userId, status: 'pending');
        return true;
      } else {
        print('rejectInvite status ${res.statusCode}: ${res.body}');
        _toastError('تعذّر الرفض', _extractServerMessage(res));
      }
    } catch (e) {
      print('Exception rejectInvite: $e');
      _toastError('تعذّر الرفض', e.toString());
    } finally {
      isSaving.value = false;
    }
    return false;
  }

  // ===================== Companies Picker =====================

  /// جلب شركات المستخدم لاختيار شركة لإرسال الدعوات
  /// GET /users/{userId}/companies?scope=owner|member|any
  Future<void> fetchMyCompanies({
    required int userId,
    String scope = 'owner',
  }) async {
    isLoading.value = true;
    try {
      final uri =
          Uri.parse('$_baseUrl/users/$userId/companies?scope=$scope');
      final res = await _get(uri);

      if (res.statusCode == 200) {
        final body = _safeDecode(res.body);
        if (body['success'] == true && body['data'] is List) {
          final list = (body['data'] as List)
              .map((e) => CompanySummary.fromJson(e as Map<String, dynamic>))
              .toList();
          myCompanies.assignAll(list);
        } else {
          print('fetchMyCompanies success=false: ${res.body}');
          _toastError('تعذّر الجلب', body['message']?.toString() ?? 'خطأ غير متوقع');
        }
      } else {
        print('fetchMyCompanies status ${res.statusCode}: ${res.body}');
        _toastError('تعذّر الجلب', _extractServerMessage(res));
      }
    } catch (e) {
      print('Exception fetchMyCompanies: $e');
      _toastError('تعذّر الجلب', e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
