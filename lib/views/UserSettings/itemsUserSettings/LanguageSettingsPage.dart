import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:tappuu_app/controllers/LoadingController.dart';
import 'package:tappuu_app/controllers/home_controller.dart';
import 'package:tappuu_app/views/HomeScreen/home_screen.dart';
import '../../../controllers/AdsManageSearchController.dart';
import '../../../controllers/BrowsingHistoryController.dart';
import '../../../controllers/FavoritesController.dart';
import '../../../controllers/PopularHistoryController.dart';
import '../../../controllers/ThemeController.dart';
import '../../../controllers/ViewsController.dart';
import '../../../core/constant/app_text_styles.dart';
import '../../../core/constant/appcolors.dart';
import '../../../core/localization/changelanguage.dart';

class LanguageSettingsPage extends StatelessWidget {
  const LanguageSettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    final ChangeLanguageController languageController = Get.find<ChangeLanguageController>();
    final isDarkMode = themeController.isDarkMode.value;
    final HomeController homeController = Get.find<HomeController>();



    return Scaffold(
      backgroundColor: AppColors.background(isDarkMode),
      appBar: AppBar(
        backgroundColor: AppColors.appBar(isDarkMode),
        title: Text(
          'إعدادت اللغة'.tr,
          style: TextStyle(
            fontFamily: AppTextStyles.appFontFamily,
            color: AppColors.onPrimary,
            fontSize: AppTextStyles.xlarge,

          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.onPrimary),
          onPressed: () =>Get.back()
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
        child: Column(
          children: [
            Card(
              color: AppColors.card(isDarkMode),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Column(
                children: [
                  _buildLanguageOption(
                    homeController: homeController,
                    context: context,
                    title: 'العربية'.tr,
                    code: 'ar',
                    flag: '🇸🇾', // علم سوريا
                    isSelected: languageController.currentLocale.value.languageCode == 'ar',
                    isDarkMode: isDarkMode,
                  ),
                  Divider(height: 1, color: AppColors.divider(isDarkMode).withOpacity(0.2)),
                  _buildLanguageOption(
                    homeController: homeController,
                    context: context,
                    title: 'English',
                    code: 'en',
                    flag: '🇬🇧',
                    isSelected: languageController.currentLocale.value.languageCode == 'en',
                    isDarkMode: isDarkMode,
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),
            _buildInfoCard(isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption({
    required HomeController homeController,
    required BuildContext context,
    required String title,
    required String code,
    required String flag,
    required bool isSelected,
    required bool isDarkMode,
  }) {
    final ChangeLanguageController languageController = Get.find<ChangeLanguageController>();
          final ViewsController viewsController = Get.find<ViewsController>();
  final FavoritesController favoritesController = Get.find<FavoritesController>();
  final PopularHistoryController popularHistoryController = Get.find<PopularHistoryController>();
    final BrowsingHistoryController _browsingHistoryController = Get.find<BrowsingHistoryController>();
             AdsController adsController = Get.find<AdsController>();

    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      leading: Container(
        width: 40.w,
        height: 40.h,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Center(
          child: Text(
            flag,
            style: TextStyle(fontSize: 24.sp),
          ),
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: AppTextStyles.appFontFamily,
          fontSize: AppTextStyles.large,

          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary(isDarkMode),
        ),
      ),
      trailing: isSelected
          ? Container(
              width: 24.w,
              height: 24.h,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                size: 16.w,
                color: Colors.white,
              ),
            )
          : null,
      onTap: () {
        if (!isSelected) {
          languageController.changeLanguage(code);
          homeController.isGetFirstTime.value =false;
        homeController.fetchCategories(  languageController.currentLocale.value.languageCode);
        final userId = Get.find<LoadingController>().currentUser!.id!;


    adsController.  loadFeaturedAds();

   popularHistoryController. fetchPopular(limit: 10,lang:  Get.find<ChangeLanguageController>().currentLocale.value.languageCode);
          // إعادة تحميل الصفحة لتطبيق التغييرات
          Navigator.of(context).pop();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => LanguageSettingsPage()),
          );
          Get.offAll(HomeScreen());
        }
      },
    );
  }

  Widget _buildInfoCard(bool isDarkMode) {
    return Card(
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
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.primary,
                  size: 24.r,
                ),
                SizedBox(width: 8.w),
                Text(
                  'ملاحظة'.tr,
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    fontSize: AppTextStyles.large,

                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(isDarkMode),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              'تم تغيير اللغة'.tr,
              style: TextStyle(
                fontFamily: AppTextStyles.appFontFamily,
                fontSize: AppTextStyles.medium,

                color: AppColors.textSecondary(isDarkMode),
                height: 1.5,
              ),
              textAlign: TextAlign.start,
            ),
          ],
        ),
      ),
    );
  }
}