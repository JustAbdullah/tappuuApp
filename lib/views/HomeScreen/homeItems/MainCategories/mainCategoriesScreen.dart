import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tappuu_app/controllers/home_controller.dart';
import 'package:tappuu_app/controllers/ThemeController.dart';
import 'package:tappuu_app/core/constant/app_text_styles.dart';
import 'package:tappuu_app/core/constant/appcolors.dart';
import 'package:tappuu_app/core/localization/changelanguage.dart';
import '../SubCategories/subCategoriesScreen.dart';

class MainCategoriesScreen extends StatelessWidget {
  final HomeController controller = Get.find<HomeController>();
  final List<Color> iconColors = [
    const Color.fromARGB(255, 255, 117, 75),
    const Color.fromARGB(255, 59, 184, 200),
    const Color.fromARGB(255, 133, 190, 68),
    const Color.fromARGB(255, 236, 160, 47),
    const Color.fromARGB(255, 38, 6, 17),
    const Color(0xFF90CAF9),
    const Color(0xFFA5D6A7),
    const Color(0xFFCE93D8),
  ];

  @override
  Widget build(BuildContext context) {
    final langCode = Get.find<ChangeLanguageController>().currentLocale.value.languageCode;
      final ThemeController themeC = Get.find<ThemeController>();

    final isDarkMode = themeC.isDarkMode.value;

    return Obx(() {
      if (controller.isLoadingCategories.value) {
        return _buildAdvancedShimmerLoader(context);
      }

      return Container(
      color: AppColors.surface(isDarkMode),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...controller.categoriesList.map((category) {
              final translation = category.translations.firstWhere(
                (t) => t.language == langCode,
                orElse: () => category.translations.first,
              );
        
              return _buildCategoryItem(
                id: category.id,
                image: category.image,
                name: translation.name,
                description: translation.description,
                color: iconColors[controller.categoriesList.indexOf(category) % iconColors.length],
           countAds: category.adsCount,
              );
            }).toList(),
          ],
        ),
      );
    });
  }

  Widget _buildAdvancedShimmerLoader(BuildContext context) {
    final isDarkMode = Get.find<ThemeController>().isDarkMode.value;
    final baseColor = isDarkMode ? Colors.grey[800]! : Colors.grey[350]!;
    final highlightColor = isDarkMode ? Colors.grey[700]! : Colors.grey[200]!;
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        period: Duration(milliseconds: 1500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            final color = iconColors[index % iconColors.length].withOpacity(isDarkMode ? 0.2 : 0.85);
            
            return Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isDarkMode ? Colors.grey[800]! : Colors.grey[100]!,
                      width: 1.0,
                    ),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 40.w,
                      height: 40.h,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    
                    SizedBox(width: 16.w),
                    
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: MediaQuery.of(context).size.width * 0.4,
                            height: 16.h,
                            decoration: BoxDecoration(
                              color: isDarkMode ? baseColor : Colors.grey[400]!,
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                          ),
                          
                          SizedBox(height: 6.h),
                          
                          Container(
                            width: MediaQuery.of(context).size.width * 0.7,
                            height: 12.h,
                            decoration: BoxDecoration(
                              color: isDarkMode ? baseColor : Colors.grey[400]!,
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(width: 12.w),
                    
                    Container(
                      width: 18.w,
                      height: 18.h,
                      decoration: BoxDecoration(
                        color: isDarkMode ? baseColor : Colors.grey[400]!,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
  
  Widget _buildCategoryItem({
    required int id,
    required String image,
    required String name,
    required String description,
    required Color color,
    required int countAds,
  }) {
    final isDarkMode = Get.find<ThemeController>().isDarkMode.value;
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
              controller.resetAdsPeriod(); // Reset first

            controller.nameOfMainCate.value = name;
            controller.idOfMainCate.value = id;
            Get.to(() => SubCategoriesScreen(
              categoryId: id,
              categoryName: name,
              countOfAdsInCategory: countAds,
              adsPeriod: null
            ));
          },
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDarkMode 
                    ? Colors.grey[800]! 
                    : Colors.grey[200]!,
                  width: 1.0,
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 35.w,
                  height: 35.h,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30.r),
                    child: Padding(
                      padding:  EdgeInsets.symmetric(horizontal: 3.w),
                      child: CachedNetworkImage(
                        imageUrl: image,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: color,
                          ),
                        ),
                        errorWidget: (context, url, error) => Icon(
                          Icons.category_outlined,
                          size: 24.w,
                          color: color,
                        ),
                      ),
                    ),
                  ),
                ),
                
                SizedBox(width: 16.w),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: AppTextStyles.large,

                          fontWeight: FontWeight.w700,
                          fontFamily: AppTextStyles.appFontFamily,
                          color: AppColors.textPrimary(isDarkMode),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      SizedBox(height: 1.h),
                      
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: AppTextStyles.small,

                          fontFamily: AppTextStyles.appFontFamily,
                          color: AppColors.textSecondary(isDarkMode).withOpacity(0.8),
                          height: 1.4,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                SizedBox(width: 8.w),
                
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16.w,
                  color: AppColors.grey.withOpacity(0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}