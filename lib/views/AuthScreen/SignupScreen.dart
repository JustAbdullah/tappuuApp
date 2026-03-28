// lib/views/AuthScreen/SignupScreen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tappuu_app/core/constant/app_text_styles.dart';
import 'package:tappuu_app/core/constant/appcolors.dart';

import 'package:tappuu_app/controllers/ThemeController.dart';
import 'package:tappuu_app/controllers/AuthController.dart';

import 'package:tappuu_app/views/HomeScreen/home_screen.dart';
import '../AdvertiserScreen/AdvertiserDataScreen.dart';

// reCAPTCHA v3 (Mini WebView 1×1) للـ Signup
import 'package:tappuu_app/core/recaptcha/recaptcha_mini_webview.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // مفاتيح الفورم
  final _emailFormKey = GlobalKey<FormState>();
  final _codeFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  // فوكس نودز
  final _emailFocus = FocusNode();
  final _codeFocus = FocusNode();
  final _passwordFocus = FocusNode();

  // نستخدم الـ AuthController المسجل مسبقًا في main.dart (permanent)
  final AuthController _authC = Get.find<AuthController>();

  bool get _isDarkMode {
    try {
      return Get.find<ThemeController>().isDarkMode.value;
    } catch (_) {
      return false;
    }
  }

  // ===================== reCAPTCHA v3 Mini =====================
  static const String kRecaptchaBaseUrl =
      'https://testing.arabiagroup.net/recaptcha.html';

  // توكنات خطوة البريد / إرسال الكود (action=signup_email)
  late final Widget _recaptchaSignupEmail = const RecaptchaMiniWebView(
    key: ValueKey('recaptcha_signup_email'),
    baseUrl: kRecaptchaBaseUrl,
    action: 'signup_email',
    invisible: true, // 1×1 + IgnorePointer
  );

  // توكنات خطوة الإكمال (كلمة المرور) (action=signup_complete)
  late final Widget _recaptchaSignupComplete = const RecaptchaMiniWebView(
    key: ValueKey('recaptcha_signup_complete'),
    baseUrl: kRecaptchaBaseUrl,
    action: 'signup_complete',
    invisible: true,
  );

  @override
  void dispose() {
    _emailFocus.dispose();
    _codeFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = _isDarkMode;

    return Obx(() {
      return WillPopScope(
        // زر الرجوع في الجهاز:
        // لو المستخدم في خطوة الكود أو كلمة المرور → يرجعه خطوة وراء بدل ما يطرده من الشاشة
        onWillPop: () async {
          if (_authC.currentStep.value > 0) {
            _authC.prevStep();
            return false;
          }
          return true;
        },
        child: Scaffold(
          backgroundColor: AppColors.background(isDarkMode),
          body: SafeArea(
            child: Stack(
              children: [
                // ================== UI الأساسي ==================
                SingleChildScrollView(
                  padding:
                      EdgeInsets.symmetric(horizontal: 30.w, vertical: 24.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // زر العودة (يغلق شاشة التسجيل بالكامل)
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back,
                          size: 28.w,
                          color: AppColors.textPrimary(isDarkMode),
                        ),
                        onPressed: () => Get.back(),
                      ),
                      SizedBox(height: 16.h),

                      // العنوان الرئيسي
                      Text(
                        'إنشاء حساب جديد'.tr,
                        style: TextStyle(
                          fontSize: AppTextStyles.xxxlarge,
                          fontWeight: FontWeight.bold,
                          fontFamily: AppTextStyles.appFontFamily,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(height: 8.h),

                      // وصف
                      Text(
                        'انضم إلينا الآن وتمتع بجميع الميزات الحصرية'.tr,
                        style: TextStyle(
                          fontSize: AppTextStyles.large,
                          fontFamily: AppTextStyles.appFontFamily,
                          color: AppColors.textSecondary(isDarkMode),
                        ),
                      ),
                      SizedBox(height: 28.h),

                      // مؤشر التقدم
                      _buildProgressIndicator(isDarkMode, _authC),
                      SizedBox(height: 32.h),

                      // محتوى الخطوات
                      if (_authC.currentStep.value == 0)
                        _buildEmailStep(isDarkMode),
                      if (_authC.currentStep.value == 1)
                        _buildVerificationStep(isDarkMode),
                      if (_authC.currentStep.value == 2)
                        _buildPasswordStep(isDarkMode),
                    ],
                  ),
                ),

                // ================== reCAPTCHA v3 Mini ==================
                // هذه للـ send-code / إعادة الإرسال (signup_email)
                Positioned.fill(child: _recaptchaSignupEmail),

                // هذه تظهر فقط في خطوة كلمة المرور للإكمال (signup_complete)
                if (_authC.currentStep.value == 2)
                  Positioned.fill(child: _recaptchaSignupComplete),
              ],
            ),
          ),
        ),
      );
    });
  }

  // ------------------------ UI: Progress ------------------------
  Widget _buildProgressIndicator(bool isDark, AuthController c) {
    Color active = AppColors.primary;
    Color inactive = AppColors.greyLight;

    Widget dot(int step, String label) {
      final reached = c.currentStep.value >= (step - 1);
      return Expanded(
        child: Column(
          children: [
            CircleAvatar(
              radius: 18.r,
              backgroundColor: reached ? active : inactive,
              child: Text(
                '$step',
                style: TextStyle(
                  color:
                      reached ? AppColors.onPrimary : AppColors.onSurfaceLight,
                  fontSize: AppTextStyles.medium,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              label.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppTextStyles.small,
                fontFamily: AppTextStyles.appFontFamily,
                color: reached ? active : AppColors.textSecondary(isDark),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }

    Widget line(bool filled) => Expanded(
          child: Container(
            height: 2,
            margin: EdgeInsets.symmetric(horizontal: 8.w),
            color: filled ? active : inactive,
          ),
        );

    return Row(
      children: [
        dot(1, 'البريد الإلكتروني'),
        line(c.currentStep.value >= 1),
        dot(2, 'رمز التحقق'),
        line(c.currentStep.value >= 2),
        dot(3, 'كلمة المرور'),
      ],
    );
  }

  // ------------------------ Step 0: Email ------------------------
  Widget _buildEmailStep(bool isDark) {
    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // صورة/أيقونة
          Center(
            child: Container(
              height: 150.h,
              width: 150.w,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Icon(Icons.email_outlined,
                  size: 60.w, color: AppColors.primary),
            ),
          ),
          SizedBox(height: 24.h),

          Text(
            'أدخل بريدك الإلكتروني'.tr,
            style: TextStyle(
              fontSize: AppTextStyles.xxlarge,
              fontWeight: FontWeight.bold,
              fontFamily: AppTextStyles.appFontFamily,
              color: AppColors.textPrimary(isDark),
            ),
          ),
          SizedBox(height: 8.h),

          Text(
            'سيتم إرسال رمز التحقق إلى بريدك الإلكتروني للتأكد من ملكيته'.tr,
            style: TextStyle(
              fontSize: AppTextStyles.medium,
              fontFamily: AppTextStyles.appFontFamily,
              color: AppColors.textSecondary(isDark),
            ),
          ),
          SizedBox(height: 22.h),

          TextFormField(
            focusNode: _emailFocus,
            controller: _authC.emailCtrl,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.username, AutofillHints.email],
            textInputAction: TextInputAction.done,

            // ✅ Validator أكثر مرونة
            validator: (v) {
              final t = (v ?? '').trim();
              if (t.isEmpty) return 'أدخل البريد الإلكتروني'.tr;

              // نخفف الشروط: فقط نضمن وجود @ وأنها ليست في البداية/النهاية
              if (t.length < 5 ||
                  !t.contains('@') ||
                  t.startsWith('@') ||
                  t.endsWith('@')) {
                return 'تحقق من كتابة البريد بشكل صحيح (name@example.com)'.tr;
              }

              // ما عاد نلزم وجود نقطة في الدومين علشان الدومينات الداخلية / المخصّصة
              return null;
            },

            decoration: InputDecoration(
              labelText: 'البريد الإلكتروني'.tr,
              labelStyle: TextStyle(
                fontSize: AppTextStyles.medium,
                fontFamily: AppTextStyles.appFontFamily,
                color: AppColors.textSecondary(isDark),
              ),
              prefixIcon: Icon(Icons.email_outlined,
                  size: 22.w, color: AppColors.textSecondary(isDark)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: AppColors.divider(isDark)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: AppColors.divider(isDark)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: AppColors.primary, width: 1.5),
              ),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              fillColor: AppColors.surface(isDark),
              filled: true,
            ),
            style: TextStyle(color: AppColors.textPrimary(isDark)),
          ),
          SizedBox(height: 28.h),

          Obx(() {
            final sending =
                _authC.isSendingCode.value || _authC.isLoading.value;
            return SizedBox(
              width: double.infinity,
              height: 50.h,
              child: ElevatedButton(
                onPressed: sending
                    ? null
                    : () {
                        if (_emailFormKey.currentState?.validate() ?? false) {
                          // يرسل الكود + يتعامل مع reCAPTCHA v3/v2 داخليًا
                          _authC.sendVerificationCodeForSignup();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r)),
                  elevation: 2,
                ),
                child: sending
                    ? SizedBox(
                        width: 22.w,
                        height: 22.w,
                        child: const CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        'إرسال رمز التحقق'.tr,
                        style: TextStyle(
                          fontSize: AppTextStyles.large,
                          fontWeight: FontWeight.bold,
                          fontFamily: AppTextStyles.appFontFamily,
                        ),
                      ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ------------------------ Step 1: Verify Code ------------------------
  Widget _buildVerificationStep(bool isDark) {
    return Form(
      key: _codeFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              height: 150.h,
              width: 150.w,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Icon(Icons.verified_user_outlined,
                  size: 60.w, color: AppColors.primary),
            ),
          ),
          SizedBox(height: 24.h),

          Text(
            'أدخل رمز التحقق'.tr,
            style: TextStyle(
              fontSize: AppTextStyles.xxlarge,
              fontWeight: FontWeight.bold,
              fontFamily: AppTextStyles.appFontFamily,
              color: AppColors.textPrimary(isDark),
            ),
          ),
          SizedBox(height: 8.h),

          RichText(
            text: TextSpan(
              text: 'تم إرسال رمز مكون من 6 أرقام إلى '.tr,
              style: TextStyle(
                fontSize: AppTextStyles.medium,
                fontFamily: AppTextStyles.appFontFamily,
                color: AppColors.textSecondary(isDark),
              ),
              children: [
                TextSpan(
                  text: _authC.emailCtrl.text,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 22.h),

          TextFormField(
            focusNode: _codeFocus,
            controller: _authC.codeCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 6,
            validator: (v) {
              final t = (v ?? '').trim();
              if (t.length != 6) return 'أدخل الرمز المكون من 6 أرقام'.tr;
              return null;
            },
            decoration: InputDecoration(
              counterText: '',
              labelText: 'رمز التحقق'.tr,
              labelStyle: TextStyle(
                fontSize: AppTextStyles.medium,
                fontFamily: AppTextStyles.appFontFamily,
                color: AppColors.textSecondary(isDark),
              ),
              prefixIcon: Icon(Icons.lock_outlined,
                  size: 22.w, color: AppColors.textSecondary(isDark)),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: AppColors.divider(isDark)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: AppColors.primary, width: 1.5),
              ),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              fillColor: AppColors.surface(isDark),
              filled: true,
            ),
            style: TextStyle(color: AppColors.textPrimary(isDark)),
          ),
          SizedBox(height: 8.h),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'لم تستلم الرمز؟'.tr,
                style: TextStyle(
                  fontSize: AppTextStyles.small,
                  fontFamily: AppTextStyles.appFontFamily,
                  color: AppColors.textSecondary(isDark),
                ),
              ),
              TextButton(
                onPressed: () => _authC.sendVerificationCodeForSignup(),
                child: Text(
                  'إعادة الإرسال'.tr,
                  style: TextStyle(
                    fontSize: AppTextStyles.small,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          Obx(() {
            final verifying =
                _authC.isVerifying.value || _authC.isLoading.value;
            return SizedBox(
              width: double.infinity,
              height: 50.h,
              child: ElevatedButton(
                onPressed: verifying
                    ? null
                    : () {
                        if (_codeFormKey.currentState?.validate() ?? false) {
                          _authC.verifyCode(); // لو نجح → currentStep = 2
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r)),
                  elevation: 2,
                ),
                child: verifying
                    ? SizedBox(
                        width: 22.w,
                        height: 22.w,
                        child: const CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        'تحقق من الرمز'.tr,
                        style: TextStyle(
                          fontSize: AppTextStyles.large,
                          fontWeight: FontWeight.bold,
                          fontFamily: AppTextStyles.appFontFamily,
                        ),
                      ),
              ),
            );
          }),
          SizedBox(height: 12.h),

          Center(
            child: TextButton(
              onPressed: () => _authC.currentStep.value = 0,
              child: Text(
                'تغيير البريد الإلكتروني'.tr,
                style: TextStyle(
                  fontSize: AppTextStyles.medium,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------ Step 2: Password ------------------------
  Widget _buildPasswordStep(bool isDark) {
    return Form(
      key: _passwordFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              height: 150.h,
              width: 150.w,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Icon(Icons.lock_outline,
                  size: 60.w, color: AppColors.primary),
            ),
          ),
          SizedBox(height: 24.h),

          Text(
            'أنشئ كلمة مرورك'.tr,
            style: TextStyle(
              fontSize: AppTextStyles.xxlarge,
              fontWeight: FontWeight.bold,
              fontFamily: AppTextStyles.appFontFamily,
              color: AppColors.textPrimary(isDark),
            ),
          ),
          SizedBox(height: 8.h),

          Text(
            'كلمة المرور يجب أن تحتوي على 6 أحرف على الأقل'.tr,
            style: TextStyle(
              fontSize: AppTextStyles.medium,
              fontFamily: AppTextStyles.appFontFamily,
              color: AppColors.textSecondary(isDark),
            ),
          ),
          SizedBox(height: 18.h),

          Obx(() {
            return TextFormField(
              focusNode: _passwordFocus,
              controller: _authC.passwordCtrl,
              obscureText: !_authC.showPassword.value,
              autofillHints: const [AutofillHints.newPassword],
              textInputAction: TextInputAction.done,
              onChanged: _authC.validatePassword,
              validator: (v) {
                final t = (v ?? '').trim();
                if (t.length < 6) return 'الحد الأدنى 6 أحرف'.tr;
                return null;
              },
              decoration: InputDecoration(
                labelText: 'كلمة المرور'.tr,
                labelStyle: TextStyle(
                  fontSize: AppTextStyles.medium,
                  fontFamily: AppTextStyles.appFontFamily,
                  color: AppColors.textSecondary(isDark),
                ),
                prefixIcon: Icon(Icons.lock_outline,
                    size: 22.w, color: AppColors.textSecondary(isDark)),
                suffixIcon: IconButton(
                  onPressed: () => _authC.showPassword.toggle(),
                  icon: Icon(
                    _authC.showPassword.value
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: AppColors.textSecondary(isDark),
                  ),
                ),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: AppColors.divider(isDark)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                fillColor: AppColors.surface(isDark),
                filled: true,
              ),
              style: TextStyle(color: AppColors.textPrimary(isDark)),
            );
          }),
          SizedBox(height: 8.h),

          Obx(() {
            final ok = _authC.isPasswordValid.value;
            return Text(
              ok
                  ? 'كلمة المرور صالحة'.tr
                  : 'كلمة المرور يجب أن تحتوي على 6 أحرف على الأقل'.tr,
              style: TextStyle(
                fontSize: AppTextStyles.small,
                color:
                    ok ? AppColors.success : AppColors.textSecondary(isDark),
              ),
            );
          }),
          SizedBox(height: 24.h),

          Obx(() {
            final busy = _authC.isLoading.value;
            final enabled = _authC.isPasswordValid.value && !busy;

            return Row(
              children: [
                if (_authC.canCompleteLater.value) ...[
                  Expanded(
                    child: SizedBox(
                      height: 50.h,
                      child: OutlinedButton(
                        onPressed:
                            busy ? null : () => Get.offAll(() => const HomeScreen()),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r)),
                        ),
                        child: Text(
                          'لاحقًا'.tr,
                          style: TextStyle(
                            fontSize: AppTextStyles.large,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                ],
                Expanded(
                  child: SizedBox(
                    height: 50.h,
                    child: ElevatedButton(
                      onPressed: enabled
                          ? () async {
                              if (!(_passwordFormKey.currentState
                                      ?.validate() ??
                                  false)) return;

                              _authC.isLoading.value = true;
                              final res = await _authC.completeRegistration();
                              _authC.isLoading.value = false;

                              // 🔍 Debug واضح للنتيجة
                              debugPrint(
                                  '🔴 [SignupScreen] completeRegistration result: $res');

                              if (res['status'] == true) {
                                Get.offAll(
                                    () => const AccountCreatedSuccessScreen());
                              } else {
                                Get.snackbar(
                                  'خطأ'.tr,
                                  (res['message'] ?? 'فشل في الإكمال')
                                      .toString(),
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor:
                                      AppColors.error.withOpacity(0.2),
                                  colorText: AppColors.error,
                                );
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: enabled
                            ? AppColors.primary
                            : AppColors.primary.withOpacity(0.5),
                        foregroundColor: AppColors.onPrimary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r)),
                        elevation: 2,
                      ),
                      child: busy
                          ? SizedBox(
                              width: 22.w,
                              height: 22.w,
                              child: const CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              'الإنشاء'.tr,
                              style: TextStyle(
                                fontSize: AppTextStyles.large,
                                fontWeight: FontWeight.bold,
                                fontFamily: AppTextStyles.appFontFamily,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            );
          }),
          SizedBox(height: 16.h),

          Center(
            child: TextButton(
              onPressed: () => _authC.prevStep(),
              child: Text(
                'العودة'.tr,
                style: TextStyle(
                  fontSize: AppTextStyles.medium,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------ Success Screen ------------------------
class AccountCreatedSuccessScreen extends StatelessWidget {
  const AccountCreatedSuccessScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isDarkMode;
    try {
      isDarkMode = Get.find<ThemeController>().isDarkMode.value;
    } catch (_) {
      isDarkMode = false;
    }

    return Scaffold(
      backgroundColor: AppColors.background(isDarkMode),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 30.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline,
                  size: 100.w, color: AppColors.success),
              SizedBox(height: 24.h),
              Text(
                'مبروك لقد تم إنشاء حسابك بنجاح'.tr,
                style: TextStyle(
                  fontSize: AppTextStyles.xxxlarge,
                  fontWeight: FontWeight.bold,
                  fontFamily: AppTextStyles.appFontFamily,
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 28.h),

              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  onPressed: () => Get.offAll(() => const HomeScreen()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r)),
                  ),
                  child: Text(
                    'العودة للرئيسية'.tr,
                    style: TextStyle(
                      fontSize: AppTextStyles.large,
                      fontWeight: FontWeight.bold,
                      fontFamily: AppTextStyles.appFontFamily,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16.h),

              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: OutlinedButton(
                  onPressed: () =>
                      Get.offAll(() => AdvertiserDataScreen()),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r)),
                  ),
                  child: Text(
                    'بدء إضافة بيانات المعلن'.tr,
                    style: TextStyle(
                      fontSize: AppTextStyles.large,
                      fontWeight: FontWeight.bold,
                      fontFamily: AppTextStyles.appFontFamily,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12.h),

              Text(
                'اضف بيانات المعلن الظاهر للمستخدمين عند نشر الاعلانات\n(الاسم..الشعار(اختياري).رقم الاتصال ورقم الواتساب)'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppTextStyles.small,
                  fontFamily: AppTextStyles.appFontFamily,
                  color: AppColors.textSecondary(isDarkMode),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
