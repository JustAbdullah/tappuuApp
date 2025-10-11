// lib/core/controllers/bank_account_controller.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../core/data/model/BankAccountModel.dart';


class BankAccountController extends GetxController {
  final String _baseUrl = 'https://stayinme.arabiagroup.net/lar_stayInMe/public/api';
  RxList<BankAccountModel> accounts = <BankAccountModel>[].obs;
  RxBool isLoading = false.obs;
  Rxn<BankAccountModel> current = Rxn<BankAccountModel>();

  // ===== fetch all =====
  Future<void> fetchAccounts() async {
    isLoading.value = true;
    try {
      final uri = Uri.parse('$_baseUrl/bank-accounts');
      final res = await http.get(uri, headers: {'Accept': 'application/json'});

      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        // دعم صيغتين: { success: true, data: [...] } أو { status: 'success', data: [...] }
        final data = (body is Map && (body['data'] != null)) ? body['data'] : body;
        if (data is List) {
          accounts.value = data.map((e) => BankAccountModel.fromJson(e as Map<String, dynamic>)).toList();
        } else {
          accounts.value = [];
          _showSnackbar('خطأ', 'البيانات المستلمة غير متوقعة', true);
        }
      } else {
        _showSnackbar('خطأ', 'رمز الاستجابة: ${res.statusCode}', true);
      }
    } catch (e) {
      print('Exception fetchAccounts: $e');
      _showSnackbar('استثناء', 'حدث خطأ عند جلب الحسابات', true);
    } finally {
      isLoading.value = false;
    }
  }

  // ===== fetch one =====
  Future<void> fetchAccount(int id) async {
    isLoading.value = true;
    try {
      final uri = Uri.parse('$_baseUrl/bank-accounts/$id');
      final res = await http.get(uri, headers: {'Accept': 'application/json'});
      if (res.statusCode == 200) {
        final body = json.decode(res.body) as Map<String, dynamic>;
        final data = body['data'] ?? body;
        current.value = BankAccountModel.fromJson(data as Map<String, dynamic>);
      } else {
        _showSnackbar('خطأ', 'رمز الاستجابة: ${res.statusCode}', true);
      }
    } catch (e) {
      print('Exception fetchAccount: $e');
      _showSnackbar('استثناء', 'حدث خطأ عند جلب الحساب', true);
    } finally {
      isLoading.value = false;
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
    );
  }
}
