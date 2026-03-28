// favorite_sellers_unified_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../controllers/FavoriteSellerController.dart';
import '../../../controllers/LoadingController.dart';
import '../../../controllers/ThemeController.dart';
import '../../../core/constant/app_text_styles.dart';
import '../../../core/constant/appcolors.dart';
import '../../../core/data/model/FavoriteSeller.dart';
import '../../AdvertiserAdsScreen/AdvertiserAdsScreen.dart';


class FavoriteSellersUnifiedPage extends StatefulWidget {
  const FavoriteSellersUnifiedPage({Key? key}) : super(key: key);

  @override
  State<FavoriteSellersUnifiedPage> createState() => _FavoriteSellersUnifiedPageState();
}

class _FavoriteSellersUnifiedPageState extends State<FavoriteSellersUnifiedPage> {
  final FavoriteSellerController favCtrl = Get.put(FavoriteSellerController());
  final ThemeController themeController = Get.find<ThemeController>();
  final LoadingController loadingController = Get.find<LoadingController>();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initFetch());
  }

  void _initFetch() {
    if (_initialized) return;
    final user = loadingController.currentUser;
    if (user != null) {
      _initialized = true;
      favCtrl.fetchFavorites(userId: user?.id??0);
    } else {
      // لو ما فيه user حالياً، ممكن تستنى أو تعرض رسالة
    }
  }

  String _relativeFrom(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 0) return '${'قبل'.tr} ${diff.inDays} ${'يوم'.tr}';
    if (diff.inHours > 0) return '${'قبل'.tr} ${diff.inHours} ${'ساعة'.tr}';
    if (diff.inMinutes > 0) return '${'قبل'.tr} ${diff.inMinutes} ${'دقيقة'.tr}';
    return 'الآن'.tr;
  }

  Future<void> _refresh() async {
    final user = loadingController.currentUser;
    if (user != null) {
      await favCtrl.fetchFavorites(userId: user?.id??0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = themeController.isDarkMode.value;

    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      appBar: AppBar(
        backgroundColor: AppColors.appBar(isDark),
        title: Text(
          'الباعة المفضّلين'.tr,
          style: TextStyle(
            fontFamily: AppTextStyles.appFontFamily,
            color: AppColors.onPrimary,
            fontSize: AppTextStyles.xlarge,

          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.onPrimary),
          onPressed: (){
              Get.back();  
              Get.back();
          }
         
        ),
      ),
      body: Obx(() {
        if (favCtrl.isLoadingFavorites.value && !_initialized) {
          return Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (favCtrl.favoriteList.isEmpty) {
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: 120.h),
                Center(
                  child: Text(
                    'لا توجد بائعين مفضّلين'.tr,
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: AppTextStyles.large,

                      color: AppColors.textPrimary(isDark),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.separated(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            itemCount: favCtrl.favoriteList.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              thickness: 0.5,
              color: AppColors.grey.withOpacity(0.5),
            ),
            itemBuilder: (context, index) {
              final FavoriteSeller s = favCtrl.favoriteList[index];
              final subtitle = '${'متابع منذ'.tr} ${_relativeFrom(s.followedAt)}';
              return _buildSellerTile(s, subtitle, isDark);
            },
          ),
        );
      }),
    );
  }

  Widget _buildSellerTile(FavoriteSeller seller, String subtitle, bool isDark) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          leading: seller.advertiser.logo != null && seller.advertiser.logo!.isNotEmpty
              ? CircleAvatar(
                  radius: 22.r,
                  backgroundImage: NetworkImage(seller.advertiser.logo!),
                )
              : CircleAvatar(
                  radius: 22.r,
                  backgroundColor: AppColors.grey,
                  child: Icon(Icons.store, color: Colors.white),
                ),
          title: Text(
            seller.advertiser.name.toString(),
            style: TextStyle(
              fontFamily: AppTextStyles.appFontFamily,
              fontSize: AppTextStyles.medium,

              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary(isDark),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              fontFamily: AppTextStyles.appFontFamily,
              fontSize: AppTextStyles.small,

              color: Colors.green.shade700,
            ),
          ),
          trailing: IconButton(
            icon: Icon(Icons.more_vert, color: AppColors.textSecondary(isDark)),
            onPressed: () => _showOptionsForSeller(seller, isDark),
          ),
          onTap: () => _openSellerAds(seller),
        ),
      ],
    );
  }

  void _showOptionsForSeller(FavoriteSeller seller, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card(isDark),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.store),
                title: Text('عرض إعلانات البائع'.tr, style: TextStyle(fontFamily: AppTextStyles.appFontFamily)),
                onTap: () {
                  Get.back();
                  _openSellerAds(seller);
                },
              ),
              ListTile(
                leading: Icon(Icons.favorite_border),
                title: Text('إلغاء المتابعة'.tr, style: TextStyle(fontFamily: AppTextStyles.appFontFamily)),
                onTap: () async {
                  Get.back();
                  final userId = loadingController.currentUser?.id ?? 0;
                  final success = await favCtrl.toggleFavoriteByIds(
                    userId: userId,
                    advertiserProfileId: seller.advertiserProfileId,
                  );
                  if (success) {
                    Get.snackbar('نجاح'.tr, 'تم إلغاء المتابعة'.tr,
                      backgroundColor: Colors.green.withOpacity(0.9),
                      colorText: Colors.white,
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  } else {
                    Get.snackbar('فشل'.tr, 'حدث خطأ، حاول لاحقاً'.tr,
                      backgroundColor: Colors.red.withOpacity(0.9),
                      colorText: Colors.white,
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.share),
                title: Text('مشاركة'.tr, style: TextStyle(fontFamily: AppTextStyles.appFontFamily)),
                onTap: () {
                  // TODO: مشاركة رابط البائع
                  Get.back();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _openSellerAds(FavoriteSeller seller) async {
    // جلب إعلانات البائع ثم الانتقال لصفحة الإعلانات عندك (إن وُجدت)
    try {
      await favCtrl.fetchAdvertiserAds(advertiserProfileId: seller.advertiserProfileId);
          // الانتقال لشاشة إعلانات المعلن
      Get.to(() => AdvertiserAdsScreen(
        advertiser: seller.advertiser,
        idAdv: seller.advertiserProfileId,
      ));
    } catch (e) {
      debugPrint('Failed open seller ads: $e');
    }
  }
}
