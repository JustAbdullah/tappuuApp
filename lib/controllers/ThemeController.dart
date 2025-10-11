import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends GetxController {
  RxBool isDarkMode = false.obs;

  @override
  void onInit() {
    super.onInit();
  _loadTheme();
  }

  // تبديل الوضع
  /* void toggleTheme() async {
    isDarkMode.value = !isDarkMode.value;
    Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
    _saveTheme(isDarkMode.value);
  }*/
// دالة لتفعيل المود العادي (فاتح)

  void  toggleTheme(){
     isDarkMode.value? enableLightMode():enableDarkMode();
       Get.forceAppUpdate(); // أهم جزء في الحل

  }
  void enableLightMode() async {
    isDarkMode.value = false;
    Get.changeThemeMode(ThemeMode.light); // تغيير الثيم إلى الوضع الفاتح
    _saveTheme(isDarkMode.value); // حفظ الحالة في الذاكرة
  }

  // دالة لتفعيل المود المظلم (داكن)
  void enableDarkMode() async {
    isDarkMode.value = true;
    Get.changeThemeMode(ThemeMode.dark); // تغيير الثيم إلى الوضع المظلم
    _saveTheme(isDarkMode.value); // حفظ الحالة في الذاكرة
  }

  // حفظ الوضع المختار في التخزين المحلي
  void _saveTheme(bool isDark) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDarkMode', isDark);
  }

  // تحميل الوضع المحفوظ
  void _loadTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    isDarkMode.value = prefs.getBool('isDarkMode') ?? false;
    Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
  }
}
