import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../controllers/FavoritesController.dart';
import '../../../../controllers/LoadingController.dart';
import '../../../../controllers/ThemeController.dart';
import '../../../../core/constant/app_text_styles.dart';
import '../../../../core/constant/appcolors.dart';
import 'FavoritesAdItem.dart';

// ignore: must_be_immutable
class FavoritesScreen extends StatelessWidget {
  int ?idGroup;
  String ?nameOfGroup;
   FavoritesScreen({super.key,
   this.idGroup,
   this.nameOfGroup="المفضلة",
  });

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final isDarkMode = themeController.isDarkMode.value;
    final favoritesController = Get.put(FavoritesController());
    final LoadingController loadingC = Get.find<LoadingController>();

    // جلب مفضلات المستخدم عند فتح الشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (loadingC.currentUser != null) {
        favoritesController.fetchFavorites(
          userId: loadingC.currentUser?.id ?? 0,
          favoriteGroupId: idGroup,
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background(isDarkMode),
      appBar: AppBar(
        title: Text(
          nameOfGroup.toString(),
        
          style: TextStyle(
            color: AppColors.onPrimary,
            fontFamily: AppTextStyles.appFontFamily,
            fontSize: AppTextStyles.xxlarge,

            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.appBar(isDarkMode),
        elevation: 0,
        centerTitle: true, leading: IconButton(
          icon: Icon(Icons.arrow_back,color: AppColors.onPrimary,),
          onPressed: () {
           Get.back();
             Get.back();
          },
        ),
      ),
      body: Obx(() {
        return Column(
          children: [
            // عنوان قسم المفضلة
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'الإعلانات المفضلة'.tr,
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: AppTextStyles.xlarge,

                      fontWeight: FontWeight.bold,
                      color: AppColors.buttonAndLinksColor,
                    ),
                  ),
                  // عدد الإعلانات في المفضلة
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppColors.buttonAndLinksColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      favoritesController.favorites.length.toString(),
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: AppTextStyles.medium,

                        fontWeight: FontWeight.bold,
                        color: AppColors.buttonAndLinksColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: favoritesController.isLoading.value
                  ? _buildShimmerLoader()
                  : favoritesController.favorites.isEmpty
                      ? Center(
                          child: Text(
                            'لا توجد إعلانات في المفضلة'.tr,
                            style: TextStyle(
                              fontFamily: AppTextStyles.appFontFamily,
                              fontSize: AppTextStyles.xlarge,

                              color: AppColors.textSecondary(isDarkMode),
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () async {
                            if (loadingC.currentUser != null) {
                              await favoritesController.fetchFavorites(
                                userId: loadingC.currentUser?.id ?? 0,
                              );
                            }
                          },
                          child: ListView.builder(
                            padding: EdgeInsets.symmetric(vertical: 8.h),
                            itemCount: favoritesController.favorites.length,
                            itemBuilder: (context, index) {
                              return FavoritesAdItem(
                                ad: favoritesController.favorites[index],
                              );
                            },
                          ),
                        ),
            ),
          ],
        );
      }),
    );
  }

  // مؤشر التحميل الوميضي
  Widget _buildShimmerLoader() {
    final themeController = Get.find<ThemeController>();
    final isDarkMode = themeController.isDarkMode.value;

    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: EdgeInsets.only(bottom: 16.h),
          decoration: BoxDecoration(
            color: AppColors.surface(isDarkMode),
            borderRadius: BorderRadius.circular(0.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                spreadRadius: 1,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Shimmer.fromColors(
            baseColor: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
            highlightColor: isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
            child: Padding(
              padding: EdgeInsets.all(10.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 18.h,
                              width: double.infinity,
                              color: Colors.white,
                            ),
                            SizedBox(height: 6.h),
                            Container(
                              height: 16.h,
                              width: 250.w,
                              color: Colors.white,
                            ),
                            SizedBox(height: 12.h),
                            Container(
                              height: 24.h,
                              width: 120.w,
                              color: Colors.white,
                            ),
                            SizedBox(height: 16.h),
                            Row(
                              children: [
                                Icon(Icons.location_on,
                                    size: 16.sp, color: Colors.transparent),
                                SizedBox(width: 4.w),
                                Container(
                                  height: 16.h,
                                  width: 120.w,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                            SizedBox(height: 8.h),
                            Container(
                              height: 14.h,
                              width: 90.w,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Container(
                        width: 150.w,
                        height: 100.h,
                        color: Colors.white,
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: List.generate(
                        3,
                        (index) => Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12.w, vertical: 6.h),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Container(
                                width: 50.w,
                                height: 12.h,
                                color: Colors.white,
                              ),
                            )),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}