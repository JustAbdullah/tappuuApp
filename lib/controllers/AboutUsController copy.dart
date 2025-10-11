import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../core/data/model/AboutUs.dart';

enum SnackType { success, error, info }

class AboutUsController extends GetxController {
  static const _baseUrl = 'https://stayinme.arabiagroup.net/lar_stayInMe/public/api';

  // state
  final Rxn<AboutUs> aboutUs = Rxn<AboutUs>();
  final isLoading = false.obs;
  final isGetFirstTime = false.obs;

  // optional: لو تحتاج توكن تمرره للـ methods
  Map<String, String> _defaultHeaders({String? token}) {
    final headers = {'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  @override
  void onInit() {
    super.onInit();
    fetchAboutUs();
  }

  // -----------------------
  // Helper snack method (مضمن إغلاق أي Snackbars حالياً)
  // -----------------------
  void _showSnack({
    required String title,
    required String message,
    SnackType type = SnackType.info,
    IconData? icon,
    int seconds = 3,
  }) {
    try {
      Get.closeAllSnackbars();
    } catch (_) {}
    final LinearGradient gradient;
    final Color textColor = Colors.white;
    switch (type) {
      case SnackType.success:
        gradient = LinearGradient(colors: [Colors.green.shade600, Colors.green.shade400]);
        break;
      case SnackType.error:
        gradient = LinearGradient(colors: [Colors.red.shade700, Colors.red.shade400]);
        break;
      case SnackType.info:
      default:
        gradient = LinearGradient(colors: [Colors.blue.shade700, Colors.blue.shade400]);
        break;
    }

    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(12),
      borderRadius: 12,
      backgroundGradient: gradient,
      colorText: textColor,
      icon: icon != null ? Icon(icon, color: Colors.white) : null,
      shouldIconPulse: true,
      duration: Duration(seconds: seconds),
      maxWidth: 800,
      isDismissible: true,
      forwardAnimationCurve: Curves.easeOutQuad,
      reverseAnimationCurve: Curves.easeInQuad,
      snackStyle: SnackStyle.FLOATING,
    );
  }

  // -----------------------
  // Helper: parse response body safely and decide success
  // returns: (ok, message, data)
  // -----------------------
  Map<String, dynamic> _parseResponse(http.Response res) {
    final int status = res.statusCode;
    String raw = res.body ?? '';
    try {
      final parsed = json.decode(raw);
      if (parsed is Map<String, dynamic>) {
        final bool successFlag = (parsed['success'] == true) || (parsed['status'] == 'success');
        final dynamic data = parsed['data'] ?? parsed;
        final String? message = parsed['message']?.toString();
        return {'ok': (status >= 200 && status < 300) && (successFlag || data != null || message != null), 'message': message ?? '', 'data': data};
      } else {
        // non-object json (array/string) — if status is 2xx treat as ok
        return {'ok': status >= 200 && status < 300, 'message': '', 'data': parsed};
      }
    } catch (e) {
      // not json: if 2xx treat as ok
      return {'ok': status >= 200 && status < 300, 'message': raw, 'data': null};
    }
  }

  // -----------------------
  // Fetch (index) - single record expected
  // GET /about-us or legacy /about-us
  // -----------------------
  Future<void> fetchAboutUs({String? token}) async {
    isLoading.value = true;
    try {
      final uri = Uri.parse('$_baseUrl/about-us');
      final res = await http.get(uri, headers: _defaultHeaders(token: token));

      if (res.statusCode == 200) {
        final result = json.decode(res.body) as Map<String, dynamic>;
        if (result['success'] == true && result['data'] != null) {
          aboutUs.value = AboutUs.fromJson(result['data'] as Map<String, dynamic>);
        } else {
          // قد يرجع null أو رسالة، فنجعل القيمة null
          aboutUs.value = null;
        }
      } else {
        _showSnack(
          title: 'خطأ',
          message: 'فشل في جلب بيانات من نحن. الحالة: ${res.statusCode}',
          type: SnackType.error,
          icon: Icons.error_outline,
        );
      }
    } catch (e) {
      _showSnack(title: 'استثناء', message: 'حدث خطأ: $e', type: SnackType.error, icon: Icons.error);
    } finally {
      isLoading.value = false;
    }
  }

  // -----------------------
  // Create (store)
  // POST /about-us  (tries fallback /about-us/store)
  // -----------------------
  Future<bool> createAboutUs({
    required String title,
    required String description,
    String? facebook,
    String? twitter,
    String? instagram,
    String? youtube,
    String? whatsapp,
    String? token,
  }) async {
    isLoading.value = true;
    try {
      final body = json.encode({
        'title': title,
        'description': description,
        'facebook': facebook,
        'twitter': twitter,
        'instagram': instagram,
        'youtube': youtube,
        'whatsapp': whatsapp,
      });

      // المحاولة الأولى: RESTful POST /about-us
      Uri uri = Uri.parse('$_baseUrl/about-us');
      http.Response res = await http.post(uri, headers: _defaultHeaders(token: token), body: body);

      // fallback: بعض السيرفرات عندك قد تستخدم /store
      if (res.statusCode == 404) {
        uri = Uri.parse('$_baseUrl/about-us/store');
        res = await http.post(uri, headers: _defaultHeaders(token: token), body: body);
      }

      final parsed = _parseResponse(res);
      if (parsed['ok'] == true) {
        // إذا وردت بيانات مفيدة نحدّث الموديل المحلي
        if (parsed['data'] is Map<String, dynamic>) {
          try {
            aboutUs.value = AboutUs.fromJson(parsed['data'] as Map<String, dynamic>);
          } catch (_) {}
        }
        _showSnack(title: 'تمت الإضافة', message: parsed['message']?.toString().isNotEmpty == true ? parsed['message'] : 'تم إنشاء بيانات من نحن بنجاح.', type: SnackType.success, icon: Icons.check_circle);
        return true;
      } else {
        final msg = parsed['message']?.toString() ?? 'فشل الإضافة. الحالة: ${res.statusCode}';
        _showSnack(title: 'خطأ', message: msg, type: SnackType.error, icon: Icons.error_outline);
        return false;
      }
    } catch (e) {
      _showSnack(title: 'استثناء', message: 'حدث خطأ: $e', type: SnackType.error, icon: Icons.error);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // -----------------------
  // Update
  // PUT /about-us/{id}  (tries fallback POST /about-us/update/{id})
  // -----------------------
  Future<bool> updateAboutUs({
    required int id,
    required String title,
    required String description,
    String? facebook,
    String? twitter,
    String? instagram,
    String? youtube,
    String? whatsapp,
    String? token,
  }) async {
    isLoading.value = true;
    try {
      final body = json.encode({
        'title': title,
        'description': description,
        'facebook': facebook,
        'twitter': twitter,
        'instagram': instagram,
        'youtube': youtube,
        'whatsapp': whatsapp,
      });

      // أولاً: حاول PUT إلى RESTful endpoint
      Uri uri = Uri.parse('$_baseUrl/about-us/$id');
      http.Response res;
      try {
        res = await http.put(uri, headers: _defaultHeaders(token: token), body: body);
      } catch (e) {
        // بعض بيئات HTTP قد لا تسمح PUT عبر بعض البروكسيات — نحتاط وننتقل للفالباك
        res = http.Response('', 404);
      }

      // fallback: بعض السيرفرات تستخدم POST /about-us/update/{id}
      if (res.statusCode == 404) {
        uri = Uri.parse('$_baseUrl/about-us/update/$id');
        res = await http.post(uri, headers: _defaultHeaders(token: token), body: body);
      }

      final parsed = _parseResponse(res);
      if (parsed['ok'] == true) {
        if (parsed['data'] is Map<String, dynamic>) {
          try {
            aboutUs.value = AboutUs.fromJson(parsed['data'] as Map<String, dynamic>);
          } catch (_) {}
        }
        _showSnack(title: 'تم التعديل', message: parsed['message']?.toString().isNotEmpty == true ? parsed['message'] : 'تم تحديث بيانات من نحن بنجاح.', type: SnackType.success, icon: Icons.edit);
        return true;
      } else {
        final msg = parsed['message']?.toString() ?? 'فشل التعديل. الحالة: ${res.statusCode}';
        _showSnack(title: 'خطأ', message: msg, type: SnackType.error, icon: Icons.error_outline);
        return false;
      }
    } catch (e) {
      _showSnack(title: 'استثناء', message: 'حدث خطأ: $e', type: SnackType.error, icon: Icons.error);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // -----------------------
  // Delete (destroy)
  // DELETE /about-us/{id}  (fallback /about-us/delete/{id})
  // -----------------------
  Future<bool> deleteAboutUs({required int id, String? token}) async {
    isLoading.value = true;
    try {
      Uri uri = Uri.parse('$_baseUrl/about-us/$id');
      http.Response res = await http.delete(uri, headers: _defaultHeaders(token: token));

      if (res.statusCode == 404) {
        uri = Uri.parse('$_baseUrl/about-us/delete/$id');
        res = await http.delete(uri, headers: _defaultHeaders(token: token));
      }

      final parsed = _parseResponse(res);
      if (parsed['ok'] == true) {
        if (aboutUs.value != null && aboutUs.value!.id == id) {
          aboutUs.value = null;
        }
        _showSnack(title: 'تم الحذف', message: parsed['message']?.toString().isNotEmpty == true ? parsed['message'] : 'تم الحذف بنجاح.', type: SnackType.success, icon: Icons.delete_forever);
        return true;
      } else {
        final msg = parsed['message']?.toString() ?? 'فشل الحذف. الحالة: ${res.statusCode}';
        _showSnack(title: 'خطأ', message: msg, type: SnackType.error, icon: Icons.error_outline);
        return false;
      }
    } catch (e) {
      _showSnack(title: 'استثناء', message: 'حدث خطأ: $e', type: SnackType.error, icon: Icons.error);
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
