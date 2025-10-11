// lib/controllers/AboutUsController.dart
import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../core/data/model/AboutUs.dart';

class AboutUsController extends GetxController {
  static const _baseUrl = 'https://stayinme.arabiagroup.net/lar_stayInMe/public/api';
  RxBool isGetFirstTime = false.obs;
  
  final Rxn<AboutUs> aboutUs = Rxn<AboutUs>();
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    if (!isGetFirstTime.value) {
      fetchAboutUs();
      isGetFirstTime.value = true;
    }
  }

  Future<void> fetchAboutUs() async {
    isLoading.value = true;
    try {
      final uri = Uri.parse('$_baseUrl/about-us');
      final res = await http.get(uri);

      if (res.statusCode == 200) {
        final result = json.decode(res.body) as Map<String, dynamic>;
        if (result['success'] == true) {
          aboutUs.value = AboutUs.fromJson(result['data'] as Map<String, dynamic>);
        }
      }
    } catch (e) {
      print('Exception fetchAboutUs: $e');
    } finally {
      isLoading.value = false;
    }
  }
}