import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tappuu_app/controllers/home_controller.dart';
import 'package:tappuu_app/controllers/ThemeController.dart';
import 'package:tappuu_app/core/constant/app_text_styles.dart';
import 'package:tappuu_app/core/constant/appcolors.dart';
import 'package:tappuu_app/core/localization/changelanguage.dart';

import '../../controllers/AdsManageSearchController.dart';
import '../HomeScreen/homeItems/SubCategories/subCategoriesScreen.dart';
import '../HomeScreen/menubar.dart';
import '../viewAdsScreen/AdsScreen.dart';

class UrgentCategoriesScreen extends StatefulWidget {
  final String period;

  const UrgentCategoriesScreen({
    super.key,
    required this.period,
  });

  @override
  State<UrgentCategoriesScreen> createState() => _UrgentCategoriesScreenState();
}

class _UrgentCategoriesScreenState extends State<UrgentCategoriesScreen> {
  final HomeController controller = Get.find<HomeController>();
  final AdsController adsController = Get.find<AdsController>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    // تأخير جلب البيانات حتى بعد اكتمال البناء
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCategories();
    });
  }

  void _loadCategories() {
    final langCode = Get.find<ChangeLanguageController>().currentLocale.value.languageCode;
    controller.fetchCategories(langCode, adsPeriod: widget.period);
    _hasInitialized = true;
  }

  @override
  void didUpdateWidget(UrgentCategoriesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // إعادة جلب البيانات إذا تغيرت الفترة الزمنية
    if (oldWidget.period != widget.period && _hasInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadCategories();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Get.find<ThemeController>().isDarkMode.value;
    final bgColor = AppColors.background(isDarkMode);
    
    return Scaffold( 
      key: _scaffoldKey,
      drawer: Menubar(),
      backgroundColor: bgColor,
      appBar: _buildAppBar(context, _scaffoldKey),
      body: _buildBody(bgColor),
    );
  }

 PreferredSizeWidget _buildAppBar(BuildContext context, GlobalKey<ScaffoldState> _scaffoldKey) {
  final String title = _getAppBarTitle();
  final String subTitle = _getAppBarSubTitle(); // سطر إضافي لو تحب تستخدمه مستقبلاً
  final bool showSubTitle = subTitle.trim().isNotEmpty;

  return AppBar(
    backgroundColor: AppColors.primary,
    leadingWidth: 100,
    leading: Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20.w,
            color: AppColors.onSurfaceDark,
          ),
          onPressed: () => Get.back(),
        ),
        InkWell(
          onTap: () {
            _scaffoldKey.currentState?.openDrawer();
          },
          child: Icon(
            Icons.menu,
            size: 30.w,
            color: Colors.white,
          ),
        ),
      ],
    ),
    centerTitle: true,
    title: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // السطر الأول (العنوان الرئيسي)
        Text(
          title,
          style: TextStyle(
            fontSize: AppTextStyles.xlarge,
            fontWeight: FontWeight.w700,
            fontFamily: AppTextStyles.appFontFamily,
            color: AppColors.onSurfaceDark,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        // السطر الثاني (يظهر فقط لو فيه قيمة)
        if (showSubTitle) ...[
          SizedBox(height: 2.h),
          Text(
            subTitle,
            style: TextStyle(
              fontSize: AppTextStyles.medium,
              fontWeight: FontWeight.w600,
              fontFamily: AppTextStyles.appFontFamily,
              color: AppColors.onSurfaceDark.withOpacity(0.9),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    ),
    elevation: 0,
  );
}

// دالة العنوان الرئيسي
String _getAppBarTitle() {
  if (widget.period == '24h') {
    return 'الإعلانات العاجلة';
  } else if (widget.period == '48h') {
    return 'الإعلانات العاجلة';
  }
  return 'الإعلانات العاجلة';
}

// دالة السطر الثاني (الفرعي)
String _getAppBarSubTitle() {
  if (widget.period == '24h') {
    return 'آخر 24 ساعة';
  } else if (widget.period == '48h') {
    return 'آخر 48 ساعة';
  }
  return '';
}
  int _getHours() {
    if (widget.period == '24h') {
      return 24;
    } else if (widget.period == '48h') {
      return 48;
    }
    return 24;
  }

  Widget _buildBody(Color bgColor) {
    return Obx(() {
      if (controller.isLoadingCategories.value) {
        return _buildShimmerLoader(bgColor);
      }

      if (controller.categoriesList.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'لا توجد تصنيفات'.tr,
                style: TextStyle(
                  fontSize: AppTextStyles.large,
                  fontFamily: AppTextStyles.appFontFamily,
                  color: Get.find<ThemeController>().isDarkMode.value
                      ? AppColors.textPrimary(true)
                      : AppColors.textPrimary(false),
                ),
              ),
              SizedBox(height: 16.h),
              ElevatedButton(
                onPressed: () {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _loadCategories();
                  });
                },
                child: Text('إعادة المحاولة'.tr),
              ),
            ],
          ),
        );
      }

      return Column(
        children: [
          // زر "خليه فارغ حاليا"
          
          // رابط "عرض جميع الإعلانات العاجلة" مع العدد الإجمالي
          _buildViewAllUrgentAdsLink(_getHours()),
          
          // قائمة التصنيفات الرئيسية
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
              itemCount: controller.categoriesList.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                thickness: 1,
                color: Get.find<ThemeController>().isDarkMode.value
                    ? Colors.grey[800]
                    : Colors.grey[200],
              ),
              itemBuilder: (context, index) {
                final category = controller.categoriesList[index];
                final translation = category.translations.firstWhere(
                  (t) => t.language == Get.find<ChangeLanguageController>().currentLocale.value.languageCode,
                  orElse: () => category.translations.first,
                );

                return _buildCategoryItem(
                  id: category.id,
                  name: translation.name,
                  adsCount: category.adsCount,
                  imageUrl: category.image,
                );
              },
            ),
          ),
        ],
      );
    });
  }


  // رابط "عرض جميع الإعلانات العاجلة" مع العدد الإجمالي
  Widget _buildViewAllUrgentAdsLink(int hours) { 
    final totalAds = controller.categoriesList.fold(0, (sum, category) => sum + category.adsCount);
    final isDarkMode = Get.find<ThemeController>().isDarkMode.value;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 0.h),
          child: InkWell(
            onTap: () {
              final int? selectedHours = hours;
              final String? tf = adsController.toTimeframe(selectedHours);

              adsController.viewMode.value = "grid_simple";
              Get.to(() => AdsScreen(
                categoryId: null,
                titleOfpage: "الإعلانات العاجلة".tr,
                currentTimeframe: tf,
              ));
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'عرض جميع الإعلانات العاجلة'.tr,
                  style: TextStyle(
                    fontSize: AppTextStyles.medium,
                    fontFamily: AppTextStyles.appFontFamily,
                    color: AppColors.buttonAndLinksColor,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
        
                Row(
                  children: [
                    Text(
                      "(${totalAds.toString()})",
                      style: TextStyle(
                        fontSize: AppTextStyles.medium,
                        fontFamily: AppTextStyles.appFontFamily,
                        color: AppColors.buttonAndLinksColor,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
        
                    IconButton(
                      icon: Icon(Icons.arrow_forward_ios,
                          size: 20.w,
                          color:  AppColors.buttonAndLinksColor),
                      onPressed: (){
                        final int? selectedHours = hours;
                        final String? tf = adsController.toTimeframe(selectedHours);

                        adsController.viewMode.value = "grid_simple";
                        Get.to(() => AdsScreen(
                          categoryId: null,
                          titleOfpage: "الإعلانات العاجلة".tr,
                          currentTimeframe: tf,
                        ));
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 4.h,),
        Divider(
          height: 1,
          thickness: 1.5,
          color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
        ),
      ],
    );
  }

  Widget _buildShimmerLoader(Color bgColor) {
    final isDarkMode = Get.find<ThemeController>().isDarkMode.value;
    final baseColor = isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDarkMode ? Colors.grey[700]! : Colors.grey[100]!;
    
    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      period: Duration(milliseconds: 1500),
      child: Column(
        children: [
          // تأثير تحميل لزر "خليه فارغ حاليا"
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Container(
              width: double.infinity,
              height: 50.h,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
          
          // تأثير تحميل لرابط "عرض جميع الإعلانات العاجلة"
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 150.w,
                  height: 20.h,
                  decoration: BoxDecoration(
                    color: baseColor,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 30.w,
                      height: 20.h,
                      decoration: BoxDecoration(
                        color: baseColor,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Container(
                      width: 24.w,
                      height: 24.h,
                      decoration: BoxDecoration(
                        color: baseColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // تأثير تحميل للقائمة
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: ListView.separated(
                itemCount: 7,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  thickness: 1.5,
                  color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                ),
                itemBuilder: (context, index) {
                  return Container(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 30.w,
                              height: 30.h,
                              decoration: BoxDecoration(
                                color: baseColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Container(
                              width: MediaQuery.of(context).size.width * 0.5,
                              height: 18.h,
                              decoration: BoxDecoration(
                                color: baseColor,
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Container(
                              width: 30.w,
                              height: 24.h,
                              decoration: BoxDecoration(
                                color: baseColor,
                                borderRadius: BorderRadius.circular(24.r),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Container(
                              width: 24.w,
                              height: 24.h,
                              decoration: BoxDecoration(
                                color: baseColor,
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem({
    required int id,
    required String name,
    required int adsCount,
    required String? imageUrl,
  }) {
    final isDarkMode = Get.find<ThemeController>().isDarkMode.value;
    
    return InkWell(
      onTap: () {
          controller.setAdsPeriod(widget.period); // Set period first

print(widget.period);
          Get.to(() => SubCategoriesScreen(
              categoryId: id,
              categoryName: name,
              countOfAdsInCategory: adsCount,
              adsPeriod: widget. period,
              
            ));
          
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: TextStyle(
                fontSize: AppTextStyles.large,
                fontWeight: FontWeight.w500,
                fontFamily: AppTextStyles.appFontFamily,
                color: AppColors.textPrimary(isDarkMode),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Row(
              children: [
                Text(
                  '($adsCount)',
                  style: TextStyle(
                    fontSize: AppTextStyles.medium,
                    fontFamily: AppTextStyles.appFontFamily,
                    color: AppColors.grey500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(width: 12.w),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16.w,
                  color: AppColors.grey.withOpacity(0.6),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget(String imageUrl) {
    if (imageUrl.toLowerCase().endsWith('.svg')) {
      return Container(
        width: 30.w,
        height: 30.h,
        margin: EdgeInsets.only(left: 8.w),
        child: SvgPicture.network(
          imageUrl,
          fit: BoxFit.cover,
          placeholderBuilder: (BuildContext context) => Container(
            padding: const EdgeInsets.all(10.0),
            child: CircularProgressIndicator(
              color: AppColors.primary,
            ),
          ),
        ),
      );
    } else {
      return Container(
        width: 20.w,
        height: 20.h,
        margin: EdgeInsets.only(left: 8.w),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: NetworkImage(imageUrl),
            fit: BoxFit.cover,
          ),
        ),
      );
    }
  }
}