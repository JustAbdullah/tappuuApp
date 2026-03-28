import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:tappuu_app/controllers/ThemeController.dart';
import 'package:tappuu_app/core/constant/appcolors.dart';
import 'package:tappuu_app/core/constant/app_text_styles.dart';

import '../../core/data/model/AdResponse.dart';
import 'AdDetailsScreen.dart';
import 'package:tappuu_app/controllers/CurrencyController.dart';

class AdItem extends StatelessWidget {
  final Ad ad;
  final String viewMode;

  const AdItem({
    super.key,
    required this.ad,
    required this.viewMode,
  });

  @override
  Widget build(BuildContext context) {
    final CurrencyController currencyController = Get.put(CurrencyController());
    switch (viewMode) {
      case 'vertical_detailed':
        return _buildVerticalDetailed(currencyController);
      case 'grid_simple':
        return _buildGridSimple(currencyController);
      case 'grid_detailed':
        return _buildGridDetailed(currencyController);
      case 'vertical_simple':
      default:
        return _buildVerticalSimple(currencyController);
    }
  }

  // ------------------------------
  // Helper: parse possible date strings safely
  DateTime? _parseDateSafe(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String && v.isNotEmpty) {
      try {
        return DateTime.parse(v).toLocal();
      } catch (_) {
        try {
          return DateTime.parse(v.replaceAll(' ', 'T')).toLocal();
        } catch (_) {
          return null;
        }
      }
    }
    return null;
  }

  // ------------------------------
  // Core rule: premium depends strictly on ad.packages
  bool get _isPremiumByPackage {
    try {
      if (ad.packages == null || ad.packages.isEmpty) return false;
      final now = DateTime.now();

      for (final dynamic p in ad.packages) {
        try {
          bool isActive = false;
          DateTime? expiresAt;
          dynamic premiumPackage;

          if (p is AdPackage) {
            isActive = p.isActive;
            expiresAt = p.expiresAt;
            premiumPackage = p.premiumPackage;
          } else if (p is Map) {
            isActive = (p['is_active'] == true) || (p['is_active'] == 1) || (p['isActive'] == true) || (p['isActive'] == 1);
            expiresAt = _parseDateSafe(p['expires_at'] ?? p['expiresAt']);
            premiumPackage = p['premium_package'] ?? p['premiumPackage'];
          } else {
            continue;
          }

          if (!isActive) continue;
          if (expiresAt == null) continue;
          if (!expiresAt.isAfter(now)) continue;

          int? typeId;
          if (premiumPackage == null) {
            continue;
          } else if (premiumPackage is PremiumPackage) {
            typeId = premiumPackage.packageTypeId ?? premiumPackage.type?.id;
          } else if (premiumPackage is Map) {
            final dynamic rawTypeId = premiumPackage['package_type_id'] ?? premiumPackage['packageTypeId'] ?? premiumPackage['type']?['id'];
            if (rawTypeId != null) typeId = int.tryParse(rawTypeId.toString());
          } else if (premiumPackage is int) {
            typeId = premiumPackage;
          }

          if (typeId != null && typeId == 1) {
            return true;
          }
        } catch (_) {
          continue;
        }
      }
    } catch (_) {}
    return false;
  }

  // ------------------------------
  // PREMIUM BADGE — supports dark mode nicely
  Widget _buildPremiumBadge() {
    if (!_isPremiumByPackage) {
      return SizedBox(height: 0, width: 0);
    }

    final themeController = Get.find<ThemeController>();
    final bool isDark = themeController.isDarkMode.value;

    final List<Color> gradientColors = isDark
        ? [const Color(0xFFFFD186), const Color(0xFFFFB74D)]
        : [
            AppColors.PremiumColor,
            const Color.fromARGB(246, 235, 235, 225).withOpacity(0.1),
            AppColors.PremiumColor,
          ];

    final textColor = isDark ? Colors.black87 : Colors.grey[700];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
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
          fontSize: 8.5.sp,
          fontWeight: FontWeight.w700,
          color: textColor,
          height: 1.0,
        ),
      ),
    );
  }

  // ------------------------------
  // vertical_simple — COMPACT, image fixed on the RIGHT
  Widget _buildVerticalSimple(CurrencyController currencyController) {
    final city = ad.city;
    final area = ad.area;
    final themeController = Get.find<ThemeController>();

    final bool isPremium = _isPremiumByPackage;

    const double _cardH = 86; // ارتفاع الكرت أصغر
    const double _imgW = 125;  // عرض كتلة الصورة في اليمين

    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      decoration: BoxDecoration(
        color: isPremium
            ? const Color.fromARGB(255, 237, 202, 24).withOpacity(0.35)
            : AppColors.surface(themeController.isDarkMode.value),
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
          onTap: () => Get.to(() => AdDetailsScreen(ad: ad)),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h), // مسافات أصغر
            child: SizedBox(
              height: _cardH.h, // تثبيت ارتفاع الكرت لتصغيره
              child: Row(
                textDirection: TextDirection.rtl, // الصورة يمين
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // IMAGE (RIGHT) — مربعة، تأخذ كامل الكتلة اليمنى بلا حواف دائرية ولا عدّاد
                  if (ad.images.isNotEmpty)
                    SizedBox(
                      width: _imgW.w,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            ad.images.first,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: AppColors.grey.withOpacity(0.2),
                              child: Icon(Icons.broken_image, size: 16.sp, color: AppColors.grey),
                            ),
                          ),
                          if (ad.show_time == 1)
                            Positioned(
                              top: 4.w,
                              left: 4.w,
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
                                color: Colors.black.withOpacity(0.38),
                                child: Text(
                                  _formatDate(ad.createdAt),
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.appFontFamily,
                                    fontSize: 9.sp,
                                    color: Colors.white,
                                    height: 1.0,
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
                        child: Center(child: Icon(Icons.broken_image, size: 16.sp, color: AppColors.grey)),
                      ),
                    ),

                  SizedBox(width: 6.w),

                  // LEFT CONTENT (العنوان أعلى، شريط الموقع+السعر أسفل أقصى اليسار)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [

                        
                        // Title row (with optional premium badge)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              
                              child: Padding(
                                padding:  EdgeInsets.only(top: 20.h),
                                child: Text(
                                  ad.title,
                                  maxLines: 2, // أقصى حد سطرين
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.appFontFamily,
                                    fontSize: AppTextStyles.medium,
                                    color: AppColors.textPrimary(themeController.isDarkMode.value),
                                    height: 1.15,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 6.w),
                            _buildPremiumBadge(),
                          ],
                        ),

                        // BOTTOM BAR (يسار أسفل الكرت): الموقع أولاً ثم السعر
                        Row(
                          children: [
                            // الموقع
                            Flexible(
                              fit: FlexFit.tight,
                              child: Row(
                                children: [
                                  Icon(Icons.location_on, size: 12.sp, color: AppColors.grey),
                                  SizedBox(width: 2.w),
                                  Expanded(
                                    child: Text(
                                      city != null && area != null
                                          ? '${city.name}, ${area.name}'
                                          : (city?.name ?? ''),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: AppTextStyles.appFontFamily,
                                        fontSize: 10.5.sp,
                                        color: AppColors.textSecondary(themeController.isDarkMode.value),
                                        height: 1.0,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // السعر (بعد الموقع)
                            if (ad.price != null)
                              Text(
                                currencyController.formatPrice(ad.price!),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: AppTextStyles.appFontFamily,
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
          ),
        ),
      ),
    );
  }

  // ------------------------------
  // vertical_detailed — unchanged layout, minor polish only
  Widget _buildVerticalDetailed(CurrencyController currencyController) {
    final themeController = Get.find<ThemeController>();
    final city = ad.city;
    final area = ad.area;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.w),
      decoration: BoxDecoration(
        color: _isPremiumByPackage
            ? const Color.fromARGB(255, 237, 202, 24).withOpacity(0.06)
            : AppColors.surface(themeController.isDarkMode.value),
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12.r),
          onTap: () => Get.to(() => AdDetailsScreen(ad: ad)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (ad.images.isNotEmpty)
                Container(
                  height: 170.h,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12.r),
                      topRight: Radius.circular(12.r),
                    ),
                    color: AppColors.grey.withOpacity(0.2),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12.r),
                          topRight: Radius.circular(12.r),
                        ),
                        child: Image.network(
                          ad.images[0],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(child: CircularProgressIndicator(color: AppColors.primary));
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.broken_image, size: 50.w, color: AppColors.grey);
                          },
                        ),
                      ),
                      Positioned(
                        top: 8.h,
                        left: 8.w,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.45),
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
                      if (_isPremiumByPackage)
                        Positioned(top: 8.h, right: 8.w, child: _buildPremiumBadge()),
                      if (ad.price != null)
                        Positioned(
                          left: 8.w,
                          bottom: 8.h,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.65),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              currencyController.formatPrice(ad.price!),
                              style: TextStyle(
                                fontFamily: AppTextStyles.appFontFamily,
                                fontSize: AppTextStyles.small,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              Padding(
                padding: EdgeInsets.all(14.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: ad.images.isEmpty ? 0 : 8.h),
                    Text(
                      ad.title,
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: AppTextStyles.xlarge,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary(themeController.isDarkMode.value),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 6.h),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16.sp, color: AppColors.textSecondary(themeController.isDarkMode.value)),
                        SizedBox(width: 4.w),
                        Text(
                          '${city?.name ?? ''}${area?.name ?? ''}',
                          style: TextStyle(
                            fontFamily: AppTextStyles.appFontFamily,
                            fontSize: AppTextStyles.medium,
                            color: AppColors.textSecondary(themeController.isDarkMode.value),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    if (ad.attributes != null && ad.attributes.isNotEmpty)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ad.attributes.take(2).map((attr) {
                            final chipText = _resolveAttributeText(attr);
                            return Padding(
                              padding: EdgeInsets.only(right: 8.w),
                              child: _buildFeatureChip(chipText),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------
  Widget _buildFeatureChip(String value) {
    final themeController = Get.find<ThemeController>();
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.card(themeController.isDarkMode.value),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        value,
        style: TextStyle(
          fontFamily: AppTextStyles.appFontFamily,
          fontSize: AppTextStyles.small,
          color: AppColors.textSecondary(themeController.isDarkMode.value),
        ),
      ),
    );
  }

  // ------------------------------
  // grid_simple — minor polish only
  Widget _buildGridSimple(CurrencyController currencyController) {
    final themeController = Get.find<ThemeController>();
    final bool isPremium = _isPremiumByPackage;

    return Container(
      margin: EdgeInsets.all(0.w),
      decoration: BoxDecoration(
        color: isPremium
            ? const Color.fromARGB(255, 237, 202, 24).withOpacity(0.06)
            : AppColors.surface(themeController.isDarkMode.value),
        borderRadius: BorderRadius.circular(0.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(0.r),
          onTap: () => Get.to(() => AdDetailsScreen(ad: ad)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  Container(
                    height: 116.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(0.r),
                        topRight: Radius.circular(0.r),
                      ),
                      color: AppColors.grey.withOpacity(0.2),
                    ),
                    child: ad.images.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(0.r),
                              topRight: Radius.circular(0.r),
                            ),
                            child: Image.network(
                              ad.images[0],
                              fit: BoxFit.cover,
                              width: double.infinity,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(child: CircularProgressIndicator(color: AppColors.primary));
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(Icons.broken_image, size: 50.w, color: AppColors.grey);
                              },
                            ),
                          )
                        : Center(child: Icon(Icons.broken_image, size: 50.w, color: AppColors.grey)),
                  ),
                  Positioned(
                    top: 0,
                    child: Container(
                      height: 20.h,
                      color: Colors.black.withOpacity(0.7),
                      padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 1.w),
                      child: Text(
                        ad.price != null ? currencyController.formatPrice(ad.price!) : '',
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          fontFamily: AppTextStyles.appFontFamily,
                          fontSize: AppTextStyles.small,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.all(4.w),
                child: Text(
                  ad.title,
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    fontSize: AppTextStyles.small,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary(themeController.isDarkMode.value),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------
  // grid_detailed — unchanged except minor polish
  Widget _buildGridDetailed(CurrencyController currencyController) {
    final themeController = Get.find<ThemeController>();
    final bool isPremium = _isPremiumByPackage;

    return Container(
      margin: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: isPremium
            ? const Color.fromARGB(255, 237, 202, 24).withOpacity(0.06)
            : AppColors.surface(themeController.isDarkMode.value),
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12.r),
          onTap: () => Get.to(() => AdDetailsScreen(ad: ad)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ad.images.isNotEmpty
                  ? Container(
                      height: 88.h,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12.r),
                          topRight: Radius.circular(12.r),
                        ),
                        color: AppColors.grey.withOpacity(0.2),
                      ),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(12.r),
                              topRight: Radius.circular(12.r),
                            ),
                            child: Image.network(
                              ad.images[0],
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(child: CircularProgressIndicator(color: AppColors.primary));
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Center(child: Icon(Icons.broken_image, size: 50.w, color: AppColors.grey));
                              },
                            ),
                          ),
                          Positioned(
                            top: 8.h,
                            left: 8.w,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.45),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Text(
                                _formatDate(ad.createdAt),
                                style: TextStyle(
                                  fontFamily: AppTextStyles.appFontFamily,
                                  fontSize: 10.sp,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          if (_isPremiumByPackage)
                            Positioned(top: 8.h, right: 8.w, child: _buildPremiumBadge()),
                          if (ad.price != null)
                            Positioned(
                              left: 8.w,
                              bottom: 8.h,
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.65),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Text(
                                  currencyController.formatPrice(ad.price!),
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.appFontFamily,
                                    fontSize: AppTextStyles.small,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    )
                  : Container(
                      height: 88.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12.r),
                          topRight: Radius.circular(12.r),
                        ),
                        color: AppColors.grey.withOpacity(0.2),
                      ),
                      child: Center(child: Icon(Icons.broken_image, size: 50.w, color: AppColors.grey)),
                    ),
              Container(
                padding: EdgeInsets.all(5.w),
                constraints: BoxConstraints(minHeight: 86.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      ad.title,
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: AppTextStyles.medium,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary(themeController.isDarkMode.value),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 6.h),
                    if (ad.attributes != null && ad.attributes.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 4.h),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: ad.attributes.take(2).map((attr) {
                              final chipText = _resolveAttributeText(attr);
                              return Padding(
                                padding: EdgeInsets.only(right: 6.w),
                                child: _buildFeatureChip(chipText),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------
  String _resolveAttributeText(AttributeValue attr) {
    final name = (attr.name ?? '').toString().trim();
    final value = (attr.value ?? '').toString().trim();
    if (name.isNotEmpty) return name;
    return value;
  }

  // ------------------------------
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

  // ------------------------------
  Widget _buildTag(String text) {
    final themeController = Get.find<ThemeController>();
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
