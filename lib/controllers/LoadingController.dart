// ===== LoadingController.dart (محدّث كامل) =====

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:tappuu_app/controllers/home_controller.dart';
import 'package:tappuu_app/views/HomeScreen/home_screen.dart';
import '../core/data/model/user.dart';
import 'SearchHistoryController.dart';
import 'sharedController.dart';

class LoadingController extends GetxController {
  var isLoading = RxBool(true);
  var isGo = RxBool(false);
  User? currentUser;
  Rxn<User> currentUserToFix = Rxn<User>();

  HomeController homeController = Get.put(HomeController());
  RxBool showOneTimeLogin = true.obs;

  @override
  void onInit() {
    super.onInit();
  }

  // ===================== Helpers for topics storage =====================
  // Stored format in SharedPreferences: only numbers as strings for categories (e.g. '2','3') and 'all'

  String _normalizeStoredTopic(String raw) {
    final r = raw.trim();
    if (r == 'all') return 'all';
    if (r.startsWith('category_')) {
      final parts = r.split('_');
      if (parts.length >= 2) return parts.last;
    }
    return r; // assume it's already numeric string like '2'
  }

  String _fcmTopicFromStored(String stored) {
    if (stored == 'all') return 'all';
    return 'category_${stored}';
  }

  Future<Set<String>> _getSavedTopics() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('subscribed_topics') ?? [];
    // normalize stored values so old values like 'category_2' become '2'
    final normalized = list.map((e) => _normalizeStoredTopic(e)).toSet();
    return normalized;
  }

  Future<void> _saveTopics(Set<String> topics) async {
    final prefs = await SharedPreferences.getInstance();
    // store as normalized (numbers and 'all')
    await prefs.setStringList('subscribed_topics', topics.toList());
  }

  Future<void> _addSavedTopic(String topic) async {
    final saved = await _getSavedTopics();
    saved.add(_normalizeStoredTopic(topic));
    await _saveTopics(saved);
  }

  Future<void> _removeSavedTopic(String topic) async {
    final saved = await _getSavedTopics();
    saved.remove(_normalizeStoredTopic(topic));
    await _saveTopics(saved);
  }

  // Public helper: subscribe by category id (keeps local storage as number but subscribes to FCM 'category_x')
  Future<bool> subscribeToCategoryId(int categoryId) async {
    final stored = categoryId.toString();
    final saved = await _getSavedTopics();
    final fcmTopic = _fcmTopicFromStored(stored);

    if (saved.contains(stored)) {
      debugPrint('[subscribe] already saved locally: $stored');
      // Try safe re-subscribe to FCM to mitigate missing server-side subscription
      try {
        await FirebaseMessaging.instance.subscribeToTopic(fcmTopic);
        debugPrint('[subscribe] re-subscribed to FCM topic: $fcmTopic');
      } catch (e) {
        debugPrint('[subscribe] re-subscribe failed for $fcmTopic: $e');
      }
      await printSavedTopics();
      return true;
    }

    try {
      await FirebaseMessaging.instance.subscribeToTopic(fcmTopic);
      await _addSavedTopic(stored);
      debugPrint('[subscribe] Subscribed to $fcmTopic and saved $stored');
      await printSavedTopics();
      return true;
    } catch (e, st) {
      debugPrint('[subscribe] Error subscribing to $fcmTopic: $e\n$st');
      return false;
    }
  }

  // Public helper: unsubscribe by category id
  Future<bool> unsubscribeFromCategoryId(int categoryId) async {
    final stored = categoryId.toString();
    final fcmTopic = _fcmTopicFromStored(stored);

    final saved = await _getSavedTopics();
    if (!saved.contains(stored)) {
      debugPrint('[unsubscribe] not saved locally: $stored');
      return true;
    }

    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic(fcmTopic);
      await _removeSavedTopic(stored);
      debugPrint('[unsubscribe] Unsubscribed from $fcmTopic and removed $stored');
      await printSavedTopics();
      return true;
    } catch (e, st) {
      debugPrint('[unsubscribe] Error unsubscribing from $fcmTopic: $e\n$st');
      return false;
    }
  }

  // Public: subscribe and persist locally (keeps for backward compatibility if raw topic passed)
  Future<bool> subscribeToTopicPublic(String topic) async {
    // Accept either 'all', '2', or 'category_2'
    final stored = _normalizeStoredTopic(topic);
    if (stored == 'all') {
      try {
        await FirebaseMessaging.instance.subscribeToTopic('all');
        final saved = await _getSavedTopics();
        saved.add('all');
        await _saveTopics(saved);
        debugPrint('[subscribe] Subscribed to topic: all');
        await printSavedTopics();
        return true;
      } catch (e, st) {
        debugPrint('[subscribe] Error subscribing to all: $e\n$st');
        return false;
      }
    }
    // otherwise it's a category id string
    final id = int.tryParse(stored);
    if (id != null) {
      return await subscribeToCategoryId(id);
    }

    // fallback: subscribe directly to the raw topic
    try {
      await FirebaseMessaging.instance.subscribeToTopic(topic);
      await _addSavedTopic(topic);
      debugPrint('[subscribe] Subscribed to topic (fallback): $topic');
      await printSavedTopics();
      return true;
    } catch (e, st) {
      debugPrint('[subscribe] Error subscribing fallback $topic: $e\n$st');
      return false;
    }
  }

  // Public: unsubscribe and remove local record (accepts 'all','2','category_2')
  Future<bool> unsubscribeFromTopicPublic(String topic) async {
    final stored = _normalizeStoredTopic(topic);
    if (stored == 'all') {
      try {
        await FirebaseMessaging.instance.unsubscribeFromTopic('all');
        final saved = await _getSavedTopics();
        saved.remove('all');
        await _saveTopics(saved);
        debugPrint('[unsubscribe] Unsubscribed from all');
        await printSavedTopics();
        return true;
      } catch (e, st) {
        debugPrint('[unsubscribe] Error unsubscribing from all: $e\n$st');
        return false;
      }
    }
    final id = int.tryParse(stored);
    if (id != null) {
      return await unsubscribeFromCategoryId(id);
    }

    // fallback
    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
      await _removeSavedTopic(topic);
      debugPrint('[unsubscribe] Unsubscribed from topic (fallback): $topic');
      await printSavedTopics();
      return true;
    } catch (e, st) {
      debugPrint('[unsubscribe] Error unsubscribing fallback $topic: $e\n$st');
      return false;
    }
  }

  // طباعة المواضيع المحفوظة والتوكِن لأغراض الـ debug
  Future<void> printSavedTopics() async {
    final saved = await _getSavedTopics();
    final token = await FirebaseMessaging.instance.getToken();
    debugPrint('=== FCM Debug Info ===');
    debugPrint('FCM token: $token');
    debugPrint('Saved subscribed topics (normalized): $saved');
    debugPrint('=======================');
  }

  // يعيد التأكد من الاشتراكات حسب سجلات البحث على السيرفر، ويحتاج userId
  Future<void> ensureSubscriptionsFromSearchHistory(int userId) async {
    try {
      final searchCtrl = Get.put(SearchHistoryController(), permanent: false);
      await searchCtrl.fetchSearchHistory(userId: userId);

      // سجلات تطلب إشعارات الهاتف
      final notifyRecords = searchCtrl.searchHistoryList.where((s) => s.notifyPhone == true).toList();

      final expectedIds = <int>{};
      for (final r in notifyRecords) {
        expectedIds.add(r.categoryId);
      }

      // احصل على المواضيع المحفوظة محلياً
      final saved = await _getSavedTopics(); // normalized: {'all','2','3'}

      // 1) اشترك في المواضيع المتوقعة وليست محفوظة
      for (final id in expectedIds) {
        final stored = id.toString();
        if (!saved.contains(stored)) {
          debugPrint('[ensure] topic $stored expected but missing locally -> subscribing');
          await subscribeToCategoryId(id);
        } else {
          // To be safe, attempt a re-subscribe (idempotent) to fix server-side loss
          final fcmTopic = _fcmTopicFromStored(stored);
          debugPrint('[ensure] topic $stored exists locally -> re-subscribing to $fcmTopic');
          try {
            await FirebaseMessaging.instance.subscribeToTopic(fcmTopic);
            debugPrint('[ensure] re-subscribed to $fcmTopic');
          } catch (e) {
            debugPrint('[ensure] re-subscribe failed for $fcmTopic: $e');
          }
        }
      }

      // 2) إذا هناك مواضيع محفوظة محلياً لكن لم تعد مطلوبة (المستخدم ألغى من السيرفر)، فكّ الاشتراك
      for (final s in saved) {
        if (s == 'all') continue;
        final id = int.tryParse(s);
        if (id == null) continue;
        if (!expectedIds.contains(id)) {
          debugPrint('[ensure] topic $s saved locally but no longer expected -> unsubscribing');
          await unsubscribeFromCategoryId(id);
        }
      }

      // أخيراً: طباعة تقرير
      await printSavedTopics();
      debugPrint('[ensure] Subscriptions synced with search history for user $userId');
    } catch (e, st) {
      debugPrint('[ensure] Error ensuring subscriptions: $e\n$st');
    }
  }

  // ======================================================================
Future<void> loadUserData() async {
  if (isGo.value) return;

  final shared = Get.find<SharedController>();
  SharedPreferences prefs = await SharedPreferences.getInstance();

  debugPrint('loadUserData: start');

  // التحقق مما إذا كانت هذه أول مرة يُفتح فيها التطبيق
  String? firstTimeFlag = prefs.getString('firstTimeFlag');
  bool isFirstTime = firstTimeFlag == null || firstTimeFlag == 'isFirstTime';

  // تأخير ابتدائي بسيط (splash)
  int delaySeconds = isFirstTime ? 3 : 3;
  await Future.delayed(Duration(seconds: delaySeconds));

  if (isFirstTime) {
    await prefs.setString('firstTimeFlag', 'isNotFirstTime');
    await Future.delayed(const Duration(milliseconds: 500));

    // قبل التنقّل: ننتظر نافذة قصيرة جداً لنرى إذا سيصل deep link
    debugPrint('loadUserData: first open — checking for incoming deep link');
    final bool safeToGo = await _waitForDeepLinkGrace(shared);
    if (safeToGo) {
      debugPrint('loadUserData: no deep link detected -> navigating to Home');
      isGo.value = true;
      Get.to(() => HomeScreen());
      isGo.value = false;
    } else {
      debugPrint('loadUserData: deep link arrived -> staying on loading to let deep link flow');
    }
    return;
  }

  // ليس أول فتح: حاول قراءة بيانات المستخدم من SharedPreferences
  String? userData = prefs.getString('user');
  await Future.delayed(const Duration(milliseconds: 500));

  if (userData != null) {
    try {
      currentUser = User.fromJson(jsonDecode(userData));
      currentUserToFix.value = User.fromJson(jsonDecode(userData));

      try {
        await ensureSubscriptionsFromSearchHistory(currentUser?.id ?? 0);
      } catch (e) {
        debugPrint('ensureSubscriptionsFromSearchHistory error: $e');
      }
    } catch (e) {
      debugPrint('loadUserData: failed parsing stored user: $e');
    }
  }

  // الآن: قبل أي انتقال نهائي إلى الرئيسية، انتظر نافذة صغيرة (grace) لترى إن وصل deep link
  debugPrint('loadUserData: checking deep link / navigation flags before going Home. hasPending=${shared.hasPendingDeepLink.value}, isNavigating=${shared.isNavigatingToAd.value}');

  // إذا واضح أن هناك عملية تنقل جارية أو رابط قيد المعالجة -> لا ننقُل.
  if (shared.hasPendingDeepLink.value || shared.isNavigatingToAd.value) {
    debugPrint('loadUserData: detected pending deep link or navigation already -> not navigating to Home');
    // ننتظر انتهاء المعالجة كما كان منطقك سابقاً
    const int maxWaitMs = 5000;
    final Completer<bool> completer = Completer<bool>();
    final sub = shared.hasPendingDeepLink.listen((val) {
      if (!val && !completer.isCompleted) completer.complete(true); // انتهت المعالجة مبكراً
    });
    Future.delayed(Duration(milliseconds: maxWaitMs)).then((_) {
      if (!completer.isCompleted) completer.complete(false);
    });
    final bool cleared = await completer.future;
    await sub.cancel();
    if (cleared) {
      debugPrint('loadUserData: deep link cleared while waiting -> not navigating (SharedController already handled nav).');
      return;
    } else {
      debugPrint('loadUserData: timeout waiting for deep link -> staying on Loading (avoid interrupt).');
      return;
    }
  }

  // لا توجد إشارات الآن — لكن أعطِ نافذة قصيرة (debounce) لتفادي سباقات التوقيت:
  final bool safeToNavigate = await _waitForDeepLinkGrace(shared);
  if (safeToNavigate) {
    debugPrint('loadUserData: safe after grace -> navigating to Home');
    isGo.value = true;
    Get.offAll(() => HomeScreen());
    isGo.value = false;
    return;
  } else {
    debugPrint('loadUserData: deep link detected during grace -> will not navigate to Home');
    return;
  }
}

/// Helper: small grace period to detect an incoming deep link or navigation start.
/// Returns true if safe to navigate to Home (no deep link arrived), false if deep link arrived.
Future<bool> _waitForDeepLinkGrace(SharedController shared, {int graceMs = 350}) async {
  // If already pending -> not safe
  if (shared.hasPendingDeepLink.value || shared.isNavigatingToAd.value) return false;

  final Completer<bool> completer = Completer<bool>();
  final sub1 = shared.hasPendingDeepLink.listen((val) {
    if (val && !completer.isCompleted) completer.complete(false);
  });
  final sub2 = shared.isNavigatingToAd.listen((val) {
    if (val && !completer.isCompleted) completer.complete(false);
  });

  Future.delayed(Duration(milliseconds: graceMs)).then((_) {
    if (!completer.isCompleted) completer.complete(true);
  });

  final result = await completer.future;
  await sub1.cancel();
  await sub2.cancel();
  return result;
}



  // rest of your controller (handleAfterRecordChange, refreshUserData, logout etc.)
  Future<void> handleAfterRecordChange({
    required int userId,
    required int affectedCategoryId,
  }) async {
    try {
      final searchCtrl = Get.find<SearchHistoryController>();
      await searchCtrl.fetchSearchHistory(userId: userId);

      final needNotify = searchCtrl.searchHistoryList.any((s) =>
          s.categoryId == affectedCategoryId && s.notifyPhone == true);

      if (!needNotify) {
        await unsubscribeFromCategoryId(affectedCategoryId);
      } else {
        await subscribeToCategoryId(affectedCategoryId);
      }
    } catch (e) {
      debugPrint('handleAfterRecordChange error: $e');
    }
  }

  Future<void> refreshUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userData = prefs.getString('user');

    if (userData != null) {
      currentUser = User.fromJson(jsonDecode(userData));
    }
    update();
  }

  void setUser(User u) {
    currentUser = u;
    currentUserToFix.value = u;
  }

  void clearUser() {
    currentUser = null;
    currentUserToFix.value = null;
  }

  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // cancel all topic subscriptions on logout
    try {
      final saved = await _getSavedTopics();
      for (final t in saved) {
        final fcmTopic = _fcmTopicFromStored(t);
        try {
          await FirebaseMessaging.instance.unsubscribeFromTopic(fcmTopic);
        } catch (e) {
          debugPrint('logout: failed unsubscribe $fcmTopic: $e');
        }
      }
      await _saveTopics(<String>{});
    } catch (e) {
      debugPrint('error unsubscribing all topics on logout: $e');
    }

    clearUser();
    isGo.value = false;
    showOneTimeLogin.value = false;

    Get.snackbar(
      'تم تسجيل الخروج',
      'تم تسجيل الخروج بنجاح.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      margin: EdgeInsets.all(16),
      borderRadius: 8,
    );

    Get.offAll(() => HomeScreen());
  }
}

