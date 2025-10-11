// lib/core/controllers/ad_report_controller.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../core/data/model/ad_report_model.dart';

class AdReportController extends GetxController {
  final String _baseUrl = 'https://stayinme.arabiagroup.net/lar_stayInMe/public/api';

  RxList<AdReportModel> reports = <AdReportModel>[].obs;
  RxBool isLoadingReports = false.obs;

  // single report for use after create/update
  Rxn<AdReportModel> currentReport = Rxn<AdReportModel>();

  // ======= fetch all reports (admin) =======
  Future<void> fetchReports({
    String lang = 'ar',
    int page = 1,
    int perPage = 15,
    String? reportStatus,
    String? adStatus,
    String? searchTitle,
  }) async {
    isLoadingReports.value = true;
    try {
      final query = <String, String>{
        'lang': lang,
        'page': page.toString(),
        'per_page': perPage.toString(),
      };

      if (reportStatus != null) query['report_status'] = reportStatus;
      if (adStatus != null) query['ad_status'] = adStatus;
      if (searchTitle != null && searchTitle.isNotEmpty) query['search_title'] = searchTitle;

      final uri = Uri.parse('$_baseUrl/users/ad-reports').replace(queryParameters: query);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        if (body['status'] == 'success') {
          final list = body['data'] as List<dynamic>? ?? [];
          reports.value = list.map((e) => AdReportModel.fromJson(e as Map<String, dynamic>, lang: lang)).toList();
        } else {
          _showSnackbar('فشل', body['message']?.toString() ?? 'حدث خطأ', true);
        }
      } else {
        _showSnackbar('خطأ', 'رمز الاستجابة:', true);
      }
    } catch (e) {
      print('Exception fetchReports: $e');
      _showSnackbar('استثناء', 'حدث خطأ عند جلب البلاغات: ', true);
    } finally {
      isLoadingReports.value = false;
    }
  }

  // ======= fetch reports for a user =======
 Future<void> fetchUserReports({
  required int userId,
  String direction = 'both',
  String lang = 'ar',
  int page = 1,
  int perPage = 15,
}) async {
  isLoadingReports.value = true;
  try {
    final query = {
      'direction': direction,
      'lang': lang,
      'page': page.toString(),
      'per_page': perPage.toString(),
    };

    final uri = Uri.parse('$_baseUrl/users/$userId/ad-reports').replace(queryParameters: query);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final body = json.decode(response.body) as Map<String, dynamic>;
      
      if (body['status'] == 'success') {
        // التحقق من أن data هي قائمة وليست خريطة
        if (body['data'] is List) {
          final list = body['data'] as List<dynamic>;
          reports.value = list.map((e) {
            // تأكد من أن كل عنصر في القائمة هو Map
            if (e is Map<String, dynamic>) {
              return AdReportModel.fromJson(e, lang: lang);
            } else {
              print('عنصر غير متوقع في القائمة: ${e.runtimeType}');
              return AdReportModel(
                id: -1, // قيمة افتراضية للعناصر غير الصالحة
                reason: '',
                details: '',
                evidence: [],
                status: 'unknown',
                isAnonymous: false,
              );
            }
          }).where((report) => report.id != -1).toList();
        } else {
          print('التوقيت: List مطلوب ولكن تم استقبال: ${body['data']?.runtimeType}');
          reports.value = [];
        }
      } else {
        _showSnackbar('فشل', body['message']?.toString() ?? 'حدث خطأ', true);
        print(body['message']?.toString());
      }
    } else {
      _showSnackbar('خطأ', 'رمز الاستجابة: ${response.statusCode}', true);
    }
  } catch (e) {
    print('استثناء في fetchUserReports: $e');
    _showSnackbar('استثناء', 'حدث خطأ عند جلب بلاغات المستخدم', true);
  } finally {
    isLoadingReports.value = false;
  }
}
  // ======= create a report =======
  /// payload keys: ad_id (int), reporter_id (int? nullable), is_anonymous (bool), reason (string), details (string?), evidence (List<String>?)
  Future<bool> createReport(Map<String, dynamic> payload) async {
    try {
      final uri = Uri.parse('$_baseUrl/ad-reports');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        if (body['status'] == 'success') {
          // backend returned created report (maybe with relations)
          final data = body['data'];
          if (data is Map<String, dynamic>) {
            final model = AdReportModel.fromJson(data, lang: payload['lang'] ?? 'ar');
            currentReport.value = model;
            // refresh list or push to top
            reports.insert(0, model);
          }
          _showSnackbar('نجاح', 'تم إنشاء البلاغ بنجاح', false);
          return true;
        } else {
          _showSnackbar('فشل', body['message']?.toString() ?? 'إنشاء البلاغ فشل', true);
          return false;
        }
      } else {
        _showSnackbar('خطأ', 'رمز الاستجابة: ${response.statusCode}', true);
        return false;
      }
    } catch (e) {
      print('Exception createReport: $e');
      _showSnackbar('استثناء', 'حدث خطأ أثناء إنشاء البلاغ: $e', true);
      return false;
    }
  }

  // ======= update status =======
  Future<bool> updateStatus({
    required int id,
    required String status, // pending|in_review|resolved|rejected
    int? handledBy,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/ad-reports/$id/status');
      final bodyMap = <String, dynamic>{'status': status};
      if (handledBy != null) bodyMap['handled_by'] = handledBy;

      final response = await http.patch(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(bodyMap),
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        if (body['status'] == 'success') {
          // update local list item if present
          final updated = body['data'];
          if (updated is Map<String, dynamic>) {
            final model = AdReportModel.fromJson(updated);
            // replace in reports list
            final idx = reports.indexWhere((r) => r.id == model.id);
            if (idx != -1) {
              reports[idx] = model;
            }
            currentReport.value = model;
          }
          _showSnackbar('نجاح', 'تم تحديث حالة البلاغ', false);
          return true;
        } else {
          _showSnackbar('فشل', body['message']?.toString() ?? 'فشل التحديث', true);
          return false;
        }
      } else {
        _showSnackbar('خطأ', 'رمز الاستجابة: ${response.statusCode}', true);
        return false;
      }
    } catch (e) {
      print('Exception updateStatus: $e');
      _showSnackbar('استثناء', 'حدث خطأ أثناء تحديث الحالة: $e', true);
      return false;
    }
  }

  // ======= delete report =======
  Future<bool> deleteReport(int id) async {
    try {
      final uri = Uri.parse('$_baseUrl/ad-reports/$id');
      final response = await http.delete(uri);

      if (response.statusCode == 200) {
        // remove locally
        reports.removeWhere((r) => r.id == id);
        _showSnackbar('نجاح', 'تم حذف البلاغ', false);
        return true;
      } else {
        _showSnackbar('خطأ', 'رمز الاستجابة: ${response.statusCode}', true);
        return false;
      }
    } catch (e) {
      print('Exception deleteReport: $e');
      _showSnackbar('استثناء', 'حدث خطأ أثناء حذف البلاغ: $e', true);
      return false;
    }
  }

  // ===== helper snackbar =====
  void _showSnackbar(String title, String message, bool isError) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: isError ? Colors.redAccent : Colors.green,
      colorText: Colors.white,
      borderRadius: 10,
      margin: EdgeInsets.all(12),
      duration: Duration(seconds: isError ? 4 : 3),
      icon: Icon(isError ? Icons.error_outline : Icons.check_circle, color: Colors.white),
      shouldIconPulse: true,
      dismissDirection: DismissDirection.horizontal,
    );
  }
}
