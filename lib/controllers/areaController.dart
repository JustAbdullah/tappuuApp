// lib/core/controllers/area_controller.dart

import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../core/data/model/Area.dart';
import '../core/localization/changelanguage.dart';

class AreaController extends GetxController {
  // Observable لقائمة المناطق الجارية
  final RxList<Area> areas = <Area>[].obs;

  // معرف المنطقة المحدد (مثل ما كنت تستخدم)
  final idOfArea = Rx<int?>(null);

  // حالة التحميل للاستخدام في الواجهات
  final RxBool isLoading = false.obs;

  // كاش داخلي: المفتاح '<cityId>_<lang>'
  final Map<String, List<Area>> _cache = {};

  // غيّر إلى الـ base URL عندك
  final String baseUrl = 'https://stayinme.arabiagroup.net/lar_stayInMe/public/api';

  // (اختياري) توكن المصادقة إذا مطلوب
  String? authToken;

  /// يبني مفتاح الكاش
  String _cacheKey(int cityId, String lang) => '${cityId}_$lang';

  /// جلب المناطق للمدينة من الـ API.
  /// - يعيد true لو نجح، false لو فشل.
  /// - يستخدم الكاش ما لم تطلب forceRefresh = true.
  Future<bool> fetchAreas(int cityId, {bool forceRefresh = false}) async {
    final langCode = _safeLangCode();
    final key = _cacheKey(cityId, langCode);

    // إرجاع من الكاش إن وجد ولم يُطلب تحديث قسري
    if (!forceRefresh && _cache.containsKey(key)) {
      areas.value = _cache[key]!;
      return true;
    }

    isLoading.value = true;
    try {
      final uri = Uri.parse('$baseUrl/areas/city/$cityId')
          .replace(queryParameters: {'lang': langCode});

      final headers = <String, String>{
        'Accept': 'application/json',
        'Accept-Language': langCode,
      };
      if (authToken != null && authToken!.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final response = await http.get(uri, headers: headers).timeout(
            const Duration(seconds: 15),
          );

      if (response.statusCode == 200) {
        final body = response.body;
        final decoded = json.decode(body);

        // نتعامل مع احتمال أن الـ API يرجع كائن يحتوي على data أو يرجع مباشرة مصفوفة
        List<dynamic> list;
        if (decoded is Map && decoded['data'] is List) {
          list = List<dynamic>.from(decoded['data']);
        } else if (decoded is List) {
          list = List<dynamic>.from(decoded);
        } else {
          // شكّل غير متوقع
          print('AreaController.fetchAreas: unexpected response structure');
          isLoading.value = false;
          return false;
        }

        final fetched = list
            .map((e) => Area.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        // خزّن في الكاش وحدّث الـ observable
        _cache[key] = fetched;
        areas.value = fetched;
        isLoading.value = false;
        return true;
      } else {
        // خطأ من السيرفر — اطبع لمساعدة التصحيح
        print(
            'AreaController.fetchAreas failed: status=${response.statusCode}, body=${response.body}');
        isLoading.value = false;
        return false;
      }
    } on TimeoutException catch (e) {
      print('AreaController.fetchAreas timeout: $e');
      isLoading.value = false;
      return false;
    } catch (e) {
      print('AreaController.fetchAreas exception: $e');
      isLoading.value = false;
      return false;
    }
  }

  /// يعيد اسم المنطقة بحسب المعرف (يدعم البحث في القوائم المحمّلة والكاش)
  String? getAreaNameById(int? areaId) {
    if (areaId == null) return null;

    // 1) ابحث في القائمة الحالية أولاً
    final foundCurrent = areas.firstWhereOrNull((a) => a.id == areaId);
    if (foundCurrent != null) return foundCurrent.name;

    // 2) ابحث في الكاش
    for (final list in _cache.values) {
      final f = list.firstWhereOrNull((a) => a.id == areaId);
      if (f != null) return f.name;
    }

    return null;
  }

  /// يعيد اسم المدينة للمنطقة إن وُجد (حقل cityName في الموديل)
  String? getCityNameForArea(int? areaId) {
    if (areaId == null) return null;

    final foundCurrent = areas.firstWhereOrNull((a) => a.id == areaId);
    if (foundCurrent != null) return foundCurrent.cityName;

    for (final list in _cache.values) {
      final f = list.firstWhereOrNull((a) => a.id == areaId);
      if (f != null) return f.cityName;
    }
    return null;
  }

  /// يفرّغ كاش لمدينة واحدة (حسب اللغة الحالية)
  void invalidateCityCache(int cityId) {
    final lang = _safeLangCode();
    _cache.remove(_cacheKey(cityId, lang));
  }

  /// يفرّغ كل الكاش
  void clearCache() {
    _cache.clear();
  }

  /// يحصل على المناطق من الكاش أو يجلبها من السيرفر إن لم تكن موجودة
  Future<List<Area>> getAreasOrFetch(int cityId) async {
    final lang = _safeLangCode();
    final key = _cacheKey(cityId, lang);
    if (_cache.containsKey(key)) return _cache[key]!;
    final ok = await fetchAreas(cityId);
    return ok ? (_cache[key] ?? []) : [];
  }

  /// مساعدة: الحصول على كود اللغة بأمان
  String _safeLangCode() {
    try {
      final code =
          Get.find<ChangeLanguageController>().currentLocale.value.languageCode;
      return (code == null || code.isEmpty) ? 'ar' : code;
    } catch (_) {
      return 'ar';
    }
  }

  /// اختياري: تعيّن التوكن لو احتجت للمصادقة
  void setAuthToken(String token) {
    authToken = token;
  }

  /// اختبارات/تجارب سريعة: طباعة حالة الكنترولر
  @override
  void onClose() {
    // نظف إذا لزم
    super.onClose();
  }
}

/// امتداد مفيد لو لم يكن لديك في المشروع
extension FirstWhereOrNullExtension<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E element) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}
