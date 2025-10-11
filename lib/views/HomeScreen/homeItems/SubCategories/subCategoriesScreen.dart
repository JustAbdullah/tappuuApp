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
import 'package:tappuu_app/views/HomeScreen/homeItems/SubCategoriesLevelTwo/subCategoriesScreenLevelTwo.dart';

import '../../../../controllers/AdsManageSearchController.dart';
import '../../../../controllers/BrowsingHistoryController.dart';
import '../../../../controllers/LoadingController.dart';
import '../../../../controllers/PopularHistoryController.dart';
import '../../../viewAdsScreen/AdsScreen.dart';
import '../../menubar.dart';

class SubCategoriesScreen extends StatefulWidget {
  final int categoryId;
  final String categoryName;
  final int countOfAdsInCategory;
  final String? adsPeriod;

  const SubCategoriesScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.countOfAdsInCategory,
    this.adsPeriod,
  });

  @override
  State<SubCategoriesScreen> createState() => _SubCategoriesScreenState();
}

class _SubCategoriesScreenState extends State<SubCategoriesScreen> {
  final HomeController controller = Get.find<HomeController>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    final langCode = Get.find<ChangeLanguageController>().currentLocale.value.languageCode;
    
    // إعادة تعيين البيانات السابقة إذا كان التصنيف مختلف
    if (controller.currentCategoryId.value != widget.categoryId) {
      controller.clearSubCategories();
    }
    
    // جلب البيانات الجديدة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchSubcategories(
        widget.categoryId, 
        langCode, 
        adsPeriod: widget.adsPeriod,
        forceRefresh: true
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Get.find<ThemeController>().isDarkMode.value;
    final bgColor = AppColors.background(isDarkMode);
    
    return Scaffold( 
      key: _scaffoldKey,
      drawer: Menubar(),
      backgroundColor: bgColor,
      appBar: _buildAppBar(context),
      body: _buildBody(bgColor),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final isDarkMode = Get.find<ThemeController>().isDarkMode.value;
    final String subtitle = _getAppBarTitle();
    final bool showSubtitle = subtitle.trim().isNotEmpty;

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
            onPressed: () {
              // مسح البيانات المؤقتة عند الرجوع
              controller.clearSubCategories();
              Get.back();
            },
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
          Text(
            widget.categoryName,
            style: TextStyle(
              fontSize: AppTextStyles.large,
              fontWeight: FontWeight.w700,
              fontFamily: AppTextStyles.appFontFamily,
              color: AppColors.onSurfaceDark,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (showSubtitle) ...[
            SizedBox(height: 2.h),
            Text(
              subtitle,
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

  String _getAppBarTitle() {
    if (widget.adsPeriod == '24h') {
      return 'الإعلانات العاجلة - آخر 24 ساعة';
    } else if (widget.adsPeriod == '48h') {
      return 'الإعلانات العاجلة - آخر 48 ساعة';
    }
    return '';
  }

  int _getHours() {
    if (widget.adsPeriod == '24h') {
      return 24;
    } else if (widget.adsPeriod == '48h') {
      return 48;
    }
    return 0;
  }

  Widget _buildBody(Color bgColor) {
    return Obx(() {
      if (controller.isLoadingSubcategoryLevelOne.value) {
        return _buildShimmerLoader(bgColor);
      }

      if (controller.subCategories.isEmpty) {
        return Center(
          child: Text(
            'لا توجد تصنيفات فرعية'.tr,
            style: TextStyle(
              fontSize: AppTextStyles.large,
              fontFamily: AppTextStyles.appFontFamily,
              color: Get.find<ThemeController>().isDarkMode.value
                  ? AppColors.textPrimary(true)
                  : AppColors.textPrimary(false),
            ),
          ),
        );
      }

      return Column(
        children: [
          _buildViewAllAdsLink(_getHours()),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
              itemCount: controller.subCategories.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                thickness: 1,
                color: Get.find<ThemeController>().isDarkMode.value
                    ? Colors.grey[800]
                    : Colors.grey[200],
              ),
              itemBuilder: (context, index) {
                final subCategory = controller.subCategories[index];
                final translation = subCategory.translations.firstWhere(
                  (t) => t.language == Get.find<ChangeLanguageController>().currentLocale.value.languageCode,
                  orElse: () => subCategory.translations.first,
                );

                return _buildSubCategoryItem(
                  idSub: subCategory.id,
                  nameCate: widget.categoryName,
                  nameSub: translation.name,
                  adsCount: subCategory.adsCount,
                  imageUrl: subCategory.image,
                );
              },
            ),
          ),
        ],
      );
    });
  }

  Widget _buildViewAllAdsLink(int? hours) {
    final isDarkMode = Get.find<ThemeController>().isDarkMode.value;
    final AdsController adsController = Get.find<AdsController>();
    final actualCount = controller.totalSubCategoriesAdsCount;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 0.h),
          child: InkWell(
            onTap: () {
              final int? selectedHours = hours;
              final String? tf = adsController.toTimeframe(selectedHours);
              Get.find<AdsController>().viewMode.value = 'vertical_simple';
              Get.to(() => AdsScreen(
                titleOfpage: widget.categoryName,
                categoryId: widget.categoryId,
                nameOfMain: widget.categoryName,
                countofAds: actualCount,
                currentTimeframe: tf,
              ));
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'عرض جميع الإعلانات'.tr,
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
                      "(${actualCount.toString()})",
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
                          size: 20.w, color: AppColors.buttonAndLinksColor),
                      onPressed: () {
                        Get.to(() => AdsScreen(
                          titleOfpage: widget.categoryName,
                          categoryId: widget.categoryId,
                          nameOfMain: widget.categoryName,
                          countofAds: actualCount,
                        ));
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 4.h),
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
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  width: 150.w,
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
          ),
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
                        Container(
                          width: MediaQuery.of(context).size.width * 0.6,
                          height: 18.h,
                          decoration: BoxDecoration(
                            color: isDarkMode ? baseColor : Colors.grey[400]!,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 30.w,
                              height: 24.h,
                              decoration: BoxDecoration(
                                color: isDarkMode ? baseColor : Colors.grey[400]!,
                                borderRadius: BorderRadius.circular(24.r),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Container(
                              width: 24.w,
                              height: 24.h,
                              decoration: BoxDecoration(
                                color: isDarkMode ? baseColor : Colors.grey[400]!,
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

  Widget _buildSubCategoryItem({
    required int idSub,
    required String nameCate,
    required String nameSub,
    required int adsCount,
    required String? imageUrl,
  }) {
    final isDarkMode = Get.find<ThemeController>().isDarkMode.value;
    
    return InkWell(
      onTap: () {
        BrowsingHistoryController _browsing = Get.put(BrowsingHistoryController());
        print('//////////////// isIduser:${Get.find<LoadingController>().currentUser?.id}');

        Get.find<LoadingController>().currentUser != null
            ? _browsing.addHistory(categoryId: widget.categoryId, subcat1Id: idSub, userId: Get.find<LoadingController>().currentUser?.id??0)
            : null;
        Get.find<PopularHistoryController>().addOrIncrement(categoryId: widget.categoryId, subcat1Id: idSub);

        controller.idOfSubCate.value = idSub;
        controller.nameOfSubCate.value = nameSub;
        
        Get.to(() => SubCategoriesScreenLeveLTwo(
          nameMainCate: nameCate,
          MainId: widget.categoryId,
          SubCateId: idSub,
          subCateName: nameSub,
          allSubOnecount: adsCount,
          adsPeriod: widget.adsPeriod,
        ));
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                if (imageUrl != null && imageUrl.isNotEmpty)
                  _buildImageWidget(imageUrl),
                SizedBox(width: 8.w),
                Text(
                  nameSub,
                  style: TextStyle(
                    fontSize: AppTextStyles.large,
                    fontWeight: FontWeight.w500,
                    fontFamily: AppTextStyles.appFontFamily,
                    color: AppColors.textPrimary(isDarkMode),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
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