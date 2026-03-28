import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../controllers/ThemeController.dart';
import '../../core/constant/app_text_styles.dart';
import '../../core/constant/appcolors.dart';
import 'servicesItems/AboutUsScreen.dart';
import 'servicesItems/AddAdMechanismScreen.dart';
import 'servicesItems/ContactUsScreen.dart';
import 'servicesItems/PremiumPackagesScreen.dart';
import 'servicesItems/ReportProblemScreen.dart';
import 'servicesItems/TermsAndConditionsScreen.dart';

class ServicesDrawer extends StatelessWidget {
  const ServicesDrawer({Key? key}) : super(key: key);

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
                        bottomRight: Radius.circular(12.r)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('خدماتنا'.tr, 
                            style: TextStyle(
                              fontFamily: AppTextStyles.appFontFamily,
                              color: AppColors.onPrimary,
                              fontSize: AppTextStyles.xxlarge,

                              fontWeight: FontWeight.w700,
                            )),
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
                        // Services Section
                        _section(
                          title: 'الخدمات المتاحة'.tr,
                          icon: Icons.handyman_outlined,
                          items: [
                            _buildItem(
                              title: '١- من نحن'.tr,
                              icon: Icons.info_outline,
                              onTap: () => _handleAboutUs(),
                            ),
                            _buildItem(
                              title: '٢- الشروط والأحكام'.tr,
                              icon: Icons.description_outlined,
                              onTap: () => _handleTermsAndConditions(),
                            ),
                            _buildItem(
                              title: '٣- الباقات'.tr,
                              icon: Icons.credit_card_outlined,
                              onTap: () => _handlePackages(),
                            ),
                            _buildItem(
                              title: '٤- آلية إضافة إعلان'.tr,
                              icon: Icons.add_circle_outline,
                              onTap: () => _handleAddAdMechanism(),
                            ),
                        
                           _buildItem(
                              title: '٥- الإبلاغ عن مشكلة'.tr,
                              icon: Icons.report_problem_outlined,
                              onTap: () => _handleReportProblem(),
                            ),
                          ],
                          cardColor: cardColor,
                          primary: primary,
                          textColor: textColor,
                          iconColor: iconColor,
                        ),
                        
                        SizedBox(height: 24.h),
                        
                        // Support Section
                      /*  _section(
                          title: 'الدعم الفني',
                          icon: Icons.support_agent,
                          items: [
                            _buildItem(
                              title: 'الأسئلة الشائعة',
                              icon: Icons.help_outline,
                              onTap: () => _handleFAQ(),
                            ),
                            _buildItem(
                              title: 'الدليل الإرشادي',
                              icon: Icons.menu_book_outlined,
                              onTap: () => _handleUserGuide(),
                            ),
                          ],
                          cardColor: cardColor,
                          primary: primary,
                          textColor: textColor,
                          iconColor: iconColor,
                        ),*/
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

  Widget _buildItem({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
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
            leading: Icon(icon, color: iconColor, size: 22.w),
            title: Text(title, 
                style: TextStyle(
                  fontSize: AppTextStyles.medium,

                  color: AppColors.textPrimary(isDarkMode),
                  fontFamily: AppTextStyles.appFontFamily,
                )),
            trailing: Icon(Icons.arrow_forward_ios, 
                  size: 16.w, 
                  color: iconColor),
            onTap: onTap,
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
                Text(title, 
                    style: TextStyle(
                      fontSize: AppTextStyles.large,

                      fontWeight: FontWeight.w600,
                      color: primary,
                      fontFamily: AppTextStyles.appFontFamily,
                    )),
              ],
            ),
          ),
          
          // Section items
          ...items,
        ],
      ),
    );
  }

  // ============== معالجات الأحداث ============== //
  
  void _handleAboutUs() {
    Get.to(()=>AboutUsScreen());

  }

  void _handleTermsAndConditions() {
       Get.to(()=>TermsAndConditionsScreen());

  }

  void _handlePackages() {
    Get.to(()=> PremiumPackagesScreen());
        // التنقل إلى صفحة الباقات
  }

  void _handleAddAdMechanism() {
           Get.to(()=>AddAdMechanismScreen());

  }

  void _handleContactUs() {
              Get.to(()=>ContactUsScreen());

  }

  void _handleReportProblem() {
                  Get.to(()=>ReportProblemScreen());

  }

}