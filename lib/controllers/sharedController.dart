// lib/controllers/sharedController.dart (محدّث)
// استبدلت كل استدعاءات `log(...)` بـ `debugPrint(...)`
// تأكد من تعديل مسارات الاستيراد إذا كانت مختلفة في مشروعك.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';

import '../core/data/model/AdResponse.dart';
import '../views/viewAdsScreen/AdLoadingCleanScreen.dart';
// عدّل المسار إذا كان مختلفًا في مشروعك
import '../views/viewAdsScreen/AdsScreen.dart';

class SharedController extends GetxController {
  final String _baseUrl = 'https://stayinme.arabiagroup.net/lar_stayInMe/public/api';
  RxBool isNavigatingToAd = false.obs; // إضافة جديدة لمنع التداخل

  // بيانات الإعلان المفصّل (قابلة للملاحظة)
  Rx<Ad?> adDetails = Rx<Ad?>(null);
  RxBool isLoadingAd = false.obs;
  RxString currentAdId = ''.obs;

  // لمنع تكرار معالجة نفس الـ deep link بسرعة
  DateTime? _lastProcessedAt;
  static const Duration _minProcessInterval = Duration(milliseconds: 1200);

  RxBool hasPendingDeepLink = false.obs;

  // استدعاء عندما ينتهي التعامل أو تريد إعادة التعيين
  void markDeepLinkHandled() {
    resetDeepLinkState();
  }

  // دالة جديدة لإعادة تعيين حالة الروابط العميقة
  void resetDeepLinkState() {
    hasPendingDeepLink.value = false;
    currentAdId.value = '';
  }

  // ---------------------- Helpers ----------------------
  int? _tryParseInt(String? s) {
    if (s == null) return null;
    return int.tryParse(s);
  }

  double? _tryParseDouble(String? s) {
    if (s == null) return null;
    return double.tryParse(s);
  }

  List<Map<String, dynamic>>? _tryParseAttributes(String? encoded) {
    if (encoded == null || encoded.trim().isEmpty) return null;
    try {
      // قد يكون مُشفر URI — فك التشفير ثم decode JSON
      final decoded = Uri.decodeComponent(encoded);
      final data = jsonDecode(decoded);
      if (data is List) {
        return List<Map<String, dynamic>>.from(data.map((e) => Map<String, dynamic>.from(e)));
      }
    } catch (e, st) {
      debugPrint('Failed parsing attributes from deep link: $e\n$st');
    }
    return null;
  }

  List<int>? _tryParseAdIds(String? csv) {
    if (csv == null || csv.trim().isEmpty) return null;
    try {
      return csv.split(',').map((s) => int.tryParse(s.trim())).whereType<int>().toList();
    } catch (e) {
      return null;
    }
  }

  // ---------------------- Deep link handler ----------------------
 // ---------------------- Deep link handler ----------------------
// ---------------------- Deep link handler ----------------------
void handleDeepLink(String link) {
  try {
    final uri = Uri.parse(link);
    final now = DateTime.now();

    // تجنب معالجة الروابط المتكررة بسرعة كبيرة
    if (_lastProcessedAt != null && now.difference(_lastProcessedAt!) < _minProcessInterval) {
      debugPrint('Ignoring deep link because it was fired too soon again.');
      return;
    }
    _lastProcessedAt = now;

    // تجاهل الروابط إذا كان هناك تنقل نشط
    if (isNavigatingToAd.value) {
      debugPrint('Ignoring deep link: Navigation already in progress');
      return;
    }

    // التحقق من أن الرابط مدعوم
    final bool isSupportedHost = (uri.scheme == 'https' && uri.host == 'testing.arabiagroup.net');
    final bool isSupportedScheme = (uri.scheme == 'stayinme');

    if (!isSupportedHost && !isSupportedScheme) {
      debugPrint('Deep link not supported: $uri');
      return;
    }

    // معالجة مسارات الإعلانات
    if (uri.path == '/ads' || uri.path.startsWith('/ads/')) {
      
      // حالة: رابط تفاصيل إعلان فردي (/ads/{id})
      if (uri.pathSegments.length >= 2 && uri.pathSegments[1].trim().isNotEmpty) {
        final adId = uri.pathSegments[1];

        // منع معالجة نفس الإعلان مرتين
        if (currentAdId.value == adId) {
          debugPrint('Deep link for ad $adId ignored because it is already current.');
          return;
        }

        // تمييز بدء عملية التنقل
        isNavigatingToAd.value = true;
        currentAdId.value = adId;
        hasPendingDeepLink.value = true;
        debugPrint('Deep link processing started for adId=$adId; navigating to loader...');

        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future.delayed(const Duration(milliseconds: 300), () {
            try {
              // الحل النهائي: استخدام offAll مع إزالة كل الشاشات السابقة
             Get.to(
                () => AdLoadingCleanScreen(adId: adId), 
               
               
             
                duration: Duration.zero, // إلغاء أي انتقالات متحركة
              );

              ///اختبار تجريبي
             // Get.to(()=> TestingApp());
               
              debugPrint('Navigated to AdLoadingScreen for adId=$adId');
            } catch (e, st) {
              debugPrint('Error navigating to AdLoadingScreen: $e\n$st');
              resetDeepLinkState();
              isNavigatingToAd.value = false;
            }
          });
        });
        return;
      }

      // حالة: رابط صفحة الإعلانات مع فلتر (/ads?query=params)
      final params = uri.queryParameters;

      final int? categoryId = _tryParseInt(params['category_id']);
      final int? sub1 = _tryParseInt(params['sub_category_level_one_id']);
      final int? sub2 = _tryParseInt(params['sub_category_level_two_id']);
      final String? search = params['search'];
      final String? sortBy = params['sort_by'];
      final String order = params['order'] ?? 'desc';
      final double? lat = _tryParseDouble(params['latitude']);
      final double? lng = _tryParseDouble(params['longitude']);
      final double? distance = _tryParseDouble(params['distance']);
      final List<Map<String, dynamic>>? attributes = _tryParseAttributes(params['attributes']);
      final int? cityId = _tryParseInt(params['city_id']);
      final int? areaId = _tryParseInt(params['area_id']);
      final String? timeframe = params['timeframe'];
      final bool onlyFeatured = (params['only_featured'] == '1' || params['only_featured'] == 'true');
      final String? preset = params['preset'];
      final String? lang = params['lang'];
      final int page = _tryParseInt(params['page']) ?? 1;
      final int perPage = _tryParseInt(params['per_page']) ?? 15;
      final List<int>? adIds = _tryParseAdIds(params['ad_ids']);

      // تمييز الرابط كقيد المعالجة
      isNavigatingToAd.value = true;
      hasPendingDeepLink.value = true;
      debugPrint('Deep link (listing) processing started with params: category=$categoryId, sub1=$sub1, sub2=$sub2, search=$search');

      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 250), () {
          try {
            // الحل النهائي: إزالة كافة الشاشات السابقة
            Get.offAll(
              () => AdsScreen(
                titleOfpage: search?.isNotEmpty == true ? search! : (preset ?? 'الإعلانات'),
                categoryId: categoryId,
                subCategoryId: sub1,
                subTwoCategoryId: sub2,
                nameOfMain: null,
                nameOFsub: null,
                nameOFsubTwo: null,
                currentTimeframe: timeframe,
                onlyFeatured: onlyFeatured,
                countofAds: 0,
                cityId: cityId,
                areaId: areaId,
              ),
              predicate: (route) => false, // إزالة كافة الشاشات السابقة
              duration: Duration.zero, // إلغاء أي انتقالات متحركة
            );
            debugPrint('Navigated to AdsScreen with deep link params.');
          } catch (e, st) {
            debugPrint('Error navigating to AdsScreen: $e\n$st');
            resetDeepLinkState();
          } finally {
            isNavigatingToAd.value = false;
          }
        });
      });
      return;
    }

    debugPrint('Deep link path not recognized: $uri');
  } catch (e, st) {
    debugPrint('Error in handleDeepLink: $e\n$st');
    resetDeepLinkState();
    isNavigatingToAd.value = false;
  }
}

  /// يجلب تفاصيل الإعلان من API ويعيد الـ Ad إذا نجحت العملية، أو null عند الفشل.
  Future<Ad?> fetchAdDetails({
    required String adId,
    String lang = 'ar',
    Duration timeout = const Duration(seconds: 12),
  }) async {
    isLoadingAd.value = true;

    final Uri uri = Uri.parse('$_baseUrl/ads/details')
        .replace(queryParameters: {'ad_id': adId, 'lang': lang});

    try {
      debugPrint('>> fetchAdDetails - GET: $uri');

      final headers = <String, String>{
        'Accept': 'application/json',
      };

      final res = await http.get(uri, headers: headers).timeout(
            timeout,
            onTimeout: () {
              throw TimeoutException('Request timed out after ${timeout.inSeconds}s');
            },
          );

      debugPrint('<< fetchAdDetails - status: ${res.statusCode}');
      debugPrint('<< fetchAdDetails - body: ${res.body}');

      if (res.statusCode != 200) {
        dynamic errorJson;
        try {
          errorJson = jsonDecode(res.body);
        } catch (_) {
          errorJson = null;
        }

        if (res.statusCode == 422 && errorJson != null && errorJson['errors'] != null) {
          final errors = errorJson['errors'];
          final String errorMessage = (errors is Map)
              ? errors.values.map((v) => (v is List ? v.join(', ') : v.toString())).join('\n')
              : 'Validation error';
          debugPrint('!! Validation (422) errors: $errors');
          Get.snackbar('خطأ'.tr, errorMessage, duration: const Duration(seconds: 4));
        } else {
          final serverMsg = errorJson != null
              ? (errorJson['message'] ?? errorJson['error'] ?? res.body)
              : res.body;
          debugPrint('!! Server error (${res.statusCode}): $serverMsg');
          Get.snackbar('خطأ من الخادم'.tr, 'حدث خطأ (${res.statusCode}).'.tr,
              duration: const Duration(seconds: 4));
        }

        adDetails.value = null;
        return null;
      }

      // هنا status code == 200
      dynamic jsonData;
      try {
        jsonData = jsonDecode(res.body);
      } on FormatException catch (fe, st) {
        debugPrint('!! JSON FormatException: $fe\n$st');
        Get.snackbar('خطأ في البيانات'.tr, 'استجابة الخادم ليست بصيغة صحيحة.'.tr,
            duration: const Duration(seconds: 4));
        adDetails.value = null;
        return null;
      }

      final statusRaw = jsonData['status'];
      final bool isSuccess = (statusRaw == true) ||
          (statusRaw is String && statusRaw.toString().toLowerCase() == 'success');

      if (jsonData is Map && isSuccess && jsonData['data'] != null) {
        try {
          final Ad ad = Ad.fromJson(jsonData['data']);
          adDetails.value = ad;
          return ad;
        } catch (parseErr, st) {
          debugPrint('!! Error parsing Ad.fromJson: $parseErr\n$st');
          Get.snackbar('خطأ'.tr, 'فشل تحويل بيانات الإعلان.'.tr, duration: const Duration(seconds: 4));
          adDetails.value = null;
          return null;
        }
      }

      if (statusRaw is String && statusRaw.toLowerCase() == 'fail') {
        final errors = jsonData['errors'];
        debugPrint('!! Server validation fail: $errors');
        final String errorMessage = errors is Map
            ? errors.values.map((v) => (v is List ? v.join(', ') : v.toString())).join('\n')
            : (jsonData['message'] ?? 'فشل في جلب الإعلان');
        Get.snackbar('خطأ'.tr, errorMessage, duration: const Duration(seconds: 4));
        adDetails.value = null;
        return null;
      }

      if (statusRaw is String && statusRaw.toLowerCase() == 'error') {
        final serverMsg = jsonData['message'] ?? jsonData['error'] ?? 'حدث خطأ من الخادم';
        debugPrint('!! Server returned error: $serverMsg');
        Get.snackbar('خطأ من الخادم'.tr, serverMsg.toString(), duration: const Duration(seconds: 4));
        adDetails.value = null;
        return null;
      }

      debugPrint('!! Unexpected response structure: $jsonData');
      Get.snackbar('خطأ'.tr, 'استجابة غير متوقعة من الخادم.'.tr, duration: const Duration(seconds: 4));
      adDetails.value = null;
      return null;
    } on SocketException catch (se, st) {
      debugPrint('!! SocketException: $se\n$st');
      Get.snackbar('خطأ في الاتصال'.tr, 'لا يوجد اتصال بالإنترنت أو لا يمكن الوصول إلى الخادم.'.tr,
          duration: const Duration(seconds: 4));
      adDetails.value = null;
      return null;
    } on TimeoutException catch (te, st) {
      debugPrint('!! TimeoutException: $te\n$st');
      Get.snackbar('انتهت المهلة'.tr, 'انتهت مهلة الاتصال بالخادم، حاول لاحقًا.'.tr,
          duration: const Duration(seconds: 4));
      adDetails.value = null;
      return null;
    } on HttpException catch (he, st) {
      debugPrint('!! HttpException: $he\n$st');
      Get.snackbar('خطأ من الخادم'.tr, 'حدث خطأ أثناء الاتصال بالخادم.'.tr,
          duration: const Duration(seconds: 4));
      adDetails.value = null;
      return null;
    } catch (e, st) {
      debugPrint('!! Unknown error in fetchAdDetails: $e\n$st');
      Get.snackbar('خطأ'.tr, 'فشل تحميل تفاصيل الإعلان: ${e.toString()}', duration: const Duration(seconds: 5));
      adDetails.value = null;
      return null;
    } finally {
      isLoadingAd.value = false;
    }
  }

  /// مشاركة رابط الإعلان
  void shareAd(int adId) {
    final httpsLink = 'https://testing.arabiagroup.net/ads/$adId';
    Share.share('شاهد الإعلان: $httpsLink');
  }

  void resetAdDetails() {
    adDetails.value = null;
    currentAdId.value = '';
  }

  @override
  void onClose() {
    debugPrint('SharedController.onClose - resetting ad details.');
    resetDeepLinkState();
    super.onClose();
  }
}
