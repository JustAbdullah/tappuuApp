import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:tappuu_app/core/constant/appcolors.dart';
import 'package:tappuu_app/core/constant/app_text_styles.dart';
import 'package:tappuu_app/controllers/ThemeController.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({Key? key}) : super(key: key);

  // دالة لفتح تطبيق البريد
  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@stayinme.com',
      queryParameters: {'subject': 'استفسار عن تطبيق Stay in Me'},
    );

    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      Get.snackbar('خطأ'.tr, 'لا يمكن فتح تطبيق البريد'.tr,
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  // دالة لفتح الرابط في المتصفح
  Future<void> _launchURL(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      Get.snackbar('خطأ'.tr, 'لا يمكن فتح الرابط'.tr,
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          title: Text('التواصل معنا'.tr, 
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
        body: SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // مقدمة
              Text('يسعدنا تواصلكم معنا! فريق Stay in Me دائمًا متاح للإجابة على استفساراتكم ومساعدتكم في أي وقت.'.tr,
                style: TextStyle(
                  fontSize: AppTextStyles.large,

                  height: 1.8,
                  color: textColor,
                  fontFamily: AppTextStyles.appFontFamily,
                ),
              ),
              SizedBox(height: 30.h),
              
              // بطاقة معلومات الاتصال
              Container(
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
                  children: [
                    _buildContactInfo(
                      icon: Icons.email,
                      title: 'البريد الإلكتروني'.tr,
                      value: 'support@stayinme.com',
                      onTap: _launchEmail,
                      isDarkMode: isDarkMode,
                    ),
                    SizedBox(height: 15.h),
                    _buildContactInfo(
                      icon: Icons.phone,
                      title: 'الهاتف'.tr,
                      value: '+963 11 123 4567',
                      onTap: () => _launchURL('tel:+963111234567'),
                      isDarkMode: isDarkMode,
                    ),
                    SizedBox(height: 15.h),
                    _buildContactInfo(
                      icon: Icons.language,
                      title: 'الموقع الإلكتروني'.tr,
                      value: 'www.stayinme.com',
                      onTap: () => _launchURL('https://www.stayinme.com'),
                      isDarkMode: isDarkMode,
                    ),
                    SizedBox(height: 15.h),
                    _buildContactInfo(
                      icon: Icons.location_on,
                      title: 'العنوان'.tr,
                      value: 'دمشق، سوريا'.tr,
                      onTap: () => _launchURL('https://maps.app.goo.gl/'),
                      isDarkMode: isDarkMode,
                    ),
                  ],
                ),
              ),
            
              SizedBox(height: 30.h),
              
              // ساعات العمل
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.access_time, 
                          color: AppColors.primary, size: 24.w),
                        SizedBox(width: 10.w),
                        Text('ساعات العمل'.tr,
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
                    _buildWorkingHours('الأحد - الخميس', '9:00 ص - 5:00 م'),
                    _buildWorkingHours('الجمعة', '10:00 ص - 2:00 م'),
                    _buildWorkingHours('السبت', 'عطلة رسمية'),
                  ],
                ),
              ),
              
           
              SizedBox(height: 30.h),
            ],
          ),
        ),
      );
    });
  }
  
  Widget _buildContactInfo({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 50.w,
            height: 50.w,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 24.w),
          ),
          SizedBox(width: 15.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                  style: TextStyle(
                    fontSize: AppTextStyles.large,

                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontFamily: AppTextStyles.appFontFamily,
                  ),
                ),
                SizedBox(height: 5.h),
                Text(value,
                  style: TextStyle(
                    fontSize: AppTextStyles.medium,

                    color: AppColors.textPrimary(isDarkMode),
                    fontFamily: AppTextStyles.appFontFamily,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, 
            color: AppColors.grey500, size: 18.w),
        ],
      ),
    );
  }
  
  Widget _buildWorkingHours(String day, String hours) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(day,
            style: TextStyle(
              fontSize: AppTextStyles.large,

              fontWeight: FontWeight.w600,
              fontFamily: AppTextStyles.appFontFamily,
            ),
          ),
          Text(hours,
            style: TextStyle(
              fontSize: AppTextStyles.large,

              color: AppColors.grey600,
              fontFamily: AppTextStyles.appFontFamily,
            ),
          ),
        ],
      ),
    );
  }
}