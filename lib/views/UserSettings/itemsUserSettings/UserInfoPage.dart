import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../controllers/LoadingController.dart';
import '../../../controllers/ThemeController.dart';
import '../../../core/constant/app_text_styles.dart';
import '../../../core/constant/appcolors.dart';
import '../../../core/data/model/user.dart';

class UserInfoPage extends StatelessWidget {
  const UserInfoPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    final LoadingController loadingController = Get.find<LoadingController>();
    final isDarkMode = themeController.isDarkMode.value;
    final currentUser = loadingController.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background(isDarkMode),
      appBar: AppBar(
        backgroundColor: AppColors.appBar(isDarkMode),
        title: Text(
          'معلومات الحساب'.tr,
          style: TextStyle(
            fontFamily: AppTextStyles.appFontFamily,
            color: AppColors.onPrimary,
            fontSize: AppTextStyles.xlarge,

          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.onPrimary),
          onPressed: () {
Get.back();
Get.back();

          }
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
        child: currentUser == null
            ? Center(
                child: Text(
                  'لا تتوفر بيانات المستخدم'.tr,
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    fontSize: AppTextStyles.large,

                    color: AppColors.textPrimary(isDarkMode),
                  ),
                ),
              )
            : Card(
                color: AppColors.card(isDarkMode),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoItem(
                        icon: Icons.email,
                        title: 'البريد الإلكتروني'.tr,
                        value: currentUser.email ?? 'غير محدد',
                        isDarkMode: isDarkMode,
                      ),
                      SizedBox(height: 16.h),
                      _buildInfoItem(
                        icon: Icons.calendar_today,
                        title: 'تاريخ التسجيل'.tr,
                        value: _formatDate(currentUser.date),
                        isDarkMode: isDarkMode,
                      ),
                      SizedBox(height: 16.h),
                      _buildInfoItem(
                        icon: Icons.verified_user,
                        title: 'حالة الحساب'.tr,
                        value: _getAccountStatus(currentUser),
                        isDarkMode: isDarkMode,
                      ),
                      SizedBox(height: 16.h),
                      _buildInfoItem(
                        icon: Icons.post_add,
                        title: 'الإعلانات المجانية'.tr,
                        value: _getFreePostsInfo(currentUser),
                        isDarkMode: isDarkMode,
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'غير محدد';
    
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _getAccountStatus(User user) {
    if (user.is_delete == 1) return 'محذوف';
    if (user.is_block == 1) return 'محظور';
    return 'مفعل'.tr;
  }

  String _getFreePostsInfo(User user) {
    final used = user.free_posts_used;
    final max = user.max_free_posts;
    return '$used / $max (${max - used} ${'متبقية'.tr})';
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
    required bool isDarkMode,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: AppColors.primary,
          size: 24.r,
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: AppTextStyles.appFontFamily,
                  fontSize: AppTextStyles.medium,

                  color: AppColors.textSecondary(isDarkMode),
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                value,
                style: TextStyle(
                  fontFamily: AppTextStyles.appFontFamily,
                  fontSize: AppTextStyles.large,

                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary(isDarkMode),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}