import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tappuu_app/controllers/CurrencyController.dart';
import 'package:tappuu_app/controllers/LoadingController.dart';
import 'package:tappuu_app/views/AddAds/AddAdScreen.dart';
import '../../controllers/AdsManageSearchController.dart';
import '../../controllers/BrowsingHistoryController.dart';
import '../../controllers/PopularHistoryController.dart';
import '../../controllers/ThemeController.dart';
import '../../controllers/WaitingScreenController.dart';
import '../../controllers/home_controller.dart';
import '../../core/constant/appcolors.dart';
import '../../core/constant/images_path.dart';
import '../../core/localization/changelanguage.dart';
import '../../customWidgets/EditableTextWidget.dart';
import '../MyConversationsScreen/MyConversationsScreen.dart';
import '../UserSettings/RecommendedAds/RecommendedAds.dart';
import '../UserSettings/itemsUserSettings/FavoritesScreen/FavoritesAdItem.dart';
import '../UserSettings/itemsUserSettings/FavoritesScreen/FavoritesScreen.dart';
import '../UserSettings/itemsUserSettings/SearchHistoryScreen/SearchHistoryAdItem.dart';
import '../UserSettings/itemsUserSettings/SearchHistoryScreen/SearchHistoryScreen.dart';
import '../UserSettings/itemsUserSettings/UserInfoPage.dart';
import '../urgent/MainCategoriesWithUrgentScreen.dart';
import '../viewAdsScreen/AdItem.dart';
import '../viewAdsScreen/AdsScreen.dart';
import 'homeItems/LoginPopup.dart';
import 'homeItems/MainCategories/mainCategoriesScreen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tappuu_app/core/constant/app_text_styles.dart';
import 'homeItems/PopularTagsSection/PopularTagsSection.dart';
import 'package:tappuu_app/controllers/FavoritesController.dart';
import 'package:tappuu_app/controllers/ViewsController.dart';



import 'package:shimmer/shimmer.dart';

import 'menubar.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
final RxBool isHistoryExpanded = false.obs;
final RxBool isFavoritesExpanded = false.obs;
  final RxBool isRecommendedExpanded = false.obs; // أضف هذا

  final ThemeController themeC = Get.find<ThemeController>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final HomeController homeController = Get.find<HomeController>();
  final AdsController adsController = Get.put(AdsController());

  final LoadingController loadingController = Get.find<LoadingController>();
  final ViewsController viewsController = Get.put(ViewsController());
  final FavoritesController favoritesController = Get.put(FavoritesController());
  final PopularHistoryController popularHistoryController = Get.put(PopularHistoryController());
    final BrowsingHistoryController _browsingHistoryController = Get.put(BrowsingHistoryController());
final CurrencyController currencyController = Get.put(CurrencyController());
 @override
void initState() {
  super.initState();
  _loadUserData();
}
 void _loadUserData() async {
    if (loadingController.currentUser != null) {
      // تهيئة المتحكمات فقط للمستخدمين المسجلين
    ViewsController  viewsController = Get.put(ViewsController());
    FavoritesController  favoritesController = Get.put(FavoritesController());
    BrowsingHistoryController  _browsingHistoryController = Get.put(BrowsingHistoryController());
      
      final userId = loadingController.currentUser!.id!;
      await viewsController!.fetchViews(
        userId: userId, 
        perPage: 3, 
        lang: Get.find<ChangeLanguageController>().currentLocale.value.languageCode
      );
      
      await favoritesController!.fetchFavorites(
        userId: userId, 
        perPage: 3, 
        lang: Get.find<ChangeLanguageController>().currentLocale.value.languageCode
      );
      
      await _browsingHistoryController!.fetchRecommendedAds(
        userId: userId,
        lang: Get.find<ChangeLanguageController>().currentLocale.value.languageCode,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = themeC.isDarkMode.value;

    WidgetsBinding.instance.addPostFrameCallback((_) {
    
      if (loadingController.currentUser == null) {
          if(loadingController.showOneTimeLogin.value == false){
   Get.dialog(
          LoginPopup(),
          barrierDismissible: true,
        );
        loadingController.showOneTimeLogin.value = true;
      }else{
        
      }
     
      }
    });

    return Scaffold(
  key: _scaffoldKey,
  backgroundColor: AppColors.backgroundHome(isDarkMode),
  drawer: Menubar(), // بدل drawer العادي
  body:  SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              
              automaticallyImplyLeading: false,

              pinned: true,
              floating: false,
              expandedHeight: 0,
              toolbarHeight: 60.h,
              backgroundColor: AppColors.appBar(isDarkMode),
              flexibleSpace:  Directionality(
          textDirection: TextDirection.ltr, // نجبر اتجاه اليسار - يمين هنا فقط
        child: _buildAppBar(isDarkMode)),
            ),
            SliverList(
              delegate: SliverChildListDelegate([
                _buildSearchField(isDarkMode),
                SizedBox(height:15.h,),
                MainCategoriesScreen(),
               
                    SizedBox(height:10.h,),
                // قسم العروض العاجلة
                _buildUrgentSection(
                  hours: '24h',
                  isDarkMode: isDarkMode,
                ),
                _buildUrgentSection(
                  hours: '48h',
                  isDarkMode: isDarkMode,
                ),
                         SizedBox(height:10.h,),
                   _buildFavoritesSection(isDarkMode),

              _buildRecommendedSection(isDarkMode),

                    // قسم سجل المشاهدة
                _buildHistoryViewsSection(isDarkMode),
                
                // قسم المفضلة
             
                 
                // قسم الإعلانات المميزة
                _buildFeaturedAdsSection(isDarkMode),
                
                              
  PopularTagsSection(),
            
              ]),
            ),
          ],
        ),

        
      ),

       floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
          floatingActionButton: FloatingActionButton(
            onPressed: () {
               if (loadingController.currentUser != null) {
  Get.to(() => AddAdScreen(
                  
                  ));                  } else {
                    Get.dialog(
                      LoginPopup(),
                      barrierDismissible: true,
                    );
                  }
            
            },
            backgroundColor: AppColors.primary,
            child: Icon(Icons.add, color: Colors.white, size: 28.w),
          ),
    );
  }

  // ==================== ويدجت قسم الإعلانات المميزة (معدلة بشكل طولي) ====================
  Widget _buildFeaturedAdsSection(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal:10.w, vertical: 10.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الإعلانات المميزة'.tr,
                style: TextStyle(
                  fontFamily: AppTextStyles.appFontFamily,
                  fontSize: AppTextStyles.xlarge,

                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(isDarkMode),
                ),
              ),
              
              // رابط مشاهدة الكل
            
            ],
          ),
        ),
        
        // قائمة الإعلانات المميزة (3 عناصر فقط بشكل طولي)
        Obx(() {
          if (adsController.isLoadingFeatured.value) {
            return _buildVerticalShimmerLoader(isDarkMode);
          }
          
          if (adsController.featuredAds.isEmpty) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              child: Text(
                'لا توجد إعلانات مميزة حالياً'.tr,
                style: TextStyle(
                  fontFamily: AppTextStyles.appFontFamily,
                  fontSize: AppTextStyles.medium,

                  color: AppColors.textSecondary(isDarkMode),
                ),
              ),
            );
          }
          
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 0.w),
            child: Column(
              children: adsController.featuredAds.take(3).map((ad) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 0.h),
                  child: AdItem(
                    ad: ad,
                    viewMode: 'vertical_simple',
                  ),
                );
              }).toList(),
            ),
          );
        }),
        SizedBox(height: 10.h,),

        Padding(
          padding:  EdgeInsets.symmetric(horizontal: 15.w,vertical: 0.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [  InkWell(
                  onTap: () {
                    adsController.viewMode.value = "grid_simple";
                    Get.to(() => AdsScreen(
                      categoryId: null,
                      titleOfpage: "الإعلانات المميزة".tr,
                      onlyFeatured: true,
                    ));
                  },
                  child: Text(
                    'مشاهدة الكل'.tr,
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: AppTextStyles.small,

                      fontWeight: FontWeight.w700,
                      color: AppColors.buttonAndLinksColor,
                      decoration: TextDecoration.underline,
                      
                    ),
                  ),
                ),],),
        )
      ],
    );
  }

  // ==================== شيمر التحميل العمودي (للإعلانات المميزة وسجل المشاهدة والمفضلة) ====================
  Widget _buildVerticalShimmerLoader(bool isDarkMode) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      child: Column(
        children: List.generate(3, (index) {
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
                  offset: Offset(0, 2),
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
                        // الجزء النصي
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // العنوان (سطرين)
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
                              
                              // السعر
                              Container(
                                height: 24.h,
                                width: 120.w,
                                color: Colors.white,
                              ),
                              
                              SizedBox(height: 16.h),
                              
                              // الموقع
                              Row(
                                children: [
                                  Icon(Icons.location_on, size: 16.sp, color: Colors.transparent),
                                  SizedBox(width: 4.w),
                                  Container(
                                    height: 16.h,
                                    width: 120.w,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                              
                              SizedBox(height: 8.h),
                              
                              // التاريخ
                              Container(
                                height: 14.h,
                                width: 90.w,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(width: 16.w),
                        
                        // الصورة
                        Container(
                          width: 150.w,
                          height: 100.h,
                          color: Colors.white,
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 12.h),
                    
                    // التصنيفات
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: List.generate(3, (index) => Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
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
        }),
      ),
    );


  }
  // ======== سجل المشاهدة ======== //
Widget _buildHistoryViewsSection(bool isDarkMode) {
  final lc = Get.find<LoadingController>();

  return Obx(() {
    return _buildSectionContainer(
      title: 'سجل المشاهدة'.tr,
      description:
          'قائمة سجلات المشاهدات التى قمت بها للاعلانات بمختلف الأقسام'.tr,
      imagePath: ImagesPath.history,
      onShowPressed: () {
        if (lc.currentUserToFix.value != null) {
          isHistoryExpanded.value = true;
        } else {
          Get.dialog(LoginPopup(), barrierDismissible: true);
        }
      },
      onHidePressed: () => isHistoryExpanded.value = false,
      onViewAllPressed: () {
        if (lc.currentUserToFix.value != null) {
          Get.to(() => SearchHistoryScreen());
        } else {
          Get.dialog(LoginPopup(), barrierDismissible: true);
        }
      },
      isExpanded: isHistoryExpanded.value,
      isDarkMode: isDarkMode,
      content: Obx(() {
        if (isHistoryExpanded.value && lc.currentUserToFix.value == null) {
          return Padding(
            padding: EdgeInsets.all(1.h),
            child: Text(
              'سجل المشاهدة متاح فقط للمستخدمين المسجلين'.tr,
              textAlign: TextAlign.center,
            ),
          );
        }
        if (viewsController!.isLoading.value) {
          return _buildVerticalShimmerLoader(isDarkMode);
        }
        if (viewsController!.views.isEmpty) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: Text(
              'لا توجد عناصر في سجل المشاهدة'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTextStyles.appFontFamily,
                fontSize: AppTextStyles.medium,

                color: AppColors.textSecondary(isDarkMode),
              ),
            ),
          );
        }
        return Column(
          children: viewsController!.views.take(3).map((ad) {
            return Padding(
              padding: EdgeInsets.only(bottom: 0.h),
              child: SearchHistoryAdItem(ad: ad),
            );
          }).toList(),
        );
      }),
    );
  });
}

// ======== المفضلة ======== //
Widget _buildFavoritesSection(bool isDarkMode) {
  final lc = Get.find<LoadingController>();

  return Obx(() {
    return _buildSectionContainer(
      title: 'المفضلة'.tr,
      description:
          'قائمة الإعلانات التي قمت بحفظها في المفضلة للعودة إليها لاحقاً'.tr,
      imagePath: ImagesPath.Favorites,
      onShowPressed: () {
        if (lc.currentUserToFix.value != null) {
          isFavoritesExpanded.value = true;
        } else {
          Get.dialog(LoginPopup(), barrierDismissible: true);
        }
      },
      onHidePressed: () => isFavoritesExpanded.value = false,
      onViewAllPressed: () {
        if (lc.currentUserToFix.value != null) {
          Get.to(() => FavoritesScreen());
        } else {
          Get.dialog(LoginPopup(), barrierDismissible: true);
        }
      },
      isExpanded: isFavoritesExpanded.value,
      isDarkMode: isDarkMode,
      content: Obx(() {
        if (isFavoritesExpanded.value && lc.currentUserToFix.value == null) {
          return Padding(
            padding: EdgeInsets.all(16.h),
            child: Text(
              'المفضلة متاحة فقط للمستخدمين المسجلين'.tr,
              textAlign: TextAlign.center,
            ),
          );
        }
        if (favoritesController!.isLoading.value) {
          return _buildVerticalShimmerLoader(isDarkMode);
        }
        if (favoritesController!.favorites.isEmpty) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: Text(
              'لا توجد عناصر في المفضلة'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTextStyles.appFontFamily,
                fontSize: AppTextStyles.medium,

                color: AppColors.textSecondary(isDarkMode),
              ),
            ),
          );
        }
        return Column(
          children: favoritesController!.favorites.take(3).map((ad) {
            return Padding(
              padding: EdgeInsets.only(bottom: 0.h),
              child: FavoritesAdItem(ad: ad),
            );
          }).toList(),
        );
      }),
    );
  });
}

// ======== إعلانات مقترحة لك ======== //
Widget _buildRecommendedSection(bool isDarkMode) {
  final lc = Get.find<LoadingController>();

  return Obx(() {
    return _buildSectionContainer(
      title: 'إعلانات مقترحة لك'.tr,
      description: 'إعلانات قد تهمك بناءً على سجل تصفحك'.tr,
      imagePath: ImagesPath.lists,
      onShowPressed: () {
        if (lc.currentUserToFix.value != null) {
          isRecommendedExpanded.value = true;
        } else {
          Get.dialog(LoginPopup(), barrierDismissible: true);
        }
      },
      onHidePressed: () => isRecommendedExpanded.value = false,
      onViewAllPressed: () {
        if (lc.currentUserToFix.value != null) {
          Get.to(() => RecommendedAdsScreen());
        } else {
          Get.dialog(LoginPopup(), barrierDismissible: true);
        }
      },
      isExpanded: isRecommendedExpanded.value,
      isDarkMode: isDarkMode,
      content: Obx(() {
        if (isRecommendedExpanded.value &&
            lc.currentUserToFix.value == null) {
          return Padding(
            padding: EdgeInsets.all(16.h),
            child: Text(
              'هذه الميزة متاحة بعد تسجيل الدخول'.tr,
              textAlign: TextAlign.center,
            ),
          );
        }
        if (_browsingHistoryController!
            .isLoadingRecommended.value) {
          return _buildVerticalShimmerLoader(isDarkMode);
        }
        if (_browsingHistoryController!
            .recommendedAds.isEmpty) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: Text(
              'لا توجد إعلانات مقترحة حالياً'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTextStyles.appFontFamily,
                fontSize: AppTextStyles.medium,

                color: AppColors.textSecondary(isDarkMode),
              ),
            ),
          );
        }
        return Column(
          children: _browsingHistoryController!
              .recommendedAds
              .take(3)
              .map((ad) => Padding(
                    padding: EdgeInsets.only(bottom: 0.h),
                    child: AdItem(ad: ad, viewMode: 'vertical_simple'),
                  ))
              .toList(),
        );
      }),
    );
  });
}



  // ويدجت لحقل البحث
Widget _buildSearchField(bool isDarkMode) {
  return Container(
    height: 65.h,
    width: MediaQuery.of(context).size.width,
    color: AppColors.background(isDarkMode),
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 25.w, vertical: 12.h),
      child: Container(
        height: 20.h,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        decoration: BoxDecoration(
          color: AppColors.surface(isDarkMode),
          borderRadius: BorderRadius.circular(0.r),
          border: Border.all(
            color: Colors.black,
            width: 0.3,
          ),
        ),
        child: Row(
          children: [
            // أيقونة البحث العادي
            Icon(
              Icons.search,
              color: AppColors.grey,
              size: 24.w,
            ),
            SizedBox(width: 12.w),
            
            // حقل النص والمساحة الممتدة
            Expanded(
              child: InkWell(
                onTap: () {
                   Get.to(() => AdsScreen(
                    categoryId: null,
                    titleOfpage: "البحث والفلترة!".tr,
                    openTextSearch: true,
                  ));
                 
                },
                child: Text(
                  'ابحث عن إعلان ...'.tr,
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    fontSize: AppTextStyles.medium,
                    color: AppColors.textSecondary(isDarkMode),
                  ),
                ),
              ),
            ),
            
            // أيقونة البحث بالصورة
            InkWell(
              onTap: () {
                Get.to(() => AdsScreen(
                    categoryId: null,
                    titleOfpage: "البحث والفلترة!".tr,
                    openImageSearch: true,
                  ));
              },
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                child: Icon(
                  Icons.camera_alt,
                  color: AppColors.grey,
                  size: 24.w,
                ),
              ),
            ),
            
            // أيقونة البحث الصوتي
            InkWell(
              onTap: () {
               Get.to(() => AdsScreen(
                    categoryId: null,
                    titleOfpage: "البحث والفلترة!".tr,
                    openVoiceSearch: true,
                  ));
              },
              child: Icon(
                Icons.mic,
                color: AppColors.grey,
                size: 24.w,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  // ويدجت لقسم الإعلانات العاجلة
  Widget _buildUrgentSection({
    required String hours,
    required bool isDarkMode,
  }) {
    return InkWell(
      onTap: () {
 Get.to(()=>UrgentCategoriesScreen(period: hours,));
      
      },
      child: Container(
        height: 70.h,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        decoration: BoxDecoration(
          color: AppColors.surface(isDarkMode),
          border: Border(
            bottom: BorderSide(
              color: AppColors.grey.withOpacity(0.2),
              width: 1,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 36.w,
              height: 36.h,
              decoration: BoxDecoration(
                color: isDarkMode ? AppColors.grey700 : AppColors.grey300,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  'ع'.tr,
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    fontSize: AppTextStyles.xlarge,

                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ), 
            SizedBox(width: 7.w),
            
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'عاجل'.tr,
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: AppTextStyles.xlarge,

                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary(isDarkMode),
                    ),
                  ),
                  SizedBox(height: 0.h),
                  Text(
                    hours == "24h"
                      ? 'عرض الإعلانات الجديدة آخر 24 ساعة'.tr
                      : 'عرض الإعلانات الجديدة آخر 48 ساعة'.tr,
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: AppTextStyles.medium,

                      fontWeight: FontWeight.normal,
                      color: AppColors.textSecondary(isDarkMode),
                    ),
                  ),
                ],
              ),
            ),
            
            Icon(
              Icons.arrow_forward_ios,
              size: 20.w,
              color: AppColors.grey,
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildAppBar(bool isDarkMode) {

    final WaitingScreenController waiting =
      Get.put(WaitingScreenController(), permanent: true);
        final waitingImage = waiting.imageUrl.value;
  return   Directionality(
          textDirection: TextDirection.rtl, // نجبر اتجاه اليسار - يمين هنا فقط
          child:  Container(
      height: 70.h,
      padding: EdgeInsets.symmetric(horizontal: 12.w,vertical: 5.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // القائمة (Drawer) ثابتة على اليسار مهما كانت اللغة
          Directionality(
            textDirection: TextDirection.rtl, // نجبر اتجاه اليسار - يمين هنا فقط
            child: InkWell(
              onTap: () { print(waitingImage.toString());
                _scaffoldKey.currentState?.openDrawer();
              },
              child: Icon(
               Icons.menu,
                size: 32.w,
                color: Colors.white,
              ),
            ),
          ),  SizedBox(width: 15.w),
      Padding(
                  padding:  EdgeInsets.only(top: 7.h),
                  child:EditableTextWidget(
  keyName: 'mainTitle',
  textAlign: TextAlign.center,
  fontWeight: FontWeight.w500,
  height: 0.5.h,
),
                ),
          SizedBox(width: 0.w),
    
          // باقي العناصر يمكنهم الالتزام باتجاه النص الافتراضي (اللي ممكن يكون rtl أو ltr)
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                  SizedBox(width: 0.w),
              
    
                SizedBox(width: 00.w),
    
                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        if (loadingController.currentUser != null) {
                          Get.to(() => ConversationsListScreen());
                        } else {
                          Get.dialog(
                            LoginPopup(),
                            barrierDismissible: true,
                          );
                        }
                      },
                      child: Icon(
                        Icons.email,
                        size: 22.w,
                        color: Colors.white,
                      ),
                    ),  SizedBox(width:10.w),
    
                InkWell(
                  onTap: () {
                    if (loadingController.currentUser != null) {
                      Get.to(() => UserInfoPage());
                    } else {
                      Get.dialog(
                        LoginPopup(),
                        barrierDismissible: true,
                      );
                    }
                  },
                  child: Icon(
                    Icons.person,
                    size: 22.w,
                    color: Colors.white,
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
  );
}


  

   
  Widget _buildSectionContainer({
  required String title,
  required String description,
  required String imagePath,
  required VoidCallback onShowPressed,
  required VoidCallback onHidePressed,
  required VoidCallback onViewAllPressed,
  required bool isExpanded,
  required bool isDarkMode,
  required Widget content,
}) {
  return Container(
    margin: EdgeInsets.symmetric(vertical: 0.h, horizontal: 0.w),
    padding: EdgeInsets.all(7.w),
    decoration: BoxDecoration(
      color: AppColors.surface(isDarkMode),
      borderRadius: BorderRadius.circular(0.r),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 6,
          spreadRadius: 1,
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // الجزء العلوي (الصورة والنص وزر الإظهار) - يظهر فقط عند عدم التوسيع
        if (!isExpanded)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                imagePath,
                width: 90.w,
                height: 100.h,
                fit: BoxFit.fitWidth,
              ),
              SizedBox(width: 5.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 10.h),
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: AppTextStyles.large,

                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary(isDarkMode),
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      description,
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: AppTextStyles.small,

                        color: AppColors.textSecondary(isDarkMode),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        InkWell(
                          onTap: onShowPressed,
                          child: Text(
                            'إظهار'.tr,
                            style: TextStyle(
                              fontFamily: AppTextStyles.appFontFamily,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.buttonAndLinksColor,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

        // الجزء السفلي (المحتوى وأزرار التحكم) - يظهر فقط عند التوسيع
        if (isExpanded) ...[
          // زر الإخفاء ومشاهدة الكل
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: onHidePressed,
                child: Text(
                  'إخفاء'.tr,
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    fontSize: AppTextStyles.medium,

                    color: AppColors.error,
                  ),
                ),
              ),
              TextButton(
                onPressed: onViewAllPressed,
                child: Text(
                  'مشاهدة الكل'.tr,
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    fontSize: AppTextStyles.small,

                    color: AppColors.buttonAndLinksColor,
                  ),
                ),
              ),
            ],
          ),
          
          // المحتوى (الإعلانات)
          SizedBox(height: 0.h),
          content,
        ],
      ],
    ),
  );
}
}