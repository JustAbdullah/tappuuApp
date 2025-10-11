import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:tappuu_app/controllers/ThemeController.dart';
import 'package:tappuu_app/core/constant/appcolors.dart';
import 'package:tappuu_app/core/constant/app_text_styles.dart';

import '../../core/data/model/AdResponse.dart';
import '../../customWidgets/custom_image_malt.dart';
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
        // حاول تنسيقات بديلة أو تجاهل
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
  // Core rule: "مميز" يعتمد حصراً على ad.packages
  // شرط أن يوجد سجل packages where:
  //  - is_active == true (أو 1)
  //  - expires_at in future
  //  - premium_package.package_type_id == 1
bool get _isPremiumByPackage {
  try {
    if (ad.packages == null || ad.packages.isEmpty) return false;
    final now = DateTime.now();

    for (final dynamic p in ad.packages) {
      try {
        // --- احصل على isActive و expiresAt و premiumPackage بأمان سواء p هو AdPackage أو Map ---
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
          // نوع غير متوقع -> نتجاهل
          continue;
        }

        if (!isActive) continue;
        if (expiresAt == null) continue;
        if (!expiresAt.isAfter(now)) continue;

        // --- اكتشاف نوع الباقة (package_type_id) بعدة طرق ---
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

        // لو وجدنا typeId == 1 => إعلان مميز
        if (typeId != null && typeId == 1) {
          // debug: لاحظ أنه يمكنك تفعيل الطباعة أثناء الاختبار
          // print('Found premium package for ad ${ad.id}, package type: $typeId, expiresAt: $expiresAt');
          return true;
        }
      } catch (e) {
        // تجاهل هذا العنصر واستمر في الباقي
        continue;
      }
    }
  } catch (e) {
    // لو صار خطأ نلّف ونرجع false
  }
  return false;
}

  // ------------------------------
  // PREMIUM BADGE — يدعم الوضع الداكن بخيارات ألوان مناسبة
  Widget _buildPremiumBadge() {
    if (! _isPremiumByPackage) {
      return Container(padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h));
    }

    final themeController = Get.find<ThemeController>();
    final bool isDark = themeController.isDarkMode.value;

    final List<Color> gradientColors = isDark
        ? [Color(0xFFFFD186), Color(0xFFFFB74D)]
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

  // ------------------------------
  // vertical_simple — تعديل لاستخدام _isPremiumByPackage بدل ad.is_premium
  Widget _buildVerticalSimple(CurrencyController currencyController) {
    final city = ad.city;
    final area = ad.area;
    final themeController = Get.find<ThemeController>();

    final bool isPremium = _isPremiumByPackage;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 0.h, horizontal: 0.w),
      decoration: BoxDecoration(
        color: isPremium
            ? const Color.fromARGB(255, 237, 202, 24).withOpacity(0.2)
            : AppColors.surface(themeController.isDarkMode.value),
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
            padding: EdgeInsets.all(5.w),
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
                          Text(
                            ad.title,
                            style: TextStyle(
                              fontFamily: AppTextStyles.appFontFamily,
                              fontSize: AppTextStyles.large,
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
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.buttonAndLinksColor,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 120.w,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (city != null && area != null)
                                        SizedBox(
                                          width: 100.w,
                                          child: Text(
                                            '${city.name}, ${area.name}',
                                            style: TextStyle(
                                              fontFamily: AppTextStyles.appFontFamily,
                                              fontSize: 11.sp,
                                              color: AppColors.textSecondary(themeController.isDarkMode.value),
                                              overflow: TextOverflow.clip,
                                            ),
                                            textAlign: TextAlign.end,
                                            maxLines: 1,
                                          ),
                                        ),
                                      SizedBox(width: 4.w),
                                      Icon(Icons.location_on, size: 11.sp, color: AppColors.grey),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    SizedBox(width: 6.w),
                    if (ad.images.isNotEmpty)
                      Container(
                        width: 125.w,
                        height: 90.h,
                        child: Stack(
                          children: [
                            ImagesViewer(
                              images: ad.images,
                              width: 125.w,
                              height: 90.h,
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

  // ------------------------------
  // vertical_detailed — السعر يظهر فقط على الصورة (overlay).
  Widget _buildVerticalDetailed(CurrencyController currencyController) {
    final themeController = Get.find<ThemeController>();
    final city = ad.city;
    final area = ad.area;
    final bool isPremium = _isPremiumByPackage;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.w),
      decoration: BoxDecoration(
        color: _isPremiumByPackage ? const Color.fromARGB(255, 237, 202, 24).withOpacity(0.06) : AppColors.surface(themeController.isDarkMode.value),
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
          onTap: () {
            Get.to(() => AdDetailsScreen(ad: ad));
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (ad.images.isNotEmpty)
                Container(
                  height: 180.h,
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
                            style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: 11.sp, color: Colors.white),
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
                            decoration: BoxDecoration(color: Colors.black.withOpacity(0.65), borderRadius: BorderRadius.circular(8.r)),
                            child: Text(
                              currencyController.formatPrice(ad.price!),
                              style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.small, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: ad.images.isEmpty ? 0 : 10.h),
                    Text(
                      ad.title,
                      style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.xlarge, fontWeight: FontWeight.bold, color: AppColors.textPrimary(themeController.isDarkMode.value)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8.h),
                    Row(children: [
                      Icon(Icons.location_on, size: 16.sp, color: AppColors.textSecondary(themeController.isDarkMode.value)),
                      SizedBox(width: 4.w),
                      Text(
                        '${city?.name ?? ''}${area?.name ?? ''}',
                        style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.medium, color: AppColors.textSecondary(themeController.isDarkMode.value)),
                      ),
                    ]),
                    SizedBox(height: 12.h),
                    if (ad.attributes != null && ad.attributes.isNotEmpty)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ad.attributes.take(2).map((attr) {
                            final chipText = _resolveAttributeText(attr);
                            return Padding(padding: EdgeInsets.only(right: 8.w), child: _buildFeatureChip(chipText));
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
      decoration: BoxDecoration(color: AppColors.card(themeController.isDarkMode.value), borderRadius: BorderRadius.circular(8.r)),
      child: Text(value, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.small, color: AppColors.textSecondary(themeController.isDarkMode.value))),
    );
  }

  // ------------------------------
  // grid_simple — لا تغيير كبير إلا استخدام _isPremiumByPackage حيث يلزم
  Widget _buildGridSimple(CurrencyController currencyController) {
    final themeController = Get.find<ThemeController>();
    final bool isPremium = _isPremiumByPackage;

    return Container(
      margin: EdgeInsets.all(0.w),
      decoration: BoxDecoration(
        color: isPremium ? const Color.fromARGB(255, 237, 202, 24).withOpacity(0.06) : AppColors.surface(themeController.isDarkMode.value),
        borderRadius: BorderRadius.circular(0.r),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, spreadRadius: 1, offset: const Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(0.r),
          onTap: () {
            Get.to(() => AdDetailsScreen(ad: ad));
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  Container(
                    height: 120.h,
                    width: double.infinity,
                    decoration: BoxDecoration(borderRadius: BorderRadius.only(topLeft: Radius.circular(0.r), topRight: Radius.circular(0.r)), color: AppColors.grey.withOpacity(0.2)),
                    child: ad.images.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.only(topLeft: Radius.circular(0.r), topRight: Radius.circular(0.r)),
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
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.7)),
                      child: ad.price != null
                          ? Padding(
                              padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 1.w),
                              child: Text(
                                currencyController.formatPrice(ad.price!),
                                textAlign: TextAlign.start,
                                style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.small, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            )
                          : Text("", textAlign: TextAlign.start, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.small, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.all(4.w),
                child: Text(
                  ad.title,
                  style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.small, fontWeight: FontWeight.w500, color: AppColors.textPrimary(themeController.isDarkMode.value)),
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
  // grid_detailed
  Widget _buildGridDetailed(CurrencyController currencyController) {
    final themeController = Get.find<ThemeController>();
    final bool isPremium = _isPremiumByPackage;

    return Container(
      margin: EdgeInsets.all(8.w),
      decoration: BoxDecoration(color: isPremium ? const Color.fromARGB(255, 237, 202, 24).withOpacity(0.06) : AppColors.surface(themeController.isDarkMode.value), borderRadius: BorderRadius.circular(12.r), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, spreadRadius: 1, offset: const Offset(0, 2))]),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12.r),
          onTap: () {
            Get.to(() => AdDetailsScreen(ad: ad));
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ad.images.isNotEmpty
                  ? Container(
                      height: 90.h,
                      width: double.infinity,
                      decoration: BoxDecoration(borderRadius: BorderRadius.only(topLeft: Radius.circular(12.r), topRight: Radius.circular(12.r)), color: AppColors.grey.withOpacity(0.2)),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.only(topLeft: Radius.circular(12.r), topRight: Radius.circular(12.r)),
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
                            child: Container(padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h), decoration: BoxDecoration(color: Colors.black.withOpacity(0.45), borderRadius: BorderRadius.circular(8.r)), child: Text(_formatDate(ad.createdAt), style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: 10.sp, color: Colors.white))),
                          ),
                          if (_isPremiumByPackage) Positioned(top: 8.h, right: 8.w, child: _buildPremiumBadge()),
                          if (ad.price != null)
                            Positioned(left: 8.w, bottom: 8.h, child: Container(padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h), decoration: BoxDecoration(color: Colors.black.withOpacity(0.65), borderRadius: BorderRadius.circular(8.r)), child: Text(currencyController.formatPrice(ad.price!), style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.small, fontWeight: FontWeight.bold, color: Colors.white)))),
                        ],
                      ),
                    )
                  : Container(height: 90.h, decoration: BoxDecoration(borderRadius: BorderRadius.only(topLeft: Radius.circular(12.r), topRight: Radius.circular(12.r)), color: AppColors.grey.withOpacity(0.2)), child: Center(child: Icon(Icons.broken_image, size: 50.w, color: AppColors.grey))),
              Container(
                padding: EdgeInsets.all(5.w),
                constraints: BoxConstraints(minHeight: 90.h),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text(ad.title, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.medium, fontWeight: FontWeight.bold, color: AppColors.textPrimary(themeController.isDarkMode.value)), maxLines: 1, overflow: TextOverflow.ellipsis),
                  SizedBox(height: 6.h),
                  SizedBox(height: 0.h),
                  if (ad.attributes != null && ad.attributes.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 4.h),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ad.attributes.take(2).map((attr) {
                            final chipText = _resolveAttributeText(attr);
                            return Padding(padding: EdgeInsets.only(right: 6.w), child: _buildFeatureChip(chipText));
                          }).toList(),
                        ),
                      ),
                    ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------
  // مساعدة لعرض اسم الخاصية أو القيمة (الأولوية لاسم الخاصية دائمًا)
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
      decoration: BoxDecoration(color: AppColors.card(themeController.isDarkMode.value), borderRadius: BorderRadius.circular(8.r)),
      child: Text(text, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.small, color: AppColors.textSecondary(themeController.isDarkMode.value))),
    );
  }
}
