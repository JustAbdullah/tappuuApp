// lib/core/controllers/card_payment_controller.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../core/data/model/CardPaymentSettingModel.dart';

class CardPaymentController extends GetxController {
  static const String _baseUrl = 'https://stayinme.arabiagroup.net/lar_stayInMe/public/api';

  // الحالة العامة
  final isLoading = false.obs;
  final isSaving = false.obs;

  // الإعداد المحمّل (قد يكون null إن لم يوجد صف)
  final Rxn<CardPaymentSettingModel> setting = Rxn<CardPaymentSettingModel>();

  // نسخة مبسطة للوصول السريع للحقل الواحد
  RxBool isEnabled = false.obs;
  TextEditingController noteController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    fetchSetting(); // جلب تلقائي عند التهيئة
  }

  /// جلب أول إعداد متاح (index) — نأخذ العنصر الأول إن عاد السيرفر قائمة
  Future<void> fetchSetting() async {
    isLoading.value = true;
    try {
      final uri = Uri.parse('$_baseUrl/card-payment-settings');
      final res = await http.get(uri, headers: {'Accept': 'application/json'});

      if (res.statusCode == 200) {
        final body = json.decode(res.body);

        // دعم عدة صيغ من السيرفر: { success: true, data: [...] } أو [...] أو { ...single... }
        dynamic data;
        if (body is Map && body['data'] != null) {
          final raw = body['data'];
          if (raw is List) {
            data = raw;
          } else if (raw is Map) {
            data = Map<String, dynamic>.from(raw);
          } else {
            data = raw;
          }
        } else if (body is List) {
          data = body;
        } else if (body is Map) {
          data = Map<String, dynamic>.from(body);
        } else {
          data = body;
        }

        Map<String, dynamic>? firstItem;
        if (data is List && data.isNotEmpty) {
          final firstRaw = data.first;
          if (firstRaw is Map) {
            firstItem = Map<String, dynamic>.from(firstRaw);
          }
        } else if (data is Map<String, dynamic>) {
          firstItem = data;
        }

        if (firstItem != null) {
          final model = CardPaymentSettingModel.fromJson(firstItem);
          setting.value = model;
          isEnabled.value = model.isEnabled;
          noteController.text = model.note ?? '';
        } else {
          // لا يوجد صفوف
          setting.value = null;
          isEnabled.value = false;
          noteController.clear();
        }
      } else {
        _showSnack('خطأ', 'فشل جلب الإعداد (${res.statusCode})', isError: true);
      }
    } catch (e) {
      _showSnack('استثناء', 'حدث خطأ عند جلب الإعداد: $e', isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  /// تبديل الحالة (toggle) باستخدام المسار PATCH /card-payment-settings/{id}/toggle
  /// يتطلب وجود setting.loaded
  Future<bool> toggleEnabled() async {
    final s = setting.value;
    if (s == null) {
      _showSnack('خطأ', 'لا يوجد إعدادات للبطاقة', isError: true);
      return false;
    }

    isSaving.value = true;
    try {
      final uri = Uri.parse('$_baseUrl/card-payment-settings/${s.id}/toggle');
      final res = await http.patch(uri, headers: {'Accept': 'application/json'});

      if (res.statusCode >= 200 && res.statusCode < 300) {
        try {
          final body = json.decode(res.body);
          Map<String, dynamic>? data;
          if (body is Map && body['data'] != null && body['data'] is Map) {
            data = Map<String, dynamic>.from(body['data'] as Map);
          } else if (body is Map && (body.containsKey('is_enabled') || body.containsKey('note'))) {
            data = Map<String, dynamic>.from(body);
          }

          if (data != null) {
            final updated = CardPaymentSettingModel.fromJson(data);
            setting.value = updated;
            isEnabled.value = updated.isEnabled;
            noteController.text = updated.note ?? '';
          } else {
            // flip locally as fallback
            isEnabled.value = !isEnabled.value;
            setting.value = CardPaymentSettingModel(id: s.id, isEnabled: isEnabled.value, note: noteController.text);
          }
        } catch (_) {
          // fallback: flip locally
          isEnabled.value = !isEnabled.value;
        }

        _showSnack('نجاح', 'تم تغيير حالة الدفع بالبطاقة', isError: false);
        return true;
      } else {
        _showSnack('خطأ', 'فشل تغيير الحالة (${res.statusCode})', isError: true);
        return false;
      }
    } catch (e) {
      _showSnack('استثناء', 'حدث خطأ أثناء التبديل: $e', isError: true);
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  /// تحديث الملاحظة أو/و is_enabled عبر PUT /card-payment-settings/{id}
  /// تمرّر isEnabledOverride لو أردت تغيير القيمة أيضاً وإلا يستخدم القيمة الحالية
  Future<bool> updateSetting({bool? isEnabledOverride, String? note}) async {
    final s = setting.value;
    if (s == null) {
      _showSnack('خطأ', 'لا يوجد إعدادات للتعديل', isError: true);
      return false;
    }

    isSaving.value = true;
    try {
      final uri = Uri.parse('$_baseUrl/card-payment-settings/${s.id}');
      final payload = <String, dynamic>{};
      if (isEnabledOverride != null) payload['is_enabled'] = isEnabledOverride ? 1 : 0;
      // if note provided (including empty string) send it
      if (note != null) payload['note'] = note;

      final res = await http.put(
        uri,
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: json.encode(payload),
      );

      if (res.statusCode >= 200 && res.statusCode < 300) {
        // update local model from response if possible
        try {
          final body = json.decode(res.body);
          Map<String, dynamic>? data;
          if (body is Map && body['data'] != null && body['data'] is Map) {
            data = Map<String, dynamic>.from(body['data'] as Map);
          } else if (body is Map && (body.containsKey('is_enabled') || body.containsKey('note'))) {
            data = Map<String, dynamic>.from(body);
          }

          if (data != null) {
            final updated = CardPaymentSettingModel.fromJson(data);
            setting.value = updated;
            isEnabled.value = updated.isEnabled;
            noteController.text = updated.note ?? '';
            _showSnack('نجاح', 'تم تحديث إعدادات الدفع بالبطاقة', isError: false);
            return true;
          }
        } catch (_) {
          // fallback: update local fields below
        }

        // fallback local update
        final newIsEnabled = isEnabledOverride ?? isEnabled.value;
        final newNote = note ?? noteController.text;
        setting.value = CardPaymentSettingModel(id: s.id, isEnabled: newIsEnabled, note: newNote);
        isEnabled.value = newIsEnabled;
        noteController.text = newNote;
        _showSnack('نجاح', 'تم تحديث إعدادات الدفع بالبطاقة', isError: false);
        return true;
      } else {
        _showSnack('خطأ', 'فشل التحديث (${res.statusCode})', isError: true);
        return false;
      }
    } catch (e) {
      _showSnack('استثناء', 'حدث خطأ أثناء التحديث: $e', isError: true);
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  // Helper: فقط لتحديث الحقل النصي من الواجهة بسهولة
  Future<bool> saveNoteFromController() async {
    return await updateSetting(note: noteController.text);
  }

  // ======= snack helper =======
  void _showSnack(String title, String message, {required bool isError}) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: isError ? Colors.redAccent : Colors.green,
      colorText: Colors.white,
      margin: EdgeInsets.all(12),
      borderRadius: 8,
      duration: Duration(seconds: isError ? 4 : 3),
    );
  }
}
