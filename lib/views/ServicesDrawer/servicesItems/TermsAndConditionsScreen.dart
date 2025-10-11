// lib/views/terms_and_conditions_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:tappuu_app/core/constant/appcolors.dart';
import 'package:tappuu_app/core/constant/app_text_styles.dart';
import 'package:tappuu_app/controllers/TermsAndConditionsController.dart';
import 'package:tappuu_app/controllers/ThemeController.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TermsAndConditionsController termsController = Get.put(TermsAndConditionsController());
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
          title: Text('الشروط والأحكام'.tr, 
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
          if (termsController.isLoading.value) {
            return Center(child: CircularProgressIndicator());
          }

          final terms = termsController.terms.value;
          if (terms == null) {
            return Center(child: Text('لا يوجد شروط وأحكام متاحة حالياً'.tr));
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(terms.content,
                  style: TextStyle(
                    fontSize: AppTextStyles.large,

                    height: 1.8,
                    color: textColor,
                    fontFamily: AppTextStyles.appFontFamily,
                  ),
                ),
              ],
            ),
          );
        }),
      );
    });
  }
}