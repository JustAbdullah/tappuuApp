// lib/controllers/favorites_controller.dart

import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../core/data/model/AdResponse.dart';
import '../core/data/model/favorite.dart';
import '../core/localization/changelanguage.dart';
import 'LoadingController.dart';

class FavoritesController extends GetxController {
  final LoadingController _loadingController = Get.find<LoadingController>();
  static const _baseUrl = 'https://stayinme.arabiagroup.net/lar_stayInMe/public/api/favorites';

  var favorites = <Ad>[].obs;
  RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    favorites = <Ad>[].obs;
  }
Future<void> fetchFavorites({
  required int userId,
  String lang = 'ar',
  String timeframe = 'all',
  int page = 1,
  int perPage = 15,
  int? favoriteGroupId,
}) async {
  isLoading.value = true;
  try {
    final params = {
      'user_id': userId.toString(),
      'lang': Get.find<ChangeLanguageController>().currentLocale.value.languageCode,
      'timeframe': timeframe,
      'page': page.toString(),
      'per_page': perPage.toString(),
    };
    if (favoriteGroupId != null) {
      params['favorite_group_id'] = favoriteGroupId.toString();
    }

    final uri = Uri.parse('$_baseUrl/list').replace(queryParameters: params);

    print('🛠️ Fetching favorites from: $uri');
    final response = await http.get(uri);

    print('🛠️ Status code: ${response.statusCode}');
    print('🛠️ Response body: ${response.body}');

    if (response.statusCode != 200) {
      print('❌ Error fetching favorites: HTTP ${response.statusCode}');
      return;
    }

    final jsonData = json.decode(response.body) as Map<String, dynamic>;

    // 1) نحاول أولاً الحصول على القائمة من مفتاح ads (إن أضافناه في السيرفر)
    List<dynamic>? rawList = (jsonData['favorites']?['ads'] as List<dynamic>?);

    // 2) إن لم يكن، نستخدم data (الحالة القديمة)
    rawList = rawList ?? (jsonData['favorites']?['data'] as List<dynamic>?) ?? (jsonData['data'] as List<dynamic>?);

    // 3) إن لم نجد أي شيء، نهيّئ لقائمة فارغة
    final list = rawList ?? [];

    final parsed = <Ad>[];
    for (var i = 0; i < list.length; i++) {
      final element = list[i];

      try {
        if (element == null) {
          print('⚠️ favorites element #$i is null — skipping');
          continue;
        }

        // إذا العنصر هو wrapper يحتوي 'ad'
        if (element is Map<String, dynamic> && element.containsKey('ad')) {
          final adMap = element['ad'];
          if (adMap is Map<String, dynamic>) {
            parsed.add(Ad.fromJson(adMap));
            continue;
          } else {
            print('⚠️ favorites element[$i][\'ad\'] is not a Map, value: $adMap — skipping');
            continue;
          }
        }

        // أحياناً الـ API يعيد العنصر مباشرةً كـ Ad (flat structure)
        if (element is Map<String, dynamic> && element.containsKey('id') && (element.containsKey('title') || element.containsKey('title_ar') || element.containsKey('ad_number'))) {
          parsed.add(Ad.fromJson(element));
          continue;
        }

        // fallback: لو العنصر قائمة أو شكل آخر، حاول تحويله إلى Map بذكاء
        if (element is Map) {
          // حاول مع cast آمن
          final m = Map<String, dynamic>.from(element as Map);
          parsed.add(Ad.fromJson(m));
          continue;
        }

        // لا نعرف الصيغة — نسجل ونتخطى
        print('⚠️ Unrecognized favorites element #$i, skipping. element: $element');
      } catch (e, st) {
        // لا نسمح لأنقطاع العملية بسبب عنصر واحد معطوب
        print('🔥 Error parsing favorite element #$i -> $e');
        print(st);
        // dump the problematic element (stringify safely)
        try {
          print('🔥 Problematic element JSON: ${json.encode(element)}');
        } catch (_) {
          print('🔥 Problematic element (non-encodable): $element');
        }
        // متعمّق: استمر إلى العنصر التالي
        continue;
      }
    }

    favorites.value = parsed;
    print('✅ Loaded ${favorites.length} favorites');

  } catch (e, st) {
    print('🔥 Exception fetching favorites: $e');
    print(st);
  } finally {
    isLoading.value = false;
  }
}


  /// يضيف إعلان إلى المفضلة أو يحدث إعدادات المفضلة
  /// backend يتطلب favorite_group_id (إلزامي)
  Future<bool> addFavorite({
  required int userId,
  required int adId,
  required int favoriteGroupId,
  NotificationSettings? notificationSettings,
}) async {
  try {
    final uri = Uri.parse('$_baseUrl/add');

    final body = <String, String>{
      'user_id': userId.toString(),
      'ad_id': adId.toString(),
      'favorite_group_id': favoriteGroupId.toString(),
    };

    if (notificationSettings != null) {
      body.addAll(notificationSettings.toRequestBody());
    }

    final resp = await http.post(
      uri,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: body,
    );

    if (resp.statusCode == 200 || resp.statusCode == 201) {
      Get.snackbar('نجاح', 'تمت الإضافة/التحديث في المفضلة', snackPosition: SnackPosition.BOTTOM);
      await fetchFavorites(userId: userId);
      return true;
    } else {
      print('Error addFavorite: ${resp.statusCode} ${resp.body}');
      return false;
    }
  } catch (e, st) {
    print('Exception addFavorite: $e');
    print(st);
    return false;
  }
}

  /// تحديث إعدادات المفضلة (يستخدم نفس endpoint add)
  Future<void> updateFavoriteSettings({
    required int userId,
    required int adId,
    required int favoriteGroupId,
    required NotificationSettings settings,
  }) async {
    await addFavorite(
      userId: userId,
      adId: adId,
      favoriteGroupId: favoriteGroupId,
      notificationSettings: settings,
    );
  }

  /// نقل المفضلة لمجموعة أخرى (endpoint move)
  Future<void> moveFavoriteToGroup({
    required int userId,
    required int adId,
    int? favoriteGroupId, // nullable => لإلغاء المجموعة
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/move');
      final body = <String, String>{
        'user_id': userId.toString(),
        'ad_id': adId.toString(),
      };
      if (favoriteGroupId != null) {
        body['favorite_group_id'] = favoriteGroupId.toString();
      } else {
        body['favorite_group_id'] = ''; // بعض باكدينات يفضّل إرسال الحقل فارغ لإلغاء التعيين
      }

      final resp = await http.post(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      );

      if (resp.statusCode == 200) {
        Get.snackbar('نجاح', 'تم نقل المفضلة للمجموعة', snackPosition: SnackPosition.BOTTOM);
        await fetchFavorites(userId: userId);
      } else {
        print('Error moveFavoriteToGroup: ${resp.statusCode} ${resp.body}');
      }
    } catch (e, st) {
      print('Exception moveFavoriteToGroup: $e');
      print(st);
    }
  }

  /// يزيل إعلان من المفضلة
  Future<void> removeFavorite({
    required int userId,
    required int adId,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/remove');
      final resp = await http.delete(uri, body: {
        'user_id': userId.toString(),
        'ad_id': adId.toString(),
      });

      if (resp.statusCode == 200) {
        Get.snackbar('نجاح', 'تم بنجاح الإزالة من مفضلتك', snackPosition: SnackPosition.BOTTOM);
        await fetchFavorites(userId: userId);
      } else {
        print('Error removeFavorite: ${resp.statusCode} ${resp.body}');
      }
    } catch (e, st) {
      print('Exception removeFavorite: $e');
      print(st);
    }
  }

  void checkIsHaveAccountFavorite(int idAd) {
    if (_loadingController.currentUser != null) {
      // هنا لن يتمكن من الإضافة لأن favoriteGroupId إلزامي؛ استدعاء واجهة اختيار/إنشاء مجموعة مطلوب
      // لذا نعرض تحذير أو نفتح شاشة اختيار المجموعة
      Get.snackbar('تنبيه', 'اختر مجموعة قبل الإضافة إلى المفضلة', snackPosition: SnackPosition.BOTTOM);
    } else {
      Get.snackbar('تنبيه', 'يجب تسجيل الدخول لإضافة مفضلات', snackPosition: SnackPosition.BOTTOM);
    }
  }
}
