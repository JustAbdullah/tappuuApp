
// ===== SearchHistoryController.dart (محدّث كامل) =====

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:tappuu_app/controllers/LoadingController.dart';

import '../core/data/model/SearchHistory.dart';

class SearchHistoryController extends GetxController {
  final String _baseUrl = 'https://stayinme.arabiagroup.net/lar_stayInMe/public/api';

  var searchHistoryList = <SearchHistory>[].obs;
  var isLoadingHistory = false.obs;
  var isSaving = false.obs;
  var isDeleting = false.obs;

  // --------------------- Helpers for local topics storage --------------------
  Future<Set<String>> _getSavedTopics() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('subscribed_topics') ?? [];
    return list.toSet();
  }

  Future<void> _saveTopics(Set<String> topics) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('subscribed_topics', topics.toList());
  }

  Future<void> _unsubscribeFromTopicLocal(String topic) async {
    try {
      // accept either 'all','2' or 'category_2' and unsubscribe the proper FCM topic
      final normalized = topic.startsWith('category_') ? topic.split('_').last : topic;
      final fcmTopic = normalized == 'all' ? 'all' : 'category_$normalized';
      await FirebaseMessaging.instance.unsubscribeFromTopic(fcmTopic);
      final saved = await _getSavedTopics();
      saved.remove(normalized);
      await _saveTopics(saved);
      debugPrint('Local unsubscribe from topic: $fcmTopic (stored as $normalized)');
    } catch (e) {
      debugPrint('Error unsubscribing from topic $topic: $e');
    }
  }

  Future<void> _unsubscribeAllLocal() async {
    try {
      final saved = await _getSavedTopics();
      for (final t in saved) {
        try {
          final fcmTopic = t == 'all' ? 'all' : 'category_$t';
          await FirebaseMessaging.instance.unsubscribeFromTopic(fcmTopic);
          debugPrint('Unsubscribed from $fcmTopic');
        } catch (e) {
          debugPrint('Failed to unsubscribe $t: $e');
        }
      }
      await _saveTopics(<String>{});
    } catch (e) {
      debugPrint('Error in _unsubscribeAllLocal: $e');
    }
  }
  // --------------------------------------------------------------------------

  /// جلب جميع سجلات البحث للمستخدم
  Future<void> fetchSearchHistory({required int userId}) async {
    isLoadingHistory.value = true;
    try {
      final uri = Uri.parse('$_baseUrl/search-history?user_id=$userId');
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final result = json.decode(res.body) as Map<String, dynamic>;
        if (result['success'] == true) {
          final list = (result['data'] as List)
              .map((e) => SearchHistory.fromJson(e as Map<String, dynamic>))
              .toList();
          searchHistoryList.value = list;
          debugPrint('fetchSearchHistory: loaded ${list.length} records for user $userId');
        } else {
          debugPrint('fetchSearchHistory: success == false, body: ${res.body}');
        }
      } else {
        debugPrint('Error fetching search history: ${res.statusCode}');
        debugPrint('Body: ${res.body}');
      }
    } catch (e, st) {
      debugPrint('Exception fetchSearchHistory: $e\n$st');
    } finally {
      isLoadingHistory.value = false;
    }
  }

  /// إضافة سجل جديد
  Future<bool> addSearchHistory({
    required int userId,
    required String recordName,
    required int categoryId,
    int? subcategoryId,
    int? secondSubcategoryId,
    bool notifyPhone = false,
    bool notifyEmail = false,
  }) async {
    isSaving.value = true;
    try {
      final uri = Uri.parse('$_baseUrl/search-history');
      final body = {
        'user_id': userId,
        'record_name': recordName,
        'category_id': categoryId,
        'subcategory_id': subcategoryId,
        'second_subcategory_id': secondSubcategoryId,
        'notify_phone': notifyPhone ? 1 : 0,
        'notify_email': notifyEmail ? 1 : 0,
      };
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (res.statusCode == 200) {
        final result = json.decode(res.body) as Map<String, dynamic>;
        if (result['success'] == true) {
          Get.snackbar('نجاح'.tr, 'تم حفظ سجل البحث بنجاح'.tr);

          // محاولة إضافة العنصر محليًا: إذا رجع السيرفر بيانات العنصر الجديد ضفها،
          // وإلا أعد جلب السجل كاملاً من السيرفر.
          try {
            if (result['data'] != null) {
              // متوقع أن 'data' يحتوي على السجل الجديد
              final newRecord = SearchHistory.fromJson(result['data'] as Map<String, dynamic>);
              // تجنّب التكرار: إذا موجود بنفس id لا نضيف
              if (!searchHistoryList.any((r) => r.id == newRecord.id)) {
                searchHistoryList.insert(0, newRecord); // أدخله في بداية القائمة
                debugPrint('addSearchHistory: inserted new record locally id=${newRecord.id}');
              }
            } else {
              // لو لم يعد السيرفر العنصر، أعد جلب القائمة
              await fetchSearchHistory(userId: userId);
            }
          } catch (e, st) {
            debugPrint('Warning: failed to parse or insert server returned record: $e\n$st');
            await fetchSearchHistory(userId: userId);
          }

          // إذا هذا السجل يطلب إشعارات الهاتف، نطلب من LoadingController التحقق/الاشتراك
          if (notifyPhone) {
            if (Get.isRegistered<LoadingController>()) {
              final loadingCtrl = Get.find<LoadingController>();
              await loadingCtrl.handleAfterRecordChange(
                userId: userId,
                affectedCategoryId: categoryId,
              );
              // طباعة حالة الاشتراكات بعد العملية
              await loadingCtrl.printSavedTopics();
            } else {
              // fallback: اشتراك محلي بسيط (نادر الحدوث لأن LoadingController عادة مسجل)
              try {
                final fcmTopic = 'category_${categoryId.toString()}';
                await FirebaseMessaging.instance.subscribeToTopic(fcmTopic);
                final saved = await _getSavedTopics();
                saved.add(categoryId.toString());
                await _saveTopics(saved);
                debugPrint('Fallback subscribe to $fcmTopic');
              } catch (e) {
                debugPrint('Fallback subscribe failed for category_${categoryId.toString()}: $e');
              }
            }
          }

          return true;
        } else {
          Get.snackbar('فشل'.tr, 'لم يتم حفظ سجل البحث'.tr);
          debugPrint('addSearchHistory: success == false, body: ${res.body}');
        }
      } else {
        debugPrint('Error adding search history: ${res.statusCode}');
        debugPrint('Body: ${res.body}');
      }
    } catch (e, st) {
      debugPrint('Exception addSearchHistory: $e\n$st');
    } finally {
      isSaving.value = false;
    }
    return false;
  }

  /// حذف سجل واحد
  Future<bool> deleteSearchHistory({
    required int id,
    required int userId,
  }) async {
    isDeleting.value = true;
    try {
      // قبل الحذف: احصل على categoryId للسجل لكي نتحقق من الاشتراكات بعد الحذف
      final record = searchHistoryList.firstWhere(
        (r) => r.id == id,
        orElse: () => SearchHistory(
          id: -1,
          userId: userId,
          recordName: '',
          categoryId: -1,
          subcategoryId: null,
          secondSubcategoryId: null,
          createdAt: '',
          notifyPhone: false,
          notifyEmail: false,
        ),
      );

      final uri = Uri.parse('$_baseUrl/search-history/$id?user_id=$userId');
      final res = await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );


      if (res.statusCode == 200) {
        final result = json.decode(res.body) as Map<String, dynamic>;
        if (result['success'] == true) {
          // حدّث اللائحة محليًا
          searchHistoryList.removeWhere((item) => item.id == id);
          debugPrint('deleteSearchHistory: removed id=$id locally');

          // أخبر LoadingController ليتحقق إذا لازال يجب الاشتراك في الفئة
          if (record.categoryId != -1) {
            if (Get.isRegistered<LoadingController>()) {
              final loadingCtrl = Get.find<LoadingController>();
              await loadingCtrl.handleAfterRecordChange(
                userId: userId,
                affectedCategoryId: record.categoryId,
              );
              await loadingCtrl.printSavedTopics();
            } else {
              // fallback: إعادة جلب السجلات ثم إلغاء الاشتراك إن لم يعد هناك حاجة
              await fetchSearchHistory(userId: userId);
              final needNotify = searchHistoryList.any((s) =>
                  s.categoryId == record.categoryId && s.notifyPhone == true);
              if (!needNotify) {
                await _unsubscribeFromTopicLocal(record.categoryId.toString());
              }
            }
          }

          return true;
        } else {
          debugPrint('deleteSearchHistory: success == false, body: ${res.body}');
        }
      } else {
        debugPrint('Error deleting search history: ${res.statusCode}');
        debugPrint('Body: ${res.body}');
      }
    } catch (e, st) {
      debugPrint('Exception deleteSearchHistory: $e\n$st');
    } finally {
      isDeleting.value = false;
    }
    return false;
  }

  /// حذف جميع السجلات
  Future<bool> deleteAllSearchHistory({required int userId}) async {
    isDeleting.value = true;
    try {
      final uri = Uri.parse('$_baseUrl/search-history?user_id=$userId');
      final res = await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        final result = json.decode(res.body) as Map<String, dynamic>;
        if (result['success'] == true) {
          // مسح اللائحة محليًا
          searchHistoryList.clear();
          debugPrint('deleteAllSearchHistory: cleared local list');

          // بعد حذف الكل: نلغي جميع الاشتراكات المحلية (لأن المستخدم لم يعد لديه سجلات)
          await _unsubscribeAllLocal();

          // أيضاً نطلب من LoadingController لو مسجّل ليعمل تنظيف إن لزم
          if (Get.isRegistered<LoadingController>()) {
            final loadingCtrl = Get.find<LoadingController>();
            // اطلب منه طباعة الحالة بعد التنظيف
            await loadingCtrl.printSavedTopics();
            debugPrint('Notified LoadingController about deleteAll.');
          }

          return true;
        } else {
          debugPrint('deleteAllSearchHistory: success == false, body: ${res.body}');
        }
      } else {
        debugPrint('Error deleteAllSearchHistory: ${res.statusCode}');
        debugPrint('Body: ${res.body}');
      }
    } catch (e, st) {
      debugPrint('Exception deleteAllSearchHistory: $e\n$st');
    } finally {
      isDeleting.value = false;
    }
    return false;
  }
}
