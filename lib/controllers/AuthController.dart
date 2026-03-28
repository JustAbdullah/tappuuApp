import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart' as userFire;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tappuu_app/views/HomeScreen/home_screen.dart';

import '../core/constant/appcolors.dart';
import '../core/data/model/user.dart' as users;
import '../core/localization/changelanguage.dart';

// reCAPTCHA v3 token cache (مولَّد عبر Mini WebView)
import '../core/recaptcha/recaptcha_token_cache.dart';

// reCAPTCHA v2 فل-سكرين (WebView داخلي)
import '../core/recaptcha/recaptcha_v2_dialog.dart';

import 'BrowsingHistoryController.dart';
import 'FavoritesController.dart';
import 'LoadingController.dart';
import 'ViewsController.dart';

class AuthController extends GetxController {
  // ==================== [Config: v2 Fallback] ====================
  static const String kRecaptchaV2PageUrl =
      'https://testing.arabiagroup.net/recaptcha-v2.html';
  static const String kRecaptchaV2SiteKey =
      '6Lc13QgsAAAAADNKzZDu8yrNDrtQOhJAOpB97mw_';

  // ==================== [Observables] ====================
  RxInt currentStep = 0.obs; // 0 = البريد الإلكتروني, 1 = الكود, 2 = كلمة المرور
  RxBool isLoading = false.obs;
  RxBool codeSent = false.obs;
  RxBool isSendingCode = false.obs;
  RxBool isVerifying = false.obs;
  RxBool isLoggingIn = false.obs;
  final RxBool isPasswordValid = false.obs;
  final RxBool showPassword = false.obs;
  final RxBool canCompleteLater = false.obs;

  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController codeCtrl = TextEditingController();
  final TextEditingController passwordCtrl = TextEditingController();

  final userFire.FirebaseAuth _auth = userFire.FirebaseAuth.instance;
  var user = Rxn<userFire.User>();

  /// جذر مسارات الـ API
  final String baseUrl =
      'https://taapuu.com/api/users';

  // ==================== [v2 Lock & Cache] ====================
  Completer<String?>? _v2Completer;
  String? _v2CachedToken;
  DateTime? _v2CachedAt;

  /// افتح reCAPTCHA v2 كصفحة فل-سكرين مرة واحدة فقط، مع كاش ≈ 110 ثانية
  Future<String?> _getV2Token() async {
    final now = DateTime.now();
    if (_v2CachedToken != null &&
        _v2CachedAt != null &&
        now.difference(_v2CachedAt!).inSeconds < 110) {
      return _v2CachedToken;
    }
    if (_v2Completer != null) return _v2Completer!.future;

    _v2Completer = Completer<String?>();
    try {
      final token = await Get.to<String>(
        () => RecaptchaV2Dialog(
          pageUrl: kRecaptchaV2PageUrl,
          siteKey: kRecaptchaV2SiteKey,
        ),
        transition: Transition.fadeIn,
        duration: const Duration(milliseconds: 120),
      );

      if (token?.isNotEmpty == true) {
        _v2CachedToken = token;
        _v2CachedAt = DateTime.now();
      }
      _v2Completer!.complete(token);
    } catch (_) {
      _v2Completer!.complete(null);
    } finally {
      _v2Completer = null;
    }
    return _v2CachedToken;
  }

  // ==================== [Lifecycle] ====================
  @override
  void onClose() {
    emailCtrl.dispose();
    codeCtrl.dispose();
    passwordCtrl.dispose();
    super.onClose();
  }

  // ==================== [Helpers: reCAPTCHA] ====================
  /// يرفق توكن reCAPTCHA v3 من الكاش (مولّد مسبقاً داخل WebView المصغّر)
  Future<Map<String, dynamic>> _withCaptcha(
    Map<String, dynamic> data,
    String action,
  ) async {
    try {
      // ✅ دائماً نأخذ توكن v3 من الـ Mini WebView الخاص بنفس الـ action
      final token = RecaptchaTokenCache.take();

      if (token != null && token.isNotEmpty) {
        data['recaptcha_token'] = token;
        data['recaptcha_version'] = 'v3';
        data['recaptcha_action'] = action;
        debugPrint('✅ [_withCaptcha] Got v3 token for action=$action');
      } else {
        debugPrint(
            '⚠️ [_withCaptcha] No reCAPTCHA v3 token available for action=$action');
      }
    } catch (e) {
      debugPrint('⚠️ _withCaptcha exception: $e');
    }
    return data;
  }

  Future<Map<String, String>> _jsonHeaders({String? recaptchaVersion}) async {
    final h = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (recaptchaVersion != null) {
      h['X-Recaptcha-Version'] = recaptchaVersion;
    }
    return h;
  }

  bool _isJson(http.Response res) {
    final ct = res.headers['content-type'] ?? '';
    return ct.contains('application/json');
  }

  bool _shouldTriggerV2Fallback(http.Response res, Map<String, dynamic>? body) {
    final msg = (body?['message'] ?? body?['error'] ?? '').toString();
    final status = body?['status']?.toString() ?? '';
    debugPrint(
        '🤖 [_shouldTriggerV2Fallback] statusCode=${res.statusCode}, status=$status, message=$msg');

    // حالة require_v2 الصريحة من الباك اند
    if (status == 'require_v2') return true;

    // 422 غالباً خطأ تحقق reCAPTCHA
    if (res.statusCode == 422) return true;

    // رسائل واضحة من الباك اند
    if (msg.contains('reCAPTCHA') || msg.contains('التحقق')) return true;

    return false;
  }

  /// طباعة تفاصيل أوضح لأي رد من الخادم (لما نكون تايهين فين المشكلة)
  void _logServerError(String ctx, http.Response res,
      [Map<String, dynamic>? body]) {
    try {
      debugPrint('❌ [$ctx] statusCode=${res.statusCode}');
      debugPrint('❌ [$ctx] headers=${res.headers}');
      final raw = res.body;
      final shortBody = raw.length > 2000 ? raw.substring(0, 2000) : raw;
      debugPrint('❌ [$ctx] rawBody=$shortBody');
      if (body != null) {
        debugPrint('❌ [$ctx] body.message=${body['message']}');
        debugPrint('❌ [$ctx] body.error=${body['error']}');
        debugPrint('❌ [$ctx] body.errors=${body['errors']}');
      }
    } catch (e) {
      debugPrint('❌ [$ctx] _logServerError exception: $e');
    }
  }

  // ==================== [Utilities] ====================
  void nextStep() => currentStep.value++;
  void prevStep() => currentStep.value--;

  void validatePassword(String value) {
    isPasswordValid.value = value.length >= 6;
  }

  Future<void> _persistUser(Map<String, dynamic> userMap) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(userMap));
  }

  Future<void> _afterAuthSuccess(users.User u) async {
    final langCode =
        Get.find<ChangeLanguageController>().currentLocale.value.languageCode;

    final loadingCtrl = Get.find<LoadingController>();
    loadingCtrl.currentUser = u;
    loadingCtrl.setUser(u);

    try {
      final viewsController = Get.find<ViewsController>();
      final favoritesController = Get.find<FavoritesController>();
      final browsingHistoryController = Get.find<BrowsingHistoryController>();

      await Future.wait([
        viewsController.fetchViews(userId: u.id ?? 0, perPage: 3, lang: langCode),
        favoritesController.fetchFavorites(
            userId: u.id ?? 0, perPage: 3, lang: langCode),
        browsingHistoryController.fetchRecommendedAds(
            userId: u.id ?? 0, lang: langCode),
      ]);
    } catch (e) {
      debugPrint('Post-auth fetch error (ignored): $e');
    }

    Get.offAll(() => const HomeScreen());
  }

  // ==================== [Google Sign-In - Firebase + API] ====================
  Future<void> signInWithGoogle() async {
    try {
      isLoading(true);

      final provider = userFire.GoogleAuthProvider()
        ..addScope('email')
        ..setCustomParameters({'prompt': 'select_account'});

      userFire.UserCredential userCredential;

      if (kIsWeb) {
        userCredential = await _auth.signInWithPopup(provider);
      } else {
        await _auth.signInWithRedirect(provider);
        final result = await _auth.getRedirectResult();
        userCredential = result;
      }

      final fbUser = userCredential.user;
      if (fbUser?.email != null) {
        user.value = fbUser;
        await _loginOrRegisterWithApi(fbUser!.email!);
      } else {
        Get.snackbar(
          'فشل تسجيل الدخول',
          'لم يتم استرجاع البريد الإلكتروني من Google.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } on userFire.FirebaseAuthException catch (e, st) {
      debugPrint('FirebaseAuthException: ${e.code} – ${e.message}');
      debugPrint('Stack trace:\n$st');
      const errorMessages = {
        'account-exists-with-different-credential':
            'هذا الحساب مُسجل بالفعل بطريقة مختلفة، حاول تسجيل الدخول بطريقة أخرى.',
        'invalid-credential': 'بيانات الدخول غير صحيحة، يرجى المحاولة مرة أخرى.',
        'operation-not-allowed': 'خاصية تسجيل الدخول عبر Google غير مفعلة حالياً.',
        'user-disabled': 'تم تعطيل هذا الحساب، يرجى التواصل مع الدعم.',
        'user-not-found': 'المستخدم غير موجود، تأكد من صحة بياناتك.',
        'popup-closed-by-user': 'تم إغلاق نافذة تسجيل الدخول قبل الإكمال.',
        'popup-blocked': 'تعذر فتح نافذة تسجيل الدخول؛ تحقق من إعدادات المتصفح.',
        'network-request-failed':
            'هناك مشكلة في الاتصال بالإنترنت، تأكد من الشبكة وحاول مرة أخرى.',
      };
      final arabicMessage =
          errorMessages[e.code] ?? 'حدث خطأ في المصادقة (${e.code}).';

      Get.snackbar(
        'خطأ في تسجيل الدخول',
        arabicMessage,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e, st) {
      debugPrint('Unexpected error in signInWithGoogle: $e');
      debugPrint('Stack trace:\n$st');
      Get.snackbar(
        'خطأ غير متوقع',
        'حصل خطأ أثناء العملية، اطلع على الـ logs لمعرفة التفاصيل.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> _loginOrRegisterWithApi(String email) async {
    try {
      final uri = Uri.parse('$baseUrl/google-signin');
      Map<String, dynamic> payload = {'email': email};
      payload = await _withCaptcha(payload, 'google_signin');

      var headers = await _jsonHeaders();
      var res = await http.post(uri, headers: headers, body: jsonEncode(payload));

      debugPrint(
          '🔐 [_loginOrRegisterWithApi] first response: status=${res.statusCode}, body=${res.body}');

      Map<String, dynamic>? body;
      if (_isJson(res)) body = jsonDecode(res.body);

      if (_isJson(res)) {
        if (res.statusCode == 200 && body?['status'] == 'success') {
          final userMap = body!['user'] as Map<String, dynamic>;
          await _persistUser(userMap);
          final u = users.User.fromJson(userMap);
          await _afterAuthSuccess(u);
          Get.snackbar(
            'نجاح',
            body['message'] ?? 'تم تسجيل الدخول بنجاح',
            snackPosition: SnackPosition.BOTTOM,
          );
        } else if (_shouldTriggerV2Fallback(res, body)) {
          final v2 = await _getV2Token();
          if (v2 != null && v2.isNotEmpty) {
            // ✅ أرسل v2 في الحقل الصحيح
            payload['recaptcha_v2_token'] = v2;
            payload['recaptcha_token'] =
                payload['recaptcha_token'] ?? 'dummy_v3';

            headers = await _jsonHeaders(recaptchaVersion: 'v2');
            res = await http.post(
              uri,
              headers: headers,
              body: jsonEncode(payload),
            );
            debugPrint(
                '🔐 [_loginOrRegisterWithApi][v2] response: status=${res.statusCode}, body=${res.body}');

            if (_isJson(res)) body = jsonDecode(res.body);

            if (res.statusCode == 200 && body?['status'] == 'success') {
              final userMap = body!['user'] as Map<String, dynamic>;
              await _persistUser(userMap);
              final u = users.User.fromJson(userMap);
              await _afterAuthSuccess(u);
              Get.snackbar(
                'نجاح',
                body['message'] ?? 'تم تسجيل الدخول بنجاح',
                snackPosition: SnackPosition.BOTTOM,
              );
              return;
            }
          }
          _logServerError('_loginOrRegisterWithApi[v2-fallback]', res, body);
          Get.snackbar(
            'خطأ',
            body?['message'] ?? 'فشل reCAPTCHA.',
            snackPosition: SnackPosition.BOTTOM,
          );
        } else {
          _logServerError('_loginOrRegisterWithApi[server-error]', res, body);
          Get.snackbar(
            'خطأ في الخادم',
            body?['message'] ?? 'تعذر إنشاء الحساب.',
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      } else {
        debugPrint(
            '⚠️ [_loginOrRegisterWithApi] non-JSON response. status=${res.statusCode}, body=${res.body}');
        Get.snackbar(
          'خطأ في الخادم',
          'استجابة غير متوقعة من السيرفر.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      debugPrint('API error: $e');
      Get.snackbar(
        'خطأ في الاتصال',
        'تعذر التواصل مع الخادم، تحقق من الإنترنت.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // ==================== [Sign out] ====================
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (_) {}
    user.value = null;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user');
    } catch (_) {}

    try {
      Get.find<LoadingController>().logout();
    } catch (_) {}

    Get.offAll(() => const HomeScreen());
  }

  // ==================== [API Functions] ====================

  /// إرسال كود التحقق (تسجيل/استعادة) مع reCAPTCHA v3 + v2 fallback "حقيقي"
  Future<Map<String, dynamic>> sendVerificationCodeApi({int force = 0}) async {
    isSendingCode(true);
    try {
      final uri = Uri.parse('$baseUrl/send-code');
      Map<String, dynamic> payload = {
        'email': emailCtrl.text.trim(),
        'force': force,
      };
      payload = await _withCaptcha(payload, 'signup_email');

      var headers = await _jsonHeaders();
      var res = await http.post(uri, headers: headers, body: jsonEncode(payload));

      debugPrint(
          '🔐 [sendVerificationCodeApi] first response: status=${res.statusCode}, body=${res.body}');

      Map<String, dynamic>? body;
      if (_isJson(res)) body = jsonDecode(res.body);

      if (_isJson(res)) {
        // ✅ أولاً: لو الباك اند طلب v2 (status=require_v2 أو 422) نروح للفولباك
        if (_shouldTriggerV2Fallback(res, body)) {
          final v2 = await _getV2Token();
          if (v2 == null || v2.isEmpty) {
            _logServerError('sendVerificationCodeApi[v2-missing]', res, body);
            return {
              'statusCode': 0,
              'message': 'لم يتم الحصول على توكن reCAPTCHA v2 من الواجهة.',
              'body': body,
            };
          }

          // نحط توكن v2 + نضمن وجود recaptcha_token (حتى لو dummy)
          payload['recaptcha_v2_token'] = v2;
          payload['recaptcha_token'] =
              payload['recaptcha_token'] ?? 'dummy_v3';

          headers = await _jsonHeaders(recaptchaVersion: 'v2');
          res = await http.post(
            uri,
            headers: headers,
            body: jsonEncode(payload),
          );

          debugPrint(
              '🔐 [sendVerificationCodeApi][v2] response: status=${res.statusCode}, body=${res.body}');

          if (_isJson(res)) body = jsonDecode(res.body);

          // نجاح حقيقي بعد v2
          if (res.statusCode == 200 &&
              (body?['status'] == 'success' || body?['status'] == true)) {
            return {
              'statusCode': 200,
              'message': body!['message'] ?? 'تم الإرسال',
              'body': body,
            };
          }

          // فشل بعد v2
          _logServerError('sendVerificationCodeApi[v2-fail]', res, body);
          return {
            'statusCode': res.statusCode,
            'message': body?['message'] ??
                body?['error'] ??
                'فشل في إرسال كود التحقق بعد التحقق اليدوي.',
            'body': body,
          };
        }

        // ✅ حالة نجاح طبيعي مع v3 فقط
        if (res.statusCode == 200 &&
            (body?['status'] == 'success' || body?['status'] == true)) {
          return {
            'statusCode': 200,
            'message': body!['message'] ?? 'تم الإرسال',
            'body': body,
          };
        }

        // ❌ أي حالة JSON ثانية تعتبر خطأ
        _logServerError('sendVerificationCodeApi[fail]', res, body);
        return {
          'statusCode': res.statusCode,
          'message': body?['message'] ??
              body?['error'] ??
              'خطأ غير متوقع في إرسال كود التحقق',
          'body': body,
        };
      } else {
        debugPrint(
            '⚠️ send-code returned non-JSON. Status ${res.statusCode}, body=${res.body}');
        return {
          'statusCode': res.statusCode,
          'message': 'استجابة غير متوقعة من السيرفر. ربما HTML؟',
          'body': res.body,
        };
      }
    } catch (e, stackTrace) {
      debugPrint('❌ فشل في الاتصال بالخادم (sendVerificationCodeApi): $e');
      debugPrint('StackTrace: $stackTrace');
      return {
        'statusCode': 0,
        'message': 'فشل في الاتصال بالخادم: ${e.toString()}',
      };
    } finally {
      isSendingCode(false);
    }
  }

  Future<Map<String, dynamic>> verifyCodeApi() async {
    isVerifying(true);
    try {
      final uri = Uri.parse('$baseUrl/verify-code');
      final Map<String, dynamic> payload = {
        'email': emailCtrl.text.trim(),
        'code': codeCtrl.text.trim()
      };

      final headers = await _jsonHeaders();
      final res = await http.post(uri, headers: headers, body: jsonEncode(payload));

      if (!_isJson(res)) {
        debugPrint(
            '⚠️ verify-code returned non-JSON. Status ${res.statusCode}, body=${res.body}');
        return {'status': false, 'message': 'استجابة غير JSON من الخادم'};
      }

      final body = jsonDecode(res.body);
      final bool success =
          (res.statusCode == 200 && body['status'] == 'success');
      if (!success) {
        _logServerError('verifyCodeApi[fail]', res, body);
      }
      return {
        'status': success,
        'message': body['message'] ?? 'فشل في التحقق',
      };
    } catch (e) {
      debugPrint('❌ verifyCodeApi exception: $e');
      return {'status': false, 'message': 'فشل في الاتصال'};
    } finally {
      isVerifying(false);
    }
  }

  Future<Map<String, dynamic>> completeRegistration() async {
    try {
      final uri = Uri.parse('$baseUrl/complete-signup');
      Map<String, dynamic> payload = {
        'email': emailCtrl.text.trim(),
        'code': codeCtrl.text.trim(),
        'password': passwordCtrl.text.trim(),
      };

      debugPrint('🔄 [completeRegistration] Preparing reCAPTCHA for signup_complete...');

      // ✅ دائماً نستخدم reCAPTCHA v3 الخاص بـ signup_complete من الـ Mini WebView
      payload = await _withCaptcha(payload, 'signup_complete');

      var headers = await _jsonHeaders();
      var res = await http.post(uri, headers: headers, body: jsonEncode(payload));

      debugPrint(
          '🔐 [completeRegistration] first response: status=${res.statusCode}, body=${res.body}');

      Map<String, dynamic>? body;
      if (_isJson(res)) body = jsonDecode(res.body);

      if (_isJson(res)) {
        // ✅ نجاح عادي (v3 فقط)
        if (body?['status'] == true) {
          final userMap = (body!['user'] as Map<String, dynamic>);
          await _persistUser(userMap);
          final u = users.User.fromJson(userMap);
          Get.find<LoadingController>().currentUser = u;
          Get.find<LoadingController>().setUser(u);
          return {
            'status': true,
            'message': body['message'] ?? 'تم',
            'user': body['user'],
          };
        }

        // ✅ لو الباك إند قال: لازم v2 (require_v2 / 422 / رسالة عن التحقق)
        else if (_shouldTriggerV2Fallback(res, body)) {
          debugPrint(
              '⚠️ [completeRegistration] Server requested v2 fallback for signup_complete');

          // ❗️ مهم جداً: لا نعيد استخدام توكن v2 القديم الخاص بخطوة الإيميل
          _v2CachedToken = null;
          _v2CachedAt = null;

          final v2 = await _getV2Token();
          if (v2 != null && v2.isNotEmpty) {
            payload['recaptcha_v2_token'] = v2;
            // نتأكد أن فيه recaptcha_token (حتى لو dummy)
            payload['recaptcha_token'] =
                (payload['recaptcha_token'] ?? 'dummy_v3');

            headers = await _jsonHeaders(recaptchaVersion: 'v2');
            res = await http.post(
              uri,
              headers: headers,
              body: jsonEncode(payload),
            );

            debugPrint(
                '🔐 [completeRegistration][v2] response: status=${res.statusCode}, body=${res.body}');

            if (_isJson(res)) body = jsonDecode(res.body);
            if (body?['status'] == true) {
              final userMap = (body!['user'] as Map<String, dynamic>);
              await _persistUser(userMap);
              final u = users.User.fromJson(userMap);
              Get.find<LoadingController>().currentUser = u;
              Get.find<LoadingController>().setUser(u);
              return {
                'status': true,
                'message': body['message'] ?? 'تم',
                'user': body['user'],
              };
            }
          }
          _logServerError('completeRegistration[v2-fallback]', res, body);
          return {
            'status': false,
            'message':
                body?['message'] ?? 'فشل التحقق البشري في خطوة إكمال التسجيل',
          };
        }

        _logServerError('completeRegistration[fail]', res, body);
        return {
          'status': false,
          'message': body?['message'] ?? 'استجابة غير صالحة من السيرفر',
        };
      } else {
        debugPrint(
            '⚠️ complete-signup returned non-JSON. Status ${res.statusCode}, body=${res.body}');
        return {'status': false, 'message': 'استجابة غير JSON من الخادم'};
      }
    } catch (e) {
      debugPrint('❌ completeRegistration exception: $e');
      return {'status': false, 'message': 'فشل في الاتصال'};
    }
  }

  /// ===================[loginApi مع v2 fullscreen fallback]===================
  Future<Map<String, dynamic>> loginApi() async {
    isLoggingIn(true);
    try {
      final uri = Uri.parse('$baseUrl/login');
      Map<String, dynamic> payload = {
        'email': emailCtrl.text.trim(),
        'password': passwordCtrl.text.trim(),
      };
      payload = await _withCaptcha(payload, 'login');

      // 👇 التحقق هل عندنا توكن v3 أساساً أو لا
      final String v3Token =
          (payload['recaptcha_token'] ?? '').toString().trim();
      final bool hasV3 = v3Token.isNotEmpty;

      // ==================== حالة: مافيه توكن v3 → نروح مباشرةً لـ v2 ====================
      if (!hasV3) {
        debugPrint(
            '⚠️ [loginApi] No v3 token in payload → going DIRECTLY to reCAPTCHA v2');

        final v2 = await _getV2Token();
        if (v2 == null || v2.isEmpty) {
          debugPrint(
              '❌ [loginApi] reCAPTCHA v2 dialog did not return a token.');
          return {
            'status': false,
            'message': 'لم يتم الحصول على توكن reCAPTCHA v2 من الواجهة.',
          };
        }

        // نحط توكن v2 في الـ payload ونميز الهيدر
        payload['recaptcha_v2_token'] = v2;
        payload['recaptcha_token'] = v3Token.isNotEmpty ? v3Token : 'dummy_v3';

        var headers = await _jsonHeaders(recaptchaVersion: 'v2');
        final res = await http.post(
          uri,
          headers: headers,
          body: jsonEncode(payload),
        );

        debugPrint(
            '🔐 [loginApi][direct-v2] response: status=${res.statusCode}, body=${res.body}');

        if (!_isJson(res)) {
          final snippet =
              res.body.length > 2000 ? res.body.substring(0, 2000) : res.body;
          debugPrint(
              '⚠️ Non-JSON from server (login direct-v2). Status ${res.statusCode}, body=$snippet');
          return {
            'status': false,
            'message': 'خطأ من الخادم (ليست JSON). افحص اللوج.',
          };
        }

        final body = jsonDecode(res.body);

        if (res.statusCode == 200 &&
            (body['status'] == 'success' || body['status'] == true)) {
          final userMap = (body['user'] as Map<String, dynamic>);
          await _persistUser(userMap);

          final u = users.User.fromJson(userMap);
          await _afterAuthSuccess(u);

          return {
            'status': true,
            'message': body['message'] ?? 'تم تسجيل الدخول بنجاح',
            'user': body['user'],
          };
        }

        _logServerError('loginApi[direct-v2-fail]', res, body);
        return {
          'status': false,
          'message': body['message'] ??
              body['error'] ??
              'فشل في reCAPTCHA (login direct-v2).',
        };
      }

      // ==================== حالة: عندنا توكن v3 → جرّب عادي ثم فولباك v2 ====================
      var headers = await _jsonHeaders();
      var res = await http.post(uri, headers: headers, body: jsonEncode(payload));

      debugPrint(
          '🔐 [loginApi] first response: status=${res.statusCode}, body=${res.body}');

      Map<String, dynamic>? body;
      if (_isJson(res)) body = jsonDecode(res.body);

      if (_isJson(res)) {
        // ✅ نجاح v3 مباشرة
        if (res.statusCode == 200 &&
            (body?['status'] == 'success' || body?['status'] == true)) {
          final userMap = (body!['user'] as Map<String, dynamic>);
          await _persistUser(userMap);

          final u = users.User.fromJson(userMap);
          await _afterAuthSuccess(u);

          return {
            'status': true,
            'message': body['message'] ?? 'تم تسجيل الدخول بنجاح',
            'user': body['user'],
          };
        }

        // ✅ حالة require_v2 أو فشل reCAPTCHA → نروح للفولباك v2
        else if (_shouldTriggerV2Fallback(res, body)) {
          final v2 = await _getV2Token();
          if (v2 != null && v2.isNotEmpty) {
            payload['recaptcha_v2_token'] = v2;
            payload['recaptcha_token'] =
                payload['recaptcha_token'] ?? 'dummy_v3';

            headers = await _jsonHeaders(recaptchaVersion: 'v2');
            res = await http.post(
              uri,
              headers: headers,
              body: jsonEncode(payload),
            );

            debugPrint(
                '🔐 [loginApi][v2] response: status=${res.statusCode}, body=${res.body}');

            if (_isJson(res)) body = jsonDecode(res.body);

            if (res.statusCode == 200 &&
                (body?['status'] == 'success' || body?['status'] == true)) {
              final userMap = (body!['user'] as Map<String, dynamic>);
              await _persistUser(userMap);

              final u = users.User.fromJson(userMap);
              await _afterAuthSuccess(u);

              return {
                'status': true,
                'message': body['message'] ?? 'تم تسجيل الدخول',
                'user': body['user'],
              };
            }

            // فشل بعد v2
            _logServerError('loginApi[v2-fallback-fail]', res, body);
            return {
              'status': false,
              'message': body?['message'] ??
                  body?['error'] ??
                  'فشل في reCAPTCHA (v2 fallback).',
            };
          }

          // ما قدرنا نجيب توكن v2 (المستخدم قفل النافذة مثلاً)
          return {
            'status': false,
            'message': 'لم يتم الحصول على توكن reCAPTCHA v2 من الواجهة.',
          };
        }

        // ❌ أي فشل آخر (بريد/كلمة مرور أو خطأ من الباك اند)
        else {
          debugPrint(
              '❌ [loginApi] logical failure. statusCode=${res.statusCode}, body=$body');
          _logServerError('loginApi[logic-fail]', res, body);
          return {
            'status': false,
            'message': body?['message'] ??
                'فشل في تسجيل الدخول (تحقق من البريد/كلمة المرور)',
          };
        }
      } else {
        final snippet =
            res.body.length > 2000 ? res.body.substring(0, 2000) : res.body;
        debugPrint(
            '⚠️ Non-JSON from server (login). Status ${res.statusCode}, body=$snippet');
        return {
          'status': false,
          'message': 'خطأ من الخادم (ليست JSON). افحص اللوج.',
        };
      }
    } catch (e) {
      debugPrint('❌ [loginApi] exception: $e');
      return {
        'status': false,
        'message': 'فشل في الاتصال بالخادم (loginApi)',
      };
    } finally {
      isLoggingIn(false);
    }
  }

  /// =======================================================

  Future<Map<String, dynamic>> googleSignInApi(String email) async {
    isLoading(true);
    try {
      final uri = Uri.parse('$baseUrl/google-signin');
      Map<String, dynamic> payload = {'email': email};
      payload = await _withCaptcha(payload, 'google_signin');

      var headers = await _jsonHeaders();
      var res = await http.post(uri, headers: headers, body: jsonEncode(payload));

      debugPrint(
          '🔐 [googleSignInApi] first response: status=${res.statusCode}, body=${res.body}');

      Map<String, dynamic>? body;
      if (_isJson(res)) body = jsonDecode(res.body);

      if (_isJson(res)) {
        if (res.statusCode == 200 && body?['status'] == 'success') {
          final userMap = body!['user'] as Map<String, dynamic>;

          await _persistUser(userMap);

          final u = users.User.fromJson(userMap);
          await _afterAuthSuccess(u);

          return {
            'status': true,
            'message': body['message'] ?? 'تم تسجيل الدخول بنجاح',
            'user': userMap,
            'isNewUser':
                (body['message']?.toString().contains('إنشاء') ?? false),
          };
        } else if (_shouldTriggerV2Fallback(res, body)) {
          final v2 = await _getV2Token();
          if (v2 != null && v2.isNotEmpty) {
            payload['recaptcha_v2_token'] = v2;
            payload['recaptcha_token'] =
                payload['recaptcha_token'] ?? 'dummy_v3';

            headers = await _jsonHeaders(recaptchaVersion: 'v2');
            res = await http.post(
              uri,
              headers: headers,
              body: jsonEncode(payload),
            );

            debugPrint(
                '🔐 [googleSignInApi][v2] response: status=${res.statusCode}, body=${res.body}');

            if (_isJson(res)) body = jsonDecode(res.body);
            if (res.statusCode == 200 && body?['status'] == 'success') {
              final userMap = body!['user'] as Map<String, dynamic>;
              await _persistUser(userMap);
              final u = users.User.fromJson(userMap);
              await _afterAuthSuccess(u);
              return {
                'status': true,
                'message': body['message'] ?? 'تم تسجيل الدخول بنجاح',
                'user': userMap,
                'isNewUser':
                    (body['message']?.toString().contains('إنشاء') ?? false),
              };
            }
          }
          _logServerError('googleSignInApi[v2-fallback]', res, body);
          return {
            'status': false,
            'message': body?['message'] ?? 'فشل reCAPTCHA في Google Sign-in',
          };
        } else {
          _logServerError('googleSignInApi[server-error]', res, body);
          return {
            'status': false,
            'message':
                body?['message'] ?? 'فشل تسجيل الدخول عبر Google (من الخادم)',
          };
        }
      } else {
        debugPrint(
            '⚠️ google-signin returned non-JSON. Status ${res.statusCode}, body=${res.body}');
        return {
          'status': false,
          'message': 'استجابة غير JSON من الخادم في Google Sign-in',
        };
      }
    } catch (e) {
      debugPrint('❌ [googleSignInApi] exception: $e');
      return {
        'status': false,
        'message': 'فشل في الاتصال بالخادم أثناء Google Sign-in',
      };
    } finally {
      isLoading(false);
    }
  }

  Future<Map<String, dynamic>> resetGooglePasswordApi({
    required String email,
    required String code,
    required String password,
  }) async {
    isLoading(true);
    try {
      final uri = Uri.parse('$baseUrl/reset-google-password');
      Map<String, dynamic> payload = {
        'email': email,
        'code': code,
        'password': password,
      };
      payload = await _withCaptcha(payload, 'reset_google_password');

      var headers = await _jsonHeaders();
      var res = await http.post(uri, headers: headers, body: jsonEncode(payload));

      debugPrint(
          '🔐 [resetGooglePasswordApi] first response: status=${res.statusCode}, body=${res.body}');

      Map<String, dynamic>? body;
      if (_isJson(res)) body = jsonDecode(res.body);

      if (_isJson(res)) {
        final bool success =
            (res.statusCode == 200 && body?['status'] == 'success');
        if (success) {
          return {
            'status': true,
            'message': body!['message'] ?? 'تم التحديث بنجاح',
            'details': body.toString(),
          };
        } else if (_shouldTriggerV2Fallback(res, body)) {
          final v2 = await _getV2Token();
          if (v2 != null && v2.isNotEmpty) {
            payload['recaptcha_v2_token'] = v2;
            payload['recaptcha_token'] =
                payload['recaptcha_token'] ?? 'dummy_v3';

            headers = await _jsonHeaders(recaptchaVersion: 'v2');
            res = await http.post(
              uri,
              headers: headers,
              body: jsonEncode(payload),
            );

            debugPrint(
                '🔐 [resetGooglePasswordApi][v2] response: status=${res.statusCode}, body=${res.body}');

            if (_isJson(res)) body = jsonDecode(res.body);
            final bool ok =
                (res.statusCode == 200 && body?['status'] == 'success');
            if (!ok) {
              _logServerError('resetGooglePasswordApi[v2-fail]', res, body);
            }
            return {
              'status': ok,
              'message': body?['message'] ??
                  (ok ? 'تم التحديث' : 'فشل في التحديث'),
              'details': body.toString(),
            };
          }
          _logServerError('resetGooglePasswordApi[v2-missing]', res, body);
          return {
            'status': false,
            'message': body?['message'] ?? 'فشل reCAPTCHA في reset-password',
          };
        } else {
          _logServerError('resetGooglePasswordApi[server-error]', res, body);
          return {
            'status': false,
            'message': body?['message'] ?? 'فشل في التحديث (reset-password)',
          };
        }
      } else {
        debugPrint(
            '⚠️ reset-google-password returned non-JSON. Status ${res.statusCode}, body=${res.body}');
        return {
          'status': false,
          'message': 'استجابة غير JSON من الخادم في reset-password',
        };
      }
    } catch (e, stack) {
      debugPrint('❌ [reset-google-password] Exception: $e');
      debugPrint('❌ Stack trace: $stack');
      return {
        'status': false,
        'message': 'فشل في الاتصال بالخادم',
        'error': e.toString(),
        'stack': stack.toString(),
      };
    } finally {
      isLoading(false);
    }
  }

  // ==================== [UI Facade] ====================

  /// دالة قديمة (لو في شاشات قديمة لسه تستدعيها)
  /// الآن فقط نرسل الكود بدون أي تحقق إضافي من الإيميل
  void sendVerificationCode() async {
    final email = emailCtrl.text.trim();
    emailCtrl.text = email;

    debugPrint('📧 [sendVerificationCode] email="$email" len=${email.length}');

    isLoading.value = true;
    final result = await sendVerificationCodeApi();
    isLoading.value = false;

    debugPrint(
        '📧 [sendVerificationCode] result statusCode=${result['statusCode']}, message=${result['message']}');

    if (result['statusCode'] == 200) {
      currentStep.value = 1;
      codeSent.value = true;
      _showSuccessSnackbar('تم الإرسال!', 'تم إرسال رمز التحقق إلى بريدك');
    } else {
      _showErrorSnackbar('خطأ', result['message']);
    }
  }

  void verifyCode() async {
    if (codeCtrl.text.isEmpty || codeCtrl.text.length != 6) {
      _showErrorSnackbar(
          'رمز غير صالح', 'يرجى إدخال رمز التحقق المكون من 6 أرقام');
      return;
    }

    isLoading.value = true;
    final result = await verifyCodeApi();
    isLoading.value = false;

    if (result['status'] == true) {
      currentStep.value = 2;
    } else {
      _showErrorSnackbar('خطأ', result['message']);
    }
  }

  void resendCode() {
    _showSuccessSnackbar('تم الإرسال!', 'تم إعادة إرسال رمز التحقق إلى بريدك');
  }

  Future<Map<String, dynamic>> resetGooglePassword({
    required String email,
    required String code,
    required String password,
  }) async {
    isLoading(true);
    try {
      final result = await resetGooglePasswordApi(
        email: email,
        code: code,
        password: password,
      );
      return result;
    } finally {
      isLoading(false);
    }
  }

  // ==================== [Helpers] ====================
  void _showErrorSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.error.withOpacity(0.2),
      colorText: AppColors.error,
    );
  }

  void _showSuccessSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.success.withOpacity(0.2),
      colorText: AppColors.success,
    );
  }

  // ------ جلب بيانات المستخدم للتحديث ------
  Future<Map<String, dynamic>> fetchUserDataApi(int userId) async {
    isLoading(true);
    try {
      final uri = Uri.parse('$baseUrl/user-update/$userId');
      final headers = await _jsonHeaders();

      final res = await http.get(uri, headers: headers);

      final contentType = res.headers['content-type'] ?? '';
      if (!contentType.contains('application/json')) {
        debugPrint(
            '⚠️ user-update returned non-JSON. Status ${res.statusCode}, body=${res.body}');
        return {
          'status': false,
          'message': 'استجابة غير JSON من الخادم',
        };
      }

      final Map<String, dynamic> body = jsonDecode(res.body);
      if (res.statusCode == 200 && body['status'] == 'success') {
        final userMap = body['user'] as Map<String, dynamic>;
        final updatedUser = users.User.fromJson(userMap);

        await _persistUser(userMap);
        Get.find<LoadingController>().currentUser = updatedUser;

        debugPrint("تم تحديث بيانات المستخدم");
        return {
          'status': true,
          'user': updatedUser,
          'freePostsExhausted':
              (body['free_posts_exhausted'] as bool?) ?? false,
          'accountStatus': (body['account_status'] as String?) ?? '',
        };
      } else {
        debugPrint("فشل تحديث بيانات المستخدم: ${body['message']}");
        return {
          'status': false,
          'message': body['message'] ?? 'فشل في جلب بيانات المستخدم',
        };
      }
    } catch (e) {
      debugPrint("استثناء أثناء تحديث بيانات المستخدم: $e");
      return {'status': false, 'message': 'فشل في الاتصال بالخادم'};
    } finally {
      isLoading(false);
    }
  }

  // ------ نوع الحساب ------
  void checkAccountType() {
    final currentUser = Get.find<LoadingController>().currentUser;
    if (currentUser == null) return;

    if (currentUser.signup_method == "email") {
      // حساب عادي
    } else {
      // حساب جوجل
      Get.toNamed('/reset-google-password');
    }
  }

  // ------ إرسال أكواد (تسجيل / استعادة) مخصصة للشاشات الجديدة ------

  /// إرسال كود للتحقق عند إنشاء حساب جديد
  void sendVerificationCodeForSignup() async {
    final email = emailCtrl.text.trim();
    emailCtrl.text = email;

    debugPrint(
        '📧 [sendVerificationCodeForSignup] email="$email" len=${email.length}');

    // لا يوجد أي تحقق من صحة البريد هنا، التحقق يتم فقط في الـ Form

    isLoading(true);
    final result = await sendVerificationCodeApi(force: 0);
    isLoading(false);

    debugPrint(
        '📧 [sendVerificationCodeForSignup] result statusCode=${result['statusCode']}, message=${result['message']}');

    if (result['statusCode'] == 200) {
      currentStep.value = 1;
      codeSent.value = true;
      _showSuccessSnackbar('تم الإرسال!', 'تم إرسال رمز التحقق إلى بريدك');
    } else {
      _showErrorSnackbar('خطأ', result['message']);
    }
  }

  /// إرسال كود لاستعادة كلمة المرور
  void sendVerificationCodeForReset() async {
    final email = emailCtrl.text.trim();
    emailCtrl.text = email;

    debugPrint(
        '📧 [sendVerificationCodeForReset] email="$email" len=${email.length}');

    // لا يوجد أي تحقق من صحة البريد هنا، التحقق يتم فقط في شاشة الاستعادة نفسها

    isLoading(true);
    final result = await sendVerificationCodeApi(force: 1);
    isLoading(false);

    debugPrint(
        '📧 [sendVerificationCodeForReset] result statusCode=${result['statusCode']}, message=${result['message']}');

    if (result['statusCode'] == 200) {
      currentStep.value = 1;
      codeSent.value = true;
      _showSuccessSnackbar(
          'تم الإرسال!', 'تم إرسال رمز التحقق إلى بريدك');
    } else {
      _showErrorSnackbar('خطأ', result['message']);
    }
  }

  // ------ حذف المستخدم ------
  Future<void> deleteUser(int id) async {
    try {
      final uri = Uri.parse('$baseUrl/$id');
      final headers = await _jsonHeaders();

      final response = await http.delete(uri, headers: headers);

      if (response.statusCode == 200) {
        _showSnackbar('نجاح', 'تم حذف المستخدم #$id بنجاح.', false);
        try {
          Get.find<LoadingController>().logout();
        } catch (_) {}
      } else if (response.statusCode == 404) {
        _showSnackbar('خطأ', 'المستخدم #$id غير موجود.', true);
      } else {
        _showSnackbar(
          'خطأ',
          'فشل في حذف المستخدم. رمز الحالة: ${response.statusCode}\n${response.body}',
          true,
        );
      }
    } catch (e) {
      _showSnackbar('استثناء', 'حدث خطأ أثناء الحذف: $e', true);
    }
  }

  void _showSnackbar(String title, String message, bool isError) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: isError ? Colors.redAccent : Colors.green,
      colorText: Colors.white,
      borderRadius: 10,
      margin: const EdgeInsets.all(15),
      duration: Duration(seconds: isError ? 4 : 3),
      icon: Icon(
        isError ? Icons.error_outline : Icons.check_circle,
        color: Colors.white,
      ),
      shouldIconPulse: true,
      dismissDirection: DismissDirection.horizontal,
    );
  }

  // ✅ دالة مساعدة: تنظيف التوكنات المخزنة (للاستخدام عند بدء عملية جديدة)
  void clearStoredTokens() {
    _v2CachedToken = null;
    _v2CachedAt = null;
    debugPrint('🧹 [clearStoredTokens] All tokens cleared');
  }
}
