import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/ColorController.dart';

class AppColors {
  // ─── الألوان الأساسية ─────────────────
  static Color get primary => Get.find<ColorController>().primary;
  static const Color primarySecond = Color(0xFFF2B81B);

  // ─── الألوان المحايدة ─────────────────
  static const Color greyLight = Color(0xFFBDBDBD);
  static const Color grey = Color(0xFF9E9E9E);
  static const Color greyDark = Color(0xFF616161);
  static const Color premiumColor = Color(0xFF6DBDBDA);

  // ─── ألوان النص ───────────────────────
  static const Color onPrimary = Colors.white;
  static const Color onSecondary = Colors.black;
  static const Color onBackground = Colors.black;
  static const Color onSurfaceLight = Colors.black;
  static const Color onSurfaceDark = Colors.white;

  // ─── الألوان المحايدة المحسنة ─────────
  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceLight = Colors.white;
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color cardLight = Color(0xFFF1F3F5);
  static const Color cardDark = Color(0xFF252525);

  // ─── درجات الرمادي ───────────────────
  static const Color grey50 = Color(0xFFF8F9FA);
  static const Color grey100 = Color(0xFFF1F3F5);
  static const Color grey200 = Color(0xFFE9ECEF);
  static const Color grey300 = Color(0xFFDEE2E6);
  static const Color grey400 = Color(0xFFCED4DA);
  static const Color grey500 = Color(0xFFADB5BD);
  static const Color grey600 = Color(0xFF868E96);
  static const Color grey700 = Color(0xFF495057);
  static const Color grey800 = Color(0xFF343A40);
  static const Color grey900 = Color(0xFF212529);

  // ─── الألوان الدلالية ─────────────────
  static const Color success = Color(0xFF34C759);
  static const Color error = Color(0xFFFF3B30);
  static const Color warning = Color(0xFFFF9500);
  static const Color buttonAndLinksColor = Color(0xFF558ED2);
  static const Color redId = Color(0xFF8C261E);
  static const Color PremiumColor = Color(0xFF6DBDBDA);
static const Color yellow = Color(0xFFF7C84B);

  // ─── دوال الوضع الفاتح/الداكن ─────────
  static Color background(bool isDarkMode) => isDarkMode ? backgroundDark : backgroundLight;
  static Color backgroundHome(bool isDarkMode) => isDarkMode ? backgroundDark : Color(0xFFEEEEEE);
  static Color surface(bool isDarkMode) => isDarkMode ? surfaceDark : surfaceLight;
  static Color card(bool isDarkMode) => isDarkMode ? cardDark : cardLight;
  static Color textPrimary(bool isDarkMode) => isDarkMode ? grey100 : grey900;
  static Color textSecondary(bool isDarkMode) => isDarkMode ? grey400 : grey600;
  static Color border(bool isDarkMode) => isDarkMode ? grey700 : grey300;
  static Color divider(bool isDarkMode) => border(isDarkMode);
  static Color icon(bool isDarkMode) => isDarkMode ? grey300 : grey600;
  static Color appBar(bool isDarkMode) => isDarkMode ? surfaceDark : primary;
  static Color tagBackground(bool isDarkMode) => isDarkMode ? Color(0xFF374151) : Color(0xFFE5E7EB);
  static Color tagBorder(bool isDarkMode) => isDarkMode ? Color(0xFF4B5563) : Color(0xFFD1D5DB);
  static Color tagText(bool isDarkMode) => isDarkMode ? Color(0xFFF9FAFB) : Color(0xFF1F2937);
  static Color backGroundButton(bool isDarkMode) => isDarkMode ? Color(0xFF4B5563) : Color(0xFFF0F0F0);
  static Color texButton(bool isDarkMode) => isDarkMode ? Colors.black : grey600;
}
