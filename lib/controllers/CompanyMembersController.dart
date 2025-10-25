import 'dart:convert';
import 'dart:io';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../core/data/model/company_member.dart';

class CompanyMembersController extends GetxController {
  static const _root = 'https://stayinme.arabiagroup.net/lar_stayInMe/public/api';
  static const _uploadApi = '$_root/upload';

  var members = <CompanyMember>[].obs;
  var isLoading = false.obs;
  var isSaving = false.obs;
  var isDeleting = false.obs;

  // === Avatar (بنفس نمط الشعار) ===
  final Rx<File?> avatarFile = Rx<File?>(null);
  final uploadedAvatarUrl = ''.obs; // ناتج /upload
  bool avatarChanged = false;

  Future<void> pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      avatarFile.value = File(picked.path);
      avatarChanged = true;
      update(['avatar']);
    }
  }

  void removeAvatar() {
    avatarFile.value = null;
    uploadedAvatarUrl.value = '';
    avatarChanged = true;
    update(['avatar']);
  }

  /// يرفع الصورة لـ /upload ويعبّي uploadedAvatarUrl بقيمة أول رابط
  Future<void> uploadAvatarViaUploadApi() async {
    if (avatarFile.value == null) return;
    final req = http.MultipartRequest('POST', Uri.parse(_uploadApi));
    req.files.add(await http.MultipartFile.fromPath('images[]', avatarFile.value!.path));
    final resp = await req.send();
    final body = await resp.stream.bytesToString();
    if (resp.statusCode == 201) {
      final jsonBody = jsonDecode(body) as Map<String, dynamic>;
      final urls = List<String>.from(jsonBody['image_urls'] ?? const []);
      uploadedAvatarUrl.value = urls.isNotEmpty ? urls.first : '';
    } else {
      throw Exception('Upload avatar failed: ${resp.statusCode} $body');
    }
  }

  // ================== CRUD ==================

  Future<void> fetchMembers(int companyId) async {
    isLoading.value = true;
    try {
      final uri = Uri.parse('$_root/companies/$companyId/members/');
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
      final uri = Uri.parse('$_root/companies/$companyId/members/$memberId');
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
  /// خيار 1: تمرر avatarUrl
  /// خيار 2: تمرر avatarFile (نرسل Multipart مباشرة لنفس endpoint)
  /// خيار 3: تستخدم pickAvatar + uploadAvatarViaUploadApi ثم ما ترسل إلا avatar_url
  Future<bool> addMember({
    required int companyId,
    required int inviterUserId,
    required int userId,
    required String role, // publisher | viewer
    required String displayName,
    String? contactPhone,
    String? whatsappPhone,
    String? whatsappCallNumber,
    String? avatarUrl,
    File? avatarFileParam,
  }) async {
    isSaving.value = true;
    try {
      // أولوية: الملف الممرَّر للدالة > الملف الموجود في الحالة > avatarUrl الممرَّر
      final File? fileToSend = avatarFileParam ?? avatarFile.value;
      final String? urlToSend = (uploadedAvatarUrl.value.isNotEmpty)
          ? uploadedAvatarUrl.value
          : avatarUrl;

      if (fileToSend != null) {
        // Multipart مباشرة
        final req = http.MultipartRequest(
          'POST',
          Uri.parse('$_root/companies/$companyId/members/'),
        );
        req.fields.addAll({
          'inviter_user_id': inviterUserId.toString(),
          'user_id': userId.toString(),
          'role': role,
          'display_name': displayName,
          if (contactPhone != null) 'contact_phone': contactPhone,
          if (whatsappPhone != null) 'whatsapp_phone': whatsappPhone,
          if (whatsappCallNumber != null) 'whatsapp_call_number': whatsappCallNumber,
        });
        req.files.add(await http.MultipartFile.fromPath('avatar', fileToSend.path));

        final resp = await req.send();
        final body = await resp.stream.bytesToString();
        if (resp.statusCode == 201 || resp.statusCode == 200) {
          await fetchMembers(companyId);
          return true;
        } else {
          print('addMember/multipart status ${resp.statusCode}: $body');
          return false;
        }
      } else {
        // عادي x-www-form-urlencoded مع avatar_url (إن وُجد)
        final uri = Uri.parse('$_root/companies/$companyId/members/');
        final res = await http.post(uri, body: {
          'inviter_user_id': inviterUserId.toString(),
          'user_id': userId.toString(),
          'role': role,
          'display_name': displayName,
          if (contactPhone != null) 'contact_phone': contactPhone,
          if (whatsappPhone != null) 'whatsapp_phone': whatsappPhone,
          if (whatsappCallNumber != null) 'whatsapp_call_number': whatsappCallNumber,
          if (urlToSend != null && urlToSend.isNotEmpty) 'avatar_url': urlToSend,
        });

        final ok = res.statusCode == 201 || res.statusCode == 200;
        if (ok) {
          await fetchMembers(companyId);
          return true;
        } else {
          print('addMember status ${res.statusCode}: ${res.body}');
        }
      }
    } catch (e) {
      print('Exception addMember: $e');
    } finally {
      isSaving.value = false;
    }
    return false;
  }

  /// تحديث عضو
  /// يدعم:
  /// - avatarUrl عادي
  /// - أو avatarFile (نرسل Multipart مع _method=PUT)
  Future<bool> updateMember({
    required int companyId,
    required int memberId,
    required int actorUserId,
    String? role,   // owner | publisher | viewer
    String? status, // active | removed
    String? displayName,
    String? contactPhone,
    String? whatsappPhone,
    String? whatsappCallNumber,
    String? avatarUrl,
    File? avatarFileParam,
  }) async {
    isSaving.value = true;
    try {
      final File? fileToSend = avatarFileParam ?? avatarFile.value;
      final String? urlToSend = (uploadedAvatarUrl.value.isNotEmpty)
          ? uploadedAvatarUrl.value
          : avatarUrl;

      if (fileToSend != null) {
        // Multipart + method override PUT
        final req = http.MultipartRequest(
          'POST',
          Uri.parse('$_root/companies/$companyId/members/$memberId'),
        );
        req.fields.addAll({
          '_method': 'PUT',
          'actor_user_id': actorUserId.toString(),
          if (role != null) 'role': role,
          if (status != null) 'status': status,
          if (displayName != null) 'display_name': displayName,
          if (contactPhone != null) 'contact_phone': contactPhone,
          if (whatsappPhone != null) 'whatsapp_phone': whatsappPhone,
          if (whatsappCallNumber != null) 'whatsapp_call_number': whatsappCallNumber,
        });
        req.files.add(await http.MultipartFile.fromPath('avatar', fileToSend.path));

        final resp = await req.send();
        final body = await resp.stream.bytesToString();
        final ok = resp.statusCode == 200;
        if (ok) {
          await fetchMembers(companyId);
          return true;
        } else {
          print('updateMember/multipart status ${resp.statusCode}: $body');
          return false;
        }
      } else {
        // x-www-form-urlencoded مع avatar_url (إن وُجد)
        final uri = Uri.parse('$_root/companies/$companyId/members/$memberId');
        final body = {
          'actor_user_id': actorUserId.toString(),
          if (role != null) 'role': role,
          if (status != null) 'status': status,
          if (displayName != null) 'display_name': displayName,
          if (contactPhone != null) 'contact_phone': contactPhone,
          if (whatsappPhone != null) 'whatsapp_phone': whatsappPhone,
          if (whatsappCallNumber != null) 'whatsapp_call_number': whatsappCallNumber,
          if (urlToSend != null && urlToSend.isNotEmpty) 'avatar_url': urlToSend,
        };

        final res = await http.put(uri, body: body);
        final ok = res.statusCode == 200;
        if (ok) {
          await fetchMembers(companyId);
          return true;
        } else {
          print('updateMember status ${res.statusCode}: ${res.body}');
        }
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
      final uri = Uri.parse('$_root/companies/$companyId/members/$memberId');
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
