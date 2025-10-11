import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../core/data/model/PremiumPackage.dart';

class PremiumPackageController extends GetxController {
  final String _baseUrl = 'https://stayinme.arabiagroup.net/lar_stayInMe/public/api';

  RxList<PremiumPackage> packagesList = <PremiumPackage>[].obs;
  RxBool isLoadingPackages = false.obs;

  RxBool isSaving = false.obs;
  RxBool isDeleting = false.obs;

  // ======== [جلب الباقات] ========
  Future<void> fetchPackages({String? status, int? perPage}) async {
    isLoadingPackages.value = true;
    try {
      final uri = Uri.parse('$_baseUrl/premium-packages').replace(queryParameters: {
        if (status != null) 'is_active': status,
        if (perPage != null) 'per_page': perPage.toString(),
      });

      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body) as Map<String, dynamic>;
        if (jsonResponse['success'] == true) {
          final data = jsonResponse['data'];
          // data could be List or paginated object
          List items = [];
          if (data is List) {
            items = data;
          } else if (data is Map && data['data'] is List) {
            items = data['data'];
          }
          packagesList.value = items.map((e) => PremiumPackage.fromJson(e as Map<String, dynamic>)).toList();
        } else {
          _showSnackbar('خطأ', jsonResponse['message'] ?? 'فشل جلب الباقات', true);
        }
      } else {
        _showSnackbar('خطأ', 'خطأ في الاتصال بالسيرفر (${response.statusCode})', true);
      }
    } catch (e) {
      _showSnackbar('خطأ', 'حدث خطأ أثناء جلب الباقات: $e', true);
    } finally {
      isLoadingPackages.value = false;
    }
  }

  // ======== [إنشاء باقة] ========
  Future<void> createPackage(PremiumPackage pkg) async {
    if (pkg.name.trim().isEmpty) {
      _showSnackbar('تحذير', 'الرجاء إدخال اسم الباقة', true);
      return;
    }

    isSaving.value = true;
    try {
      final uri = Uri.parse('$_baseUrl/premium-packages');
      final res = await http.post(uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(pkg.toJson()));

      final resData = json.decode(res.body);
      if (res.statusCode == 201 || (res.statusCode == 200 && resData['success'] == true)) {
        _showSnackbar('نجاح', 'تم إنشاء الباقة بنجاح', false);
        // أعد جلب الباقات
        await fetchPackages();
      } else {
        _showSnackbar('خطأ', resData['message'] ?? 'فشل إنشاء الباقة', true);
      }
    } catch (e) {
      _showSnackbar('خطأ', 'حدث خطأ أثناء إنشاء الباقة: $e', true);
    } finally {
      isSaving.value = false;
    }
  }

  // ======== [تحديث باقة] ========
  Future<void> updatePackage(PremiumPackage pkg) async {
    if (pkg.id == null) {
      _showSnackbar('تحذير', 'معرف الباقة مطلوب للتحديث', true);
      return;
    }

    isSaving.value = true;
    try {
      final uri = Uri.parse('$_baseUrl/premium-packages/${pkg.id}');
      final res = await http.put(uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(pkg.toJson()));

      final resData = json.decode(res.body);
      if (res.statusCode == 200 && resData['success'] == true) {
        _showSnackbar('نجاح', 'تم تحديث الباقة بنجاح', false);
        await fetchPackages();
      } else {
        _showSnackbar('خطأ', resData['message'] ?? 'فشل تحديث الباقة', true);
      }
    } catch (e) {
      _showSnackbar('خطأ', 'حدث خطأ أثناء تحديث الباقة: $e', true);
    } finally {
      isSaving.value = false;
    }
  }

  // ======== [حذف باقة] ========
  Future<void> deletePackage(int id) async {
    isDeleting.value = true;
    try {
      final uri = Uri.parse('$_baseUrl/premium-packages/$id');
      final res = await http.delete(uri);
      final resData = json.decode(res.body);
      if (res.statusCode == 200 && resData['success'] == true) {
        _showSnackbar('نجاح', 'تم حذف الباقة بنجاح', false);
        await fetchPackages();
      } else {
        _showSnackbar('خطأ', resData['message'] ?? 'فشل حذف الباقة', true);
      }
    } catch (e) {
      _showSnackbar('خطأ', 'حدث خطأ أثناء حذف الباقة: $e', true);
    } finally {
      isDeleting.value = false;
    }
  }

  // ======== [إخفاء/عرض باقة واحدة (toggle)] ========
  Future<void> toggleActive(int id) async {
    isSaving.value = true;
    try {
      final uri = Uri.parse('$_baseUrl/premium-packages/$id/toggle-active');
      final res = await http.post(uri);
      final resData = json.decode(res.body);
      if (res.statusCode == 200 && resData['success'] == true) {
        _showSnackbar('نجاح', 'تم تحديث حالة الباقة', false);
        await fetchPackages();
      } else {
        _showSnackbar('خطأ', resData['message'] ?? 'فشل تحديث حالة الباقة', true);
      }
    } catch (e) {
      _showSnackbar('خطأ', 'حدث خطأ أثناء تحديث حالة الباقة: $e', true);
    } finally {
      isSaving.value = false;
    }
  }

  // ======== [إخفاء كل الباقات مرة واحدة] ========
  Future<void> hideAllPackages() async {
    isSaving.value = true;
    try {
      final uri = Uri.parse('$_baseUrl/premium-packages/hide-all');
      final res = await http.post(uri);
      final resData = json.decode(res.body);
      if (res.statusCode == 200 && resData['success'] == true) {
        _showSnackbar('نجاح', resData['message'] ?? 'تم إخفاء كل الباقات', false);
        await fetchPackages();
      } else {
        _showSnackbar('خطأ', resData['message'] ?? 'فشل إخفاء الباقات', true);
      }
    } catch (e) {
      _showSnackbar('خطأ', 'حدث خطأ أثناء إخفاء الباقات: $e', true);
    } finally {
      isSaving.value = false;
    }
  }

  // ======== [Snackbar helper] ========
  void _showSnackbar(String title, String message, bool isError) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: isError ? Colors.redAccent : Colors.green,
      colorText: Colors.white,
      borderRadius: 10,
      margin: EdgeInsets.all(15),
      duration: Duration(seconds: isError ? 4 : 3),
      icon: Icon(isError ? Icons.error_outline : Icons.check_circle, color: Colors.white),
      shouldIconPulse: true,
      dismissDirection: DismissDirection.horizontal,
    );
  }
}
