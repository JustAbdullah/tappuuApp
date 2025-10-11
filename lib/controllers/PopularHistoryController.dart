// popular_history_controller.dart
import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../core/data/model/PopularHistory.dart';
import '../core/localization/changelanguage.dart';

class PopularHistoryController extends GetxController {
  static const _baseUrl = 'https://stayinme.arabiagroup.net/lar_stayInMe/public/api';
RxBool isGetFirstTime = false.obs;

  
 // ==================== [الدوال الرئيسية] ====================
  @override
  void onInit() {
    super.onInit();
    // جلب التصنيفات عند التشغيل الأول فقط
    if (!isGetFirstTime.value) {
      fetchPopular(limit: 10,lang:  Get.find<ChangeLanguageController>().currentLocale.value.languageCode);
      isGetFirstTime.value = true;
    }
  }

  var popularList = <PopularHistory>[].obs;
  var isLoadingPopular = false.obs;
/// Fetch top popular histories
Future<void> fetchPopular({
  int limit = 5,
  String lang = 'ar',
}) async {
  isLoadingPopular.value = true;
  try {
    final uri = Uri.parse('$_baseUrl/popular/popular-data').replace(
      queryParameters: {
        'limit': limit.toString(),
        'lang' : lang,
      },
    );
    final res = await http.get(uri);
    if (res.statusCode == 200) {
      final result = json.decode(res.body) as Map<String, dynamic>;
      if (result['success'] == true) {
        final list = (result['data'] as List)
            .map((e) => PopularHistory.fromJson(e as Map<String, dynamic>))
            .toList();
        popularList.value = list;
      }
    }
  } catch (e) {
    print('Exception fetchPopular: $e');
  } finally {
    isLoadingPopular.value = false;
  }
}
  /// Add or increment a popular history entry
 Future<void> addOrIncrement({
  required int categoryId,
  required int subcat1Id,
  int? subcat2Id,
}) async {
  final uri = Uri.parse('$_baseUrl/popular/popular');
  try {
    final body = {
      'category_id': categoryId.toString(),
      'subcat1_id': subcat1Id.toString(),
      if (subcat2Id != null) 'subcat2_id': subcat2Id.toString(),
    };
    
    final res = await http.post(uri, body: body);
    
    if (res.statusCode == 201) {
      print('✅ تم تحديث التصفح الشعبي بنجاح');
    } else if (res.statusCode == 422) {
      final errors = jsonDecode(res.body)?['errors'];
      print('❌ أخطاء التحقق: $errors');
    } else {
    
      print('❌ خطأ غير متوقع: ${res.statusCode}');
    }
  } catch (e) {
    print('🚨 استثناء في addOrIncrement: $e');
  }
}

 
}
