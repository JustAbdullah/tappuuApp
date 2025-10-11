import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../core/data/model/AdvertiserProfile.dart';

class AdvertiserController extends GetxController {
  var loading = false.obs;
  var uploadedImageUrls = "".obs;
  var isSaving = false.obs;
  AdvertiserProfile? originalProfileForEdit;
  bool hasLogoChanged = false;

  final String uploadApiUrl =
      "https://stayinme.arabiagroup.net/lar_stayInMe/public/api/upload";

  var accountType = 'individual'.obs;

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

    if (originalProfileForEdit != null) {
      // originalProfileForEdit!.logo = null;
    }

    update(['logo']);
  }

  Future<void> uploadLogoToServer() async {
    try {
      loading.value = true;
      if (logoPath.value == null) {
        loading.value = false;
        return;
      }

      var request = http.MultipartRequest('POST', Uri.parse(uploadApiUrl));
      request.files.add(
        await http.MultipartFile.fromPath(
          'images[]',
          logoPath.value!.path,
        ),
      );

      var response = await request.send();
      if (response.statusCode == 201) {
        var responseData = await response.stream.bytesToString();
        var jsonData = json.decode(responseData);
        uploadedImageUrls.value =
            (List<String>.from(jsonData['image_urls']).isNotEmpty)
                ? List<String>.from(jsonData['image_urls']).first
                : "";
      } else {
        var responseData = await response.stream.bytesToString();
        throw Exception("Failed to upload image: ${response.statusCode} - $responseData");
      }
    } catch (e) {
      throw Exception("Failed to upload image: $e");
    } finally {
      loading.value = false;
    }
  }

  void setSaving(bool saving) {
    isSaving.value = saving;
    update(['button']);
  }

  final String baseUrl =
      "https://stayinme.arabiagroup.net/lar_stayInMe/public/api/advertiser-profiles";
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
        Get.snackbar(
          'خطأ',
          'فشل جلب البيانات',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'تأكد من اتصال الانترنت',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> createProfile(AdvertiserProfile profile) async {
    isLoading(true);
    try {
      final res = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(profile.toJson()),
      );

      if (res.statusCode == 201) {
        await fetchProfiles(profile.userId);

        Get.snackbar(
          'نجاح',
          'تم إنشاء ملف المعلن',
          snackPosition: SnackPosition.BOTTOM,
          duration: Duration(seconds: 2),
        );

        await Future.delayed(Duration(seconds: 2));
        Get.offAllNamed('/home');
      } else {
        final body = jsonDecode(res.body);
        Get.snackbar(
          'خطأ',
          body['message'] ?? 'فشل الإنشاء',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'تأكد من اتصال الانترنت',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> updateProfile(AdvertiserProfile updatedProfile) async {
    isLoading(true);
    try {
      final Map<String, dynamic> updatedData = {};

      if (updatedProfile.name != originalProfileForEdit?.name)
        updatedData['name'] = updatedProfile.name;

      if (updatedProfile.description != originalProfileForEdit?.description)
        updatedData['description'] = updatedProfile.description;

      if (updatedProfile.contactPhone != originalProfileForEdit?.contactPhone)
        updatedData['contact_phone'] = updatedProfile.contactPhone;

      if (updatedProfile.whatsappPhone != originalProfileForEdit?.whatsappPhone)
        updatedData['whatsapp_phone'] = updatedProfile.whatsappPhone;

      if (updatedProfile.whatsappCallNumber != originalProfileForEdit?.whatsappCallNumber)
        updatedData['whatsapp_call_number'] = updatedProfile.whatsappCallNumber;

      if (hasLogoChanged) updatedData['logo'] = updatedProfile.logo;

      if (updatedProfile.accountType != originalProfileForEdit?.accountType) {
        updatedData['account_type'] = updatedProfile.accountType ?? 'individual';
      }

      if (updatedData.isEmpty) {
        Get.snackbar(
          'تنبيه',
          'لم تقم بأي تغييرات',
          snackPosition: SnackPosition.BOTTOM,
        );
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
        final updatedProfileResponse =
            AdvertiserProfile.fromJson(responseData['profile']);

        final index = profiles.indexWhere((p) => p.id == originalProfileForEdit!.id);
        if (index != -1) {
          profiles[index] = updatedProfileResponse;
        }

        if (selected.value?.id == originalProfileForEdit!.id) {
          selected.value = updatedProfileResponse;
        }

        Get.snackbar(
          'نجاح',
          'تم تحديث ملف المعلن بنجاح',
          snackPosition: SnackPosition.BOTTOM,
          duration: Duration(seconds: 2),
        );

        await Future.delayed(Duration(seconds: 2));
        Get.back();
      } else {
        final body = jsonDecode(res.body);
        Get.snackbar(
          'خطأ',
          body['message'] ?? 'فشل التحديث',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'تأكد من اتصال الانترنت: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading(false);
    }
  }

  Rx<File?> logoPath = Rx<File?>(null);
  var businessNameCtrl = TextEditingController();
  var descriptionCtrl = TextEditingController();
  var contactPhoneCtrl = TextEditingController();
  var whatsappPhoneCtrl = TextEditingController();
  var whatsappCallNumberCtrl = TextEditingController();

  void updateButton() {
    update(['button']);
  }

  @override
  void onClose() {
    resetSelection();
    businessNameCtrl.dispose();
    descriptionCtrl.dispose();
    contactPhoneCtrl.dispose();
    whatsappPhoneCtrl.dispose();
    whatsappCallNumberCtrl.dispose();
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
  }

  void resetSelection() {
    selected.value = null;
    originalProfileForEdit = null;
    hasLogoChanged = false;
    uploadedImageUrls.value = "";
    logoPath.value = null;
    accountType.value = 'individual';
  }

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
        await createProfile(updatedProfile);
      } else {
        await updateProfile(updatedProfile);
      }
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'حدث خطأ أثناء الحفظ: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSaving.value = false;
      update(['button']);
    }
  }

  var isDeletingProfile = false.obs;

  Future<void> deleteProfile(int profileId) async {
    isDeletingProfile.value = true;
    try {
      final uri = Uri.parse('$baseUrl/$profileId');
      final response = await http.delete(uri);

      if (response.statusCode == 200) {
        Get.snackbar(
          'نجاح',
          'تم حذف ملف المعلن بنجاح',
          snackPosition: SnackPosition.BOTTOM,
        );
        profiles.removeWhere((p) => p.id == profileId);
        if (selected.value?.id == profileId) {
          selected.value = null;
          originalProfileForEdit = null;
        }
        update();
      } else {
        final body = json.decode(response.body);
        String msg = body['message'] ?? 'فشل في حذف ملف المعلن';
        throw Exception(msg);
      }
    } catch (e) {
      Get.snackbar(
        'خطأ',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isDeletingProfile.value = false;
      update();
    }
  }

  void setAccountType(String type) {
    if (type != 'individual' && type != 'company') return;
    accountType.value = type;
    update(['account_type']);
  }
}