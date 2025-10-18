import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tappuu_app/core/constant/app_text_styles.dart';
import 'package:tappuu_app/core/constant/appcolors.dart';
import 'package:tappuu_app/controllers/ThemeController.dart';
import 'package:tappuu_app/controllers/AdvertiserController.dart';
import 'package:tappuu_app/views/HomeScreen/home_screen.dart';
import '../../controllers/LoadingController.dart';
import '../../core/data/model/AdvertiserProfile.dart';

class AdvertiserDataScreen extends StatelessWidget {
  AdvertiserDataScreen({Key? key}) : super(key: key);

  final ThemeController themeC = Get.find<ThemeController>();
  final LoadingController loadingC = Get.find<LoadingController>();

  @override
  Widget build(BuildContext context) {
    final isDarkMode = themeC.isDarkMode.value;
    final AdvertiserController advController = Get.put(AdvertiserController());

    return Scaffold(
      backgroundColor: AppColors.background(isDarkMode),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () { Get.back(); Get.back(); },
        ),
        title: Text(
          'بيانات المعلن'.tr,
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
        child: Obx(() {
          if (advController.isLoading.value) {
            return Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // العنوان
                Center(
                  child: Text(
                    'أنشئ بياناتك كمعلن'.tr,
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
                    'هذه البيانات ستظهر للمستخدمين عند نشر الإعلانات'.tr,
                    style: TextStyle(
                      fontSize: AppTextStyles.large,
                      fontFamily: AppTextStyles.appFontFamily,
                      color: AppColors.textSecondary(isDarkMode),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 30.h),

                // الشعار
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
                      Obx(() => Container(
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
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              )
                            ],
                          ),
                          child: Stack(
                            children: [
                              if (advController.logoPath.value != null)
                                ClipOval(
                                  child: Image.file(
                                    advController.logoPath.value!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                ),
                              Positioned.fill(
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(100),
                                    onTap: () => advController.pickLogo(),
                                    child: advController.logoPath.value == null
                                        ? Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.add_a_photo, size: 40.w, color: AppColors.primary),
                                                SizedBox(height: 8.h),
                                                Text('إضافة شعار'.tr,
                                                    style: TextStyle(
                                                      fontSize: AppTextStyles.medium,
                                                      color: AppColors.primary,
                                                    )),
                                              ],
                                            ),
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                                ),
                              ),
                              if (advController.logoPath.value != null)
                                Positioned(
                                  bottom: 8.h,
                                  right: 8.w,
                                  child: FloatingActionButton(
                                    mini: true,
                                    backgroundColor: AppColors.primary,
                                    onPressed: () => advController.removeLogo(),
                                    child: const Icon(Icons.close, color: Colors.white),
                                  ),
                                ),
                            ],
                          ),
                        )),
                      SizedBox(height: 16.h),
                      Text(
                        'اضغط على الدائرة لإضافة أو تغيير الشعار'.tr,
                        style: TextStyle(
                          fontSize: AppTextStyles.medium,
                          color: AppColors.textSecondary(isDarkMode),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 28.h),

                // نوع الحساب + الحوار المنبثق
                _buildAccountTypeField(context, advController, isDarkMode),
                SizedBox(height: 22.h),

                // اسم المعلن
                Obx(() => _buildInputField(
                      title: 'اسم المعلن*'.tr,
                      hint: advController.accountType.value == 'individual'
                          ? 'أدخل اسمك الشخصي'.tr
                          : 'أدخل اسم الشركة أو المؤسسة'.tr,
                      icon: Icons.business,
                      controller: advController.businessNameCtrl,
                      isDarkMode: isDarkMode,
                      onChanged: (value) => advController.updateButton(),
                    )),
                SizedBox(height: 18.h),

                // اسم المالك يظهر بأنيميشن لما النوع = شركة
                Obx(() {
                  final isCompany = advController.accountType.value == 'company';
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, anim) =>
                        SizeTransition(sizeFactor: CurvedAnimation(parent: anim, curve: Curves.easeOut), child: child),
                    child: isCompany
                        ? Padding(
                            key: const ValueKey('ownerField'),
                            padding: EdgeInsets.only(top: 6.h),
                            child: _buildInputField(
                              title: 'اسم المالك*'.tr,
                              hint: 'أدخل أسم المالك هنا'.tr,
                              icon: Icons.person,
                              controller: advController.ownerDisplayNameCtrl,
                              isDarkMode: isDarkMode,
                              onChanged: (_) => advController.updateButton(),
                            ),
                          )
                        : const SizedBox.shrink(key: ValueKey('emptyOwnerField')),
                  );
                }),
                SizedBox(height: 22.h),

                // الوصف
                Obx(() => _buildInputField(
                      title: 'وصف المعلن (اختياري)'.tr,
                      hint: advController.accountType.value == 'individual'
                          ? 'أدخل وصفًا مختصرًا عن نشاطك'.tr
                          : 'أدخل وصفًا مختصرًا عن نشاط الشركة'.tr,
                      icon: Icons.description,
                      controller: advController.descriptionCtrl,
                      isDarkMode: isDarkMode,
                      maxLines: 3,
                    )),
                SizedBox(height: 18.h),

                // الهاتف
                _buildInputField(
                  title: 'رقم الاتصال*'.tr,
                  hint: 'مثال: 00963XXXXXXXX'.tr,
                  icon: Icons.phone,
                  controller: advController.contactPhoneCtrl,
                  isDarkMode: isDarkMode,
                  keyboardType: TextInputType.phone,
                  onChanged: (value) => advController.updateButton(),
                ),
                SizedBox(height: 18.h),

                // واتساب (اختياري)
                _buildInputField(
                  title: 'رقم الواتساب (اختياري)'.tr,
                  hint: 'مثال: 00963XXXXXXXXXXXXXXXX'.tr,
                  icon: Icons.wallet, // لو تبغيه WhatsApp: Icons.whatsapp (لو عندك الأيقونة)
                  controller: advController.whatsappPhoneCtrl,
                  isDarkMode: isDarkMode,
                  keyboardType: TextInputType.phone,
                ),
                SizedBox(height: 18.h),

                // واتساب اتصال مباشر
                _buildInputField(
                  title: 'رقم الاتصال المباشر بالواتساب (اختياري)'.tr,
                  hint: 'مثال: 00963XXXXXXXXXXXXXXXX'.tr,
                  icon: Icons.phone_in_talk,
                  controller: advController.whatsappCallNumberCtrl,
                  isDarkMode: isDarkMode,
                  keyboardType: TextInputType.phone,
                ),
                SizedBox(height: 28.h),

                // زر الحفظ
                GetBuilder<AdvertiserController>(
                  id: 'button',
                  builder: (btnController) {
                    final isCompany = btnController.accountType.value == 'company';
                    final baseValid = btnController.businessNameCtrl.text.isNotEmpty &&
                        btnController.contactPhoneCtrl.text.isNotEmpty;
                    final isValid = isCompany
                        ? (baseValid && btnController.ownerDisplayNameCtrl.text.trim().isNotEmpty)
                        : baseValid;

                    final isSaving = btnController.isSaving.value;

                    return SizedBox(
                      width: double.infinity,
                      height: 56.h,
                      child: ElevatedButton(
                        onPressed: (isValid && !isSaving)
                            ? () async {
                                try {
                                  // بدل setSaving(true)
                                  btnController.isSaving.value = true;
                                  btnController.update(['button']);

                                  if (btnController.logoPath.value != null) {
                                    await btnController.uploadLogoToServer();
                                  }

                                  final profile = AdvertiserProfile(
                                    userId: loadingC.currentUser?.id ?? 0,
                                    logo: btnController.uploadedImageUrls.value,
                                    name: btnController.businessNameCtrl.text,
                                    description: btnController.descriptionCtrl.text,
                                    contactPhone: btnController.contactPhoneCtrl.text,
                                    whatsappPhone: btnController.whatsappPhoneCtrl.text,
                                    whatsappCallNumber: btnController.whatsappCallNumberCtrl.text,
                                    accountType: btnController.accountType.value,
                                  );

                                  // ملاحظة: احرص أن الكنترولر يرسل owner_display_name عند النوع = شركة
                                  await btnController.createProfile(profile);
                                  Get.offAll(() => HomeScreen());
                                } catch (e) {
                                  Get.snackbar('خطأ'.tr, '${'فشل في حفظ البيانات:'.tr}');
                                  print(e);
                                } finally {
                                  // بدل setSaving(false)
                                  btnController.isSaving.value = false;
                                  btnController.update(['button']);
                                }
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: (isValid && !isSaving)
                              ? AppColors.primary
                              : AppColors.primary.withOpacity(0.4),
                          foregroundColor: AppColors.onPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                          elevation: (isValid && !isSaving) ? 4 : 0,
                          shadowColor: AppColors.primary.withOpacity(0.25),
                        ),
                        child: isSaving
                            ? CircularProgressIndicator(color: AppColors.onPrimary, strokeWidth: 3)
                            : Text('حفظ البيانات'.tr,
                                style: TextStyle(
                                  fontSize: AppTextStyles.xlarge,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: AppTextStyles.appFontFamily,
                                )),
                      ),
                    );
                  },
                ),
                SizedBox(height: 16.h),

                Center(
                  child: Text(
                    '* الحقول الإلزامية'.tr,
                    style: TextStyle(
                      fontSize: AppTextStyles.medium,
                      fontFamily: AppTextStyles.appFontFamily,
                      color: AppColors.textSecondary(isDarkMode),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  /// نوع الحساب — مع نافذة منبثقة عند اختيار "شركة"
  Widget _buildAccountTypeField(
      BuildContext context, AdvertiserController controller, bool isDarkMode) {
    return Obx(() => Column(
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
                    onTap: () async {
                      controller.setAccountType('company');
                      await _showCompanyInfoDialog(context, isDarkMode);
                    },
                    isDarkMode: isDarkMode,
                  ),
                ),
              ],
            ),
          ],
        ));
  }

  // ✅ مصححة: Future<void> + await داخلها بدون return
  Future<void> _showCompanyInfoDialog(BuildContext context, bool isDark) async {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'company_info',
      barrierColor: Colors.black.withOpacity(0.45),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, __, ___) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
        return Transform.scale(
          scale: 0.95 + (0.05 * curved.value),
          child: Opacity(
            opacity: curved.value,
            child: Center(
              child: Material(
                color: AppColors.surface(isDark),
                elevation: 12,
                borderRadius: BorderRadius.circular(18.r),
                child: Container(
                  width: 0.9.sw,
                  padding: EdgeInsets.all(18.w),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18.r),
                    border: Border.all(color: AppColors.primary.withOpacity(0.15), width: 1),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(10.w),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary.withOpacity(0.12),
                            ),
                            child: Icon(Icons.apartment, color: AppColors.primary, size: 22.w),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(
                              'حساب شركة — ماذا تستفيد؟'.tr,
                              style: TextStyle(
                                
                                fontSize: AppTextStyles.xlarge,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary(isDark),
                                fontFamily: AppTextStyles.appFontFamily,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(ctx).maybePop(),
                            icon: Icon(Icons.close, color: AppColors.textSecondary(isDark)),
                          )
                        ],
                      ),
                      SizedBox(height: 12.h),

                      _featureRow(isDark, Icons.group_add, 'دعوات متعددة تحت مظلة الشركة'.tr,
                          'أضف أعضاء بفئات صلاحيات مختلفة للنشر والمتابعة.'.tr),
                      _featureRow(isDark, Icons.verified_user, 'صلاحيات مرنة'.tr,
                          'مالك / ناشر / عارض — تحكم في من ينشر ومن يشاهد.'.tr),
                      _featureRow(isDark, Icons.campaign, 'إعلانات لكل عضو'.tr,
                          'كل عضو ينشر بإسم الشركة ويظهر اسمه عند التواصل.'.tr),
                   

                      SizedBox(height: 10.h),
                      Divider(color: AppColors.textSecondary(isDark).withOpacity(0.2)),
                      SizedBox(height: 10.h),

                  
                      SizedBox(height: 14.h),

                      SizedBox(
                        width: double.infinity,
                        height: 48.h,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(ctx).maybePop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.onPrimary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                          ),
                          child: Text('إغلاق'.tr,
                              style: TextStyle(fontSize: AppTextStyles.large, fontWeight: FontWeight.w700,                      fontFamily: AppTextStyles.appFontFamily,
)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 260),
    );
  }

  Widget _featureRow(bool isDark, IconData icon, String title, String subtitle) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20.w),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                                            fontFamily: AppTextStyles.appFontFamily,

                      fontSize: AppTextStyles.large,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary(isDark),
                    )),
                SizedBox(height: 4.h),
                Text(subtitle,
                    style: TextStyle(
                      fontSize: AppTextStyles.medium,
                      color: AppColors.textSecondary(isDark),
                    )),
              ],
            ),
          ),
        ],
      ),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 10.w),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface(isDarkMode),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.textSecondary(isDarkMode).withOpacity(0.5),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppColors.primary.withOpacity(0.18), blurRadius: 12, offset: const Offset(0, 6))]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              title == 'شركة'.tr ? Icons.apartment : Icons.person,
              color: isSelected ? AppColors.onPrimary : AppColors.textPrimary(isDarkMode),
              size: 20.w,
            ),
            SizedBox(width: 8.w),
            Text(
              title,
              style: TextStyle(
                fontSize: AppTextStyles.large,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.onPrimary : AppColors.textPrimary(isDarkMode),
              ),
            ),
          ],
        ),
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
        SizedBox(height: 10.h),
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
            prefixIcon: Icon(icon, size: 22.w, color: AppColors.textSecondary(isDarkMode)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: BorderSide.none),
            filled: true,
            fillColor: AppColors.surface(isDarkMode),
            contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
          style: TextStyle(fontSize: AppTextStyles.large, color: AppColors.textPrimary(isDarkMode)),
        ),
      ],
    );
  }
}
