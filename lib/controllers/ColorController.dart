// lib/controllers/ColorController.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../core/data/model/AppColor.dart';

class ColorController extends GetxController {
  static const _baseUrl = 'https://stayinme.arabiagroup.net/lar_stayInMe/public/api';
   
  // اللون الأساسي التفاعلي
  final Rx<Color> primaryColor = const Color(0xFF2D5E8C).obs;
  final isLoading = false.obs;
  final Color defaultColor = const Color(0xFF2D5E8C);

  @override
  void onInit() {
    super.onInit();
    fetchPrimaryColor();
  }

  Future<void> fetchPrimaryColor() async {
    isLoading.value = true;
    try {
      final uri = Uri.parse('$_baseUrl/colors');
      final res = await http.get(uri);

      if (res.statusCode == 200) {
        final result = json.decode(res.body) as Map<String, dynamic>;
        if (result['success'] == true) {
          final list = (result['data'] as List)
              .map((e) => AppColor.fromJson(e as Map<String, dynamic>))
              .toList();
          
          // البحث عن اللون الأساسي
          final primary = list.firstWhere(
            (color) => color.name == 'primary',
            orElse: () => AppColor(
              id: 0, 
              name: 'primary', 
              hexCode: defaultColor.value.toRadixString(16).substring(2)
            ),
          );
          
          // تحديث اللون الأساسي
          primaryColor.value = primary.toColor();
        }
      }
    } catch (e) {
      print('Exception fetchPrimaryColor: $e');
      // استخدام اللون الافتراضي في حالة الخطأ
      primaryColor.value = defaultColor;
    } finally {
      isLoading.value = false;
    }
  }

  Color get primary => primaryColor.value;
}