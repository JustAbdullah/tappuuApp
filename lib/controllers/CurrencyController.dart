import 'dart:convert';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../core/services/appservices.dart';

class CurrencyController extends GetxController {
  final String _baseUrl =
      "https://stayinme.arabiagroup.net/lar_stayInMe/public/api/v1";

  /// كل العملات من السيرفر
  var currencies = <Map<String, dynamic>>[].obs;

  /// العملة الحالية (افتراضي SYP)
  var currentCurrency = 'SYP'.obs;

  /// تحميل العملات من الـ API
  Future<void> fetchCurrencies() async {
    try {
      final res = await http.get(Uri.parse("$_baseUrl/currencies"));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          currencies.value =
              List<Map<String, dynamic>>.from(data['data'] as List);
        }
      }
    } catch (e) {
      print("Error fetching currencies: $e");
    }
  }

  /// تغيير العملة
  void changeCurrency(String currencyCode) {
    // إذا الكود مش موجود ضمن العملات، نرجعه للـ SYP
    final exists =
        currencies.any((element) => element['code'] == currencyCode.toUpperCase());
    if (!exists) {
      currencyCode = 'SYP';
    }

    currentCurrency.value = currencyCode;
    saveCurrency(currencyCode);

    // تحديث جميع الصفحات لتطبيق التغيير
    Get.forceAppUpdate();
  }

  /// حفظ العملة المختارة في SharedPreferences
  void saveCurrency(String currencyCode) {
    Get.find<AppServices>().sharedPreferences.setString('currency', currencyCode);
  }

  /// استعادة العملة عند التشغيل
  @override
  void onInit() {
    super.onInit();
    final prefs = Get.find<AppServices>().sharedPreferences;
    final savedCurrency = prefs.getString('currency');

    String code = savedCurrency ?? 'SYP';
    final exists =
        currencies.any((element) => element['code'] == code.toUpperCase());

    if (!exists) {
      code = 'SYP';
    }

    currentCurrency.value = code;

    // نجيب العملات من السيرفر عند بداية التشغيل
    fetchCurrencies();
  }

  /// تنسيق السعر حسب العملة الحالية
  String formatPrice(double price) {
    final syFormat = NumberFormat.currency(
      locale: 'ar_SY',
      symbol: '',
      decimalDigits: 0,
    );
    final usdFormat = NumberFormat.currency(
      locale: 'en_US',
      symbol: '\$',
      decimalDigits: 2,
    );

    // نجيب العملة الحالية من القائمة (مع الـ rate)
    final currency = currencies.firstWhereOrNull(
      (c) => c['code'] == currentCurrency.value,
    );

    if (currency == null) {
      // fallback: رجع السعر بالليرة
      return '${syFormat.format(price)} ليرة.س';
    }

    if (currency['code'] == 'SYP') {
      // السعر بالليرة السورية
      return '${syFormat.format(price)} ليرة.س';
    } else {
      // تحويل السعر من SYP إلى العملة المختارة حسب الـ rate
      final rate = (currency['rate'] as num).toDouble();
      if (rate == 0) return usdFormat.format(0);

      final converted = price / rate;
      return "${currency['symbol'] ?? currency['code']} ${converted.toStringAsFixed(2)}";
    }
  }
}
