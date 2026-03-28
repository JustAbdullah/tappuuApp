import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:tappuu_app/controllers/LoadingController.dart';
import 'package:tappuu_app/views/AddAds/AddAdScreen.dart';
import 'package:tappuu_app/views/HomeScreen/home_screen.dart';

import '../../controllers/ThemeController.dart';
import '../../controllers/home_controller.dart';
import '../../core/constant/app_text_styles.dart';
import '../../core/constant/appcolors.dart';
import '../../core/localization/changelanguage.dart';
import '../ServicesDrawer/ServicesDrawer.dart';
import '../UserSettings/SettingsDrawer.dart';
import '../UserSettings/itemsUserSettings/UserInfoPage.dart';
import 'homeItems/LoginPopup.dart';
import 'homeItems/SubCategories/subCategoriesScreen.dart';

class Menubar extends StatelessWidget {
  const Menubar({super.key});

  @override
  Widget build(BuildContext context) {
    final HomeController controller = Get.find<HomeController>();
    final ThemeController themeController = Get.find<ThemeController>();
    final LoadingController loadingController = Get.find<LoadingController>();
    final List<Color> iconColors = [
      const Color.fromARGB(255, 255, 117, 75),
      const Color.fromARGB(255, 59, 184, 200),
      const Color.fromARGB(255, 133, 190, 68),
      const Color.fromARGB(255, 236, 160, 47),
      const Color(0xFFF48FB1),
      const Color(0xFF90CAF9),
      const Color(0xFFA5D6A7),
      const Color(0xFFCE93D8),
    ];

    return Obx(() {
      final isDarkMode = themeController.isDarkMode.value;
      
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Drawer(
          backgroundColor: AppColors.surface(isDarkMode),
          width: MediaQuery.of(context).size.width * 0.75,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                ),
                child: Column(
                  children: [
                    _buildTopMenuItem(
                      title: 'الرئيسية'.tr,
                      isDarkMode: isDarkMode,
                      onTap: () {
                        Get.offAll(HomeScreen());
                      },
                    ),
                    _buildTopMenuItem(
                      title: 'الملف الشخصي'.tr,
                      isDarkMode: isDarkMode,
                      onTap: () {



                          if(loadingController.currentUser != null){
                             Get.to(()=>UserInfoPage());
                      }else {
                             Get.dialog(
          LoginPopup(),
          barrierDismissible: true,
        );}}
                    ),
                    _buildTopMenuItem(
                      title: 'الاعدادت'.tr,
                      isDarkMode: isDarkMode,
                      onTap: () {

                        if(loadingController.currentUser != null){
                            void _openSettingsDrawer(BuildContext context) {
                          showGeneralDialog(
                            context: context,
                            barrierDismissible: true,
                            barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
                            barrierColor: Colors.black.withOpacity(0.5),
                            transitionDuration: const Duration(milliseconds: 300),
                            pageBuilder: (context, animation, secondaryAnimation) {
                              return SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(1, 0),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: SettingsDrawer(),
                              );
                            },
                          );
                        }
                        _openSettingsDrawer(context);
                        }else {
                             Get.dialog(
          LoginPopup(),
          barrierDismissible: true,
        );

                        }
                      
                      },
                    ),  _buildTopMenuItem(
                      title: 'اضف اعلان'.tr,
                      isDarkMode: isDarkMode,
                      onTap: () {
                         
  if ( Get.find<LoadingController>().currentUser == null) {
    Get.snackbar('تنبيه'.tr, 'يجب تسجيل الدخول'.tr,
        snackPosition: SnackPosition.BOTTOM);
    return;
  }
                        Get.to(()=>AddAdScreen());
                      },
                    ),
                    _buildTopMenuItem(
                      title: 'خدماتنا'.tr,
                      isDarkMode: isDarkMode,
                      onTap: () {

                       
                        void _openServicesDrawer(BuildContext context) {
                          showGeneralDialog(
                            context: context,
                            barrierDismissible: true,
                            barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
                            barrierColor: Colors.black.withOpacity(0.5),
                            transitionDuration: const Duration(milliseconds: 300),
                            pageBuilder: (context, animation, secondaryAnimation) {
                              return SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(1, 0),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: ServicesDrawer(),
                              );
                            },
                          );
                        }
                        _openServicesDrawer(context);
                      },
                    ),
                    
                    Divider(
                      color: Colors.white.withOpacity(0.2),
                      thickness: 1,
                      height: 1,
                    ),
                  ],
                ),
              ),
              
              Container(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                color: AppColors.surface(isDarkMode),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      child: Text(
                        'التصنيفات الرئيسية'.tr,
                        style: TextStyle(
                          fontFamily: AppTextStyles.appFontFamily,
                          fontSize: AppTextStyles.large,

                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary(isDarkMode),
                        ),
                      ),
                    ),
                    
                    Obx(() {
                      if (controller.isLoadingCategories.value) {
                        return Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      
                      return Column(
                        children: controller.categoriesList.asMap().entries.map((entry) {
                          final index = entry.key;
                          final category = entry.value;
                          final langCode = Get.find<ChangeLanguageController>().currentLocale.value.languageCode;
                          final translation = category.translations.firstWhere(
                            (t) => t.language == langCode,
                            orElse: () => category.translations.first,
                          );

                          return _buildSmallCategoryItem(
                            id: category.id,
                            image: category.image,
                            name: translation.name,
                            color: iconColors[index % iconColors.length],
                            isDarkMode: isDarkMode,
                            onTap: () {
                              Get.to(() => SubCategoriesScreen(
                                categoryId: category.id,
                                categoryName: translation.name,
                                countOfAdsInCategory: category.adsCount,
                              ));
                            },
                          );
                        }).toList(),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildTopMenuItem({
    required String title,
    required bool isDarkMode,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
      title: Text(
        title,
        style: TextStyle(   
          fontFamily: AppTextStyles.appFontFamily,
          fontSize: AppTextStyles.large,

          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16.w,
        color: Colors.white.withOpacity(0.7),
      ),
      onTap: onTap,
    );
  }

  Widget _buildSmallCategoryItem({
    required int id,
    required String image,
    required String name,
    required Color color,
    
    required bool isDarkMode,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 8.w),
        leading: Container(
          width: 36.w,
          height: 36.h,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: CachedNetworkImage(
              imageUrl: image,
              width: 24.w,
              height: 24.h,
              placeholder: (context, url) => CircularProgressIndicator(
                strokeWidth: 1.5,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
              errorWidget: (context, url, error) => Icon(
                Icons.category,
                size: 18.w,
                color: color,
              ),
            ),
          ),
        ),
        title: Text(
          name,
          style: TextStyle(   
            fontFamily: AppTextStyles.appFontFamily,
            fontSize: AppTextStyles.medium,

            color: AppColors.textPrimary(isDarkMode),
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 14.w,
          color: AppColors.grey.withOpacity(0.6),
        ),
        onTap: onTap,
      ),
    );

  }}