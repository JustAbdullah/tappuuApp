import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:tappuu_app/controllers/ThemeController.dart';
import 'package:tappuu_app/controllers/areaController.dart';

import '../../../../controllers/CurrencyController.dart';
import '../../../../controllers/FavoritesController.dart';
import '../../../../controllers/LoadingController.dart';
import '../../../../core/constant/app_text_styles.dart';
import '../../../../core/constant/appcolors.dart';
import '../../../../core/data/model/AdResponse.dart';
import '../../../../customWidgets/custom_image_malt.dart';
import '../../../viewAdsScreen/AdDetailsScreen.dart';

class FavoritesAdItem extends StatelessWidget {
  final Ad ad;

  const FavoritesAdItem({super.key, required this.ad});

  @override
  Widget build(BuildContext context) {
    final AreaController areaController = Get.put(AreaController());
    final city = ad.city;
    final areaName = areaController.getAreaNameById(ad.areaId);
    final themeController = Get.find<ThemeController>();
    final isDarkMode = themeController.isDarkMode.value;
    final favoritesController = Get.find<FavoritesController>();
    final LoadingController loadingC = Get.find<LoadingController>();
    final CurrencyController currencyController = Get.put(CurrencyController());

    return Container(
      margin: EdgeInsets.symmetric(vertical: 0.h, horizontal: 0.w),
      decoration: BoxDecoration(
        color: ad.is_premium?const Color.fromARGB(255, 237, 202, 24).withOpacity(0.2):      
        AppColors.surface(themeController.isDarkMode.value),
        borderRadius: BorderRadius.circular(0.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            spreadRadius: 1,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(0.r),
          onTap: () {
            Get.to(() => AdDetailsScreen(ad: ad));
          },
          child: Padding(
            padding: EdgeInsets.all(0.w), // زودت padding قليلاً فقط
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // المعلومات
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 7.h),

                          // العنوان (كبّرته قليلاً)
                          Text(
                            ad.title,
                            style: TextStyle(
                              fontFamily: AppTextStyles.appFontFamily,
                              fontSize: AppTextStyles.medium,
 // من 14.5 -> 15
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary(themeController.isDarkMode.value),
                              height: 1.35,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              _buildPremiumBadge(),
                            ],
                          ),

                          SizedBox(height: 8.h),

                          // السعر (بقي في نفس المكان لكن أكبر قليلاً)
                          if (ad.price != null)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox(
                                  width: 110.w,
                                  child: RichText(
                                    maxLines: 1,
                                    text: TextSpan(
                                      
                                      text: currencyController.formatPrice(ad.price!),
                                      style: TextStyle(
                                        fontFamily: AppTextStyles.appFontFamily,
                                        fontSize: AppTextStyles.small,
 // من 13.5 -> 14
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.buttonAndLinksColor,
                                        overflow: TextOverflow.ellipsis,
                                        
                                      ),
                                      
                                    ),
                                  ),
                                ),SizedBox(
                                        width: 120.w,
                                        child:
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                   
SizedBox(
                                        width: 100.w,
                                  child:      Text(
                                    
                                        '${city?.name??""}, ${ad.area?.name.toString()??""}',
                                          style: TextStyle(
                                            fontFamily: AppTextStyles.appFontFamily,
                                            fontSize: 11.sp, // من 10.5 -> 11
                                            color: AppColors.textSecondary(themeController.isDarkMode.value),
                                            overflow: TextOverflow.clip,
                                            
                                          ),
                                          textAlign: TextAlign.end,
                                          maxLines: 1,
)),
                                     
                                    SizedBox(width: 4.w),
                                    Icon(Icons.location_on, size: 11.sp, color: AppColors.grey),
                                  ],
                                )),
                              ],
                            ),

                        ],
                      ),
                    ),

                    SizedBox(width: 6.w),

                    // عارض الصور المدمج (كبرته قليلاً لكن نفس المكان)
                    if (ad.images.isNotEmpty)
                      Container(
                        width: 125.w, // من 120 -> 140
                        height: 90.h, // من 80 -> 90
                        child: Stack(
                          children: [
                            ImagesViewer(
                              images: ad.images,
                              width: 125.w,
                              height:90.h,
                              isCompactMode: true,
                              enableZoom: true,
                              fit: BoxFit.cover,
                              showPageIndicator: ad.images.length > 1,
                              imageQuality: ImageQuality.high,
                            ),

                              Visibility(
                              visible: ad.show_time == 1,
                              child: Positioned(
                                top: 6.w,
                                left: 6.w,
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.4),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Text(
                                    _formatDate(ad.createdAt),
                                    style: TextStyle(
                                      fontFamily: AppTextStyles.appFontFamily,
                                      fontSize: 11.sp,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                SizedBox(height: 4.w),

                Divider(
                  height: 1,
                  thickness: 0.3,
                  color: AppColors.grey.withOpacity(0.7),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }


  // PREMIUM BADGE — يدعم الوضع الداكن بخيارات ألوان مناسبة
  Widget _buildPremiumBadge() {
    if (ad.is_premium != true) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      );
    }

    final themeController = Get.find<ThemeController>();
    final bool isDark = themeController.isDarkMode.value;

    final List<Color> gradientColors = isDark
        ? [Color(0xFFFFD186), Color(0xFFFFB74D)] // ألوان للـ dark
        : [
            AppColors.PremiumColor,
            const Color.fromARGB(246, 235, 235, 225).withOpacity(0.1),
            AppColors.PremiumColor,
          ];

    final textColor = isDark ? Colors.black87 : Colors.grey[700];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        'Premium offer',
        style: TextStyle(
          fontFamily: AppTextStyles.appFontFamily,
          fontSize: 9.2.sp,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${'قبل'.tr} ${difference.inDays} ${'يوم'.tr}';
    } else if (difference.inHours > 0) {
      return '${'قبل'.tr} ${difference.inHours} ${'ساعة'.tr}';
    } else if (difference.inMinutes > 0) {
      return '${'قبل'.tr} ${difference.inMinutes} ${'دقيقة'.tr}';
    } else {
      return 'الآن'.tr;
    }
  }

}