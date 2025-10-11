import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tappuu_app/core/constant/app_text_styles.dart';
import 'package:tappuu_app/core/constant/appcolors.dart';
import 'package:tappuu_app/controllers/ThemeController.dart';
import 'package:tappuu_app/controllers/AuthController.dart';
import 'package:tappuu_app/views/HomeScreen/home_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({Key? key}) : super(key: key);

  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Get.find<ThemeController>().isDarkMode.value;
    final AuthController authC = Get.put(AuthController());

    return GetX<AuthController>(
      builder: (_authC) {
        return Scaffold(
          backgroundColor: AppColors.background(isDarkMode),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 40.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // زر العودة
                  IconButton(
                    icon: Icon(Icons.arrow_back, size: 28.w, 
                      color: AppColors.textPrimary(isDarkMode)),
                    onPressed: () => Get.back(),
                  ),
                  SizedBox(height: 30.h),
                  
                  // العنوان الرئيسي
                  Text(
                    'إعادة تعيين كلمة المرور'.tr,
                    style: TextStyle(
                      fontSize: AppTextStyles.xxxlarge,

                      fontWeight: FontWeight.bold,
                      fontFamily: AppTextStyles.appFontFamily,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  
                  // وصف التطبيق
                  Text(
                    'أدخل بريدك الإلكتروني لإرسال رمز التحقق وإعادة تعيين كلمة المرور'.tr,
                    style: TextStyle(
                      fontSize: AppTextStyles.large,

                      fontFamily: AppTextStyles.appFontFamily,
                      color: AppColors.textSecondary(isDarkMode),
                    ),
                  ),
                  SizedBox(height: 40.h),
                  
                  // مؤشر التقدم
                  _buildProgressIndicator(isDarkMode, authC),
                  SizedBox(height: 40.h),
                  
                  // محتوى الخطوات
                  if (_authC.currentStep.value == 0) _buildEmailStep(isDarkMode, authC),
                  if (_authC.currentStep.value == 1) _buildVerificationStep(isDarkMode, authC),
                  if (_authC.currentStep.value == 2) _buildPasswordStep(isDarkMode, authC),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressIndicator(bool isDarkMode, AuthController authCrl) {
    Color activeColor = AppColors.primary;
    Color inactiveColor = AppColors.greyLight;

    return Row(
      children: [
        // الخطوة 1 - البريد الإلكتروني
        Expanded(
          child: Column(
            children: [
              CircleAvatar(
                radius: 18.r,
                backgroundColor: authCrl.currentStep.value >= 0 ? activeColor : inactiveColor,
                child: Text(
                  '1',
                  style: TextStyle(
                    color: authCrl.currentStep.value >= 0 ? AppColors.onPrimary : AppColors.onSurfaceLight,
                    fontSize: AppTextStyles.medium,

                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'البريد الإلكتروني'.tr,
                style: TextStyle(
                  fontSize: AppTextStyles.small,

                  fontFamily: AppTextStyles.appFontFamily,
                  color: authCrl.currentStep.value >= 0 ? activeColor : AppColors.textSecondary(isDarkMode),
                ),
              ),
            ],
          ),
        ),
        
        // الخط المتصل بين 1 و 2
        Expanded(
          child: Divider(
            thickness: 2,
            color: authCrl.currentStep.value >= 1 ? activeColor : inactiveColor,
          ),
        ),
        
        // الخطوة 2 - رمز التحقق
        Expanded(
          child: Column(
            children: [
              CircleAvatar(
                radius: 18.r,
                backgroundColor: authCrl.currentStep.value >= 1 ? activeColor : inactiveColor,
                child: Text(
                  '2',
                  style: TextStyle(
                    color: authCrl.currentStep.value >= 1 ? AppColors.onPrimary : AppColors.onSurfaceLight,
                    fontSize: AppTextStyles.medium,

                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'رمز التحقق'.tr,
                style: TextStyle(
                  fontSize: AppTextStyles.small,

                  fontFamily: AppTextStyles.appFontFamily,
                  color: authCrl.currentStep.value >= 1 ? activeColor : AppColors.textSecondary(isDarkMode),
                ),
              ),
            ],
          ),
        ),
        
        // الخط المتصل بين 2 و 3
        Expanded(
          child: Divider(
            thickness: 2,
            color: authCrl.currentStep.value >= 2 ? activeColor : inactiveColor,
          ),
        ),
        
        // الخطوة 3 - كلمة المرور
        Expanded(
          child: Column(
            children: [
              CircleAvatar(
                radius: 18.r,
                backgroundColor: authCrl.currentStep.value >= 2 ? activeColor : inactiveColor,
                child: Text(
                  '3',
                  style: TextStyle(
                    color: authCrl.currentStep.value >= 2 ? AppColors.onPrimary : AppColors.onSurfaceLight,
                    fontSize: AppTextStyles.medium,

                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'كلمة المرور الجديدة'.tr,
                style: TextStyle(
                  fontSize: AppTextStyles.small,

                  fontFamily: AppTextStyles.appFontFamily,
                  color: authCrl.currentStep.value >= 2 ? activeColor : AppColors.textSecondary(isDarkMode),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmailStep(bool isDarkMode, AuthController authCrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // صورة توضيحية
        Center(
          child: Container(
            height: 150.h,
            width: 150.w,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Icon(
              Icons.email_outlined,
              size: 60.w,
              color: AppColors.primary,
            ),
          ),
        ),
        SizedBox(height: 30.h),
        
        // عنوان الخطوة
        Text(
          'أدخل بريدك الإلكتروني'.tr,
          style: TextStyle(
            fontSize: AppTextStyles.xxlarge,

            fontWeight: FontWeight.bold,
            fontFamily: AppTextStyles.appFontFamily,
            color: AppColors.textPrimary(isDarkMode),
          ),
        ),
        SizedBox(height: 10.h),
        
        // نص إرشادي
        Text(
          'سيتم إرسال رمز التحقق إلى بريدك الإلكتروني لتأكيد هويتك'.tr,
          style: TextStyle(
            fontSize: AppTextStyles.medium,

            fontFamily: AppTextStyles.appFontFamily,
            color: AppColors.textSecondary(isDarkMode),
          ),
        ),
        SizedBox(height: 30.h),
        
        // حقل البريد الإلكتروني
        TextFormField(
          controller: authCrl.emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'البريد الإلكتروني'.tr,
            labelStyle: TextStyle(
              fontSize: AppTextStyles.medium,

              fontFamily: AppTextStyles.appFontFamily,
              color: AppColors.textSecondary(isDarkMode),
            ),
            prefixIcon: Icon(Icons.email_outlined, size: 24.w, 
              color: AppColors.textSecondary(isDarkMode)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: AppColors.divider(isDarkMode)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: AppColors.divider(isDarkMode)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: AppColors.primary, width: 1.5),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w, vertical: 16.h),
            fillColor: AppColors.surface(isDarkMode),
            filled: true,
          ),
          style: TextStyle(
            color: AppColors.textPrimary(isDarkMode),
          ),
        ),
        SizedBox(height: 40.h),
        
        // زر المتابعة
        SizedBox(
          width: double.infinity,
          height: 50.h,
          child: ElevatedButton(
            onPressed: authCrl.sendVerificationCodeForReset,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r)),
              elevation: 2,
            ),
            child: authCrl.isLoading.value
              ? SizedBox(
                  width: 24.w,
                  height: 24.h,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
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
        ),
      ],
    );
  }

  Widget _buildVerificationStep(bool isDarkMode, AuthController authCrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // صورة توضيحية
        Center(
          child: Container(
            height: 150.h,
            width: 150.w,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Icon(
              Icons.verified_user_outlined,
              size: 60.w,
              color: AppColors.primary,
            ),
          ),
        ),
        SizedBox(height: 30.h),
        
        // عنوان الخطوة
        Text(
          'أدخل رمز التحقق'.tr,
          style: TextStyle(
            fontSize: AppTextStyles.xxlarge,

            fontWeight: FontWeight.bold,
            fontFamily: AppTextStyles.appFontFamily,
            color: AppColors.textPrimary(isDarkMode),
          ),
        ),
        SizedBox(height: 10.h),
        
        // نص إرشادي
        RichText(
          text: TextSpan(
            text: 'تم إرسال رمز مكون من 6 أرقام إلى '.tr,
            style: TextStyle(
              fontSize: AppTextStyles.medium,

              fontFamily: AppTextStyles.appFontFamily,
              color: AppColors.textSecondary(isDarkMode),
            ),
            children: [
              TextSpan(
                text: authCrl.emailCtrl.text,
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 30.h),
        
        // حقل إدخال رمز التحقق
        TextFormField(
          controller: authCrl.codeCtrl,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: InputDecoration(
            labelText: 'رمز التحقق'.tr,
            labelStyle: TextStyle(
              fontSize: AppTextStyles.medium,

              fontFamily: AppTextStyles.appFontFamily,
              color: AppColors.textSecondary(isDarkMode),
            ),
            prefixIcon: Icon(Icons.lock_outlined, size: 24.w, 
              color: AppColors.textSecondary(isDarkMode)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: AppColors.divider(isDarkMode)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: AppColors.primary, width: 1.5),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w, vertical: 16.h),
            fillColor: AppColors.surface(isDarkMode),
            filled: true,
          ),
          style: TextStyle(
            color: AppColors.textPrimary(isDarkMode),
          ),
        ),
        SizedBox(height: 10.h),
        
        // إعادة إرسال الرمز
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'لم تستلم الرمز؟'.tr,
              style: TextStyle(
                fontSize: AppTextStyles.small,

                fontFamily: AppTextStyles.appFontFamily,
                color: AppColors.textSecondary(isDarkMode),
              ),
            ),
            TextButton(
              onPressed: authCrl.resendCode,
              child: Text(
                'إعادة الإرسال'.tr,
                style: TextStyle(
                  fontSize: AppTextStyles.small,

                  fontWeight: FontWeight.bold,
                  fontFamily: AppTextStyles.appFontFamily,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 30.h),
        
        // زر التحقق
        SizedBox(
          width: double.infinity,
          height: 50.h,
          child: ElevatedButton(
            onPressed: authCrl.verifyCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r)),
              elevation: 2,
            ),
            child: authCrl.isLoading.value
              ? SizedBox(
                  width: 24.w,
                  height: 24.h,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
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
        ),
        SizedBox(height: 20.h),
        
        // العودة لتغيير البريد
        Center(
          child: TextButton(
            onPressed: () => authCrl.currentStep.value = 0,
            child: Text(
              'تغيير البريد الإلكتروني'.tr,
              style: TextStyle(
                fontSize: AppTextStyles.medium,

                fontFamily: AppTextStyles.appFontFamily,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordStep(bool isDarkMode, AuthController authCrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // صورة توضيحية
        Center(
          child: Container(
            height: 150.h,
            width: 150.w,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Icon(
              Icons.lock_reset,
              size: 60.w,
              color: AppColors.primary,
            ),
          ),
        ),
        SizedBox(height: 30.h),
        
        // عنوان الخطوة
        Text(
          'أنشئ كلمة مرور جديدة'.tr,
          style: TextStyle(
            fontSize: AppTextStyles.xxlarge,

            fontWeight: FontWeight.bold,
            fontFamily: AppTextStyles.appFontFamily,
            color: AppColors.textPrimary(isDarkMode),
          ),
        ),
        SizedBox(height: 10.h),
        
        // نص إرشادي
        Text(
          'كلمة المرور يجب أن تحتوي على 6 أحرف على الأقل'.tr,
          style: TextStyle(
            fontSize: AppTextStyles.medium,

            fontFamily: AppTextStyles.appFontFamily,
            color: AppColors.textSecondary(isDarkMode),
          ),
        ),
        SizedBox(height: 30.h),
        
        // حقل كلمة المرور
        Obx(() => TextFormField(
          controller: authCrl.passwordCtrl,
          obscureText: !authCrl.showPassword.value,
          onChanged: authCrl.validatePassword,
          decoration: InputDecoration(
            labelText: 'كلمة المرور الجديدة'.tr,
            labelStyle: TextStyle(
              fontSize: AppTextStyles.medium,

              fontFamily: AppTextStyles.appFontFamily,
              color: AppColors.textSecondary(isDarkMode),
            ),
            prefixIcon: Icon(Icons.lock_outline, size: 24.w, 
              color: AppColors.textSecondary(isDarkMode)),
            suffixIcon: IconButton(
              icon: Icon(
                authCrl.showPassword.value ? Icons.visibility : Icons.visibility_off,
                color: AppColors.textSecondary(isDarkMode),
              ),
              onPressed: () => authCrl.showPassword.toggle(),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: AppColors.divider(isDarkMode)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: AppColors.primary, width: 1.5),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w, vertical: 16.h),
            fillColor: AppColors.surface(isDarkMode),
            filled: true,
          ),
          style: TextStyle(
            color: AppColors.textPrimary(isDarkMode),
          ),
        )),
        SizedBox(height: 10.h),
        
        // مؤشر قوة كلمة المرور
        Obx(() => Text(
          authCrl.isPasswordValid.value 
            ? 'كلمة المرور صالحة'.tr
            : 'كلمة المرور يجب أن تحتوي على 6 أحرف على الأقل'.tr,
          style: TextStyle(
            fontSize: AppTextStyles.small,

            color: authCrl.isPasswordValid.value 
              ? AppColors.success 
              : AppColors.textSecondary(isDarkMode),
          ),
        )),
        SizedBox(height: 30.h),
        
        // زر إعادة التعيين
     SizedBox(
  width: double.infinity,
  height: 50.h,
  child: ElevatedButton(
    onPressed: authCrl.isPasswordValid.value
      ? () async {
          final result = await authCrl.resetGooglePassword(
            email: authCrl.emailCtrl.text,
            code: authCrl.codeCtrl.text,
            password: authCrl.passwordCtrl.text,
          );
          
          if (result['status'] == true) {
            Get.offAll(() => PasswordResetSuccessScreen());
          } else {
            // عرض رسالة الخطأ مع التفاصيل
            final errorDetails = result['error'] ?? result['message'];
            Get.snackbar(
              'خطأ'.tr,
              errorDetails,
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: AppColors.error.withOpacity(0.2),
              colorText: AppColors.error,
              duration: Duration(seconds: 5),
              mainButton: TextButton(
                onPressed: () {
                  // نسخ تفاصيل الخطأ للحافظة
                  Clipboard.setData(ClipboardData(text: errorDetails));
                  Get.back();
                },
                child: Text('نسخ التفاصيل'),
              ),
            );
          }
        }
      : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: authCrl.isPasswordValid.value 
                ? AppColors.primary 
                : AppColors.primary.withOpacity(0.5),
              foregroundColor: AppColors.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r)),
              elevation: 2,
            ),
            child: authCrl.isLoading.value
              ? SizedBox(
                  width: 24.w,
                  height: 24.h,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  'إعادة تعيين كلمة المرور'.tr,
                  style: TextStyle(
                    fontSize: AppTextStyles.large,

                    fontWeight: FontWeight.bold,
                    fontFamily: AppTextStyles.appFontFamily,
                  ),
                ),
          ),
        ),
        SizedBox(height: 20.h),
        
        // العودة للخطوة السابقة
        Center(
          child: TextButton(
            onPressed: () => authCrl.prevStep(),
            child: Text(
              'العودة'.tr,
              style: TextStyle(
                fontSize: AppTextStyles.medium,

                fontFamily: AppTextStyles.appFontFamily,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class PasswordResetSuccessScreen extends StatelessWidget {
  const PasswordResetSuccessScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Get.find<ThemeController>().isDarkMode.value;

    return Scaffold(
      backgroundColor: AppColors.background(isDarkMode),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 30.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // أيقونة نجاح
              Icon(
                Icons.check_circle_outline,
                size: 100.w,
                color: AppColors.success,
              ),
              SizedBox(height: 30.h),
              
              // رسالة التهنئة
              Text(
                'تم إعادة تعيين كلمة المرور بنجاح'.tr,
                style: TextStyle(
                  fontSize: AppTextStyles.xxxlarge,

                  fontWeight: FontWeight.bold,
                  fontFamily: AppTextStyles.appFontFamily,
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20.h),
              
              // نص توجيهي
              Text(
                'يمكنك الآن تسجيل الدخول باستخدام كلمة المرور الجديدة'.tr,
                style: TextStyle(
                  fontSize: AppTextStyles.large,

                  fontFamily: AppTextStyles.appFontFamily,
                  color: AppColors.textSecondary(isDarkMode),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40.h),
              
              // زر تسجيل الدخول
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  onPressed: () => Get.offAll(() => HomeScreen()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    'تسجيل الدخول'.tr,
                    style: TextStyle(
                      fontSize: AppTextStyles.large,

                      fontWeight: FontWeight.bold,
                      fontFamily: AppTextStyles.appFontFamily,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              
              // زر العودة للرئيسية
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: OutlinedButton(
                  onPressed: () => Get.offAll(() => HomeScreen()),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    'العودة للرئيسية'.tr,
                    style: TextStyle(
                      fontSize: AppTextStyles.large,

                      fontWeight: FontWeight.bold,
                      fontFamily: AppTextStyles.appFontFamily,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}