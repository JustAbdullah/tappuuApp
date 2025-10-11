
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:tappuu_app/controllers/LoadingController.dart';

import '../core/data/model/AdResponse.dart';
import '../core/data/model/BrowsingHistory.dart';
import '../core/localization/changelanguage.dart';
class BrowsingHistoryController extends GetxController {

    static const _baseUrl = 'https://stayinme.arabiagroup.net/lar_stayInMe/public/api';



@override
void onInit() {
  super.onInit();
  if(Get.find<LoadingController>().currentUser != null)
  fetchHistory(userId:Get.find<LoadingController>().currentUser?.id??0, lang: Get.find<ChangeLanguageController>().currentLocale.value.languageCode).then((_) {
    fetchRecommendedAds(userId: Get.find<LoadingController>().currentUser?.id??0, lang: Get.find<ChangeLanguageController>().currentLocale.value.languageCode);
  });
}
  var historyList = <BrowsingHistory>[].obs;
  var isLoadingHistory = false.obs;
/// Fetch entire browsing history for a user
Future<void> fetchHistory({
  required int userId,
  String lang = 'en', // أو 'ar'
}) async {
  isLoadingHistory.value = true;
  try {
    final uri = Uri.parse('$_baseUrl/browse/history').replace(
      queryParameters: {
        'user_id': userId.toString(),
        'lang'    : lang,
      },
    );
    final res = await http.get(uri);
    if (res.statusCode == 200) {
      final data = json.decode(res.body) as Map<String, dynamic>;
      if (data['success'] == true) {
        final list = (data['data'] as List)
            .map((e) => BrowsingHistory.fromJson(e as Map<String, dynamic>))
            .toList();
        historyList.value = list;
      }
    }
  } catch (e) {
    print('Exception fetchHistory: $e');
  } finally {
    isLoadingHistory.value = false;
  }
}
  /// Add (or update) a browsing entry
  /// Add (or update) a browsing entry
  Future<void> addHistory({
    required int userId,
    required int categoryId,
    required int subcat1Id,
    int? subcat2Id,
  }) async {
    final uri = Uri.parse('$_baseUrl/browse/store');
    final body = {
      'user_id': userId.toString(),
      'category_id': categoryId.toString(),
      'subcat1_id': subcat1Id.toString(),
      if (subcat2Id != null) 'subcat2_id': subcat2Id.toString(),
    };

    debugPrint('➡️ [addHistory] $uri');
    debugPrint('➡️ Payload: $body');

    try {
      final res = await http.post(uri, body: body);

      debugPrint('⬅️ Status: ${res.statusCode}');
      debugPrint('⬅️ Body: ${res.body}');

      if (res.statusCode == 201) {
        debugPrint('✅ addHistory succeeded');
        // إذا حابب تعيد تحميل التاريخ بعد الإضافة:
        // await fetchHistory(userId: userId);
      } else {
        debugPrint('⚠️ addHistory failed with status ${res.statusCode}');
      }
    } catch (e, stack) {
      debugPrint('❌ Exception addHistory: $e');
      debugPrint(stack.toString());
    }
  }


  /// Delete a single entry by its ID
  Future<void> deleteOne({required int userId, required int id}) async {
    final uri = Uri.parse('$_baseUrl/browse/history/$id').replace(
      queryParameters: {'user_id': userId.toString()},
    );
    try {
      final res = await http.delete(uri);
      if (res.statusCode == 200) {
        await fetchHistory(userId: userId);
      }
    } catch (e) {
      print('Exception deleteOne: $e');
    }
  }

  /// Delete all history for a user
  Future<void> deleteAll({required int userId}) async {
    final uri = Uri.parse('$_baseUrl/browse/history').replace(
      queryParameters: {'user_id': userId.toString()},
    );
    try {
      final res = await http.delete(uri);
      if (res.statusCode == 200) {
        historyList.clear();
      }
    } catch (e) {
      print('Exception deleteAll: $e');
    }


  }


    var recommendedAds = <Ad>[].obs;
  var isLoadingRecommended = false.obs;

  /// Fetch recommended ads based on browsing history
  Future<void> fetchRecommendedAds({
    required int userId,
    String lang = 'ar',
    String status = 'published',
    int perHistory = 10,
    int page = 1,
    int perPage = 15,
  }) async {
    isLoadingRecommended.value = true;
    try {
      final uri = Uri.parse('$_baseUrl/ads/recommended').replace(
        queryParameters: {
          'user_id'     : userId.toString(),
          'lang'        : lang,
          'status'      : status,
          'per_history' : perHistory.toString(),
          'page'        : page.toString(),
          'per_page'    : perPage.toString(),
        },
      );
      debugPrint('➡️ [recommendedByHistory] $uri');

      final res = await http.get(uri);
      debugPrint('⬅️ Status: ${res.statusCode}');
      debugPrint('⬅️ Body: ${res.body}');
  if (res.statusCode == 200) {
      final jsonData = json.decode(res.body) as Map<String, dynamic>;
      final rawList = (jsonData['data'] as List<dynamic>);
      print('✅ [DATA COUNT] ${rawList.length} items');

      final adResponse = AdResponse.fromJson({'data': rawList});
      recommendedAds.value         = adResponse.data;
     
      } else {
        debugPrint('⚠️ fetchRecommendedAds failed with status ${res.statusCode}');
      }
    } catch (e, st) {
      debugPrint('❌ Exception fetchRecommendedAds: $e');
      debugPrint(st.toString());
    } finally {
      isLoadingRecommended.value = false;
    }
  }

}
