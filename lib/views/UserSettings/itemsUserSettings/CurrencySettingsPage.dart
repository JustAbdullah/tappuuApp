import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../controllers/ThemeController.dart';
import '../../../controllers/CurrencyController.dart';
import '../../../core/constant/app_text_styles.dart';
import '../../../core/constant/appcolors.dart';

class CurrencySettingsPage extends StatelessWidget {
  const CurrencySettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    final CurrencyController currencyController = Get.put(CurrencyController());
    final isDarkMode = themeController.isDarkMode.value;

    return Scaffold(
      backgroundColor: AppColors.background(isDarkMode),
      appBar: AppBar(
        backgroundColor: AppColors.appBar(isDarkMode),
        title: Text(
          'إعدادات العملة'.tr,
          style: TextStyle(
            fontFamily: AppTextStyles.appFontFamily,
            color: AppColors.onPrimary,
            fontSize: AppTextStyles.xlarge,

          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.onPrimary),
          onPressed: () => Get.back(),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
        child: Column(
          children: [
            Obx(() {
              if (currencyController.currencies.isEmpty) {
                return Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                );
              }

              return Card(
                color: AppColors.card(isDarkMode),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Column(
                  children: [
                    for (int i = 0;
                        i < currencyController.currencies.length;
                        i++) ...[
                      _buildCurrencyOption(
                        title: currencyController.currencies[i]['name'],
                        code: currencyController.currencies[i]['code'],
                        symbol: currencyController.currencies[i]['symbol'] ??
                            currencyController.currencies[i]['code'],
                        isSelected: currencyController.currentCurrency.value ==
                            currencyController.currencies[i]['code'],
                        isDarkMode: isDarkMode,
                      ),
                      if (i != currencyController.currencies.length - 1)
                        Divider(
                          height: 1,
                          color: AppColors.divider(isDarkMode).withOpacity(0.2),
                        ),
                    ]
                  ],
                ),
              );
            }),
            SizedBox(height: 24.h),
            _buildInfoCard(isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyOption({
    required String title,
    required String code,
    required String symbol,
    required bool isSelected,
    required bool isDarkMode,
  }) {
    final CurrencyController currencyController = Get.find<CurrencyController>();

    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      leading: Container(
        width: 40.w,
        height: 40.h,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Center(
          child: Text(
            symbol,
            style: TextStyle(
              fontSize: AppTextStyles.xxlarge,

              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: AppTextStyles.appFontFamily,
          fontSize: AppTextStyles.large,

          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary(isDarkMode),
        ),
      ),
      trailing: isSelected
          ? Container(
              width: 24.w,
              height: 24.h,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                size: 16.w,
                color: Colors.white,
              ),
            )
          : null,
      onTap: () {
        if (!isSelected) {
          currencyController.changeCurrency(code);
          Get.forceAppUpdate();
        }
      },
    );
  }

  Widget _buildInfoCard(bool isDarkMode) {
    return Card(
      color: AppColors.card(isDarkMode),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.primary,
                  size: 24.r,
                ),
                SizedBox(width: 8.w),
                Text(
                  'ملاحظة'.tr,
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    fontSize: AppTextStyles.large,

                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(isDarkMode),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              'سيتم عرض جميع الأسعار بالعملة المحددة. يمكنك تغييرها في أي وقت.'.tr,
              style: TextStyle(
                fontFamily: AppTextStyles.appFontFamily,
                fontSize: AppTextStyles.medium,

                color: AppColors.textSecondary(isDarkMode),
                height: 1.5,
              ),
              textAlign: TextAlign.start,
            ),
          ],
        ),
      ),
    );
  }
}
