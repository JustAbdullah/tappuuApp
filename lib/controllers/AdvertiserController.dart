import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../core/data/model/AdvertiserProfile.dart';

class AdvertiserController extends GetxController {
  // ================== الحالة ==================
  var loading = false.obs;
  var uploadedImageUrls = "".obs;
  var isSaving = false.obs;
  AdvertiserProfile? originalProfileForEdit;
  bool hasLogoChanged = false;

  // API Endpoints
  static const String _root =
      "https://stayinme.arabiagroup.net/lar_stayInMe/public/api";
  final String uploadApiUrl = "$_root/upload";
  final String baseUrl = "$_root/advertiser-profiles";

  // individual | company
  var accountType = 'individual'.obs;

  // ================== Pick/Upload Logo ==================
  Rx<File?> logoPath = Rx<File?>(null);

  Future<void> pickLogo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      logoPath.value = File(pickedFile.path);
      hasLogoChanged = true;
      update(['logo']);
    }
  }

  void removeLogo() {
    logoPath.value = null;
    uploadedImageUrls.value = "";
    hasLogoChanged = true;
    update(['logo']);
  }

  Future<void> uploadLogoToServer() async {
    try {
      loading.value = true;
      if (logoPath.value == null) {
        loading.value = false;
        return;
      }

      final request = http.MultipartRequest('POST', Uri.parse(uploadApiUrl));
      request.files.add(
        await http.MultipartFile.fromPath('images[]', logoPath.value!.path),
      );

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        final jsonData = json.decode(responseData);
        final list = List<String>.from(jsonData['image_urls']);
        uploadedImageUrls.value = list.isNotEmpty ? list.first : "";
      } else {
        throw Exception("Failed to upload image: ${response.statusCode} - $responseData");
      }
    } catch (e) {
      throw Exception("Failed to upload image: $e");
    } finally {
      loading.value = false;
    }
  }

  // ================== نصوص الإدخال ==================
  var businessNameCtrl = TextEditingController();
  var descriptionCtrl = TextEditingController();
  var contactPhoneCtrl = TextEditingController();
  var whatsappPhoneCtrl = TextEditingController();
  var whatsappCallNumberCtrl = TextEditingController();

  // جديد: اسم المالك الظاهر تحت الشركة (وقت الإنشاء فقط)
  var ownerDisplayNameCtrl = TextEditingController();

  void updateButton() => update(['button']);

  // ================== مصادر API للملف ==================
  var isLoading = false.obs;
  var profiles = <AdvertiserProfile>[].obs;
  var selected = Rxn<AdvertiserProfile>();

  Future<void> fetchProfiles(int userId) async {
    isLoading(true);
    try {
      final res = await http.get(Uri.parse('$baseUrl/$userId'));
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        profiles.value = data.map((e) => AdvertiserProfile.fromJson(e)).toList();
        update();
      } else {
        Get.snackbar('خطأ', 'فشل جلب البيانات', snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar('خطأ', 'تأكد من اتصال الانترنت', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading(false);
    }
  }

  // === إنشاء ملف معلن جديد (يرسل owner_display_name لو النوع شركة) ===
  Future<void> createProfile(AdvertiserProfile profile) async {
    isLoading(true);
    try {
      // 1) بناء جسم الطلب
      final Map<String, dynamic> bodyMap = profile.toJson();

      // أرسل رابط الشعار لو متوفر
      if (uploadedImageUrls.value.isNotEmpty) {
        bodyMap['logo'] = uploadedImageUrls.value;
      }

      // لو شركة — نرسل اسم المالك/المدير الظاهر
      if (accountType.value == 'company') {
        final ownerName = ownerDisplayNameCtrl.text.trim();
        if (ownerName.isNotEmpty) {
          bodyMap['owner_display_name'] = ownerName;
        }
      }

      // 2) الطلب مع مهلة
      final uri = Uri.parse(baseUrl);
      final res = await http
          .post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(bodyMap))
          .timeout(const Duration(seconds: 25));

      // نحاول قراءة الاستجابة
      final raw = res.body;
      Map<String, dynamic>? jsonBody;
      try {
        jsonBody = raw.isNotEmpty ? jsonDecode(raw) as Map<String, dynamic> : null;
      } catch (_) {
        jsonBody = null;
      }

      // 3) نجاح
      if (res.statusCode == 201 || res.statusCode == 200) {
        await fetchProfiles(profile.userId);
        Get.snackbar(
          'نجاح',
          'تم إنشاء ملف المعلن',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
        return;
      }

      // 4) أخطاء تحقق (Laravel 422)
      if (res.statusCode == 422) {
        final message = (jsonBody?['message'] as String?) ?? 'بعض الحقول غير صحيحة';
        final details = _formatValidationErrors(jsonBody?['errors'] as Map<String, dynamic>?);

        Get.snackbar(
          'الحقول غير صحيحة',
          '$message\n$details',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 5),
        );

        _logHttpError(
          tag: 'CREATE_PROFILE/VALIDATION',
          status: res.statusCode,
          url: uri.toString(),
          requestBody: bodyMap,
          responseBody: raw,
        );
        return;
      }

      // 5) أي خطأ آخر
      final serverMsg = (jsonBody?['message'] as String?) ?? 'حدث خطأ غير متوقع';
      Get.snackbar(
        'فشل الإنشاء',
        '(${res.statusCode}) $serverMsg',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );

      _logHttpError(
        tag: 'CREATE_PROFILE/ERROR',
        status: res.statusCode,
        url: uri.toString(),
        requestBody: bodyMap,
        responseBody: raw,
      );
    } on SocketException catch (e) {
      Get.snackbar('مشكلة اتصال', 'تحقق من الإنترنت أو الخادم.', snackPosition: SnackPosition.BOTTOM);
      debugPrint('[CREATE_PROFILE/NETWORK] SocketException: $e');
    } on TimeoutException catch (e) {
      Get.snackbar('انتهت المهلة', 'الخادم لم يستجب في الوقت المناسب.', snackPosition: SnackPosition.BOTTOM);
      debugPrint('[CREATE_PROFILE/TIMEOUT] $e');
    } on FormatException catch (e) {
      Get.snackbar('استجابة غير مفهومة', 'الخادم أعاد صيغة غير متوقعة.', snackPosition: SnackPosition.BOTTOM);
      debugPrint('[CREATE_PROFILE/FORMAT] $e');
    } catch (e, st) {
      Get.snackbar('خطأ غير متوقع', '$e', snackPosition: SnackPosition.BOTTOM);
      debugPrint('[CREATE_PROFILE/UNCAUGHT] $e\n$st');
    } finally {
      isLoading(false);
    }
  }

  /// يحوّل أخطاء Laravel 422 إلى نقاط مرتبة للمستخدم
  String _formatValidationErrors(Map<String, dynamic>? errors) {
    if (errors == null || errors.isEmpty) return '';
    final buf = StringBuffer('\n');
    errors.forEach((field, msgs) {
      if (msgs is List && msgs.isNotEmpty) {
        buf.writeln('• $field: ${msgs.first}');
      } else if (msgs is String && msgs.isNotEmpty) {
        buf.writeln('• $field: $msgs');
      }
    });
    return buf.toString();
  }

  /// طباعة احترافية لكل ما يلزمك وقت التطوير
  void _logHttpError({
    required String tag,
    required int status,
    required String url,
    required Map<String, dynamic> requestBody,
    required String responseBody,
  }) {
    debugPrint('''
[$tag]
→ URL: $url
→ Status: $status
→ Request JSON:
${const JsonEncoder.withIndent('  ').convert(requestBody)}
→ Response:
$responseBody
''');
  }

  Future<void> updateProfile(AdvertiserProfile updatedProfile) async {
    isLoading(true);
    try {
      final Map<String, dynamic> updatedData = {};

      if (updatedProfile.name != originalProfileForEdit?.name) {
        updatedData['name'] = updatedProfile.name;
      }
      if (updatedProfile.description != originalProfileForEdit?.description) {
        updatedData['description'] = updatedProfile.description;
      }
      if (updatedProfile.contactPhone != originalProfileForEdit?.contactPhone) {
        updatedData['contact_phone'] = updatedProfile.contactPhone;
      }
      if (updatedProfile.whatsappPhone != originalProfileForEdit?.whatsappPhone) {
        updatedData['whatsapp_phone'] = updatedProfile.whatsappPhone;
      }
      if (updatedProfile.whatsappCallNumber != originalProfileForEdit?.whatsappCallNumber) {
        updatedData['whatsapp_call_number'] = updatedProfile.whatsappCallNumber;
      }
      if (hasLogoChanged) {
        updatedData['logo'] = updatedProfile.logo;
      }
      if (updatedProfile.accountType != originalProfileForEdit?.accountType) {
        updatedData['account_type'] = updatedProfile.accountType ?? 'individual';
      }

      if (updatedData.isEmpty) {
        Get.snackbar('تنبيه', 'لم تقم بأي تغييرات', snackPosition: SnackPosition.BOTTOM);
        isLoading(false);
        return;
      }

      final res = await http.put(
        Uri.parse('$baseUrl/${originalProfileForEdit!.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updatedData),
      );

      if (res.statusCode == 200) {
        final responseData = jsonDecode(res.body);
        final updatedProfileResponse = AdvertiserProfile.fromJson(responseData['profile']);

        final index = profiles.indexWhere((p) => p.id == originalProfileForEdit!.id);
        if (index != -1) {
          profiles[index] = updatedProfileResponse;
        }

        if (selected.value?.id == originalProfileForEdit!.id) {
          selected.value = updatedProfileResponse;
        }

        Get.snackbar('نجاح', 'تم تحديث ملف المعلن بنجاح',
            snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 2));
      } else {
        final body = jsonDecode(res.body);
        Get.snackbar('خطأ', body['message'] ?? 'فشل التحديث', snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar('خطأ', 'تأكد من اتصال الانترنت: $e', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading(false);
    }
  }

  // ================== دوال العضو داخل الشركة (تعديل/مغادرة) ==================
  /// تعديل بياناتي كعضو داخل شركة (غير المالك لا يستطيع تغيير role/status)
  /// ملاحظة:
  /// - avatarUrl: إن مرّرت رابطًا سيتم تحديثه.
  ///   ولو مررته كسلسلة فارغة '' سيتم مسح الصورة من العضو.
  Future<void> updateMyCompanyMembership({
    required int companyId,
    required int memberId,
    required int actorUserId,
    required String displayName,
    String? contactPhone,
    String? whatsappPhone,
    String? whatsappCallNumber,
    String? avatarUrl, // NEW
  }) async {
    try {
      final uri = Uri.parse('$_root/companies/$companyId/members/$memberId');

      // جسم الطلب form-encoded
      final body = <String, String>{
        'actor_user_id': actorUserId.toString(),
        'display_name': displayName,
        if (contactPhone != null) 'contact_phone': contactPhone,
        if (whatsappPhone != null) 'whatsapp_phone': whatsappPhone,
        if (whatsappCallNumber != null) 'whatsapp_call_number': whatsappCallNumber,
        // لو null ما نرسل المفتاح، لو '' نرسله فاضي لمسح الصورة، ولو رابط نرسله للتحديث
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      };

      final res = await http.put(
        uri,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: body,
      );

      if (res.statusCode == 200) {
        Get.snackbar(
          'تم الحفظ',
          'تم تحديث بيانات العضو',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      } else {
        final m = _safeDecode(res.body);
        Get.snackbar(
          'تعذر التحديث',
          m['message']?.toString() ?? res.body,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar('خطأ', e.toString(), snackPosition: SnackPosition.BOTTOM);
    }
  }

  /// مغادرة الشركة (status=removed) — غير مسموح بحذف المالك
  Future<void> removeMyCompanyMembership({
    required int companyId,
    required int memberId,
    required int actorUserId,
  }) async {
    try {
      final uri = Uri.parse('$_root/companies/$companyId/members/$memberId');
      final res = await http.delete(
        uri,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'actor_user_id': actorUserId.toString(),
        },
      );

      if (res.statusCode == 200) {
        Get.snackbar('تم', 'غادرت الشركة بنجاح',
            snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 2));
      } else {
        final body = _safeDecode(res.body);
        Get.snackbar('تعذر الإجراء', body['message']?.toString() ?? res.body,
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar('خطأ', e.toString(), snackPosition: SnackPosition.BOTTOM);
    }
  }

  // ================== دورة حياة ==================
  @override
  void onClose() {
    resetSelection();
    businessNameCtrl.dispose();
    descriptionCtrl.dispose();
    contactPhoneCtrl.dispose();
    whatsappPhoneCtrl.dispose();
    whatsappCallNumberCtrl.dispose();
    ownerDisplayNameCtrl.dispose();
    super.onClose();
  }

  void loadProfileForEdit(AdvertiserProfile profile) {
    originalProfileForEdit = profile;
    businessNameCtrl.text = profile.name ?? '';
    descriptionCtrl.text = profile.description ?? '';
    contactPhoneCtrl.text = profile.contactPhone ?? '';
    whatsappPhoneCtrl.text = profile.whatsappPhone ?? '';
    whatsappCallNumberCtrl.text = profile.whatsappCallNumber ?? '';
    uploadedImageUrls.value = profile.logo ?? '';
    hasLogoChanged = false;
    logoPath.value = null;
    accountType.value = profile.accountType ?? 'individual';

    // في وضع التعديل لا نستخدم owner_display_name (خاص بالإنشاء للشركات)
    ownerDisplayNameCtrl.clear();
  }

  void resetSelection() {
    selected.value = null;
    originalProfileForEdit = null;
    hasLogoChanged = false;
    uploadedImageUrls.value = "";
    logoPath.value = null;
    accountType.value = 'individual';
    ownerDisplayNameCtrl.clear();
  }

  // ================== حفظ (ينادي create أو update) ==================
  Future<void> saveProfileChanges(int userId) async {
    if (isSaving.value) return;
    isSaving.value = true;
    update(['button']);

    try {
      if (hasLogoChanged && logoPath.value != null) {
        await uploadLogoToServer();
      }

      final updatedProfile = AdvertiserProfile(
        id: originalProfileForEdit?.id,
        userId: userId,
        name: businessNameCtrl.text.trim(),
        description: descriptionCtrl.text.trim(),
        contactPhone: contactPhoneCtrl.text.trim(),
        whatsappPhone: whatsappPhoneCtrl.text.trim(),
        whatsappCallNumber: whatsappCallNumberCtrl.text.trim(),
        logo: uploadedImageUrls.value.isNotEmpty
            ? uploadedImageUrls.value
            : originalProfileForEdit?.logo,
        accountType: accountType.value,
      );

      if (originalProfileForEdit == null) {
        // إنشاء جديد
        await createProfile(updatedProfile);
      } else {
        // تحديث
        await updateProfile(updatedProfile);
      }
    } catch (e) {
      Get.snackbar('خطأ', 'حدث خطأ أثناء الحفظ: $e', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isSaving.value = false;
      update(['button']);
    }
  }

  // ================== حذف ==================
  var isDeletingProfile = false.obs;

  Future<void> deleteProfile(int profileId) async {
    isDeletingProfile.value = true;
    try {
      final uri = Uri.parse('$baseUrl/$profileId');
      final response = await http.delete(uri);

      if (response.statusCode == 200) {
        Get.snackbar('نجاح', 'تم حذف ملف المعلن بنجاح', snackPosition: SnackPosition.BOTTOM);
        profiles.removeWhere((p) => p.id == profileId);
        if (selected.value?.id == profileId) {
          selected.value = null;
          originalProfileForEdit = null;
        }
        update();
      } else {
        final body = json.decode(response.body);
        final msg = body['message'] ?? 'فشل في حذف ملف المعلن';
        throw Exception(msg);
      }
    } catch (e) {
      Get.snackbar('خطأ', e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isDeletingProfile.value = false;
      update();
    }
  }

  // ================== نوع الحساب ==================
  void setAccountType(String type) {
    if (type != 'individual' && type != 'company') return;
    accountType.value = type;
    update(['account_type', 'button']);
  }

  // ================== أدوات مساعدة ==================
  Map<String, dynamic> _safeDecode(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {'raw': decoded};
    } catch (_) {
      return {'raw': body};
    }
  }
}
