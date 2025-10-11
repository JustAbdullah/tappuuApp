// lib/controllers/favorite_groups_controller.dart

import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../core/data/model/favorite.dart';
import 'LoadingController.dart';

class FavoriteGroupsController extends GetxController {
  final LoadingController _loadingController = Get.find<LoadingController>();
  static const _baseUrl = 'https://stayinme.arabiagroup.net/lar_stayInMe/public/api/favorite-groups';
  

  var groups = <FavoriteGroup>[].obs;
  RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    groups = <FavoriteGroup>[].obs;
  }

  /// جلب جميع مجموعات المستخدم
  Future<void> fetchGroups({ required int userId }) async {
    isLoading.value = true;
    try {
      final uri = Uri.parse('$_baseUrl/list').replace(queryParameters: {
        'user_id': userId.toString(),
      });

      final resp = await http.get(uri);
      if (resp.statusCode == 200) {
        final jsonData = json.decode(resp.body) as Map<String, dynamic>;
        final raw = (jsonData['groups'] as List<dynamic>?) ?? [];
        groups.value = raw.map((e) => FavoriteGroup.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        print('Error fetchGroups: ${resp.statusCode} ${resp.body}');
      }
    } catch (e, st) {
      print('Exception fetchGroups: $e');
      print(st);
    } finally {
      isLoading.value = false;
    }
  }

  /// إنشاء مجموعة جديدة
  Future<FavoriteGroup?> createGroup({
    required int userId,
    required String name,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/create');
      final body = {
        'user_id': userId.toString(),
        'name': name,
      };

      final resp = await http.post(uri,
        headers: {'Accept':'application/json','Content-Type':'application/x-www-form-urlencoded'},
        body: body,
      );

      if (resp.statusCode == 201 || resp.statusCode == 200) {
        final jsonData = json.decode(resp.body) as Map<String, dynamic>;
        final groupJson = jsonData['group'] as Map<String, dynamic>?;
        if (groupJson != null) {
          final group = FavoriteGroup.fromJson(groupJson);
          // ضفها للقائمة محليًا
          groups.insert(0, group);
          return group;
        }
      } else {
        print('Error createGroup: ${resp.statusCode} ${resp.body}');
      }
    } catch (e, st) {
      print('Exception createGroup: $e');
      print(st);
    }
    return null;
  }

  /// تعديل اسم المجموعة
  Future<bool> updateGroup({
    required int id,
    required int userId,
    required String name,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/$id');
      final resp = await http.put(uri,
        headers: {'Accept':'application/json','Content-Type':'application/x-www-form-urlencoded'},
        body: {
          'user_id': userId.toString(),
          'name': name,
        },
      );

      if (resp.statusCode == 200) {
        // حدّث محليًا
        final idx = groups.indexWhere((g) => g.id == id);
        if (idx != -1) {
          final old = groups[idx];
          groups[idx] = FavoriteGroup(id: old.id, userId: old.userId, name: name, favoritesCount: old.favoritesCount);
        }
        return true;
      } else {
        print('Error updateGroup: ${resp.statusCode} ${resp.body}');
      }
    } catch (e, st) {
      print('Exception updateGroup: $e');
      print(st);
    }
    return false;
  }

  /// حذف مجموعة
  Future<bool> deleteGroup({
    required int id,
    required int userId,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/$id');
      final resp = await http.delete(uri, body: {
        'user_id': userId.toString(),
      });

      if (resp.statusCode == 200) {
        groups.removeWhere((g) => g!.id == id);
        return true;
      } else {
        print('Error deleteGroup: ${resp.statusCode} ${resp.body}');
      }
    } catch (e, st) {
      print('Exception deleteGroup: $e');
      print(st);
    }
    return false;
  }
}
