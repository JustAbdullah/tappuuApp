import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../core/data/model/company_member.dart';

class CompanyMembersController extends GetxController {
  static const _baseUrl = 'https://stayinme.arabiagroup.net/lar_stayInMe/public/api';

  var members = <CompanyMember>[].obs;
  var isLoading = false.obs;
  var isSaving = false.obs;
  var isDeleting = false.obs;

  Future<void> fetchMembers(int companyId) async {
    isLoading.value = true;
    try {
      final uri = Uri.parse('$_baseUrl/companies/$companyId/members/');
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        if (body['success'] == true) {
          final list = (body['data'] as List)
              .map((e) => CompanyMember.fromJson(e as Map<String, dynamic>))
              .toList();
          members.value = list;
        }
      } else {
        print('fetchMembers status ${res.statusCode}: ${res.body}');
      }
    } catch (e) {
      print('Exception fetchMembers: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<CompanyMember?> fetchMember(int companyId, int memberId) async {
    try {
      final uri = Uri.parse('$_baseUrl/companies/$companyId/members/$memberId');
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        if (body['success'] == true) {
          return CompanyMember.fromJson(body['data'] as Map<String, dynamic>);
        }
      } else {
        print('fetchMember status ${res.statusCode}: ${res.body}');
      }
    } catch (e) {
      print('Exception fetchMember: $e');
    }
    return null;
  }

  /// إضافة عضو (المالك فقط)
  Future<bool> addMember({
    required int companyId,
    required int inviterUserId,
    required int userId,
    required String role, // publisher | viewer
    required String displayName,
    String? contactPhone,
    String? whatsappPhone,
    String? whatsappCallNumber,
  }) async {
    isSaving.value = true;
    try {
      final uri = Uri.parse('$_baseUrl/companies/$companyId/members/');
      final res = await http.post(uri, body: {
        'inviter_user_id': inviterUserId.toString(),
        'user_id': userId.toString(),
        'role': role,
        'display_name': displayName,
        if (contactPhone != null) 'contact_phone': contactPhone,
        if (whatsappPhone != null) 'whatsapp_phone': whatsappPhone,
        if (whatsappCallNumber != null) 'whatsapp_call_number': whatsappCallNumber,
      });

      final ok = res.statusCode == 201 || res.statusCode == 200;
      if (ok) {
        await fetchMembers(companyId);
        return true;
      } else {
        print('addMember status ${res.statusCode}: ${res.body}');
      }
    } catch (e) {
      print('Exception addMember: $e');
    } finally {
      isSaving.value = false;
    }
    return false;
  }

  /// تحديث عضو (المالك يقدر يعدّل كل شيء، العضو نفسه يعدّل بياناته الظاهرة فقط)
  Future<bool> updateMember({
    required int companyId,
    required int memberId,
    required int actorUserId,
    String? role, // owner | publisher | viewer
    String? status, // active | removed
    String? displayName,
    String? contactPhone,
    String? whatsappPhone,
    String? whatsappCallNumber,
  }) async {
    isSaving.value = true;
    try {
      final uri = Uri.parse('$_baseUrl/companies/$companyId/members/$memberId');
      final body = {
        'actor_user_id': actorUserId.toString(),
        if (role != null) 'role': role,
        if (status != null) 'status': status,
        if (displayName != null) 'display_name': displayName,
        if (contactPhone != null) 'contact_phone': contactPhone,
        if (whatsappPhone != null) 'whatsapp_phone': whatsappPhone,
        if (whatsappCallNumber != null) 'whatsapp_call_number': whatsappCallNumber,
      };

      final res = await http.put(uri, body: body);
      final ok = res.statusCode == 200;
      if (ok) {
        await fetchMembers(companyId);
        return true;
      } else {
        print('updateMember status ${res.statusCode}: ${res.body}');
      }
    } catch (e) {
      print('Exception updateMember: $e');
    } finally {
      isSaving.value = false;
    }
    return false;
  }

  /// إزالة عضو (status=removed) — المالك فقط
  Future<bool> removeMember({
    required int companyId,
    required int memberId,
    required int actorUserId,
  }) async {
    isDeleting.value = true;
    try {
      final uri = Uri.parse('$_baseUrl/companies/$companyId/members/$memberId');
      final res = await http.delete(uri, body: {
        'actor_user_id': actorUserId.toString(),
      });

      final ok = res.statusCode == 200;
      if (ok) {
        members.removeWhere((m) => m.id == memberId);
        return true;
      } else {
        print('removeMember status ${res.statusCode}: ${res.body}');
      }
    } catch (e) {
      print('Exception removeMember: $e');
    } finally {
      isDeleting.value = false;
    }
    return false;
  }
}
