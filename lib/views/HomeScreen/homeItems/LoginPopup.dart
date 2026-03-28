// lib/desktop_or_web/widgets/login_popup.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/ThemeController.dart';
import '../../../controllers/AuthController.dart';
import '../../../core/constant/app_text_styles.dart';
import '../../../core/constant/appcolors.dart';
import '../../AuthScreen/ResetPasswordScreen.dart';
import '../../AuthScreen/SignupScreen.dart';

// reCAPTCHA v3 (Mini WebView 1×1)
import '../../../core/recaptcha/recaptcha_mini_webview.dart';

class LoginPopup extends StatefulWidget {
  const LoginPopup({super.key});

  @override
  State<LoginPopup> createState() => _LoginPopupState();
}

class _LoginPopupState extends State<LoginPopup>
    with AutomaticKeepAliveClientMixin<LoginPopup> {
  // دومين صفحة reCAPTCHA v3 — تولّد التوكن وتخزّنه في RecaptchaTokenCache
  static const String kRecaptchaBaseUrl =
      'https://testing.arabiagroup.net/recaptcha.html';

  // نثبّت نسخة واحدة من الودجت ونمنع إعادة إنشائه مع أي setState
  late final Widget _recaptcha = const RecaptchaMiniWebView(
    key: ValueKey('recaptcha_login_v3'),
    baseUrl: kRecaptchaBaseUrl,
    action: 'login',
    invisible: true, // 1×1 + Opacity≈0 + IgnorePointer
  );

  @override
  bool get wantKeepAlive => true;

  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late final AuthController _authC = Get.isRegistered<AuthController>()
      ? Get.find<AuthController>()
      : Get.put(AuthController());

  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _obscurePassword = true;

  bool _isDark(BuildContext context) {
    try {
      final themeC = Get.find<ThemeController>();
      return themeC.isDarkMode.value;
    } catch (_) {
      return Theme.of(context).brightness == Brightness.dark;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // مهم مع AutomaticKeepAliveClientMixin
    final isDarkMode = _isDark(context);

    return Scaffold(
      backgroundColor: AppColors.background(isDarkMode),
      body: SafeArea(
        child: Stack(
          children: [
            // ===================== UI =====================
            SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: AutofillGroup(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back,
                          size: 24.0,
                          color: AppColors.textPrimary(isDarkMode),
                        ),
                        onPressed: () => Get.back(),
                        padding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 16.0),

                      Text(
                        'تسجيل الدخول',
                        style: TextStyle(
                          fontSize: AppTextStyles.xxxlarge,
                          fontWeight: FontWeight.bold,
                          fontFamily: AppTextStyles.appFontFamily,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4.0),

                      Text(
                        'سجل دخولك لاستئناف تجربتك',
                        style: TextStyle(
                          fontSize: AppTextStyles.medium,
                          fontFamily: AppTextStyles.appFontFamily,
                          color: AppColors.textSecondary(isDarkMode),
                        ),
                      ),
                      const SizedBox(height: 24.0),

                      _buildInputField(
                        label: 'البريد الإلكتروني',
                        controller: _emailController,
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        isDarkMode: isDarkMode,
                        focusNode: _emailFocus,
                        autofillHints: const [
                          AutofillHints.username,
                          AutofillHints.email,
                        ],
                        validator: (v) {
                          final text = (v ?? '').trim();
                          if (text.isEmpty) return 'أدخل البريد الإلكتروني';
                          if (!text.contains('@') || !text.contains('.')) {
                            return 'بريد إلكتروني غير صالح';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                      ),
                      const SizedBox(height: 16.0),

                      _buildPasswordField(isDarkMode),
                      const SizedBox(height: 8.0),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () =>
                              Get.to(() => const ResetPasswordScreen()),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                          ),
                          child: Text(
                            'نسيت كلمة المرور؟',
                            style: TextStyle(
                              fontSize: AppTextStyles.small,
                              fontWeight: FontWeight.w600,
                              fontFamily: AppTextStyles.appFontFamily,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24.0),

                      Obx(() {
                        final loading = _authC.isLoggingIn.value;
                        return ElevatedButton(
                          onPressed: loading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.onPrimary,
                            minimumSize: const Size(double.infinity, 48.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            elevation: 2,
                            shadowColor:
                                AppColors.primary.withOpacity(0.35),
                          ),
                          child: loading
                              ? const SizedBox(
                                  width: 24.0,
                                  height: 24.0,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2.5),
                                )
                              : Text(
                                  'تسجيل الدخول',
                                  style: TextStyle(
                                    fontSize: AppTextStyles.large,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: AppTextStyles.appFontFamily,
                                  ),
                                ),
                        );
                      }),
                      const SizedBox(height: 24.0),

                      Center(
                        child: TextButton(
                          onPressed: () {
                            Get.back();
                            Get.to(() => const SignupScreen());
                          },
                          child: RichText(
                            text: TextSpan(
                              text: 'ليس لديك حساب؟ ',
                              style: TextStyle(
                                fontSize: AppTextStyles.medium,
                                fontWeight: FontWeight.w500,
                                fontFamily: AppTextStyles.appFontFamily,
                                color: AppColors.textSecondary(isDarkMode),
                              ),
                              children: [
                                TextSpan(
                                  text: 'إنشاء حساب جديد',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: AppTextStyles.medium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10.0),
                    ],
                  ),
                ),
              ),
            ),

            // ===================== reCAPTCHA v3 Mini (1×1) =====================
            // نسخة واحدة ثابتة داخل الـ Stack — لا تعيد البناء ولا تغطي اللمس
            Positioned.fill(child: _recaptcha),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required TextInputType keyboardType,
    required bool isDarkMode,
    FocusNode? focusNode,
    Iterable<String>? autofillHints,
    String? Function(String?)? validator,
    ValueChanged<String>? onFieldSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTextStyles.appFontFamily,
            fontSize: AppTextStyles.medium,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary(isDarkMode),
          ),
        ),
        const SizedBox(height: 6.0),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          autofillHints: autofillHints,
          textInputAction: TextInputAction.next,
          onFieldSubmitted: onFieldSubmitted,
          style: TextStyle(
            fontSize: AppTextStyles.medium,
            color: AppColors.textPrimary(isDarkMode),
          ),
          validator: validator,
          decoration: InputDecoration(
            prefixIcon: Icon(
              icon,
              size: 22.0,
              color: AppColors.textSecondary(isDarkMode),
            ),
            filled: true,
            fillColor: AppColors.surface(isDarkMode),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide(color: AppColors.divider(isDarkMode)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide(color: AppColors.divider(isDarkMode)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide(color: AppColors.primary, width: 1.2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14.0, vertical: 14.0),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'كلمة المرور',
          style: TextStyle(
            fontFamily: AppTextStyles.appFontFamily,
            fontSize: AppTextStyles.medium,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary(isDarkMode),
          ),
        ),
        const SizedBox(height: 6.0),
        TextFormField(
          controller: _passwordController,
          focusNode: _passwordFocus,
          obscureText: _obscurePassword,
          autofillHints: const [AutofillHints.password],
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _login(),
          style: TextStyle(
            fontSize: AppTextStyles.medium,
            color: AppColors.textPrimary(isDarkMode),
          ),
          validator: (v) {
            final text = (v ?? '').trim();
            if (text.isEmpty) return 'أدخل كلمة المرور';
            if (text.length < 6) return 'الحد الأدنى 6 أحرف';
            return null;
          },
          decoration: InputDecoration(
            prefixIcon: Icon(
              Icons.lock_outlined,
              size: 22.0,
              color: AppColors.textSecondary(isDarkMode),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                size: 22.0,
                color: AppColors.textSecondary(isDarkMode),
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            filled: true,
            fillColor: AppColors.surface(isDarkMode),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide(color: AppColors.divider(isDarkMode)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide(color: AppColors.divider(isDarkMode)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide(color: AppColors.primary, width: 1.2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14.0, vertical: 14.0),
          ),
        ),
      ],
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    // مرّر القيم إلى الكنترولر
    _authC.emailCtrl.text = _emailController.text.trim();
    _authC.passwordCtrl.text = _passwordController.text.trim();

    // امنع ضغطات مزدوجة
    if (_authC.isLoggingIn.value) return;

    final result = await _authC.loginApi();

    // ✅ طباعة النتيجة كاملة في الكونسل لمعرفة وين المشكلة بالضبط
    print('🔴 [LoginPopup] loginApi result: $result');

    if (result['status'] == true) {
      final msg =
          (result['message'] ?? 'تم تسجيل الدخول بنجاح').toString();
      Get.snackbar(
        'نجاح',
        msg,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success,
        colorText: AppColors.onPrimary,
      );
    } else {
      final msg = (result['message'] ?? 'خطأ في تسجيل الدخول').toString();

      if (msg.contains('reCAPTCHA')) {
        print('🧪 [LoginPopup] reCAPTCHA-related failure: $msg');
      }

      Get.snackbar(
        'فشل',
        msg,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: AppColors.onPrimary,
      );
    }
  }
}
