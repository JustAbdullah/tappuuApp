import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:tappuu_app/views/UserSettings/itemsUserSettings/LanguageSettingsPage.dart';
import '../../controllers/AuthController.dart';
import '../../controllers/LoadingController.dart';
import '../../controllers/ThemeController.dart';
import '../../core/constant/app_text_styles.dart';
import '../../core/constant/appcolors.dart';
import '../AddAds/AddAdScreen.dart';
import '../AdvertiserScreen/AdvertiserDataScreen.dart';
import '../AuthScreen/ResetPasswordScreen.dart';
import '../MyConversationsScreen/MyConversationsScreen.dart';
import '../UserAds/UserAdsScreen.dart';
import 'FavoriteGroupsPage/FavoriteGroupsPage.dart';
import 'FavoriteSellersPage/FavoriteSellersPage.dart';
import 'MyReportsScreen/MyReportsScreen.dart';
import 'TransferProofsPage/TransferProofsPage.dart';
import 'UserWalletsPage/UserWalletsPage.dart' ;
import 'itemsUserSettings/AdvertiserProfilesScreen.dart';
import 'itemsUserSettings/CurrencySettingsPage.dart';
import 'itemsUserSettings/SearchHistoryDirectPage/SearchHistoryDirectPage.dart';
import 'itemsUserSettings/SearchHistoryScreen/SearchHistoryScreen.dart';
import 'itemsUserSettings/UserInfoPage.dart';

class SettingsDrawer extends StatelessWidget {
  const SettingsDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    final isDarkMode = themeController.isDarkMode.value;

    return Obx(() {
      final bgColor = AppColors.surface(isDarkMode);
      final cardColor = AppColors.card(isDarkMode);
      final primary = AppColors.primary;
      final textColor = AppColors.textPrimary(isDarkMode);
      final iconColor = AppColors.icon(isDarkMode);
      final dividerColor = AppColors.divider(isDarkMode);

      return Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Drawer(
            width: 280.w,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.horizontal(left: Radius.circular(16.r)),
            ),
            child: Container(
              color: bgColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header with improved styling
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
                    decoration: BoxDecoration(
                      color: AppColors.appBar(isDarkMode),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(12.r),
                        bottomRight: Radius.circular(12.r),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'الإعدادات'.tr,
                          style: TextStyle(
                            fontFamily: AppTextStyles.appFontFamily,
                            color: AppColors.onPrimary,
                            fontSize: AppTextStyles.xxlarge,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: AppColors.onPrimary, size: 24.w),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
                      children: [
                        // Ads Section
                        _section(
                          title: 'الإعلانات'.tr,
                          icon: Icons.campaign_outlined,
                          items: [
                            _buildItem(
                              title: 'إضافة إعلان جديد'.tr,
                              onTap: () {
                                Get.back(); // close drawer
                                Get.to(() => AddAdScreen());
                              },
                            ),
                            _buildItem(
                              title: 'إدارة الإعلانات'.tr,
                              onTap: () {
                                Get.back();
                                Get.to(() => UserAdsScreen(statusAds: 'published', name: 'إعلاناتي المنشورة'));
                              },
                            ),
                            _buildItem(
                              title: 'غير المنشورة'.tr,
                              onTap: () {
                                Get.back();
                                Get.to(() => UserAdsScreen(statusAds: 'under_review', name: 'إعلاناتي تحت المراجعة'));
                              },
                            ),
                          ],
                          cardColor: cardColor,
                          primary: primary,
                          textColor: textColor,
                          iconColor: iconColor,
                        ),

                        SizedBox(height: 16.h),

                        // Account Section
                        _section(
                          title: 'حسابي'.tr,
                          icon: Icons.person_outline,
                          items: [
                            _buildItem(
                              title: 'معلوماتي'.tr,
                              onTap: () {
                                Get.back();
                                Get.to(() => UserInfoPage());
                              },
                            ),
                            _buildItem(
                              title: 'محفظتي'.tr,
                              onTap: () {
                                Get.back();
                                Get.to(() => UserWalletsPage(userId: Get.find<LoadingController>().currentUser?.id ?? 0));
                              },
                            ),
                            _buildItem(
                              title: 'عمليات التحويل'.tr,
                              onTap: () {
                                Get.back();
                                Get.to(() => TransferProofsPage(userId: Get.find<LoadingController>().currentUser?.id ?? 0));
                              },
                            ),
                            _buildItem(
                              title: 'تعيين كلمة المرور'.tr,
                              onTap: () {
                                Get.back();
                                Get.to(() => ResetPasswordScreen());
                              },
                            ),
                            _buildItem(
                              title: 'المحادثات'.tr,
                              onTap: () {
                                Get.back();
                                Get.to(() => ConversationsListScreen());
                              },
                            ),
                            _buildItem(
                              title: 'بلاغاتي'.tr,
                              onTap: () {
                                Get.back();
                                Get.to(() => MyReportsScreen());
                              },
                            ),
                          ],
                          cardColor: cardColor,
                          primary: primary,
                          textColor: textColor,
                          iconColor: iconColor,
                        ),

                        SizedBox(height: 16.h),

                        // Advertisers Section
                        _section(
                          title: 'المعلنين'.tr,
                          icon: Icons.business_outlined,
                          items: [
                            _buildItem(
                              title: 'إدارة المعلنين'.tr,
                              onTap: () {
                                Get.back();
                                Get.to(() => AdvertiserProfilesScreen());
                              },
                            ),
                            _buildItem(
                              title: 'إضافة معلن جديد'.tr,
                              onTap: () {
                                Get.back();
                                Get.to(() => AdvertiserDataScreen());
                              },
                            ),
                          ],
                          cardColor: cardColor,
                          primary: primary,
                          textColor: textColor,
                          iconColor: iconColor,
                        ),

                        SizedBox(height: 16.h),

                        // Favorites Section
                        _section(
                          title: 'المفضلات'.tr,
                          icon: Icons.favorite_border,
                          items: [
                            _buildItem(
                              title: 'مفضلاتي من الإعلانات'.tr,
                              onTap: () {
                                Get.back();
                                Get.to(() => FavoriteGroupsPage());
                              },
                            ),
                            _buildItem(
                              title: 'سجل المشاهدات الأخيرة'.tr,
                              onTap: () {
                                Get.back();
                                Get.to(() => SearchHistoryScreen());
                              },
                            ),
                            _buildItem(
                              title: 'سجل البحث'.tr,
                              onTap: () {
                                Get.back();
                                Get.to(() => SearchHistoryDirectPage());
                              },
                            ),
                            _buildItem(
                              title: 'الباعة المفضلين'.tr,
                              onTap: () {
                                Get.back();
                                Get.to(() => FavoriteSellersUnifiedPage());
                              },
                            ),
                          ],
                          cardColor: cardColor,
                          primary: primary,
                          textColor: textColor,
                          iconColor: iconColor,
                        ),

                        SizedBox(height: 16.h),

                        // Appearance Section
                        _section(
                          title: 'المظهر'.tr,
                          icon: Icons.palette_outlined,
                          items: [
                            /* _buildItem(
                              title: 'اللغة'.tr,
                              onTap: () {
                                Get.back();
                                Get.to(() => LanguageSettingsPage());
                              },
                              showArrow: true,
                            ),*/
                            _buildItem(
                              title: 'العملة'.tr,
                              onTap: () {
                                Get.back();
                                Get.to(() => CurrencySettingsPage());
                              },
                              showArrow: true,
                            ),
                            _buildThemeToggleItem(
                              onToggle: (value) => themeController.toggleTheme(),
                              isDarkMode: isDarkMode,
                            ),
                          ],
                          cardColor: cardColor,
                          primary: primary,
                          textColor: textColor,
                          iconColor: iconColor,
                        ),

                        SizedBox(height: 24.h),

                        // Divider
                        Divider(height: 1.h, color: dividerColor, thickness: 0.5),
                        SizedBox(height: 16.h),

                        // Actions with improved styling
                        _actionTile(
                          'تسجيل خروج'.tr,
                          Icons.logout,
                          AppColors.error,
                          iconColor: iconColor,
                          onTap: () {
                            Get.back(); // close drawer first
                            Get.dialog(
                              AlertDialog(
                                title: Text('تسجيل الخروج'.tr),
                                content: Text('هل أنت متأكد أنك تريد تسجيل الخروج؟'.tr),
                                actions: [
                                  TextButton(
                                    onPressed: () => Get.back(),
                                    child: Text('إلغاء'.tr),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Get.find<LoadingController>().logout();
                                    },
                                    child: Text('تسجيل الخروج'.tr),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 8.h),
                        _actionTile(
                          'حذف الحساب'.tr,
                          Icons.delete_outline,
                          AppColors.error,
                          iconColor: iconColor,
                          onTap: () {
                            Get.back(); // close drawer first
                            Get.dialog(
                              AlertDialog(
                                title: Text('حذف الحساب'.tr),
                                content: Text('هل أنت متأكد أنك تريد حذف حسابك؟ هذه العملية لا يمكن التراجع عنها.'.tr),
                                actions: [
                                  TextButton(
                                    onPressed: () => Get.back(),
                                    child: Text('إلغاء'.tr),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Get.find<AuthController>().deleteUser(Get.find<LoadingController>().currentUser?.id ?? 0);
                                      Get.back();
                                    },
                                    child: Text('حذف الحساب'.tr, style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  // دالة لبناء عنصر عادي مع حدث منفصل
  Widget _buildItem({
    required String title,
    required VoidCallback onTap,
    bool showArrow = true,
  }) {
    final ThemeController themeController = Get.find<ThemeController>();
    final isDarkMode = themeController.isDarkMode.value;
    final iconColor = AppColors.icon(isDarkMode);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 8.w),
            title: Text(
              title,
              style: TextStyle(
                fontSize: AppTextStyles.medium,
                color: AppColors.textPrimary(isDarkMode),
                fontFamily: AppTextStyles.appFontFamily,
              ),
            ),
            trailing: showArrow
                ? Icon(Icons.arrow_forward_ios, size: 16.w, color: iconColor)
                : null,
            onTap: onTap,
            minLeadingWidth: 0,
            visualDensity: VisualDensity.compact,
          ),
          Divider(height: 0.5.h, color: AppColors.divider(isDarkMode)),
        ],
      ),
    );
  }

  // دالة لبناء عنصر التبديل بين الوضع المظلم والفاتح
  Widget _buildThemeToggleItem({
    required ValueChanged<bool> onToggle,
    required bool isDarkMode,
  }) {
    final primary = AppColors.primary;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 8.w),
            title: Text(
              'ثيم التطبيق'.tr,
              style: TextStyle(
                fontSize: AppTextStyles.medium,
                color: AppColors.textPrimary(isDarkMode),
                fontFamily: AppTextStyles.appFontFamily,
              ),
            ),
            trailing: Switch(
              value: isDarkMode,
              onChanged: onToggle,
              activeColor: primary,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onTap: () => onToggle(!isDarkMode),
            minLeadingWidth: 0,
            visualDensity: VisualDensity.compact,
          ),
          Divider(height: 0.5.h, color: AppColors.divider(isDarkMode)),
        ],
      ),
    );
  }

  Widget _section({
    required String title,
    required IconData icon,
    required List<Widget> items,
    required Color cardColor,
    required Color primary,
    required Color textColor,
    required Color iconColor,
  }) {
    return Card(
      color: cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header with improved spacing
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Row(
              children: [
                Icon(icon, color: primary, size: 22.w),
                SizedBox(width: 12.w),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: AppTextStyles.large,
                    fontWeight: FontWeight.w600,
                    color: primary,
                    fontFamily: AppTextStyles.appFontFamily,
                  ),
                ),
              ],
            ),
          ),

          // Section items
          ...items,
        ],
      ),
    );
  }

  Widget _actionTile(String text, IconData icon, Color color, {
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      leading: Icon(icon, color: color),
      title: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: AppTextStyles.medium,
          fontFamily: AppTextStyles.appFontFamily,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
      ),
      minLeadingWidth: 24.w,
    );
  }
}
//.One..Page .//