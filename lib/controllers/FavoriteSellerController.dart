import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../core/constant/app_text_styles.dart';
import '../core/constant/appcolors.dart';
import '../core/data/model/FavoriteSeller.dart';
import '../core/data/model/AdResponse.dart';
import 'areaController.dart';  // لتحليل الـ JSON إلى قائمة Ad

class FavoriteSellerController extends GetxController {
  // عدّل هذا حسب عنوان الـ API عندك
  final String _baseUrl = 'https://stayinme.arabiagroup.net/lar_stayInMe/public/api';

  // لائحة المعلنين المفضلين
  var favoriteList       = <FavoriteSeller>[].obs;
  var isLoadingFavorites = false.obs;
  var isToggling         = false.obs;

  /// جلب جميع المعلنين الذين تابعهم المستخدم
  Future<void> fetchFavorites({ required int userId }) async {
    isLoadingFavorites.value = true;
    try {
      final uri = Uri.parse('$_baseUrl/advertiser-follows/user/$userId');
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final result = json.decode(res.body) as Map<String, dynamic>;
        if (result['success'] == true) {
         final list = (result['data'] as List)
    .map((e) => FavoriteSeller.fromJson(e as Map<String, dynamic>))
    .toList();
favoriteList.value = list;
        }
      }
    } catch (e) {
      print('Exception fetchFavorites: $e');
    } finally {
      isLoadingFavorites.value = false;
    }
  }

  /// متابعة أو إلغاء متابعة (toggle)
   /// متابعة أو إلغاء متابعة (toggle) باستخدام معرف المستخدم ومعرف المعلن فقط
 Future<bool> toggleFavoriteByIds({
  required int userId,
  required int advertiserProfileId,
}) async {
  isToggling.value = true;
  try {
    final uri = Uri.parse('$_baseUrl/advertiser-follows/toggle');
    final body = {
      'user_id': userId,
      'advertiser_profile_id': advertiserProfileId,
    };

    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    if (res.statusCode == 200) {
      final Map<String, dynamic> result = json.decode(res.body) as Map<String, dynamic>;
      if (result['success'] == true) {
        final action = (result['action'] ?? '').toString().toLowerCase(); // "followed" | "unfollowed"
        final followId = result['follow_id'];
        debugPrint('toggleFavoriteByIds: action=$action followId=$followId');

        // إبقاء الحالة متزامنة مع السيرفر
        await fetchFavorites(userId: userId);

        // مظهر Snackbar محسّن
        final bool didFollow = action == 'followed' || action == 'follow';
        final Color bg = didFollow ? const Color(0xFF10B981) : const Color(0xFF3B82F6); // أخضر/أزرق
        final IconData icon = didFollow ? Icons.check_circle_rounded : Icons.undo_rounded;
        final String title = didFollow ? 'نجاح'.tr : 'تم إلغاء المتابعة'.tr;
        final String message = didFollow ? 'تم متابعة المعلن بنجاح.'.tr : 'تم إلغاء متابعة هذا المعلن.'.tr;

        // لمسة اهتزاز خفيفة
        HapticFeedback.lightImpact();
        Get.closeAllSnackbars();
        Get.snackbar(
          '',
          '',
          snackPosition: SnackPosition.BOTTOM,
          snackStyle: SnackStyle.FLOATING,
          margin: const EdgeInsets.all(12),
          borderRadius: 14,
          backgroundColor: bg.withOpacity(0.96),
          icon: Icon(icon, color: Colors.white),
          duration: const Duration(seconds: 3),
          animationDuration: const Duration(milliseconds: 250),
          forwardAnimationCurve: Curves.easeOutBack,
          reverseAnimationCurve: Curves.easeIn,
          titleText: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppTextStyles.appFontFamily,
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),
          messageText: Text(
            message,
            style: TextStyle(
              fontFamily: AppTextStyles.appFontFamily,
              fontSize: 14,
              color: Colors.white,
              height: 1.25,
            ),
          ),
        );

        return true;
      } else {
        debugPrint('toggleFavoriteByIds: success == false, body: ${res.body}');
        final serverMsg = (result['message'] ?? '').toString();

        HapticFeedback.mediumImpact();
        Get.closeAllSnackbars();
        Get.snackbar(
          '',
          '',
          snackPosition: SnackPosition.BOTTOM,
          snackStyle: SnackStyle.FLOATING,
          margin: const EdgeInsets.all(12),
          borderRadius: 14,
          backgroundColor: const Color(0xFFEF4444).withOpacity(0.96), // أحمر فشل
          icon: const Icon(Icons.error_outline_rounded, color: Colors.white),
          duration: const Duration(seconds: 3),
          titleText: Text(
            'فشل'.tr,
            style: TextStyle(
              fontFamily: AppTextStyles.appFontFamily,
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          messageText: Text(
            serverMsg.isNotEmpty ? serverMsg : 'لم يتم متابعة المعلن.'.tr,
            style: TextStyle(
              fontFamily: AppTextStyles.appFontFamily,
              fontSize: 14,
              color: Colors.white,
              height: 1.25,
            ),
          ),
        );
      }
    } else {
      debugPrint('toggleFavoriteByIds: status ${res.statusCode}, body: ${res.body}');
      HapticFeedback.mediumImpact();
      Get.closeAllSnackbars();
      Get.snackbar(
        '',
        '',
        snackPosition: SnackPosition.BOTTOM,
        snackStyle: SnackStyle.FLOATING,
        margin: const EdgeInsets.all(12),
        borderRadius: 14,
        backgroundColor: const Color(0xFFEF4444).withOpacity(0.96),
        icon: const Icon(Icons.error_outline_rounded, color: Colors.white),
        duration: const Duration(seconds: 3),
        titleText: Text(
          'فشل'.tr,
          style: TextStyle(
            fontFamily: AppTextStyles.appFontFamily,
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        messageText: Text(
          'خطأ في الخادم (${res.statusCode}).'.tr,
          style: TextStyle(
            fontFamily: AppTextStyles.appFontFamily,
            fontSize: 14,
            color: Colors.white,
            height: 1.25,
          ),
        ),
      );
    }
  } 


   catch (e, st) {
    debugPrint('Exception toggleFavoriteByIds: $e\n$st');
    HapticFeedback.mediumImpact();
    Get.closeAllSnackbars();
    Get.snackbar(
      '',
      '',
      snackPosition: SnackPosition.BOTTOM,
      snackStyle: SnackStyle.FLOATING,
      margin: const EdgeInsets.all(12),
      borderRadius: 14,
      backgroundColor: const Color(0xFFEF4444).withOpacity(0.96),
      icon: const Icon(Icons.error_outline_rounded, color: Colors.white),
      duration: const Duration(seconds: 3),
      titleText: Text(
        'فشل'.tr,
        style: TextStyle(
          fontFamily: AppTextStyles.appFontFamily,
          fontWeight: FontWeight.w800,
          fontSize: 16,
          color: Colors.white,
        ),
      ),
      messageText: Text(
        'حدث خطأ غير متوقع.'.tr,
        style: TextStyle(
          fontFamily: AppTextStyles.appFontFamily,
          fontSize: 14,
          color: Colors.white,
          height: 1.25,
        ),
      ),
    );
  } finally {
    isToggling.value = false;
  }
  return false;
}



  // =====================================================
  // هنا نبدأ إضافة دالة جلب إعلانات كل معلن حسب معرفه
  // =====================================================

  /// قائمة إعلانات المعلِن المفضل
  var advertiserAdsList       = <Ad>[].obs;
  var isLoadingAdvertiserAds = false.obs;
var adsCount = 0.obs;
var areasText = ''.obs;


void updateAdvertiserStats(List<Ad> ads, AreaController areaController) {
  adsCount.value = ads.length;

  final areas = <String>{};
  for (final ad in ads) {
    if (ad.areaId != null) {
      final areaName = areaController.getAreaNameById(ad.areaId);
      if (areaName != null && areaName.isNotEmpty) {
        areas.add(areaName);
      }
    }
  }
  areasText.value = areas.isNotEmpty ? areas.join('، ') : 'لا توجد مناطق محددة'.tr;
}
 Future<void> fetchAdvertiserAds({
  required int advertiserProfileId,
  String lang    = 'ar',
  String status  = 'published',
  int page       = 1,
  int perPage    = 15,
}) async {
  isLoadingAdvertiserAds.value = true;
  try {
 final queryParameters = {
  'advertiser_profile_id': advertiserProfileId.toString(),
  'lang':     lang,
  'status':   status,
  'page':     page.toString(),
  'per_page': perPage.toString(),
};

final uri = Uri.parse('$_baseUrl/ads/advertiser/$advertiserProfileId')
    .replace(queryParameters: queryParameters);



    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body) as Map<String, dynamic>;
      final adResponse = AdResponse.fromJson(jsonData);
      advertiserAdsList.value = adResponse.data;


  final areaController = Get.find<AreaController>();
  updateAdvertiserStats(advertiserAdsList, areaController);
    } else {
      print('Error fetching advertiser ads, status: ${response.statusCode}');
      try {
        final err = json.decode(response.body) as Map<String, dynamic>;
        if (err.containsKey('errors')) {
          print('▶ Validation errors:');
          (err['errors'] as Map<String, dynamic>).forEach((field, msgs) {
            print(' - $field: ${(msgs as List).join(", ")}');
          });
        } else if (err.containsKey('message')) {
          print('▶ Message: ${err['message']}');
        } else {
          print('▶ Response body: ${response.body}');
        }
      } catch (parseError) {
        print('▶ Failed to parse error body: $parseError');
        print('▶ Raw body: ${response.body}');
      }
    }
  } catch (e) {
    print('Exception fetchAdvertiserAds: $e');
  } finally {
    isLoadingAdvertiserAds.value = false;
  }
}

}
