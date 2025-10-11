// lib/controllers/user_wallet_controller.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../core/data/model/UserWallet.dart';

class UserWalletController extends GetxController {
  final String _baseUrl = 'https://stayinme.arabiagroup.net/lar_stayInMe/public/api';

  // قائمة بجميع محافظ المستخدم
  RxList<UserWallet> userWallets = <UserWallet>[].obs;
  
  // المحفظة المحددة حالياً
  Rx<UserWallet?> selectedWallet = Rx<UserWallet?>(null);
  
  RxBool isLoading = false.obs;
  RxBool isSaving = false.obs;
  RxBool isDeleting = false.obs;

  Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    // 'Authorization': 'Bearer <token>' // ضع التوكن هنا لو تستخدم مصادقة
  };

  // ======== [جلب جميع محافظ المستخدم] ========
  Future<void> fetchUserWallets(int userId) async {
    isLoading.value = true;
    try {
      final uri = Uri.parse('$_baseUrl/users/$userId/wallets');
      final res = await http.get(uri, headers: defaultHeaders);

      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        if (body['success'] == true && body['data'] != null) {
          List<UserWallet> wallets = [];
          for (var item in body['data']) {
            wallets.add(UserWallet.fromJson(Map<String, dynamic>.from(item)));
          }
          userWallets.assignAll(wallets);
        } else {
          userWallets.clear();
          _showSnackbar('خطأ', body['message'] ?? 'فشل جلب المحافظ', true);
        }
      } else if (res.statusCode == 404) {
        userWallets.clear();
        _showSnackbar('معلومة', 'لا توجد محافظ لهذا المستخدم', false);
      } else {
        _showSnackbar('خطأ', 'خطأ في الاتصال بالسيرفر (${res.statusCode})', true);
      }
    } catch (e) {
      _showSnackbar('خطأ', 'حدث خطأ أثناء جلب المحافظ: $e', true);
    } finally {
      isLoading.value = false;
    }
  }

  // ======== [جلب محفظة محددة بواسطة UUID] ========
  Future<void> fetchWalletByUuid(String walletUuid) async {
    isLoading.value = true;
    try {
      final uri = Uri.parse('$_baseUrl/wallets/$walletUuid');
      final res = await http.get(uri, headers: defaultHeaders);

      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        if (body['success'] == true && body['data'] != null) {
          selectedWallet.value = UserWallet.fromJson(Map<String, dynamic>.from(body['data']));
        } else {
          selectedWallet.value = null;
          _showSnackbar('خطأ', body['message'] ?? 'فشل جلب المحفظة', true);
        }
      } else if (res.statusCode == 404) {
        selectedWallet.value = null;
        _showSnackbar('معلومة', 'المحفظة غير موجودة', false);
      } else {
        _showSnackbar('خطأ', 'خطأ في الاتصال بالسيرفر (${res.statusCode})', true);
      }
    } catch (e) {
      _showSnackbar('خطأ', 'حدث خطأ أثناء جلب المحفظة: $e', true);
    } finally {
      isLoading.value = false;
    }
  }

  // ======== [إنشاء محفظة جديدة] ========
  Future<void> createWallet(int userId, {String currency = 'SYP', double initialBalance = 0.0}) async {
    isSaving.value = true;
    try {
      final uri = Uri.parse('$_baseUrl/users/$userId/wallets');
      final payload = {
        'currency': currency,
        'initial_balance': initialBalance,
      };

      final res = await http.post(uri, headers: defaultHeaders, body: jsonEncode(payload));
      final body = json.decode(res.body);

      if (res.statusCode == 201 && body['success'] == true) {
        _showSnackbar('نجاح', 'تم إنشاء المحفظة', false);
        // إعادة تحميل قائمة المحافظ
        await fetchUserWallets(userId);
      } else {
        _showSnackbar('خطأ',  'فشل إنشاء المحفظة', true);
      }
    } catch (e) {
      _showSnackbar('خطأ', 'حدث خطأ أثناء إنشاء المحفظة: ', true);
    } finally {
      isSaving.value = false;
    }
  }

  // ======== [شحن المحفظة - credit] ========
  Future<void> creditWallet({
    required String walletUuid,
    required double amount,
    String? note,
  }) async {
    isSaving.value = true;
    try {
      final uri = Uri.parse('$_baseUrl/wallets/credit');
      final payload = {
        'wallet_uuid': walletUuid,
        'amount': amount,
        if (note != null) 'note': note,
      };

      final res = await http.post(uri, headers: defaultHeaders, body: jsonEncode(payload));
      final body = json.decode(res.body);

      if (res.statusCode == 200 && body['success'] == true) {
        _showSnackbar('نجاح', body['message'] ?? 'تم شحن المحفظة', false);
        // تحديث المحفظة المحددة
        await fetchWalletByUuid(walletUuid);
        // تحديث قائمة المحافظ
        final wallet = selectedWallet.value;
        if (wallet != null) {
          await fetchUserWallets(wallet.userId);
        }
      } else {
        _showSnackbar('خطأ', body['message'] ?? 'فشل شحن المحفظة', true);
      }
    } catch (e) {
      _showSnackbar('خطأ', 'حدث خطأ أثناء شحن المحفظة: $e', true);
    } finally {
      isSaving.value = false;
    }
  }

  // ======== [خصم من المحفظة - debit] ========
  Future<void> debitWallet({
    required String walletUuid,
    required double amount,
    String? note,
  }) async {
    isSaving.value = true;
    try {
      final uri = Uri.parse('$_baseUrl/wallets/debit');
      final payload = {
        'wallet_uuid': walletUuid,
        'amount': amount,
        if (note != null) 'note': note,
      };

      final res = await http.post(uri, headers: defaultHeaders, body: jsonEncode(payload));
      final body = json.decode(res.body);

      if (res.statusCode == 200 && body['success'] == true) {
        _showSnackbar('نجاح', body['message'] ?? 'تم خصم المبلغ من المحفظة', false);
        // تحديث المحفظة المحددة
        await fetchWalletByUuid(walletUuid);
        // تحديث قائمة المحافظ
        final wallet = selectedWallet.value;
        if (wallet != null) {
          await fetchUserWallets(wallet.userId);
        }
      } else {
        _showSnackbar('خطأ', body['message'] ?? 'فشل خصم المبلغ', true);
      }
    } catch (e) {
      _showSnackbar('خطأ', 'حدث خطأ أثناء خصم المحفظة: $e', true);
    } finally {
      isSaving.value = false;
    }
  }

  // ======== [تجميد المحفظة] ========
  Future<void> freezeWallet(String walletUuid) async {
    isSaving.value = true;
    try {
      final uri = Uri.parse('$_baseUrl/wallets/$walletUuid/freeze');
      final res = await http.post(uri, headers: defaultHeaders);
      final body = json.decode(res.body);

      if (res.statusCode == 200 && body['success'] == true) {
        _showSnackbar('نجاح', body['message'] ?? 'تم تجميد المحفظة', false);
        // تحديث المحفظة المحددة
        await fetchWalletByUuid(walletUuid);
        // تحديث قائمة المحافظ
        final wallet = selectedWallet.value;
        if (wallet != null) {
          await fetchUserWallets(wallet.userId);
        }
      } else {
        _showSnackbar('خطأ', body['message'] ?? 'فشل تجميد المحفظة', true);
      }
    } catch (e) {
      _showSnackbar('خطأ', 'حدث خطأ أثناء تجميد المحفظة: $e', true);
    } finally {
      isSaving.value = false;
    }
  }

  // ======== [تنشيط المحفظة] ========
  Future<void> activateWallet(String walletUuid) async {
    isSaving.value = true;
    try {
      final uri = Uri.parse('$_baseUrl/wallets/$walletUuid/activate');
      final res = await http.post(uri, headers: defaultHeaders);
      final body = json.decode(res.body);

      if (res.statusCode == 200 && body['success'] == true) {
        _showSnackbar('نجاح', body['message'] ?? 'تم تنشيط المحفظة', false);
        // تحديث المحفظة المحددة
        await fetchWalletByUuid(walletUuid);
        // تحديث قائمة المحافظ
        final wallet = selectedWallet.value;
        if (wallet != null) {
          await fetchUserWallets(wallet.userId);
        }
      } else {
        _showSnackbar('خطأ', body['message'] ?? 'فشل تنشيط المحفظة', true);
      }
    } catch (e) {
      _showSnackbar('خطأ', 'حدث خطأ أثناء تنشيط المحفظة: $e', true);
    } finally {
      isSaving.value = false;
    }
  }

  // ======== [إغلاق المحفظة] ========
  Future<void> closeWallet(String walletUuid) async {
    isSaving.value = true;
    try {
      final uri = Uri.parse('$_baseUrl/wallets/$walletUuid/close');
      final res = await http.post(uri, headers: defaultHeaders);
      final body = json.decode(res.body);

      if (res.statusCode == 200 && body['success'] == true) {
        _showSnackbar('نجاح', body['message'] ?? 'تم إغلاق المحفظة', false);
        // تحديث المحفظة المحددة
        await fetchWalletByUuid(walletUuid);
        // تحديث قائمة المحافظ
        final wallet = selectedWallet.value;
        if (wallet != null) {
          await fetchUserWallets(wallet.userId);
        }
      } else {
        _showSnackbar('خطأ', body['message'] ?? 'فشل إغلاق المحفظة', true);
      }
    } catch (e) {
      _showSnackbar('خطأ', 'حدث خطأ أثناء إغلاق المحفظة: $e', true);
    } finally {
      isSaving.value = false;
    }
  }

  // ======== [حذف المحفظة] ========
  Future<void> deleteWallet(String walletUuid) async {
    isDeleting.value = true;
    try {
      final uri = Uri.parse('$_baseUrl/wallets/$walletUuid');
      final res = await http.delete(uri, headers: defaultHeaders);
      final body = json.decode(res.body);

      if (res.statusCode == 200 && body['success'] == true) {
        _showSnackbar('نجاح', body['message'] ?? 'تم حذف المحفظة', false);
        // إزالة المحفظة من القائمة
        userWallets.removeWhere((wallet) => wallet.uuid == walletUuid);
        // إذا كانت المحفظة المحذوفة هي المحددة حالياً، نضبطها على null
        if (selectedWallet.value?.uuid == walletUuid) {
          selectedWallet.value = null;
        }
      } else {
        _showSnackbar('خطأ', body['message'] ?? 'فشل حذف المحفظة', true);
      }
    } catch (e) {
      _showSnackbar('خطأ', 'حدث خطأ أثناء حذف المحفظة: $e', true);
    } finally {
      isDeleting.value = false;
    }
  }

  // ======== [Snackbar helper] ========
  void _showSnackbar(String title, String message, bool isError) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: isError ? Colors.redAccent : Colors.green,
      colorText: Colors.white,
      borderRadius: 10,
      margin: EdgeInsets.all(15),
      duration: Duration(seconds: isError ? 4 : 3),
      icon: Icon(isError ? Icons.error_outline : Icons.check_circle, color: Colors.white),
      shouldIconPulse: true,
      dismissDirection: DismissDirection.horizontal,
    );
  }





// في WalletController (أو الملف المناسب)
Future<Map<String, dynamic>> purchasePremium({
  required String walletUuid,
  required int adId,
  required List<int> packageIds,
}) async {
  isSaving.value = true;
  try {
    final uri = Uri.parse('$_baseUrl/wallets/purchasePremium');
    final payload = {
      'wallet_uuid': walletUuid,
      'ad_id': adId,
      'package_ids': packageIds,
    };

    final res = await http.post(uri, headers: defaultHeaders, body: jsonEncode(payload));
    final body = json.decode(res.body);

    if (res.statusCode == 200 && body['success'] == true) {
      _showSnackbar('نجاح', body['message'] ?? 'تم شراء/تجديد الباقات', false);

      // حدّث المحفظة إن أعاد السيرفر المحفظة أو transaction
      if (body['data'] != null && body['data']['wallet'] != null) {
        // افتراض: يوجد endpoint/لوغيك لتحويل JSON -> UserWallet model
        // يمكنك تفريغ الـ wallet object مباشرةً في قائمتك أو إعادة تحميل القوائم
        await fetchWalletByUuid(walletUuid);
        final wallet = selectedWallet.value;
        if (wallet != null) {
          await fetchUserWallets(wallet.userId);
        }
      } else {
        // كإجراء احتياطي، حدّث القوائم
        final wallet = selectedWallet.value;
        if (wallet != null) {
          await fetchWalletByUuid(wallet.uuid);
          await fetchUserWallets(wallet.userId);
        }
      }

      isSaving.value = false;
      return {'success': true, 'body': body};
    } else {
      _showSnackbar('خطأ', body['message'] ?? 'فشل شراء/تجديد الباقات', true);
      isSaving.value = false;
      return {'success': false, 'body': body};
    }
  } catch (e) {
    _showSnackbar('خطأ', 'حدث خطأ أثناء شراء الباقات: $e', true);
    isSaving.value = false;
    return {'success': false, 'error': e.toString()};
  }
}

}

