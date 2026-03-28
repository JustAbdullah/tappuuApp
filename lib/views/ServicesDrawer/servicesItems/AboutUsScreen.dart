// lib/views/about_us_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:tappuu_app/core/constant/appcolors.dart';
import 'package:tappuu_app/core/constant/app_text_styles.dart';
import 'package:tappuu_app/core/constant/images_path.dart';
import 'package:tappuu_app/controllers/AboutUsController.dart';
import 'package:tappuu_app/controllers/ThemeController.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/data/model/AboutUs.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AboutUsController aboutUsController = Get.put(AboutUsController());
    final ThemeController themeController = Get.find<ThemeController>();
    
    return Obx(() {
      final isDarkMode = themeController.isDarkMode.value;
      final bgColor = AppColors.background(isDarkMode);
      final textColor = AppColors.textPrimary(isDarkMode);
      final cardColor = AppColors.card(isDarkMode);
      
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: AppColors.appBar(isDarkMode),
          centerTitle: true,
          title: Text('من نحن'.tr, 
            style: TextStyle(
              fontFamily: AppTextStyles.appFontFamily,
              color: AppColors.onPrimary,
              fontSize: AppTextStyles.xxlarge,

              fontWeight: FontWeight.w700,
            )),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Get.back(),
          ),
        ),
        body: Obx(() {
          if (aboutUsController.isLoading.value) {
            return Center(child: CircularProgressIndicator());
          }

          final aboutUs = aboutUsController.aboutUs.value;
          if (aboutUs == null) {
            return Center(child: Text('لا يوجد بيانات عن من نحن'.tr));
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // شعار التطبيق
               
                SizedBox(height: 30.h),
              
                // عنوان رئيسي
                Text(aboutUs.title,
                  style: TextStyle(
                    fontSize: AppTextStyles.xxxlarge,

                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontFamily: AppTextStyles.appFontFamily,
                  ),
                ),
                SizedBox(height: 15.h),
              
                // وصف التطبيق
                Text(aboutUs.description,
                  style: TextStyle(
                    fontSize: AppTextStyles.large,

                    height: 1.8,
                    color: textColor,
                    fontFamily: AppTextStyles.appFontFamily,
                  ),
                ),
                SizedBox(height: 30.h),
              
                // بطاقة رسالتنا
                _buildInfoCard(
                  title: 'رسالتنا'.tr,
                  content: 'تقديم منصة شاملة وآمنة تتيح للمستخدمين التواصل التجاري بسلاسة وثقة، مع الحفاظ على خصوصية وأمان مستخدمينا.'.tr,
                  icon: Icons.message,
                  isDarkMode: isDarkMode,
                  cardColor: cardColor,
                ),
                SizedBox(height: 20.h),
              
                // بطاقة رؤيتنا
                _buildInfoCard(
                  title: 'رؤيتنا'.tr,
                  content: 'أن نكون التطبيق الأول والوجهة المفضلة للاعلانات المبوبة في سوريا والوطن العربي، من خلال تحديثات مستمرة وخدمات مميزة.'.tr,
                  icon: Icons.visibility,
                  isDarkMode: isDarkMode,
                  cardColor: cardColor,
                ),
                SizedBox(height: 20.h),
              
                // بطاقة مميزاتنا
                _buildInfoCard(
                  title: 'مميزاتنا'.tr,
                  content: '• واجهة مستخدم سهلة ومبسطة\n• تصنيفات دقيقة ومتنوعة\n• إدارة فعالة للإعلانات\n• دعم فني متواصل\n• تحديثات مستمرة لتحسين التجربة'.tr,
                  icon: Icons.star,
                  isDarkMode: isDarkMode,
                  cardColor: cardColor,
                ),
                SizedBox(height: 30.h),
              
                // فريق العمل
                Text('فريق العمل'.tr,
                  style: TextStyle(
                    fontSize: AppTextStyles.xxxlarge,

                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontFamily: AppTextStyles.appFontFamily,
                  ),
                ),
                SizedBox(height: 15.h),
              
                Text('نحن فريق من المطورين والمصممين والمختصين في التسويق الرقمي، نعمل بجهد لتطوير التطبيق باستمرار وتقديم أفضل تجربة للمستخدمين.'.tr,
                  style: TextStyle(
                    fontSize: AppTextStyles.large,

                    height: 1.8,
                    color: textColor,
                    fontFamily: AppTextStyles.appFontFamily,
                  ),
                ),
                SizedBox(height: 20.h),
              
                // روابط التواصل الاجتماعي
                if (aboutUs.facebook != null || 
                    aboutUs.twitter != null || 
                    aboutUs.instagram != null || 
                    aboutUs.youtube != null || 
                    aboutUs.whatsapp != null)
                  _buildSocialLinks(aboutUs: aboutUs),
              
                SizedBox(height: 30.h),
              
                // حقوق النشر
                Center(
                  child: Text('© 2025 Stay in Me. جميع الحقوق محفوظة'.tr,
                    style: TextStyle(
                      fontSize: AppTextStyles.medium,

                      color: AppColors.grey500,
                      fontFamily: AppTextStyles.appFontFamily,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      );
    });
  }
  
  Widget _buildInfoCard({
    required String title,
    required String content,
    required IconData icon,
    required bool isDarkMode,
    required Color cardColor,
  }) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 24.w),
              SizedBox(width: 10.w),
              Text(title,
                style: TextStyle(
                  fontSize: AppTextStyles.xlarge,

                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  fontFamily: AppTextStyles.appFontFamily,
                ),
              ),
            ],
          ),
          SizedBox(height: 15.h),
          Text(content,
            style: TextStyle(
              fontSize: AppTextStyles.medium,

              height: 1.7,
              color: AppColors.textPrimary(isDarkMode),
              fontFamily: AppTextStyles.appFontFamily,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialLinks({required AboutUs aboutUs}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('تواصل معنا'.tr,
          style: TextStyle(
            fontSize: AppTextStyles.xxxlarge,

            fontWeight: FontWeight.bold,
            color: AppColors.primary,
            fontFamily: AppTextStyles.appFontFamily,
          ),
        ),
        SizedBox(height: 15.h),
        Wrap(
          spacing: 15.w,
          children: [
            if (aboutUs.facebook != null)
              _buildSocialIcon(
                icon: Icons.facebook,
                color: Colors.blue[700]!,
                onTap: () => _launchURL(aboutUs.facebook!),
              ),
            if (aboutUs.twitter != null)
              _buildSocialIcon(
                icon: Icons.camera,
                color: Colors.lightBlue,
                onTap: () => _launchURL(aboutUs.twitter!),
              ),
            if (aboutUs.instagram != null)
              _buildSocialIcon(
                icon: Icons.camera_alt,
                color: Colors.pink,
                onTap: () => _launchURL(aboutUs.instagram!),
              ),
            if (aboutUs.youtube != null)
              _buildSocialIcon(
                icon: Icons.video_library,
                color: Colors.red,
                onTap: () => _launchURL(aboutUs.youtube!),
              ),
            if (aboutUs.whatsapp != null)
              _buildSocialIcon(
                icon: Icons.chat,
                color: Colors.green,
                onTap: () => _launchURL('https://wa.me/${aboutUs.whatsapp}'),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialIcon({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 50.w,
        height: 50.w,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(icon, color: Colors.white, size: 24.w),
        ),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      print('Could not launch $url');
    }
  }
}