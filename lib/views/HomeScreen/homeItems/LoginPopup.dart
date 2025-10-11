import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tappuu_app/core/constant/images_path.dart';

import '../../../controllers/ThemeController.dart';
import '../../../controllers/AuthController.dart';
import '../../../core/constant/app_text_styles.dart';
import '../../../core/constant/appcolors.dart';
import '../../AuthScreen/ResetPasswordScreen.dart';
import '../../AuthScreen/SignupScreen.dart';

class LoginPopup extends StatefulWidget {
  const LoginPopup({super.key});

  @override
  State<LoginPopup> createState() => _LoginPopupState();
}

class _LoginPopupState extends State<LoginPopup> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authC = Get.put(AuthController());

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Get.find<ThemeController>().isDarkMode.value;

    return Scaffold(
      backgroundColor: AppColors.background(isDarkMode),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // زر العودة
              IconButton(
                icon: Icon(Icons.arrow_back, size: 24.w, 
                  color: AppColors.textPrimary(isDarkMode)),
                onPressed: () => Get.back(),
                padding: EdgeInsets.zero,
              ),
              SizedBox(height: 16.h),
              
              // العنوان الرئيسي
              Text(
                'تسجيل الدخول'.tr,
                style: TextStyle(
                  fontSize: AppTextStyles.xxxlarge,

                  fontWeight: FontWeight.bold,
                  fontFamily: AppTextStyles.appFontFamily,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: 4.h),
              
              // وصف التطبيق
              Text(
                'سجل دخولك لاستئناف تجربتك'.tr,
                style: TextStyle(
                  fontSize: AppTextStyles.medium,

                  fontFamily: AppTextStyles.appFontFamily,
                  color: AppColors.textSecondary(isDarkMode),
                ),
              ),
              SizedBox(height: 24.h),
              
              // حقل البريد الإلكتروني
              _buildInputField(
                label: 'البريد الإلكتروني'.tr,
                controller: _emailController,
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                isDarkMode: isDarkMode,
              ),
              SizedBox(height: 16.h),
              
              // حقل كلمة المرور
              _buildPasswordField(isDarkMode),
              SizedBox(height: 8.h),
              
              // نسيت كلمة المرور؟
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () {
                    Get.to(()=>ResetPasswordScreen());
                  },
                  child: Text(
                    'نسيت كلمة المرور؟'.tr,
                    style: TextStyle(
                      fontSize: AppTextStyles.small,

                      fontWeight: FontWeight.w600,
                      fontFamily: AppTextStyles.appFontFamily,
                      color: AppColors.primary,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              
              // زر تسجيل الدخول
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  minimumSize: Size(double.infinity, 48.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  elevation: 2,
                  shadowColor: AppColors.primary.withOpacity(0.4),
                ),
                child: _isLoading
                  ? SizedBox(
                      width: 24.w,
                      height: 24.h,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.onPrimary,
                      ),
                    )
                  : Text(
                      'تسجيل الدخول'.tr,
                      style: TextStyle(
                        fontSize: AppTextStyles.large,

                        fontWeight: FontWeight.bold,
                        fontFamily: AppTextStyles.appFontFamily,
                      ),
                    ),
              ),
              SizedBox(height: 20.h),
              
              // فصل
              Row(
                children: [
                  Expanded(
                    child: Divider(
                      thickness: 1, 
                      color: AppColors.grey.withOpacity(0.3),
                  )),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.w),
                    child: Text(
                      'أو'.tr,
                      style: TextStyle(
                        fontSize: AppTextStyles.small,

                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary(isDarkMode),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      thickness: 1, 
                      color: AppColors.grey.withOpacity(0.3),
                   ) ),
                ],
              ),
            /*  SizedBox(height: 20.h),
              
              // تسجيل الدخول عبر جوجل
              _buildSocialButton(
                icon: Icons.g_mobiledata,
                text: 'تسجيل الدخول باستخدام Google'.tr,
                onPressed: () {
                _authC.signInWithGoogle();
                },
                isDarkMode: isDarkMode,
              ),*/
              SizedBox(height: 20.h),
              
              // رابط إنشاء حساب
              Center(
                child: TextButton(
                  onPressed: () {
                    Get.back();
                    Get.to(() => SignupScreen());
                  },
                  child: RichText(
                    text: TextSpan(
                      text: 'ليس لديك حساب؟ '.tr,
                      style: TextStyle(
                        fontSize: AppTextStyles.medium,

                        fontWeight: FontWeight.w500,
                        fontFamily: AppTextStyles.appFontFamily,
                        color: AppColors.textSecondary(isDarkMode),
                      ),
                      children: [
                        TextSpan(
                          text: 'إنشاء حساب جديد'.tr,
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
              SizedBox(height: 10.h),
            ],
          ),
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
        SizedBox(height: 6.h),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(
            fontSize: AppTextStyles.medium,

            color: AppColors.textPrimary(isDarkMode),
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(
              icon,
              size: 22.w,
              color: AppColors.textSecondary(isDarkMode),
            ),
            filled: true,
            fillColor: AppColors.surface(isDarkMode),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: BorderSide(color: AppColors.divider(isDarkMode)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: BorderSide(color: AppColors.divider(isDarkMode)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: BorderSide(color: AppColors.primary, width: 1.2),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 14.w, vertical: 14.h),
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
          'كلمة المرور'.tr,
          style: TextStyle(
            fontFamily: AppTextStyles.appFontFamily,
            fontSize: AppTextStyles.medium,

            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary(isDarkMode),
          ),
        ),
        SizedBox(height: 6.h),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: TextStyle(
            fontSize: AppTextStyles.medium,

            color: AppColors.textPrimary(isDarkMode),
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(
              Icons.lock_outlined,
              size: 22.w,
              color: AppColors.textSecondary(isDarkMode),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                size: 22.w,
                color: AppColors.textSecondary(isDarkMode),
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            filled: true,
            fillColor: AppColors.surface(isDarkMode),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: BorderSide(color: AppColors.divider(isDarkMode)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: BorderSide(color: AppColors.divider(isDarkMode)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: BorderSide(color: AppColors.primary, width: 1.2),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 14.w, vertical: 14.h),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String text,
    required VoidCallback onPressed,
    required bool isDarkMode,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: AppColors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          minimumSize: Size(double.infinity, 50.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16.w),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 30.w,
              color: AppColors.primary,
            ),
            SizedBox(width: 10.w),
            Flexible(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: AppTextStyles.medium,

                  fontWeight: FontWeight.w600,
                  fontFamily: AppTextStyles.appFontFamily,
                  color: AppColors.textPrimary(isDarkMode),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      Get.snackbar(
        'الحقول مطلوبة'.tr,
        'يرجى ملء جميع الحقول'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: AppColors.onPrimary,
      );
      return;
    }

    setState(() => _isLoading = true);

    // إعداد بيانات AuthController
    _authC.emailCtrl.text = _emailController.text.trim();
    _authC.passwordCtrl.text = _passwordController.text.trim();

    // استدعاء دالة تسجيل الدخول
    final result = await _authC.loginApi();

    setState(() => _isLoading = false);

    if (result['status'] == true) {
      Get.back();
      Get.snackbar(
        'نجاح'.tr,
        result['message'] ?? 'تم تسجيل الدخول'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success,
        colorText: AppColors.onPrimary,
      );
      // الانتقال للصفحة الرئيسية
      Get.offAllNamed('/home');
    } else {
      Get.snackbar(
        'فشل'.tr,
        result['message'] ?? 'خطأ في تسجيل الدخول'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: AppColors.onPrimary,
      );
    }
  }
}