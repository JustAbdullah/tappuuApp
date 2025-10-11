import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:tappuu_app/core/constant/appcolors.dart';
import 'package:tappuu_app/core/constant/app_text_styles.dart';
import 'package:tappuu_app/controllers/ThemeController.dart';
import 'package:tappuu_app/controllers/AboutUsController.dart';
import 'package:url_launcher/url_launcher.dart';

class ReportProblemScreen extends StatelessWidget {
  final _problemController = TextEditingController();
  final AboutUsController aboutUsController = Get.put(AboutUsController());

  ReportProblemScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    
    return Obx(() {
      final isDarkMode = themeController.isDarkMode.value;
      final bgColor = AppColors.background(isDarkMode);
      final textColor = AppColors.textPrimary(isDarkMode);
      final aboutUs = aboutUsController.aboutUs.value;
      
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: AppColors.appBar(isDarkMode),
          centerTitle: true,
          title: Text('الإبلاغ عن مشكلة'.tr, 
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
              Text('نحن نعتذر عن أي إزعاج تواجهه. يرجى وصف المشكلة التي واجهتها بدقة لمساعدتنا على حلها.',
                style: TextStyle(
                  fontSize: AppTextStyles.large,

                  height: 1.8,
                  color: textColor,
                  fontFamily: AppTextStyles.appFontFamily,
                ),
              ),
              SizedBox(height: 30.h),
              
              // أنواع المشاكل الشائعة
              Text('المشاكل الشائعة'.tr,
                style: TextStyle(
                  fontSize: AppTextStyles.xlarge,

                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  fontFamily: AppTextStyles.appFontFamily,
                ),
              ),
              SizedBox(height: 15.h),
              Wrap(
                spacing: 10.w,
                runSpacing: 10.h,
                children: [
                  _buildProblemChip('عدم تحميل الصور'.tr, onTap: () {
                    _problemController.text = 'عدم تحميل الصور'.tr;
                  }),
                  _buildProblemChip('تعطل التطبيق'.tr, onTap: () {
                    _problemController.text = 'تعطل التطبيق'.tr;
                  }),
                  _buildProblemChip('مشكلة في الدفع'.tr, onTap: () {
                    _problemController.text = 'مشكلة في الدفع'.tr;
                  }),
                  _buildProblemChip('مشكلة في الإعلان'.tr, onTap: () {
                    _problemController.text = 'مشكلة في الإعلان'.tr;
                  }),
                  _buildProblemChip('مشكلة في الحساب'.tr, onTap: () {
                    _problemController.text = 'مشكلة في الحساب'.tr;
                  }),
                  _buildProblemChip('أخرى'.tr, onTap: () {
                    _problemController.text = 'مشكلة أخرى'.tr;
                  }),
                ],
              ),
            
              SizedBox(height: 30.h),

              // معلومات الاتصال - البريد الإلكتروني
              if (aboutUs != null && aboutUs.contactEmail != null)
                _buildContactInfo(
                  icon: Icons.email,
                  title: 'البريد الإلكتروني',
                  value: aboutUs.contactEmail!,
                  onTap: () => _launchEmail(aboutUs.contactEmail!),
                  isDarkMode: isDarkMode,
                ),
              
              SizedBox(height: 30.h),
           
              // دعم مباشر عبر الواتساب
              if (aboutUs != null && aboutUs.whatsapp != null)
                Center(
                  child: Column(
                    children: [
                      Text('هل تحتاج إلى دعم فوري؟'.tr,
                        style: TextStyle(
                          fontSize: AppTextStyles.xlarge,

                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          fontFamily: AppTextStyles.appFontFamily,
                        ),
                      ),
                      SizedBox(height: 15.h),
                      ElevatedButton.icon(
                        onPressed: () => _launchWhatsApp(aboutUs.whatsapp!),
                        label: Text('واتــساب'.tr,
                          style: TextStyle(
                            color: AppColors.onPrimary,
                            fontSize: AppTextStyles.large,

                            fontFamily: AppTextStyles.appFontFamily,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          padding: EdgeInsets.symmetric(horizontal: 80.w, vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                      ),
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
  
  Widget _buildProblemChip(String text, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Chip(
        label: Text(text,
          style: TextStyle(
            fontFamily: AppTextStyles.appFontFamily,
          ),
        ),
        backgroundColor: AppColors.primary.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
        side: BorderSide(color: AppColors.primary),
      ),
    );
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

  // دالة لفتح تطبيق البريد
  Future<void> _launchEmail(String email) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {'subject': 'استفسار عن تطبيق Stay in Me'},
    );

    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      Get.snackbar('خطأ'.tr, 'لا يمكن فتح تطبيق البريد'.tr,
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  // دالة لفتح الواتساب
  Future<void> _launchWhatsApp(String phone) async {
    final url = "https://wa.me/$phone";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      Get.snackbar('خطأ'.tr, 'لا يمكن فتح تطبيق الواتساب'.tr,
          snackPosition: SnackPosition.BOTTOM);
    }
  }
}