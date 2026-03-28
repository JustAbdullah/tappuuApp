// lib/controllers/views_controller.dart

import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../core/data/model/AdResponse.dart';
import '../core/localization/changelanguage.dart';
import 'LoadingController.dart';

class ViewsController extends GetxController {


  LoadingController _loadingController = Get.find<LoadingController>();


  /// يجلب قائمة المشاهدات مع فلترة وزمن وصفحة
  static const _baseUrl = 'https://taapuu.com/api/views';
  var views = <Ad>[].obs;
  RxBool isLoading = false.obs;


@override
void onInit() {
  super.onInit();
  views = <Ad>[].obs;
}

Future<void> fetchViews({
  required int userId,
  String lang = 'ar',
  String timeframe = 'all',
  int page = 1,
  int perPage = 15,
}) async {
  isLoading.value = true;
  try {
    final uri = Uri.parse('$_baseUrl/list').replace(queryParameters: {
      'user_id': userId.toString(),
      'lang': Get.find<ChangeLanguageController>().currentLocale.value.languageCode,
      'timeframe': timeframe,
      'page': page.toString(),
      'per_page': perPage.toString(),
    });

    print('🛠️ Fetching views from: $uri');
    final response = await http.get(uri);

    print('🛠️ Status code: ${response.statusCode}');
    print('🛠️ Response body: ${response.body}');

    if (response.statusCode != 200) {
      print('❌ Error fetching views: HTTP ${response.statusCode}');
      return;
    }

    final jsonData = json.decode(response.body) as Map<String, dynamic>;

    // حاول القراءة من views.data أو data كـ fallback
    List<dynamic>? rawList = (jsonData['views']?['data'] as List<dynamic>?);
    rawList = rawList ?? (jsonData['data'] as List<dynamic>?) ?? [];

    final parsed = <Ad>[];
    for (var i = 0; i < rawList.length; i++) {
      final element = rawList[i];
      try {
        if (element == null) {
          print('⚠️ views element #$i is null — skipping');
          continue;
        }

        // إذا العنصر ملفوف بكائن يحتوي 'ad'
        if (element is Map<String, dynamic> && element.containsKey('ad')) {
          final adMap = element['ad'];
          if (adMap is Map<String, dynamic>) {
            parsed.add(Ad.fromJson(adMap));
            continue;
          } else if (adMap == null) {
            print('⚠️ views element[$i][\'ad\'] is null — skipping');
            continue;
          } else {
            // حاول تحويله إلى Map إن أمكن
            final m = Map<String, dynamic>.from(adMap as Map);
            parsed.add(Ad.fromJson(m));
            continue;
          }
        }

        // لو العنصر هو الـ Ad مباشرة
        if (element is Map<String, dynamic> && element.containsKey('id')) {
          parsed.add(Ad.fromJson(element));
          continue;
        }

        // محاولة عامة للحاق بأي Map
        if (element is Map) {
          final m = Map<String, dynamic>.from(element as Map);
          parsed.add(Ad.fromJson(m));
          continue;
        }

        // غير معروف — سجل وتخطى
        print('⚠️ Unrecognized views element #$i, skipping. element: $element');
      } catch (e, st) {
        print('🔥 Error parsing view element #$i -> $e');
        print(st);
        try {
          print('🔥 Problematic element JSON: ${json.encode(element)}');
        } catch (_) {
          print('🔥 Problematic element (non-encodable): $element');
        }
        continue;
      }
    }

    views.value = parsed;
    print('✅ Loaded ${views.length} views');
  } catch (e, st) {
    print('🔥 Exception fetching views: $e');
    print(st);
  } finally {
    isLoading.value = false;
  }
}



  /// يسجل مشاهدة جديدة
  Future<void> logView({
    required int userId,
    required int adId,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/log');
      final resp = await http.post(uri, body: {
        'user_id': userId.toString(),
        'ad_id': adId.toString(),
      });
      if (resp.statusCode == 200) {
      
      } else {
        print('Error logView: ${resp.body}');
      }
    } catch (e) {
      print('Exception logView: $e');
    }
  }

  /// يحذف مشاهدة معينة by view_id
  Future<void> removeView({
    required int userId,
    required int viewId,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/remove');
      final resp = await http.delete(uri, body: {
        'user_id': userId.toString(),
        'view_id': viewId.toString(),
      });
      if (resp.statusCode == 200) {
       
      } else {
        print('Error removeView: ${resp.body}');
      }
    } catch (e) {
      print('Exception removeView: $e');
    }
  }

  /// يمسح كل المشاهدات
  Future<void> clearViews({ required int userId }) async {
    try {
      final uri = Uri.parse('$_baseUrl/clear');
      final resp = await http.delete(uri, body: {
        'user_id': userId.toString(),
      });
      if (resp.statusCode == 200) {
        views.clear();
      } else {
        print('Error clearViews: ${resp.body}');
      }
    } catch (e) {
      print('Exception clearViews: $e');
    }
  }


  checkIsHaveAccount(int idAd){
    if(_loadingController.currentUser != null){
      logView(userId:_loadingController.currentUser?.id??0,adId: idAd );
    }else{
      
    }


  }
}
