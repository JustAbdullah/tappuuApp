import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tappuu_app/core/constant/app_text_styles.dart';
import 'package:tappuu_app/core/constant/appcolors.dart';
import 'package:tappuu_app/controllers/ThemeController.dart';
import 'package:tappuu_app/controllers/AdvertiserController.dart';
import '../../controllers/LoadingController.dart';
import '../HomeScreen/home_screen.dart';

class EditAdvertiserScreen extends StatelessWidget {
  EditAdvertiserScreen({Key? key}) : super(key: key);

  final ThemeController themeC = Get.find<ThemeController>();
  final LoadingController loadingC = Get.find<LoadingController>();
  final AdvertiserController controller = Get.find<AdvertiserController>();

  @override
  Widget build(BuildContext context) {
    final isDarkMode = themeC.isDarkMode.value;

    return Scaffold(
      backgroundColor: AppColors.background(isDarkMode),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.onPrimary),
          onPressed: () {
            Get.back();
            Get.back();
          },
        ),
        title: Text(
          'تعديل بيانات المعلن'.tr,
          style: TextStyle(
            fontSize: AppTextStyles.xxxlarge,
            fontFamily: AppTextStyles.appFontFamily,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary(isDarkMode),
          ),
        ),
        backgroundColor: AppColors.background(isDarkMode),
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // العنوان
              Center(
                child: Text(
                  'تعديل بيانات المعلن'.tr,
                  style: TextStyle(
                    fontSize: AppTextStyles.xxxlarge,
                    fontWeight: FontWeight.bold,
                    fontFamily: AppTextStyles.appFontFamily,
                    color: AppColors.primary,
                  ),
                ),
              ),
              SizedBox(height: 15.h),

              // وصف الصفحة
              Center(
                child: Text(
                  'قم بتحديث بياناتك ليظهر للمستخدمين بشكل صحيح'.tr,
                  style: TextStyle(
                    fontSize: AppTextStyles.large,
                    fontFamily: AppTextStyles.appFontFamily,
                    color: AppColors.textSecondary(isDarkMode),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 30.h),

              // حقل الشعار
              Center(
                child: Column(
                  children: [
                    Text(
                      'شعار المعلن (اختياري)'.tr,
                      style: TextStyle(
                        fontSize: AppTextStyles.xlarge,
                        fontWeight: FontWeight.w600,
                        fontFamily: AppTextStyles.appFontFamily,
                        color: AppColors.textPrimary(isDarkMode),
                      ),
                    ),
                    SizedBox(height: 15.h),

                    // تصميم دائرة الشعار
                    Obx(() {
                      return Container(
                        width: 180.w,
                        height: 180.h,
                        decoration: BoxDecoration(
                          color: AppColors.surface(isDarkMode),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.5),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            )
                          ],
                        ),
                        child: Stack(
                          children: [
                            // عرض الصورة الحالية أو المختارة
                            if (controller.logoPath.value != null)
                              ClipOval(
                                child: Image.file(
                                  controller.logoPath.value!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              )
                            else if (controller.uploadedImageUrls.value.isNotEmpty)
                              ClipOval(
                                child: Image.network(
                                  controller.uploadedImageUrls.value,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  errorBuilder: (context, error, stackTrace) {
                                    return _buildPlaceholderIcon(isDarkMode);
                                  },
                                ),
                              )
                            else if (controller.originalProfileForEdit?.logo != null &&
                                controller.originalProfileForEdit!.logo!.isNotEmpty)
                              ClipOval(
                                child: Image.network(
                                  controller.originalProfileForEdit!.logo!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  errorBuilder: (context, error, stackTrace) {
                                    return _buildPlaceholderIcon(isDarkMode);
                                  },
                                ),
                              )
                            else
                              _buildPlaceholderIcon(isDarkMode),

                            // زر إضافة/تغيير الصورة
                            Positioned.fill(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(100),
                                  onTap: () => controller.pickLogo(),
                                  child: controller.logoPath.value == null && 
                                         controller.uploadedImageUrls.value.isEmpty && 
                                         (controller.originalProfileForEdit?.logo == null || 
                                          controller.originalProfileForEdit!.logo!.isEmpty)
                                      ? Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.add_a_photo,
                                                size: 40.w,
                                                color: AppColors.primary,
                                              ),
                                              SizedBox(height: 8.h),
                                              Text(
                                                'تغيير الشعار'.tr,
                                                style: TextStyle(
                                                  fontSize: AppTextStyles.medium,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : Container(),
                                ),
                              ),
                            ),
                            
                            // زر إزالة الصورة
                            if (controller.logoPath.value != null || 
                                controller.uploadedImageUrls.value.isNotEmpty ||
                                (controller.originalProfileForEdit?.logo != null && 
                                 controller.originalProfileForEdit!.logo!.isNotEmpty))
                              Positioned(
                                bottom: 8.h,
                                right: 8.w,
                                child: FloatingActionButton(
                                  mini: true,
                                  backgroundColor: Colors.red,
                                  onPressed: () => controller.removeLogo(),
                                  child: Icon(Icons.close, color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                    SizedBox(height: 20.h),
                    Text(
                      'اضغط على الدائرة لتغيير الشعار'.tr,
                      style: TextStyle(
                        fontSize: AppTextStyles.medium,
                        color: AppColors.textSecondary(isDarkMode),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30.h),

              // حقل نوع الحساب
              _buildAccountTypeField(controller, isDarkMode),
              SizedBox(height: 25.h),

              // حقل اسم المعلن
              _buildInputField(
                title: 'اسم المعلن*'.tr,
                hint: controller.accountType.value == 'individual' 
                  ? 'أدخل اسمك الشخصي'.tr 
                  : 'أدخل اسم الشركة أو المؤسسة'.tr,
                icon: Icons.business,
                controller: controller.businessNameCtrl,
                isDarkMode: isDarkMode,
                onChanged: (value) => controller.updateButton(),
              ),
              SizedBox(height: 25.h),

              // حقل الوصف
              _buildInputField(
                title: 'وصف المعلن'.tr,
                hint: controller.accountType.value == 'individual' 
                  ? 'أدخل وصفًا مختصرًا عن نشاطك'.tr 
                  : 'أدخل وصفًا مختصرًا عن نشاط الشركة'.tr,
                icon: Icons.description,
                controller: controller.descriptionCtrl,
                isDarkMode: isDarkMode,
                maxLines: 3,
              ),
              SizedBox(height: 25.h),

              // حقل رقم الاتصال
              _buildInputField(
                title: 'رقم الاتصال*'.tr,
                hint: 'مثال: 00963XXXXXXXX'.tr,
                icon: Icons.phone,
                controller: controller.contactPhoneCtrl,
                isDarkMode: isDarkMode,
                keyboardType: TextInputType.phone,
                onChanged: (value) => controller.updateButton(),
              ),
              SizedBox(height: 25.h),

              // حقل واتساب
              _buildInputField(
                title: 'رقم الواتساب (اختياري)'.tr,
                hint: 'مثال: 00963XXXXXXXX'.tr,
                icon: Icons.wallet,
                controller: controller.whatsappPhoneCtrl,
                isDarkMode: isDarkMode,
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 25.h),

              // حقل الاتصال المباشر بالواتساب (جديد)
              _buildInputField(
                title: 'رقم الاتصال المباشر بالواتساب (اختياري)'.tr,
                hint: 'مثال: 00963XXXXXXXX'.tr,
                icon: Icons.phone_android,
                controller: controller.whatsappCallNumberCtrl,
                isDarkMode: isDarkMode,
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 30.h),

              // زر الحفظ
              GetBuilder<AdvertiserController>(
                id: 'button',
                builder: (btnController) {
                  final isValid = btnController.businessNameCtrl.text.isNotEmpty &&
                                 btnController.contactPhoneCtrl.text.isNotEmpty;
                  
                  final isSaving = btnController.isSaving.value;
                  final userId = loadingC.currentUser?.id ?? 0;
                  
                  return SizedBox(
                    width: double.infinity,
                    height: 55.h,
                    child: ElevatedButton(
                      onPressed: (isValid && !isSaving)
                          ? () => btnController.saveProfileChanges(userId)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (isValid && !isSaving)
                            ? AppColors.primary
                            : AppColors.primary.withOpacity(0.4),
                        foregroundColor: AppColors.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                        elevation: (isValid && !isSaving) ? 4 : 0,
                        shadowColor: AppColors.primary.withOpacity(0.3),
                      ),
                      child: isSaving
                          ? CircularProgressIndicator(
                              color: AppColors.onPrimary,
                              strokeWidth: 3,
                            )
                          : Text(
                              'حفظ التعديلات'.tr,
                              style: TextStyle(
                                fontSize: AppTextStyles.xlarge,
                                fontWeight: FontWeight.bold,
                                fontFamily: AppTextStyles.appFontFamily,
                              ),
                            ),
                    ),
                  );
                },
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountTypeField(AdvertiserController controller, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'نوع الحساب*'.tr,
          style: TextStyle(
            fontSize: AppTextStyles.xlarge,
            fontWeight: FontWeight.w600,
            fontFamily: AppTextStyles.appFontFamily,
            color: AppColors.textPrimary(isDarkMode),
          ),
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: _buildAccountTypeChoice(
                title: 'فردي'.tr,
                isSelected: controller.accountType.value == 'individual',
                onTap: () => controller.setAccountType('individual'),
                isDarkMode: isDarkMode,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: _buildAccountTypeChoice(
                title: 'شركة'.tr,
                isSelected: controller.accountType.value == 'company',
                onTap: () => controller.setAccountType('company'),
                isDarkMode: isDarkMode,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAccountTypeChoice({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 8.w),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : AppColors.surface(isDarkMode),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.textSecondary(isDarkMode).withOpacity(0.5),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: AppTextStyles.large,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? AppColors.onPrimary
                  : AppColors.textPrimary(isDarkMode),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderIcon(bool isDarkMode) {
    return Center(
      child: Icon(
        Icons.business,
        size: 60.w,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildInputField({
    required String title,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    required bool isDarkMode,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: AppTextStyles.xlarge,
            fontWeight: FontWeight.w600,
            fontFamily: AppTextStyles.appFontFamily,
            color: AppColors.textPrimary(isDarkMode),
          ),
        ),
        SizedBox(height: 12.h),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: AppTextStyles.medium,
              fontFamily: AppTextStyles.appFontFamily,
              color: AppColors.textSecondary(isDarkMode),
            ),
            prefixIcon: Icon(icon,
                size: 24.w, color: AppColors.textSecondary(isDarkMode)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: AppColors.surface(isDarkMode),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
          style: TextStyle(
            fontSize: AppTextStyles.large,
            color: AppColors.textPrimary(isDarkMode),
          ),
        ),
      ],
    );
  }
}