import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:tappuu_app/controllers/PopularHistoryController.dart';
import 'package:tappuu_app/controllers/ThemeController.dart';
import 'package:tappuu_app/core/constant/appcolors.dart';
import 'package:tappuu_app/core/constant/app_text_styles.dart';
import '../../../../core/data/model/PopularHistory.dart';
import '../../../viewAdsScreen/AdsScreen.dart';

class PopularTagsSection extends StatelessWidget {
  const PopularTagsSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeC = Get.find<ThemeController>();
    final isDarkMode = themeC.isDarkMode.value;
    final controller = Get.find<PopularHistoryController>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عنوان القسم
          Text(
            'عمليات البحث الشائعة'.tr,
            style: TextStyle(
              fontFamily: AppTextStyles.appFontFamily,
              fontSize: 13.0.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(isDarkMode),
            ),
          ),
          const SizedBox(height: 12.0),
          
          // قائمة التاجات
          Obx(() {
            if (controller.isLoadingPopular.value) {
              return _buildShimmerTags(isDarkMode);
            }
            
            if (controller.popularList.isEmpty) {
              return Text(
                'لا توجد مفاتيح بحث شائعة حالياً'.tr,
                style: TextStyle(
                  fontFamily: AppTextStyles.appFontFamily,
                  fontSize: 14.0,
                  color: AppColors.textSecondary(isDarkMode),
                ),
              );
            }
            
            return _buildTagsList(controller.popularList, isDarkMode);
          }),
        ],
      ),
    );
  }

  Widget _buildTagsList(List<PopularHistory> tags, bool isDarkMode) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: tags.map((tag) {
        // تحديد النص الذي سيُعرض في التاج
        final displayText = _getDisplayText(tag);
        
        return GestureDetector(
          onTap: () => _handleTagTap(tag,displayText ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: AppColors.background(isDarkMode),
              borderRadius: BorderRadius.circular(0.0),
              border: Border.all(
                color: AppColors.tagBorder(isDarkMode),
                width: 1.0,
              ),
            ),
            child: Text(
              displayText,
              style: TextStyle(
                fontFamily: AppTextStyles.appFontFamily,
                fontSize:  AppTextStyles.small,
                color: AppColors.tagText(isDarkMode),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // دالة مساعدة لتحديد النص المعروض في التاج
  String _getDisplayText(PopularHistory tag) {
    // إذا كان subcat_lv2 موجودًا وغير فارغ، نستخدمه
    if (tag.subcatLv2 != null && tag.subcatLv2!.isNotEmpty) {
      return tag.subcatLv2!;
    }
    // وإلا نستخدم subcategory
    return tag.subcategory;
  }

  Widget _buildShimmerTags(bool isDarkMode) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: List.generate(8, (index) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: AppColors.surface(isDarkMode),
            borderRadius: BorderRadius.circular(00.0),
          ),
          child: Text(
            '...',
            style: TextStyle(
              fontFamily: AppTextStyles.appFontFamily,
              fontSize:  AppTextStyles.small,
              color: Colors.transparent,
            ),
          ),
        );
      }),
    );
  }

  void _handleTagTap(PopularHistory tag,String name ) {
    final controller = Get.find<PopularHistoryController>();

    // إضافة زيادة في العداد عند الضغط على التاج
    controller.addOrIncrement(
      categoryId: tag.categoryId,
      subcat1Id: tag.subcat1Id,
      subcat2Id: tag.subcat2Id,
    );
    
    // التنقل إلى القسم المناسب
    Get.to(() => AdsScreen(
      titleOfpage:  name.toString(),
      categoryId: tag.categoryId,
      subCategoryId: tag.subcat1Id,
      subTwoCategoryId: tag.subcat2Id,
      nameOfMain: tag.category,
      nameOFsub: tag.subcategory,
      nameOFsubTwo: tag.subcatLv2,
      // اسم التاج المعروض للعنوان
    ));
  }
}