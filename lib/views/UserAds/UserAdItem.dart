import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:tappuu_app/controllers/ThemeController.dart';
import 'package:tappuu_app/core/constant/appcolors.dart';
import 'package:tappuu_app/core/constant/app_text_styles.dart';

import '../../controllers/AdsManageController.dart';
import '../../core/data/model/AdResponse.dart';
import '../../customWidgets/custom_image_malt.dart';
import 'AdStatisticsScreen.dart';

class UserAdItem extends StatelessWidget {
  final Ad ad;

  const UserAdItem({
    super.key, 
    required this.ad, 
  });

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final isDarkMode = themeController.isDarkMode.value;
    final adsController = Get.find<ManageAdController>();

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
            Get.to(() => AdStatisticsScreen(ad: ad));
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
                         
                         //


                          Text(
                            ad.title,
                            style: TextStyle(
                              fontFamily: AppTextStyles.appFontFamily,
                              fontSize: AppTextStyles.medium,

                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary(isDarkMode),
                              height: 1.4
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        
                          SizedBox(height: 7.h),
                          // السعر 
                          if (ad.price != null)
                            RichText(
                              text: TextSpan(
                                text: _formatPrice(ad.price!),
                                style: TextStyle(
                                  fontFamily: AppTextStyles.appFontFamily,
                                  fontSize: AppTextStyles.xlarge,

                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'ليرة سورية'.tr,
                                    style: TextStyle(
                                      fontSize: AppTextStyles.small,

                                      fontWeight: FontWeight.normal,
                                      color: AppColors.textSecondary(isDarkMode),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          
                          SizedBox(height: 5.h),
                  
                        _buildStatItem(
                        icon: Icons.remove_red_eye_outlined,
                        value: ad.views,
                        label: 'مشاهدة',
                        isDarkMode: isDarkMode
                      ),
                      
                      // عدد الإضافات للمفضلة
                      _buildStatItem(
                        icon: Icons.favorite_border,
                        value: ad.favorites_count ?? 0,
                        label: 'مفضلة',
                        isDarkMode: isDarkMode
                      ),
                      
                      // عدد المتواصلين
                      _buildStatItem(
                        icon: Icons.chat_outlined,
                        value: ad.inquirers_count ?? 0,
                        label: 'تواصل',
                        isDarkMode: isDarkMode
                      ),
                      
                         
                         
                        ],
                      ),
                    ),
                    
                    SizedBox(width: 16.w),
                    
                    // عارض الصور المدمج مع أزرار التحكم
                    if (ad.images.isNotEmpty)
                      Container(
                        width: 170.w,
                        height: 140.h,
                        child: Stack(
                          children: [
                            ImagesViewer(
                              images: ad.images,
                              width: 170.w,
                              height: 140.h,
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
                            
                            // أزرار التعديل والحذف
                         
                          ],
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 5.h),

               
                  
              
                  SizedBox(height:5.h),
                   Divider(
                height: 1,
                thickness: 0.5,
                color: AppColors.grey.withOpacity(0.9),
              ),
                  SizedBox(height: 1.h),
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
      return'${'قبل'.tr}${difference.inHours} ${'ساعة'.tr}';
    } else if (difference.inMinutes > 0) {
      return '${'قبل'.tr}${difference.inMinutes} ${'دقيقة'.tr}';
    } else {
      return 'الآن'.tr;
    }
  }

  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)} ${'مليون'.tr}';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)} ${'ألف'.tr}';
    }
    return price.toStringAsFixed(0);
  }
  

}
  // دالة لبناء عنصر إحصائية
  Widget _buildStatItem({
    required IconData icon,
    required int value,
    required String label,
    required bool isDarkMode
  }) {
    return Row(
      children: [
        Icon(icon, size: 20.sp, color: AppColors.primary),
        SizedBox(width: 4.h),
        Text(
          _formatStatValue(value),
          style: TextStyle(
            fontFamily: AppTextStyles.appFontFamily,
            fontSize: AppTextStyles.medium,

            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary(isDarkMode),
          ),
        ),
        SizedBox(width: 2.h),
        Text(
          label.tr,
          style: TextStyle(
            fontFamily: AppTextStyles.appFontFamily,
            fontSize: 11.sp,
            color: AppColors.textSecondary(isDarkMode),
          ),
        ),
      ],
    );
  }

  // دالة لتنسيق قيمة الإحصائية
  String _formatStatValue(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(4)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(4)}K';
    }
    return value.toString();
  }

