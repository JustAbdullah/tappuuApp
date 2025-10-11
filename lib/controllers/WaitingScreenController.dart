// lib/controllers/waiting_screen_controller.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../core/data/model/WaitingScreenModel.dart';
import '../core/services/appservices.dart';

class WaitingScreenController extends GetxController {
  final AppServices appServices = Get.find<AppServices>();
  final String _baseUrl = 'https://stayinme.arabiagroup.net/lar_stayInMe/public/api';

  // المخرجات (observables)
  final RxString imageUrl = ''.obs;
  final Rxn<Color> backgroundColor = Rxn<Color>();
  final RxString colorHex = ''.obs; // للاستخدام أو العرض إن احتجت

  // مفتاح التخزين المحلي
  static const String _localKey = 'waiting_screen';

  @override
  void onInit() {
    super.onInit();
    // أولاً: حمّل من الذاكرة المحلية سريعًا ثم اطلب السيرفر في الخلفية
    _loadFromLocal();
    // لا تمنع الإقلاع — نفّذ في الخلفية
    fetchFromServerAndStore();
  }

  // ======================
  // Local storage helpers
  // ======================
  Future<void> _loadFromLocal() async {
    try {
      final raw = appServices.sharedPreferences.getString(_localKey);
      if (raw == null || raw.isEmpty) return;
      final map = json.decode(raw) as Map<String, dynamic>;
      final model = WaitingScreenModel.fromJson(map);
      _applyModel(model);
      if (kDebugMode) debugPrint('WaitingScreen loaded from local cache.');
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to load waiting screen from local: $e');
    }
  }

  Future<void> _saveToLocal(Map<String, dynamic> data) async {
    try {
      await appServices.sharedPreferences.setString(_localKey, json.encode(data));
      if (kDebugMode) debugPrint('WaitingScreen saved to local.');
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to save waiting screen locally: $e');
    }
  }

  Future<void> _clearLocal() async {
    try {
      if (appServices.sharedPreferences.containsKey(_localKey)) {
        await appServices.sharedPreferences.remove(_localKey);
        if (kDebugMode) debugPrint('WaitingScreen removed from local cache.');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to clear waiting screen local: $e');
    }
  }

  // ======================
  // Server interactions
  // ======================

 // GET /api/waiting-screen
/// يجيب آخر بيانات من السيرفر ويخزنها محليًا ثم يطبّقها.
Future<void> fetchFromServerAndStore() async {
  final uri = Uri.parse('${_baseUrl}/waiting-screen');
  try {
    final res = await http.get(uri).timeout(const Duration(seconds: 8));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final body = json.decode(res.body);
      if (body is Map<String, dynamic> && body['success'] == true && body['data'] != null) {
        final data = body['data'] as Map<String, dynamic>;

        // حفظ البيانات محليًا
        await _saveToLocal(data);

        // تحويل البيانات إلى الموديل
        final model = WaitingScreenModel.fromJson(data);

        // تطبيق الموديل
        _applyModel(model);

        if (kDebugMode) debugPrint('Waiting screen fetched from server and applied.');
        return;
      }
    }
    if (kDebugMode) debugPrint('Waiting screen GET: unexpected response ${res.statusCode} ${res.body}');
  } catch (e) {
    if (kDebugMode) debugPrint('fetchFromServerAndStore error: $e');
  }
}


  /// POST /api/waiting-screen
  /// يرسل اللون والرابط للسيرفر لإنشاء أو تحديث. عند النجاح يخزن محليًا ويفعل.
  Future<bool> saveToServer({required String color, required String image}) async {
    final uri = Uri.parse('${_baseUrl}/waiting-screen');
    try {
      final payload = {'color': color, 'image_url': image};
      final res = await http.post(uri,
          headers: {'Content-Type': 'application/json'},
          body: json.encode(payload)).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = json.decode(res.body);
        if (body is Map<String, dynamic> && body['success'] == true && body['data'] != null) {
          final data = (body['data'] is Map<String, dynamic>) ? body['data'] as Map<String, dynamic> : payload;
          await _saveToLocal(data);
          _applyModel(WaitingScreenModel.fromJson(data));
          if (kDebugMode) debugPrint('Waiting screen saved on server and locally.');
          return true;
        }
      }
      if (kDebugMode) debugPrint('saveToServer failed: ${res.statusCode} ${res.body}');
    } catch (e) {
      if (kDebugMode) debugPrint('saveToServer error: $e');
    }
    return false;
  }

  /// DELETE /api/waiting-screen
  /// يحذف من السيرفر ثم يزيل المحلّي
  Future<bool> deleteFromServer() async {
    final uri = Uri.parse('${_baseUrl}/waiting-screen');
    try {
    //*.|V|.*//
    //*.|M|.*//
    //*.|Y|.*//
    //##its realy Hell##//

      final res = await http.delete(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final body = json.decode(res.body);
        // بعض الـ APIs ترجع success true أو رسالة؛ نتعامل بلين
        await _clearLocal();
        _clearModel();
        if (kDebugMode) debugPrint('Waiting screen deleted on server and locally.');
        return true;
      } else {
        if (kDebugMode) debugPrint('deleteFromServer failed: ${res.statusCode} ${res.body}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('deleteFromServer error: $e');
    }
    return false;
  }

  // ======================
  // Model application
  // ======================
  void _applyModel(WaitingScreenModel model) {
    // الصورة
    if (model.imageUrl != null && model.imageUrl!.isNotEmpty) {
      imageUrl.value = model.imageUrl!;
    } else {
      imageUrl.value = '';
    }

    // اللون
    if (model.color != null && model.color!.isNotEmpty) {
      colorHex.value = model.color!;
      final parsed = _parseHexColor(model.color!);
      if (parsed != null) {
        backgroundColor.value = parsed;
      } else {
        backgroundColor.value = null;
      }
    } else {
      colorHex.value = '';
      backgroundColor.value = null;
    }
  }

  void _clearModel() {
    imageUrl.value = '';
    colorHex.value = '';
    backgroundColor.value = null;
  }

  // ======================
  // Utility: parse hex color (#RRGGBB, RRGGBB, #AARRGGBB, AARRGGBB)
  // ======================
  Color? _parseHexColor(String hex) {
    try {
      String h = hex.replaceAll('#', '').trim();
      if (h.length == 6) h = 'FF$h'; // add full alpha
      if (h.length != 8) return null;
      final intVal = int.parse(h, radix: 16);
      return Color(intVal);
    } catch (e) {
      if (kDebugMode) debugPrint('parseHexColor failed for $hex : $e');
      return null;
    }
  }
}
