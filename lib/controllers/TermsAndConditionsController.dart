// lib/controllers/TermsAndConditionsController.dart
import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../core/data/model/TermsAndConditions.dart';
import '../core/localization/changelanguage.dart';

class TermsAndConditionsController extends GetxController {
  static const _baseUrl = 'https://stayinme.arabiagroup.net/lar_stayInMe/public/api';
  RxBool isGetFirstTime = false.obs;
  
  final Rxn<TermsAndConditions> terms = Rxn<TermsAndConditions>();
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    if (!isGetFirstTime.value) {
      fetchTerms(lang: Get.find<ChangeLanguageController>().currentLocale.value.languageCode);
      isGetFirstTime.value = true;
    }
  }

  /// جلب شروط الاستخدام
  Future<void> fetchTerms({required String lang}) async {
    isLoading.value = true;
    try {
      final uri = Uri.parse('$_baseUrl/terms');
      final res = await http.get(uri);

      if (res.statusCode == 200) {
        final result = json.decode(res.body) as Map<String, dynamic>;
        if (result['success'] == true) {
          final list = (result['data'] as List)
              .map((e) => TermsAndConditions.fromJson(e as Map<String, dynamic>))
              .toList();

          // البحث عن الشروط بلغة المستخدم
          final termsInLang = list.firstWhere(
            (term) => term.language == lang,
            orElse: () => list.first,
          );

          terms.value = termsInLang;
        }
      }
    } catch (e) {
      print('Exception fetchTerms: $e');
    } finally {
      isLoading.value = false;
    }
  }
}