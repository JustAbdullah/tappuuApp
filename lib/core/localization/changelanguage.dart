import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/appservices.dart';

class ChangeLanguageController extends GetxController {
  // ضبط اللغة الافتراضية دائماً على العربية بغض النظر عن لغة الجهاز
  var currentLocale = Locale.fromSubtags(languageCode: 'ar', scriptCode: 'Arab').obs;

  // **قائمة اللغات المدعومة**: أزلنا الإنجليزية هنا حتى يصبح التطبيق عربيًا فقط
  static const _supported = {
    'ar': Locale.fromSubtags(languageCode: 'ar', scriptCode: 'Arab'),
    // 'en' محذوف مؤقتًا لتعطيل الانجليزية
  };

  /// تغيير اللغة — تم تقييد التغيير ليبقى بالعربية فقط.
  /// إذا جاء كود غير مدعوم، نُرجع للعربية تلقائياً.
  void changeLanguage(String langCode) {
    // اذا لم تكن مدعومة، نرجع للعربية
    if (!_supported.containsKey(langCode)) {
      langCode = 'ar';
    }
    final locale = _supported[langCode]!;
    currentLocale.value = locale;
    Get.updateLocale(locale);
    saveLanguage(langCode);
    // إعادة تحميل الصفحات للتأكد من تطبيق التغيير (احترازي)
    Get.forceAppUpdate();
  }

  // حفظ اللغة في SharedPreferences (سيحفظ 'ar' فقط مع التعديلات الحالية)
  void saveLanguage(String langCode) {
    Get.find<AppServices>()
        .sharedPreferences
        .setString('lang', langCode);
  }

  // استعادة اللغة عند التشغيل
  @override
  void onInit() {
    super.onInit();
    final prefs = Get.find<AppServices>().sharedPreferences;
    final savedLang = prefs.getString('lang');

    // لتأكيد سلوك "العربية فقط" نتجاهل لغة الجهاز ونجبر العربية
    String code = 'ar';

    // إذا كان هناك قيمة محفوظة وكانت 'ar' نبقيها (أيضاً لا ندعم غيرها الآن)
    if (savedLang == 'ar') {
      code = 'ar';
    }

    final locale = _supported[code]!;
    currentLocale.value = locale;
    Get.updateLocale(locale);
  }
}
