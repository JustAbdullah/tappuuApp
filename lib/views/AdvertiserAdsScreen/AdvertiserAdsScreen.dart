import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:tappuu_app/controllers/FavoriteSellerController.dart';
import 'package:tappuu_app/core/constant/appcolors.dart';
import 'package:tappuu_app/core/constant/app_text_styles.dart';
import 'package:tappuu_app/core/data/model/AdResponse.dart';
import 'package:tappuu_app/controllers/ThemeController.dart';
import 'package:tappuu_app/controllers/CurrencyController.dart';
import 'package:tappuu_app/core/localization/changelanguage.dart';

import '../../controllers/LoadingController.dart';
import '../../controllers/areaController.dart';
import '../../customWidgets/custom_image_malt.dart';
import '../viewAdsScreen/AdDetailsScreen.dart';
import '../viewAdsScreen/ConversationScreen.dart';

class AdvertiserAdsScreen extends StatefulWidget {
  final Advertiser advertiser;
  final int idAdv;

  const AdvertiserAdsScreen({
    Key? key,
    required this.advertiser,
    required this.idAdv,
  }) : super(key: key);

  @override
  State<AdvertiserAdsScreen> createState() => _AdvertiserAdsScreenState();
}

class _AdvertiserAdsScreenState extends State<AdvertiserAdsScreen> {
  final FavoriteSellerController _controller = Get.put(FavoriteSellerController());
  final CurrencyController _currencyController = Get.find<CurrencyController>();
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  bool _isLoadingMore = false;
  String _selectedFilter = 'الكل';

  @override
  void initState() {
    super.initState();
    print(Get.find<ChangeLanguageController>().currentLocale.value.languageCode);
    _loadInitialAds();
    _scrollController.addListener(_scrollListener);
  }

  void _loadInitialAds() {
    _controller.fetchAdvertiserAds(
      lang: Get.find<ChangeLanguageController>().currentLocale.value.languageCode,
      advertiserProfileId: widget.idAdv,
      page: 1,
      perPage: 15,
    );
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        !_isLoadingMore) {
      _loadMoreAds();
    }
  }

  void _loadMoreAds() {
    if (_controller.advertiserAdsList.length % 15 == 0) {
      setState(() {
        _isLoadingMore = true;
        _currentPage++;
      });

      _controller.fetchAdvertiserAds(
        lang: Get.find<ChangeLanguageController>().currentLocale.value.languageCode,
        advertiserProfileId: widget.idAdv,
        page: _currentPage,
        perPage: 15,
      ).then((_) {
        setState(() => _isLoadingMore = false);
      });
    }
  }

  Set<String> _getUniqueAreas() {
    final areaController = Get.put(AreaController());
    final areas = <String>{};
    
    for (final ad in _controller.advertiserAdsList) {
      if (ad.areaId != null) {
        final areaName = areaController.getAreaNameById(ad.areaId);
        if (areaName != null && areaName.isNotEmpty) {
          areas.add(areaName);
        }
      }
    }
    
    return areas;
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final isDarkMode = themeController.isDarkMode.value;
    final backgroundColor = AppColors.background(isDarkMode);
    final primaryColor = AppColors.primary;
    final textPrimary = AppColors.textPrimary(isDarkMode);
    final textSecondary = AppColors.textSecondary(isDarkMode);
    final cardColor = AppColors.surface(isDarkMode);
    final dividerColor = AppColors.divider(isDarkMode);

    final uniqueAreas = _getUniqueAreas();
    final areasText = uniqueAreas.join('، ');

    // تحديد نوع الحساب والمظهر المناسب
    final accountType = widget.advertiser.accountType ?? 'individual';
    final accountTypeInfo = _getAccountTypeInfo(accountType);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: Text(
          "صفحة المتجر",
          style: TextStyle(
            fontFamily: AppTextStyles.appFontFamily,
            fontSize: AppTextStyles.xlarge,

            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      backgroundColor: backgroundColor,
      body: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 1.w),
        decoration: BoxDecoration(
          color: cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            // Logo and Name
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 60.w,
                  height: 60.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[200],
                    border: Border.all(color: primaryColor, width: 2),
                  ),
                  child: widget.advertiser.logo.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(30.r),
                          child: Image.network(
                            widget.advertiser.logo,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(Icons.business, size: 24.w, color: primaryColor),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // اسم المعلن ونوع الحساب في نفس السطر
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.advertiser.name.toString(),
                              style: TextStyle(
                                fontFamily: AppTextStyles.appFontFamily,
                                fontSize: AppTextStyles.large,

                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          // شارة نوع الحساب
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: accountTypeInfo.color,
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Text(
                              accountTypeInfo.text,
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        widget.advertiser.description,
                        style: TextStyle(
                          fontFamily: AppTextStyles.appFontFamily,
                          fontSize: AppTextStyles.small,

                          color: textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 30.h),
            
            // Send Message Button (Smaller size)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 0.h, horizontal: 15.w),
              child: Row(
                children: [
                  SizedBox(
                    width: 150.w,
                    child: ElevatedButton(
                      onPressed: () {
                        final userId = Get.find<LoadingController>().currentUser?.id;
                        if (userId == null) {
                          Get.snackbar('تنبيه'.tr, 'يجب تسجيل الدخول '.tr);
                          return;
                        } else {
                          Get.to(() => ConversationScreen(advertiser: widget.advertiser, ad: null, idAdv: widget.idAdv));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttonAndLinksColor,
                        padding: EdgeInsets.symmetric(vertical: 4.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(0.r),
                        ),
                      ),
                      child: Text(
                        'إرسال رسالة'.tr,
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
            SizedBox(height: 12.h),
            
            // Portfolio Title
            Padding(
              padding: EdgeInsets.symmetric(vertical: 0.h, horizontal: 10.w),
              child: Row(
                children: [
                  Text(
                    'محفظتنا الاستثمارية'.tr,
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: AppTextStyles.small,

                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary(isDarkMode)
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 6.h),
            
            Padding(
              padding: EdgeInsets.symmetric(vertical: 0.h, horizontal: 15.w),
              child: Row(
                children: [
                  Obx(() => Text(
                    '${'إعلاناً'.tr} ${_controller.adsCount.value}',
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: AppTextStyles.medium,

                      fontWeight: FontWeight.bold,
                      color: AppColors.buttonAndLinksColor,
                    ),
                  )),
                ],
              ),
            ),
      
            SizedBox(height: 10.h),
            
            Padding(
              padding: EdgeInsets.symmetric(vertical: 0.h, horizontal: 15.w),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        'المناطق التي نعمل فيها'.tr,
                        style: TextStyle(
                          fontFamily: AppTextStyles.appFontFamily,
                          fontSize: AppTextStyles.small,

                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Obx(() => Text(
                        _controller.areasText.value,
                        style: TextStyle(
                          fontFamily: AppTextStyles.appFontFamily,
                          fontWeight: FontWeight.w600,
                          fontSize: 11.sp,
                          color: AppColors.buttonAndLinksColor,
                        ),
                      )),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 10.h),
      
            Divider(
              height: 1.5,
              thickness: 1.5,
              color: dividerColor,
              indent: 16.w,
              endIndent: 16.w,
            ),
      
            SizedBox(height: 10.h),
      
            // ─── Quick Search Filters ─────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'بحث سريع في محفظتنا'.tr,
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: AppTextStyles.medium,

                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Obx(() {
                    if (_controller.isLoadingAdvertiserAds.value) {
                      return Center(child: CircularProgressIndicator());
                    }
                    
                    // استخراج عناوين الإعلانات الفريدة
                    final uniqueTitles = _controller.advertiserAdsList
                        .map((ad) => ad.title)
                        .toSet()
                        .toList();
                    
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: uniqueTitles.map((title) {
                          return _buildFilterButton(
                            title,
                            _selectedFilter == title,
                            onTap: () {
                              // البحث عن الإعلان الأول بهذا العنوان
                              final ad = _controller.advertiserAdsList.firstWhere(
                                (a) => a.title == title,
                                orElse: () => _controller.advertiserAdsList.first
                              );
                              
                              Get.to(() => AdDetailsScreen(ad: ad));
                            },
                          );
                        }).toList(),
                      ),
                    );
                  }),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            
            // ─── Latest Ads Title ────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'أحدث منشوراتنا'.tr,
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: AppTextStyles.medium,

                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8.h),
            
            // ─── Ads List ────────────────────────────────────────────────
            Expanded(
              child: Obx(() {
                if (_controller.isLoadingAdvertiserAds.value) {
                  return Center(child: CircularProgressIndicator());
                }
                
                if (_controller.advertiserAdsList.isEmpty) {
                  return Center(
                    child: Text(
                      'لا توجد إعلانات'.tr,
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: AppTextStyles.medium,

                        color: textSecondary,
                      ),
                    ),
                  );
                }
                
                return ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.only(bottom: 16.h),
                  itemCount: _controller.advertiserAdsList.length + (_isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _controller.advertiserAdsList.length) {
                      return Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.w),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    
                    final ad = _controller.advertiserAdsList[index];
                    return Column(
                      children: [
                        _buildAdItem(ad, isDarkMode, textPrimary, textSecondary),
                        Divider(
                          height: 1,
                          thickness: 0.3,
                          color: dividerColor,
                        ),
                      ],
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // دالة مساعدة للحصول على معلومات نوع الحساب
  _AccountTypeInfo _getAccountTypeInfo(String accountType) {
    switch (accountType) {
      case 'company':
        return _AccountTypeInfo(
          text: 'شركة'.tr,
          color: Colors.blue[700]!,
        );
      case 'individual':
      default:
        return _AccountTypeInfo(
          text: 'فردي'.tr,
          color: Colors.green[700]!,
        );
    }
  }

  Widget _buildFilterButton(String label, bool isSelected, {VoidCallback? onTap}) {
    return Padding(
      padding: EdgeInsets.only(right: 6.w),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? AppColors.primary : Colors.transparent,
          foregroundColor: isSelected ? Colors.white : AppColors.primary,
          padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 10.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4.r),
            side: BorderSide(color: AppColors.buttonAndLinksColor),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: AppColors.buttonAndLinksColor,
            fontFamily: AppTextStyles.appFontFamily,
            fontSize: AppTextStyles.medium,

          ),
        ),
      ),
    );
  }

  Widget _buildAdItem(Ad ad, bool isDarkMode, Color textPrimary, Color textSecondary) {
    ThemeController themeController = Get.find<ThemeController>();
    final areaController = Get.put(AreaController());
    CurrencyController currencyController = Get.find<CurrencyController>();
    final city = ad.city;
    final areaName = areaController.getAreaNameById(ad.areaId);
    
    return Container(
      margin: EdgeInsets.symmetric(vertical: 0.h, horizontal: 0.w),
      decoration: BoxDecoration(
        color: ad.is_premium?const Color.fromARGB(255, 237, 202, 24).withOpacity(0.2):     AppColors.surface(themeController.isDarkMode.value),
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
            padding: EdgeInsets.all(4.w),
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

                          // العنوان
                          Text(
                            ad.title,
                            style: TextStyle(
                              fontFamily: AppTextStyles.appFontFamily,
                              fontSize: AppTextStyles.medium,

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
                              _buildPremiumBadge(ad),
                            ],
                          ),

                          SizedBox(height: 8.h),

                          // السعر
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
                                     
                                        SizedBox(
                                          width: 100.w,
                                          child: Text(
                                                '${city?.name??""}, ${ad.area?.name.toString()??""}',
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

                    // عارض الصور المدمج
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

                            Positioned(
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

  Widget _buildPremiumBadge(Ad ad) {
    if (ad.is_premium != true) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      );
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

// كلاس مساعد لتخزين معلومات نوع الحساب
class _AccountTypeInfo {
  final String text;
  final Color color;

  _AccountTypeInfo({required this.text, required this.color});
}