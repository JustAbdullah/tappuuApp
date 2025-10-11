// lib/core/services/appservices.dart
import 'dart:convert';
import 'dart:ui' as ui; // لاستخدام ui.FontLoader إن احتجنا لاحقًا أو في الكنترولر
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../../controllers/editable_text_controller.dart';


/// Service مركزي للوصول إلى SharedPreferences وعمليات صغيرة مرتبطة بالـ API
class AppServices {
  late SharedPreferences sharedPreferences;

  AppServices._private();

  /// استدعاء للتهيئة: await AppServices.init();
  /// الآن يقوم أيضًا بجلب نصوص editable-texts عند فتح التطبيق وتسجيل الـ controller إن لم يكن مسجَّلاً.
  static Future<AppServices> init() async {
    AppServices services = AppServices._private();
    services.sharedPreferences = await SharedPreferences.getInstance();

    // === Fetch editable texts on app open ===
    try {
      // سجّل الكنترولر إذا لم يكن مسجلاً
      if (!Get.isRegistered<EditableTextController>()) {
        Get.put(EditableTextController());
      }
      final editableCtrl = Get.find<EditableTextController>();

      // جلب جميع النصوص من السيرفر (ينتظر اكتمال الجلب)
      await editableCtrl.fetchAll();

      if (kDebugMode) debugPrint(
        'AppServices: editable texts fetched at init (count=${editableCtrl.items.length})'
      );

      // اختياري: حمّل الخطوط المرتبطة بكل نص فوراً (سيتطلب أن تكون روابط الخطوط صحيحة)
      // نقوم بالـ await هنا لضمان أن الخطوط محمّلة قبل أن يعرض الواجهات النص — 
      // إن أردت جعل التحميل غير محظور، غيّر إلى بدون await (fire-and-forget).
      try {
        final futures = editableCtrl.items.map((e) => editableCtrl.ensureFontLoaded(e));
        await Future.wait(futures);
        if (kDebugMode) debugPrint('AppServices: fonts preloaded for editable texts.');
      } catch (e) {
        if (kDebugMode) debugPrint('AppServices: error preloading fonts: $e');
        // لا نرمي لأن نريد الاستمرار حتى لو فشل تحميل بعض الخطوط
      }
    } catch (e) {
      if (kDebugMode) debugPrint('AppServices: failed to fetch editable texts at init: $e');
    }

    return services;
  }

  // ------ إعدادات الـ API ------
  final String _baseUrl = 'https://stayinme.arabiagroup.net/lar_stayInMe/public/api';
  String get baseUrl => _baseUrl;

  // ------ مفاتيح SharedPreferences ------
  static const String _kAppLogoKey = 'app_logo_url';
  static const String _kAppLogoRawKey = 'app_logo_raw'; // raw json (for change detection)

  static const String _kWaitingScreenKey = 'waiting_screen'; // stored data JSON
  static const String _kWaitingScreenRawKey = 'waiting_screen_raw';

  // ------ حالات / flags ------
  RxBool isRefreshingPremium = false.obs;

  // ============================
  // App logo helpers (with diff-check)
  // ============================

  /// Fetches app-logo from API and updates local cache only if changed.
  Future<void> fetchAndStoreAppLogo({Duration timeout = const Duration(seconds: 30)}) async {
    final uri = Uri.parse('$_baseUrl/app-logo');
    try {
      final res = await http.get(uri).timeout(timeout);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final raw = res.body;
        final prevRaw = sharedPreferences.getString(_kAppLogoRawKey);

        if (prevRaw != null && prevRaw == raw) {
          if (kDebugMode) debugPrint('App logo: no change detected.');
          return;
        }

        // تغيّر أو لم يكن موجود -> حاول استخراج الرابط وتخزينه
        final body = json.decode(raw);
        String? url;
        if (body is Map<String, dynamic>) {
          final data = body['data'];
          if (data is Map<String, dynamic>) {
            url = (data['url'] ?? data['image'] ?? data['image_url'])?.toString();
          } else if (data is String) {
            url = data;
          }
        } else if (body is String) {
          url = body;
        }

        if (url != null && url.isNotEmpty) {
          await sharedPreferences.setString(_kAppLogoKey, url);
          await sharedPreferences.setString(_kAppLogoRawKey, raw);
          if (kDebugMode) debugPrint('App logo updated and saved: $url');
          return;
        } else {
          // لا يوجد رابط صالح في الرد -> امسح المفتاح المخزن (لتفادي روابط معطوبة)
          if (sharedPreferences.containsKey(_kAppLogoKey)) {
            await sharedPreferences.remove(_kAppLogoKey);
            await sharedPreferences.remove(_kAppLogoRawKey);
            if (kDebugMode) debugPrint('App logo response has no url -> cleared cached logo.');
          }
        }
      } else {
        if (kDebugMode) debugPrint('fetchAndStoreAppLogo HTTP error: ${res.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('fetchAndStoreAppLogo error: $e');
      // on network error: keep previous cached value to avoid making app worse
    }
  }

  String? getStoredAppLogoUrl() {
    try {
      return sharedPreferences.getString(_kAppLogoKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearStoredAppLogo() async {
    try {
      if (sharedPreferences.containsKey(_kAppLogoKey)) {
        await sharedPreferences.remove(_kAppLogoKey);
      }
      if (sharedPreferences.containsKey(_kAppLogoRawKey)) {
        await sharedPreferences.remove(_kAppLogoRawKey);
      }
      if (kDebugMode) debugPrint('App logo cleared.');
    } catch (e) {
      if (kDebugMode) debugPrint('clearStoredAppLogo error: $e');
    }
  }

  // ============================
  // Waiting screen helpers (with diff-check)
  // ============================
  ///
  /// GET /waiting-screen
  /// Stores raw JSON and parsed map under keys and returns parsed map if updated or null if nothing changed.
  Future<Map<String, dynamic>?> fetchAndStoreWaitingScreen({Duration timeout = const Duration(seconds: 8)}) async {
    final uri = Uri.parse('$_baseUrl/waiting-screen');
    try {
      final res = await http.get(uri).timeout(timeout);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final raw = res.body;
        final prevRaw = sharedPreferences.getString(_kWaitingScreenRawKey);

        if (prevRaw != null && prevRaw == raw) {
          if (kDebugMode) debugPrint('WaitingScreen: no change detected.');
          // لا نعيد تطبيق أي شيء
          return null;
        }

        // parse and save
        final body = json.decode(raw);
        if (body is Map<String, dynamic> && (body['success'] == true) && body['data'] != null) {
          final data = body['data'] as Map<String, dynamic>;
          await sharedPreferences.setString(_kWaitingScreenKey, json.encode(data));
          await sharedPreferences.setString(_kWaitingScreenRawKey, raw);
          if (kDebugMode) debugPrint('WaitingScreen updated and cached.');
          return data;
        } else {
          // response not valid -> clear stored
          if (sharedPreferences.containsKey(_kWaitingScreenKey)) {
            await sharedPreferences.remove(_kWaitingScreenKey);
            await sharedPreferences.remove(_kWaitingScreenRawKey);
            if (kDebugMode) debugPrint('WaitingScreen response invalid -> cleared cached.');
          }
        }
      } else {
        if (kDebugMode) debugPrint('fetchAndStoreWaitingScreen HTTP error: ${res.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('fetchAndStoreWaitingScreen error: $e');
    }
    return null;
  }

  /// return stored parsed waiting screen map or null
  Map<String, dynamic>? getStoredWaitingScreen() {
    try {
      final raw = sharedPreferences.getString(_kWaitingScreenKey);
      if (raw == null) return null;
      final map = json.decode(raw) as Map<String, dynamic>;
      return map;
    } catch (e) {
      if (kDebugMode) debugPrint('getStoredWaitingScreen error: $e');
      return null;
    }
  }

  Future<void> clearStoredWaitingScreen() async {
    try {
      if (sharedPreferences.containsKey(_kWaitingScreenKey)) {
        await sharedPreferences.remove(_kWaitingScreenKey);
      }
      if (sharedPreferences.containsKey(_kWaitingScreenRawKey)) {
        await sharedPreferences.remove(_kWaitingScreenRawKey);
      }
      if (kDebugMode) debugPrint('WaitingScreen cleared.');
    } catch (e) {
      if (kDebugMode) debugPrint('clearStoredWaitingScreen error: $e');
    }
  }

  // ============================
  // Utilities
  // ============================
  /// call endpoints like refresh premium
  Future<void> refreshPremiumAdsOnServer() async {
    try {
      isRefreshingPremium.value = true;
      final uri = Uri.parse('$_baseUrl/ads/refresh-premium');
      final response = await http.post(uri);
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (kDebugMode) debugPrint('refreshPremiumAdsOnServer: $body');
      } else {
        if (kDebugMode) debugPrint('refreshPremiumAdsOnServer failed: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('refreshPremiumAdsOnServer error: $e');
    } finally {
      isRefreshingPremium.value = false;
    }
  }
}
