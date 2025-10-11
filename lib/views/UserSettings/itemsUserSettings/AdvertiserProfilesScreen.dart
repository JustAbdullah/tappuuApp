import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tappuu_app/core/constant/app_text_styles.dart';
import 'package:tappuu_app/core/constant/appcolors.dart';
import 'package:tappuu_app/controllers/ThemeController.dart';
import 'package:tappuu_app/controllers/AdvertiserController.dart';
import 'package:tappuu_app/views/HomeScreen/home_screen.dart';
import '../../../controllers/LoadingController.dart';
import '../../../core/data/model/AdvertiserProfile.dart';
import '../../AdvertiserScreen/AdvertiserDataScreen.dart';
import '../../AdvertiserScreen/EditAdvertiserScreen.dart';

class AdvertiserProfilesScreen extends StatefulWidget {
  const AdvertiserProfilesScreen({Key? key}) : super(key: key);

  @override
  State<AdvertiserProfilesScreen> createState() => _AdvertiserProfilesScreenState();
}

class _AdvertiserProfilesScreenState extends State<AdvertiserProfilesScreen> {
  final ThemeController themeC = Get.find<ThemeController>();
  final AdvertiserController advC = Get.put(AdvertiserController(), permanent: true);
  final LoadingController loadingC = Get.find<LoadingController>();

  @override
  void initState() {
    super.initState();
    _fetchProfiles();
  }

  void _fetchProfiles() {
    final userId = loadingC.currentUser?.id ?? 0;
    if (userId > 0) {
      advC.fetchProfiles(userId).then((_) {
        // إعادة تعيين الحالة عند الدخول
        advC.resetSelection();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = themeC.isDarkMode.value;

    return Scaffold(
      backgroundColor: AppColors.background(isDarkMode),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            advC.resetSelection();
            Get.back();
            Get.back();
          },
        ),
        title: Text(
          'ملفات المعلنين'.tr,
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
      body: GetBuilder<AdvertiserController>(
        builder: (controller) {
          if (controller.isLoading.value) {
            return Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            );
          }

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    'ملفات المعلنين الخاصة بك'.tr,
                    style: TextStyle(
                      fontSize: AppTextStyles.xxxlarge,
                      fontWeight: FontWeight.bold,
                      fontFamily: AppTextStyles.appFontFamily,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                SizedBox(height: 15.h),

                Center(
                  child: Text(
                    'اختر ملفًا لعرض تفاصيله أو قم بإنشاء ملف جديد'.tr,
                    style: TextStyle(
                      fontSize: AppTextStyles.large,
                      fontFamily: AppTextStyles.appFontFamily,
                      color: AppColors.textSecondary(isDarkMode),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 30.h),

                // القائمة المنسدلة مع تحسينات
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface(isDarkMode),
                    borderRadius: BorderRadius.circular(14.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                  child: _buildDropdown(controller, isDarkMode),
                ),
                SizedBox(height: 30.h),

                if (controller.selected.value != null)
                  _buildProfileCard(
                    controller.selected.value!,
                    isDarkMode,
                  ),
                
                SizedBox(height: 30.h),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      controller.resetSelection();
                      Get.to(()=> AdvertiserDataScreen());
                    },
                    icon: Icon(Icons.add, size: 24.w),
                    label: Text(
                      'إنشاء ملف جديد'.tr,
                      style: TextStyle(
                        fontSize: AppTextStyles.xlarge,
                        fontFamily: AppTextStyles.appFontFamily,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      padding: EdgeInsets.symmetric(
                        horizontal: 30.w, vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDropdown(AdvertiserController controller, bool isDarkMode) {
    if (controller.profiles.isEmpty) {
      return Text(
        'لا توجد ملفات متاحة'.tr,
        style: TextStyle(
          fontSize: AppTextStyles.large,
          fontFamily: AppTextStyles.appFontFamily,
          color: AppColors.textSecondary(isDarkMode),
        ),
      );
    }

    return DropdownButton<AdvertiserProfile>(
      isExpanded: true,
      value: controller.selected.value,
      underline: SizedBox(),
      dropdownColor: AppColors.surface(isDarkMode),
      icon: Icon(Icons.arrow_drop_down, color: AppColors.textPrimary(isDarkMode)),
      iconSize: 30.w,
      hint: Text(
        'اختر ملف المعلن'.tr,
        style: TextStyle(
          fontSize: AppTextStyles.large,
          fontFamily: AppTextStyles.appFontFamily,
          color: AppColors.textSecondary(isDarkMode),
        ),
      ),
      items: controller.profiles.map((profile) {
        return DropdownMenuItem<AdvertiserProfile>(
          value: profile,
          child: Text(
            profile.name ?? profile.description ?? '${'ملف بدون وصف (ID:'.tr} ${profile.id})',
            style: TextStyle(
              fontSize: AppTextStyles.large,
              fontFamily: AppTextStyles.appFontFamily,
              color: AppColors.textPrimary(isDarkMode),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (AdvertiserProfile? newValue) {
        controller.selected.value = newValue;
        controller.update();
      },
    );
  }

  Widget _buildProfileCard(AdvertiserProfile profile, bool isDarkMode) {
    // تحديد لون ونص نوع الحساب
    final accountTypeInfo = _getAccountTypeInfo(profile.accountType, isDarkMode);
    
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card(isDarkMode),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: Offset(0, 6),
          )
        ],
      ),
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // رأس البطاقة مع نوع الحساب
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name ?? 'بدون اسم'.tr,
                      style: TextStyle(
                        fontSize: AppTextStyles.xxlarge,
                        fontWeight: FontWeight.bold,
                        fontFamily: AppTextStyles.appFontFamily,
                        color: AppColors.primary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    if (profile.description != null && profile.description!.isNotEmpty)
                      Text(
                        profile.description!,
                        style: TextStyle(
                          fontSize: AppTextStyles.large,
                          fontFamily: AppTextStyles.appFontFamily,
                          color: AppColors.textPrimary(isDarkMode),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              SizedBox(width: 10.w),
              // شارة نوع الحساب
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: accountTypeInfo.color,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  accountTypeInfo.text,
                  style: TextStyle(
                    fontSize: AppTextStyles.small,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),

          // صورة الشعار إذا كانت متوفرة
          if (profile.logo != null && profile.logo!.isNotEmpty)
            Center(
              child: Container(
                width: 100.w,
                height: 100.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: Image.network(
                    profile.logo!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.business,
                        size: 40.w,
                        color: AppColors.primary,
                      );
                    },
                  ),
                ),
              ),
            ),
          SizedBox(height: 20.h),

          Text(
            'معلومات الاتصال'.tr,
            style: TextStyle(
              fontSize: AppTextStyles.xlarge,
              fontWeight: FontWeight.bold,
              fontFamily: AppTextStyles.appFontFamily,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: 12.h),
          
          _buildInfoRow(
            icon: Icons.phone,
            label: 'رقم الاتصال'.tr,
            value: profile.contactPhone ?? 'غير محدد'.tr,
            isDarkMode: isDarkMode,
          ),
          
          _buildInfoRow(
            icon: Icons.wallet,
            label: 'واتساب'.tr,
            value: profile.whatsappPhone ?? 'غير محدد'.tr,
            isDarkMode: isDarkMode,
          ),
          
          // حقل الاتصال المباشر بالواتساب (جديد)
          _buildInfoRow(
            icon: Icons.phone_android,
            label: 'الاتصال المباشر بالواتساب'.tr,
            value: profile.whatsappCallNumber ?? 'غير محدد'.tr,
            isDarkMode: isDarkMode,
          ),
          
          SizedBox(height: 20.h),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // زر التعديل
              ElevatedButton.icon(
                onPressed: () {
                  advC.loadProfileForEdit(profile);
                  Get.to(() => EditAdvertiserScreen());
                },
                icon: Icon(Icons.edit, size: 20.w),
                label: Text('تعديل'.tr),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.yellow,
                  foregroundColor: AppColors.onSecondary,
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                ),
              ),
              
              ElevatedButton.icon(
                onPressed: () {
                  if (profile.id != null) {
                    // تأكيد قبل الحذف
                    Get.defaultDialog(
                      title: "تأكيد الحذف".tr,
                      middleText: "هل أنت متأكد أنك تريد حذف هذا الملف؟".tr,
                      textConfirm: "نعم".tr,
                      textCancel: "إلغاء".tr,
                      confirmTextColor: Colors.white,
                      onConfirm: () {
                        advC.deleteProfile(profile.id!);
                        Get.back();
                      },
                    );
                  }
                },
                icon: Icon(Icons.delete, size: 20.w),
                label: Text('حذف'.tr),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // دالة مساعدة للحصول على معلومات نوع الحساب
  _AccountTypeInfo _getAccountTypeInfo(String? accountType, bool isDarkMode) {
    switch (accountType) {
      case 'company':
        return _AccountTypeInfo(
          text: 'شركة'.tr,
          color: Colors.blue[700]!,
        );
      case 'individual':
      default:
        return _AccountTypeInfo(
          text: 'فردي'.tr,
          color: Colors.green[700]!,
        );
    }
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDarkMode,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 24.w,
            color: AppColors.primary,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: AppTextStyles.medium,
                    fontFamily: AppTextStyles.appFontFamily,
                    color: AppColors.textSecondary(isDarkMode),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: AppTextStyles.large,
                    fontWeight: FontWeight.w600,
                    fontFamily: AppTextStyles.appFontFamily,
                    color: AppColors.textPrimary(isDarkMode),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// كلاس مساعد لتخزين معلومات نوع الحساب
class _AccountTypeInfo {
  final String text;
  final Color color;

  _AccountTypeInfo({required this.text, required this.color});
}