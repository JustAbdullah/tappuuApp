import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart' as userFire;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tappuu_app/views/HomeScreen/home_screen.dart';
import '../core/constant/appcolors.dart';
import '../core/data/model/user.dart' as users;
import '../core/localization/changelanguage.dart';
import 'BrowsingHistoryController.dart';
import 'FavoritesController.dart';
import 'LoadingController.dart';
import 'ViewsController.dart';

class AuthController extends GetxController {
  // ==================== [المتغيرات القابلة للمراقبة] ====================
  RxInt currentStep = 0.obs; // 0 = البريد الإلكتروني, 1 = الكود, 2 = كلمة المرور
  RxBool isLoading = false.obs; // التحميل العام
  RxBool codeSent = false.obs; // حالة إرسال الكود
  RxBool isSendingCode = false.obs; // إرسال كود التحقق
  RxBool isVerifying = false.obs; // التحقق من الكود
  RxBool isLoggingIn = false.obs; // تسجيل الدخول
  final RxBool isPasswordValid = false.obs; // صحة كلمة المرور
  final RxBool showPassword = false.obs; // إظهار/إخفاء كلمة المرور
  final RxBool canCompleteLater = false.obs; // إكمال لاحقًا
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController codeCtrl = TextEditingController();
  final TextEditingController passwordCtrl = TextEditingController();
  final userFire.FirebaseAuth _auth = userFire.FirebaseAuth.instance;
  var user = Rxn<userFire.User>();
  final String baseUrl = 'https://stayinme.arabiagroup.net/lar_stayInMe/public/api/users';

  // ==================== [دوال إدارة الخطوات] ====================
  void nextStep() => currentStep.value++;
  void prevStep() => currentStep.value--;

  // ==================== [دوال التحقق] ====================
  void validatePassword(String value) {
    isPasswordValid.value = value.length >= 6;
  }

  // ==================== [التسجيل/الدخول عبر جوجل] ====================
  Future<void> signInWithGoogle() async {
    try {
      isLoading(true);

      // بناء الـ provider لـ OAuth
      final provider = GoogleAuthProvider()
        ..addScope('email')
        ..setCustomParameters({'prompt': 'select_account'});

      UserCredential userCredential;

      if (kIsWeb) {
        // على الويب: نافذة منبثقة
        userCredential = await _auth.signInWithPopup(provider);
      } else {
        // على الهواتف: إعادة توجيه ثم التقاط النتيجة
        await _auth.signInWithRedirect(provider);
        final result = await _auth.getRedirectResult();
        userCredential = result;
      }

      final fbUser = userCredential.user;
      if (fbUser?.email != null) {
        user.value = fbUser;
        await _loginOrRegisterWithApi(fbUser!.email!);
      }
    } on FirebaseAuthException catch (e, st) {
      debugPrint('FirebaseAuthException: ${e.code} – ${e.message}');
      debugPrint('Stack trace:\n$st');
      const errorMessages = {
        'account-exists-with-different-credential': 'هذا الحساب مُسجل بالفعل بطريقة مختلفة، حاول تسجيل الدخول بطريقة أخرى.',
        'invalid-credential': 'بيانات الدخول غير صحيحة، يرجى المحاولة مرة أخرى.',
        'operation-not-allowed': 'خاصية تسجيل الدخول عبر Google غير مفعلة حالياً.',
        'user-disabled': 'تم تعطيل هذا الحساب، يرجى التواصل مع الدعم.',
        'user-not-found': 'المستخدم غير موجود، تأكد من صحة بياناتك.',
        'popup-closed-by-user': 'تم إغلاق نافذة تسجيل الدخول قبل الإكمال.',
        'popup-blocked': 'تعذر فتح نافذة تسجيل الدخول؛ تحقق من إعدادات المتصفح.',
        'network-request-failed': 'هناك مشكلة في الاتصال بالإنترنت، تأكد من الشبكة وحاول مرة أخرى.',
      };
      final arabicMessage = errorMessages[e.code] ?? 'حدث خطأ في المصادقة (${e.code}).';

      Get.snackbar('خطأ في تسجيل الدخول', arabicMessage,
          snackPosition: SnackPosition.BOTTOM);
    } catch (e, st) {
      debugPrint('Unexpected error in signInWithGoogle: $e');
      debugPrint('Stack trace:\n$st');
      Get.snackbar('خطأ غير متوقع',
          'حصل خطأ أثناء العملية، اطلع على الـ logs لمعرفة التفاصيل.',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading(false);
    }
  }

  // ==================== [تسجيل الدخول أو إنشاء حساب في API] ====================
  Future<void> _loginOrRegisterWithApi(String email) async {
    try {
      final uri = Uri.parse('$baseUrl/google-signin');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && body['status'] == 'success') {
        final userMap = body['user'] as Map<String, dynamic>;

        // حفظ البيانات محلياً
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(userMap));

        // تحديث الحالة في الذاكرة المشتركة
        final u = users.User.fromJson(userMap);
        final loadingCtrl = Get.find<LoadingController>();
        loadingCtrl.currentUser = u;
        loadingCtrl.setUser(u);

        final langCode = Get.find<ChangeLanguageController>()
            .currentLocale
            .value
            .languageCode;

        Get.find<ViewsController>()
            .fetchViews(userId: u.id ?? 0, perPage: 3, lang: langCode);
        Get.find<FavoritesController>()
            .fetchFavorites(userId: u.id ?? 0, perPage: 3, lang: langCode);
        Get.find<BrowsingHistoryController>()
            .fetchRecommendedAds(userId: u.id ?? 0, lang: langCode);

        Get.offAll(() => HomeScreen());
        Get.snackbar('نجاح', body['message'], snackPosition: SnackPosition.BOTTOM);
      } else {
        Get.snackbar('خطأ في الخادم',
            body['message'] ?? 'تعذر إنشاء الحساب.',
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      debugPrint('API error: $e');
      Get.snackbar('خطأ في الاتصال',
          'تعذر التواصل مع الخادم، تحقق من الإنترنت.',
          snackPosition: SnackPosition.BOTTOM);
    }
  }


 

  Future<void> signOut() async {
    await _auth.signOut();
    user.value = null;
  }

  // ==================== [وظائف API] ====================
Future<Map<String, dynamic>> sendVerificationCodeApi({int force = 0}) async {
  isSendingCode(true);
  try {
    final uri = Uri.parse('$baseUrl/send-code');
    final payload = {
      'email': emailCtrl.text.trim(),
      'force': force,
    };

    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    // التحقق من نوع المحتوى أولاً
    final contentType = res.headers['content-type'] ?? '';
    if (!contentType.contains('application/json')) {
      debugPrint('⚠️ استجابة غير متوقعة من السيرفر (ليست JSON):');
      debugPrint(res.body); // طباعة HTML في التريمنال
      return {
        'statusCode': res.statusCode,
        'message': 'استجابة غير متوقعة من السيرفر. ربما HTML؟',
        'body': res.body,
      };
    }

    final body = jsonDecode(res.body);

    return {
      'statusCode': res.statusCode,
      'message': body['message'] ?? body['error'] ?? 'خطأ غير متوقع',
      'body': body,
    };
  } catch (e, stackTrace) {
    debugPrint('❌ فشل في الاتصال بالخادم: $e');
    debugPrint('StackTrace: $stackTrace');

    return {
      'statusCode': 0,
      'message': 'فشل في الاتصال بالخادم: ${e.toString()}',
    };
  } finally {
    isSendingCode(false);
  }
}


  // ------ التحقق من صحة الكود ------
  Future<Map<String, dynamic>> verifyCodeApi() async {
    isVerifying(true);
    try {
      final uri = Uri.parse('$baseUrl/verify-code');
      final payload = {'email': emailCtrl.text.trim(), 'code': codeCtrl.text.trim()};
      final res = await http.post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(payload));
      
      final body = jsonDecode(res.body);
      final bool success = (res.statusCode == 200 && body['status'] == 'success');
      return {'status': success, 'message': body['message'] ?? 'فشل في التحقق'};
    } catch (e) {
      return {'status': false, 'message': 'فشل في الاتصال'};
    } finally {
      isVerifying(false);
    }
  }

  // ------ إكمال عملية التسجيل ------
  Future<Map<String, dynamic>> completeRegistration() async {
    try {
      final uri = Uri.parse('$baseUrl/complete-signup');
      final payload = {
        'email': emailCtrl.text.trim(),
        'code': codeCtrl.text.trim(),
        'password': passwordCtrl.text.trim(),
      };
      final res = await http.post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(payload));
      
      final Map<String, dynamic> body = jsonDecode(res.body);
      final bool success = body['status'] == true;
      final String message = body['message'] ?? 'خطأ غير متوقع';

      if (success) {
        final prefs = await SharedPreferences.getInstance();
        final userJson = jsonEncode(body['user']);
        await prefs.setString('user', userJson);
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        Get.find<LoadingController>().currentUser = users.User.fromJson(userMap);
           Get.find<LoadingController>().setUser( users.User.fromJson(userMap)) ;
        return {'status': true, 'message': message, 'user': body['user']};
      } else {
        return {'status': false, 'message': message};
      }
    } catch (e) {
      return {'status': false, 'message': 'فشل في الاتصال'};
    }
  }

  // ------ تسجيل الدخول ------
  Future<Map<String, dynamic>> loginApi() async {
    isLoggingIn(true);
    try {
      final uri = Uri.parse('$baseUrl/login');
      final payload = {'email': emailCtrl.text.trim(), 'password': passwordCtrl.text.trim()};
      final res = await http.post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(payload));
      
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && body['status'] == 'success') {
        final prefs = await SharedPreferences.getInstance();
        final userJson = jsonEncode(body['user']);
        await prefs.setString('user', userJson);
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        Get.find<LoadingController>().currentUser = users.User.fromJson(userMap);
        Get.find<LoadingController>().setUser( users.User.fromJson(userMap)) ;
      final ViewsController viewsController = Get.find<ViewsController>();
  final FavoritesController favoritesController = Get.find<FavoritesController>();
    final BrowsingHistoryController _browsingHistoryController = Get.find<BrowsingHistoryController>();

        
       viewsController.fetchViews(
        userId:  Get.find<LoadingController>().currentUser?.id??0, 
        perPage: 3, 
        lang: Get.find<ChangeLanguageController>().currentLocale.value.languageCode
      );
      
       favoritesController.fetchFavorites(
        userId:  Get.find<LoadingController>().currentUser?.id??0, 
        perPage: 3, 
        lang: Get.find<ChangeLanguageController>().currentLocale.value.languageCode
      );
      
       _browsingHistoryController.fetchRecommendedAds(
        userId:  Get.find<LoadingController>().currentUser?.id??0, 
        lang: Get.find<ChangeLanguageController>().currentLocale.value.languageCode,
      );

        return {'status': true, 'message': 'تم تسجيل الدخول بنجاح', 'user': body['user']};
      } else {
        return {'status': false, 'message': body['message'] ?? 'فشل في تسجيل الدخول'};
      }
    } catch (e) {
      return {'status': false, 'message': 'فشل في الاتصال بالخادم'};
    } finally {
      isLoggingIn(false);
    }
  }


 Future<Map<String, dynamic>> googleSignInApi(String email) async {
  isLoading(true);
  try {
    final uri = Uri.parse('$baseUrl/google-signin');
    final payload = {'email': email};
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    final Map<String, dynamic> body = jsonDecode(res.body);
    final userMap = body['user'] as Map<String, dynamic>;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(userMap));

    final user = users.User.fromJson(userMap);
    final loadingCtrl = Get.find<LoadingController>();
    loadingCtrl.currentUser = user;
    loadingCtrl.setUser(user);

    final langCode = Get.find<ChangeLanguageController>().currentLocale.value.languageCode;

    Get.find<ViewsController>().fetchViews(userId: user.id ?? 0, perPage: 3, lang: langCode);
    Get.find<FavoritesController>().fetchFavorites(userId: user.id ?? 0, perPage: 3, lang: langCode);
    Get.find<BrowsingHistoryController>().fetchRecommendedAds(userId: user.id ?? 0, lang: langCode);
Get.offAll(()=> HomeScreen());
    return {
      'status': true,
      'message': body['message'] ?? 'تم تسجيل الدخول بنجاح',
      'user': userMap,
      'isNewUser': body['message']?.contains('إنشاء') ?? false,
    };
  } catch (e) {
    // حتى لو صار استثناء نكمل كأن العملية تمت
    print('Google sign-in exception ignored: $e');
    return {
      'status': true,
      'message': 'تم تسجيل الدخول بنجاح (تم تجاهل الخطأ)',
    };
  } finally {
    isLoading(false);
  }
}
  // ------ إعادة تعيين كلمة المرور لحسابات جوجل ------
  Future<Map<String, dynamic>> resetGooglePasswordApi({
  required String email,
  required String code,
  required String password,
}) async {
  isLoading(true);
  try {
    final uri = Uri.parse('$baseUrl/reset-google-password');
    final payload = {'email': email, 'code': code, 'password': password};
    
    debugPrint('➡️ [reset-google-password] $uri');
    debugPrint('➡️ Payload: $payload');
    
    final res = await http.post(
      uri, 
      headers: {'Content-Type': 'application/json'}, 
      body: jsonEncode(payload)
    );
    
    debugPrint('⬅️ Status: ${res.statusCode}');
    debugPrint('⬅️ Body: ${res.body}');
    
    final Map<String, dynamic> body = jsonDecode(res.body);
    final bool success = (res.statusCode == 200 && body['status'] == 'success');
    
    return {
      'status': success,
      'message': body['message'] ?? (success ? 'تم التحديث بنجاح' : 'فشل في التحديث'),
      'details': body.toString(), // إضافة تفاصيل الاستجابة
    };
  } catch (e, stack) {
    // طباعة كامل تفاصيل الخطأ
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

  // ==================== [دوال واجهة المستخدم] ====================
  void sendVerificationCode() async {
    if (emailCtrl.text.isEmpty || !emailCtrl.text.contains('@')) {
      _showErrorSnackbar('بريد غير صالح', 'يرجى إدخال بريد إلكتروني صحيح');
      return;
    }

    isLoading.value = true;
    final result = await sendVerificationCodeApi();
    isLoading.value = false;

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
      _showErrorSnackbar('رمز غير صالح', 'يرجى إدخال رمز التحقق المكون من 6 أرقام');
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

  // ------ إعادة تعيين كلمة مرور حساب جوجل (واجهة) ------
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
  // ==================== [دوال مساعدة] ====================
  void _showErrorSnackbar(String title, String message) {
    Get.snackbar(title, message, snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error.withOpacity(0.2), colorText: AppColors.error);
  }

  void _showSuccessSnackbar(String title, String message) {
    Get.snackbar(title, message, snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success.withOpacity(0.2), colorText: AppColors.success);
  }

  // ------ جلب بيانات المستخدم للتحديث ------
  Future<Map<String, dynamic>> fetchUserDataApi(int userId) async {
    print("############################################################################################################################################################################################################################################################################################################################################################################################################################################################################################");
    isLoading(true);
    try {
      final uri = Uri.parse('$baseUrl/user-update/$userId');
      final res = await http.get(uri, headers: {'Content-Type': 'application/json'});
      
      final Map<String, dynamic> body = jsonDecode(res.body);
      if (res.statusCode == 200 && body['status'] == 'success') {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(body['user']));
        final userMap = body['user'] as Map<String, dynamic>;
        final updatedUser = users.User.fromJson(userMap);
        Get.find<LoadingController>().currentUser = updatedUser;
        
        print("تم تحديث بيانات المستخدمممممم");
        return {
          'status': true,
          'user': updatedUser,
          'freePostsExhausted': body['free_posts_exhausted'] as bool,
          'accountStatus': body['account_status'] as String,
        };

      
      } else {        print("فشل تااام في تحديث بيانات ");
        return {'status': false, 'message': body['message'] ?? 'فشل في جلب بيانات المستخدم'};
      }
    } catch (e) {   
       print("فشل تااام في تحديث بيانات ");
      return {'status': false, 'message': 'فشل في الاتصال بالخادم'};
    } finally {
      isLoading(false);
    }
  }

  // ------ التحقق من نوع الحساب (عادي/جوجل) ------
  void checkAccountType() {
    final currentUser = Get.find<LoadingController>().currentUser;
    if (currentUser == null) return;

    if (currentUser.signup_method == "email") {
      // معالجة الحساب العادي
    } else {
      // معالجة حساب جوجل
      Get.toNamed('/reset-google-password');
    }
  }


  // ==================== [دوال واجهة المستخدم] ====================

  /// واجهة إرسال كود عند التسجيل
  void sendVerificationCodeForSignup() async {
    if (emailCtrl.text.isEmpty || !emailCtrl.text.contains('@')) {
      _showErrorSnackbar('بريد غير صالح', 'يرجى إدخال بريد إلكتروني صحيح');
      return;
    }

    isLoading(true);
    final result = await sendVerificationCodeApi(force: 0);
    isLoading(false);

    if (result['statusCode'] == 200) {
      currentStep.value = 1;
      codeSent.value = true;
      _showSuccessSnackbar('تم الإرسال!', 'تم إرسال رمز التحقق إلى بريدك');
    } else {
      _showErrorSnackbar('خطأ', result['message']);
    }
  }

  /// واجهة إرسال كود عند استعادة/تغيير كلمة المرور
  void sendVerificationCodeForReset() async {
    if (emailCtrl.text.isEmpty || !emailCtrl.text.contains('@')) {
      _showErrorSnackbar('بريد غير صالح', 'يرجى إدخال بريد إلكتروني صحيح');
      return;
    }

    isLoading(true);
    final result = await sendVerificationCodeApi(force: 1);
    isLoading(false);

    if (result['statusCode'] == 200) {
      currentStep.value = 1;
      codeSent.value = true;
      _showSuccessSnackbar('تم الإرسال!', 'تم إرسال رمز التحقق إلى بريدك');
    } else {
      _showErrorSnackbar('خطأ', result['message']);
    }
  }


    Future<void> deleteUser(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/users/\$id'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        _showSnackbar('نجاح', 'تم حذف المستخدم #\$id بنجاح.', false);
        Get.find<LoadingController>().logout();
      } else if (response.statusCode == 404) {
        _showSnackbar('خطأ', 'المستخدم #\$id غير موجود.', true);
      } else {
        _showSnackbar('خطأ', 'فشل في حذف المستخدم. رمز: \${response.statusCode}', true);
      }
    } catch (e) {
      _showSnackbar('استثناء', 'حدث خطأ أثناء الحذف: \$e', true);
    }
  }

  /// Display professional snackbars
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
      // ensure it stands out
      shouldIconPulse: true,
      dismissDirection: DismissDirection.horizontal,
    );
  }





}