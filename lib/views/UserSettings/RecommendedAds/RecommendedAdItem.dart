import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:tappuu_app/controllers/ThemeController.dart';
import 'package:tappuu_app/controllers/areaController.dart';

import '../../../../controllers/CurrencyController.dart';
import '../../../../core/constant/appcolors.dart';
import '../../../../core/data/model/AdResponse.dart';
import '../../../../customWidgets/custom_image_malt.dart';
import '../../../core/constant/app_text_styles.dart';
import '../../viewAdsScreen/AdDetailsScreen.dart';

class RecommendedAdItem extends StatelessWidget {
  final Ad ad;

  const RecommendedAdItem({super.key, required this.ad});

  @override
  Widget build(BuildContext context) {
    final AreaController areaController = Get.put(AreaController());
    final city = ad.city;
    final areaName = areaController.getAreaNameById(ad.areaId);
    final themeController = Get.find<ThemeController>();
    final isDarkMode = themeController.isDarkMode.value;
    final CurrencyController currencyController = Get.put(CurrencyController());

    return Container(
      margin: EdgeInsets.symmetric(vertical: 0.h, horizontal: 0.w),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(5.r),
          onTap: () {
            Get.to(() => AdDetailsScreen(ad: ad));
          },
          child: Padding(
            padding: EdgeInsets.all(10.w),
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
                          SizedBox(height: 15.h),

                          // العنوان
                          Text(
                            ad.title,
                            style: TextStyle(
                              fontFamily: AppTextStyles.appFontFamily,
                              fontSize: AppTextStyles.large,

                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary(isDarkMode),
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          
                          SizedBox(height: 7.h),
                          
                          // السعر
                          if (ad.price != null)
                            RichText(
                              text: TextSpan(
                                text: currencyController.formatPrice(ad.price!),
                                style: TextStyle(
                                  fontFamily: AppTextStyles.appFontFamily,
                                  fontSize: AppTextStyles.xlarge,

                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          
                          SizedBox(height: 5.h),
                  
                          // الموقع والتاريخ
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 16.sp, color: AppColors.grey),
                              SizedBox(width: 4.w),
                              if (city != null && areaName != null)
                                Text(
                                  '${city.name}, $areaName',
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.appFontFamily,
                                    fontSize: AppTextStyles.small,

                                    color: AppColors.textSecondary(isDarkMode),
                                  ),
                                ),
                              Spacer(),
                            ],
                          ), 
                          SizedBox(height: 5.h,),
                         
                        ],
                      ),
                    ),
                    
                    SizedBox(width: 16.w),
                    
                    // عارض الصور المدمج
                    if (ad.images.isNotEmpty)
                      Container(
                        width: 180.w,
                        height: 100.h,
                        child: Stack(
                          children: [
                            ImagesViewer(
                              images: ad.images,
                              width: 180.w,
                              height: 100.h,
                              isCompactMode: true,
                              enableZoom: true,
                              showPageIndicator: ad.images.length > 1,
                              imageQuality: ImageQuality.high,
                            ),
                            
                            // تاريخ النشر
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
                            
                            // شارة الإعلان المميز
                            if (ad.is_premium == true)
                              Positioned(
                                top: 8.w,
                                right: 8.w,
                                child: Opacity(
                                  opacity: 0.9,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFFFFD700), Color(0xFF50C878)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12.r),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 4,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.star, size: 14.w, color: Colors.white),
                                        SizedBox(width: 4.w),
                                        Text(
                                          'مميز'.tr,
                                          style: TextStyle(
                                            fontFamily: AppTextStyles.appFontFamily,
                                            fontSize: AppTextStyles.small,

                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 5.h),

                if (ad.category != null) ...[
                  SizedBox(height: 5.h),
                  Wrap(
                    children: [
                      _buildTag(ad.category.name, themeController),
                      SizedBox(width: 8.w),
                      if (ad.subCategoryLevelOne != null) 
                        _buildTag(ad.subCategoryLevelOne.name, themeController),
                      if (ad.subCategoryLevelTwo != null) ...[
                        SizedBox(width: 8.w),
                        _buildTag(ad.subCategoryLevelTwo!.name, themeController),
                      ],
                    ],
                  ), 
                  SizedBox(height:5.h),
                  Divider(
                    height: 1,
                    thickness: 0.5,
                    color: AppColors.grey.withOpacity(0.9),
                  ),
                  SizedBox(height: 1.h),
                ],
              ],
            ),
          ),
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

  Widget _buildTag(String text, ThemeController themeController) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.card(themeController.isDarkMode.value),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: AppTextStyles.appFontFamily,
          fontSize: AppTextStyles.small,

          color: AppColors.textSecondary(themeController.isDarkMode.value),
        ),
      ),
    );
  }
}