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

  // نفس أبعاد الكرت الطولي البسيط في الإعلانات العامة
  static const double _cardH = 78;   // ارتفاع الكرت
  static const double _imgW = 105;   // عرض كتلة الصورة في اليمين

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

    final bool isPremium = ad.is_premium == true;

    // نصّ الموقع بنفس منطق الإعلانات العامة قدر الإمكان
    String locationText = '';
    if (city != null && ad.area != null && (ad.area!.name?.toString().isNotEmpty ?? false)) {
      locationText = '${city.name}, ${ad.area!.name}';
    } else if (city != null && areaName != null && areaName.isNotEmpty) {
      locationText = '${city.name}, $areaName';
    } else if (city != null) {
      locationText = city.name;
    } else if (areaName != null && areaName.isNotEmpty) {
      locationText = areaName;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      decoration: BoxDecoration(
        color: isPremium
            ? const Color.fromARGB(255, 237, 202, 24).withOpacity(0.35)
            : AppColors.surface(isDarkMode),
        borderRadius: BorderRadius.circular(0.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.012),
            blurRadius: 3,
            spreadRadius: 0,
            offset: const Offset(0, 1),
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
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // الكرت نفسه (نفس التصميم الطولي البسيط)
                SizedBox(
                  height: _cardH.h,
                  child: Row(
                    textDirection: TextDirection.rtl, // الصورة في اليمين
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // الصورة (يمين) مع التاريخ فوقها لو show_time == 1
                      if (ad.images.isNotEmpty)
                        SizedBox(
                          width: _imgW.w,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              ImagesViewer(
                                images: ad.images,
                                width: _imgW.w,
                                height: _cardH.h,
                                isCompactMode: true,
                                enableZoom: true,
                                fit: BoxFit.cover,
                                showPageIndicator: ad.images.length > 1,
                                imageQuality: ImageQuality.high,
                              ),
                              Visibility(
                                visible: ad.show_time == 1,
                                child: Positioned(
                                  top: 4.w,
                                  left: 4.w,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 6.w, vertical: 2.h),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.4),
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                    child: Text(
                                      _formatDate(ad.createdAt),
                                      style: TextStyle(
                                        fontFamily:
                                            AppTextStyles.appFontFamily,
                                        fontSize: 9.sp,
                                        color: Colors.white,
                                        height: 1.0,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        SizedBox(
                          width: _imgW.w,
                          child: Container(
                            color: AppColors.grey.withOpacity(0.15),
                            child: Center(
                              child: Icon(
                                Icons.broken_image,
                                size: 16.sp,
                                color: AppColors.grey,
                              ),
                            ),
                          ),
                        ),

                      SizedBox(width: 6.w),

                      // المحتوى النصي (يسار)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // السطر الأول: العنوان + بادج البريميوم
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(top: 7.h),
                                    child: Text(
                                      ad.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily:
                                            AppTextStyles.appFontFamily,
                                        fontSize: AppTextStyles.medium,
                                        fontWeight: FontWeight.w400,
                                        color: AppColors.textPrimary(isDarkMode),
                                        height: 1.15,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 6.w),
                                _buildPremiumBadge(),
                              ],
                            ),

                            // السطر السفلي: الموقع ثم السعر (مثل العرض العام)
                            Row(
                              children: [
                                // الموقع
                                Flexible(
                                  fit: FlexFit.tight,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        size: 12.sp,
                                        color: AppColors.grey,
                                      ),
                                      SizedBox(width: 2.w),
                                      Expanded(
                                        child: Text(
                                          locationText,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.start,
                                          style: TextStyle(
                                            fontFamily:
                                                AppTextStyles.appFontFamily,
                                            fontSize: 10.5.sp,
                                            color: AppColors.textSecondary(
                                                isDarkMode),
                                            height: 1.0,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // السعر
                                if (ad.price != null)
                                  Text(
                                    currencyController.formatPrice(ad.price!),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily:
                                          AppTextStyles.appFontFamily,
                                      fontSize: AppTextStyles.small,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.backgroundDark,
                                      height: 1.0,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 2.h),

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
      return const SizedBox.shrink();
    }

    final themeController = Get.find<ThemeController>();
    final bool isDark = themeController.isDarkMode.value;

    final List<Color> gradientColors = isDark
        ? [const Color(0xFFFFD186), const Color(0xFFFFB74D)] // dark
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
