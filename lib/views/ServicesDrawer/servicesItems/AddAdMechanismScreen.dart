import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:tappuu_app/core/constant/appcolors.dart';
import 'package:tappuu_app/core/constant/app_text_styles.dart';
import 'package:tappuu_app/controllers/ThemeController.dart';

class AddAdMechanismScreen extends StatelessWidget {
  const AddAdMechanismScreen({Key? key}) : super(key: key);

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
          title: Text('آلية إضافة إعلان'.tr, 
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
              Text('لإضافة إعلان جديد في تطبيق Stay in Me، يرجى اتباع الخطوات التالية بدقة. هذه الآلية تضمن وصول إعلانك للجمهور المستهدف بفعالية.'.tr,
                style: TextStyle(
                  fontSize: AppTextStyles.large,

                  height: 1.8,
                  color: textColor,
                  fontFamily: AppTextStyles.appFontFamily,
                ),
              ),
              SizedBox(height: 30.h),
              
              // خطوة 1: الحساب
              _buildStepCard(
                stepNumber: '١'.tr,
                title: 'تسجيل الدخول أو إنشاء حساب'.tr,
                content: '• يجب أن يكون لديك حساب مسجل في التطبيق\n• كل حساب له عدد محدود من الإعلانات المجانية\n• يمكنك الاشتراك في إحدى الباقات لزيادة عدد الإعلانات المسموحة'.tr,
                icon: Icons.account_circle,
                isDarkMode: isDarkMode,
                cardColor: cardColor,
              ),
              SizedBox(height: 20.h),
              
              // خطوة 2: ملف المعلن
              _buildStepCard(
                stepNumber: '٢'.tr,
                title: 'إنشاء ملف المعلن'.tr,
                content: '• كل إعلان يحتاج إلى ملف معلن مرتبط به\n• يمكنك إنشاء أكثر من ملف معلن لحساب واحد\n• ملف المعلن يحتوي على:\n   - الاسم الظاهر في الإعلان\n   - الشعار (صورة شخصية/لوجو)\n   - وصف مختصر عن المعلن\n   - معلومات التواصل'.tr,
                icon: Icons.business_center,
                isDarkMode: isDarkMode,
                cardColor: cardColor,
              ),
              SizedBox(height: 20.h),
              
              // خطوة 3: التصنيفات
              _buildStepCard(
                stepNumber: '٣'.tr,
                title: 'اختيار التصنيفات المناسبة'.tr,
                content: '• اختر التصنيف الرئيسي بدقة (مثل: عقارات، سيارات، أجهزة)\n• حدد التصنيف الفرعي الأول (مثل: شقق للإيجار)\n• اختر التصنيف الفرعي الثانوي إن وجد (مثل: شقق مفروشة)\n• حدد الخصائص المميزة للإعلان من القائمة'.tr,
                icon: Icons.category,
                isDarkMode: isDarkMode,
                cardColor: cardColor,
              ),
              SizedBox(height: 20.h),
              
              // خطوة 4: تفاصيل الإعلان
              _buildStepCard(
                stepNumber: '٤'.tr,
                title: 'إدخال تفاصيل الإعلان'.tr,
                content: '• اكتب عنوانًا واضحًا وجذابًا للإعلان\n• صف الإعلان بدقة وباللغة العربية الفصحى\n• حدد السعر المناسب مع العملة\n• أضف صورًا عالية الجودة (بحد أدنى 3 صور)\n   - الصور يجب أن تكون واضحة وذات دقة عالية\n   - تجنب الصور المحمية بحقوق الملكية'.tr,
                icon: Icons.description,
                isDarkMode: isDarkMode,
                cardColor: cardColor,
              ),
              SizedBox(height: 20.h),
              
              // خطوة 5: الموقع الجغرافي
              _buildStepCard(
                stepNumber: '٥'.tr,
                title: 'تحديد الموقع الجغرافي'.tr,
                content: '• اختر المحافظة (مثل: دمشق، حلب، اللاذقية)\n• حدد المنطقة أو الحي بدقة\n• استخدم خريطة التطبيق لتحديد الموقع الجغرافي الدقيق\n• الموقع الدقيق يساعد المشترين في الوصول إليك بسهولة'.tr,
                icon: Icons.location_on,
                isDarkMode: isDarkMode,
                cardColor: cardColor,
              ),
              SizedBox(height: 20.h),
              
              // خطوة 6: المراجعة والنشر
              _buildStepCard(
                stepNumber: '٦'.tr,
                title: 'مراجعة الإعلان ونشره'.tr,
                content: '• راجع جميع المعلومات المدخلة قبل النشر\n• تأكد من صحة البيانات ودقتها\n• اضغط على زر "نشر الإعلان"\n• سيمر الإعلان بمرحلة مراجعة من قبل الفريق\n• سيتم إشعارك عند الموافقة على الإعلان ونشره'.tr,
                icon: Icons.check_circle,
                isDarkMode: isDarkMode,
                cardColor: cardColor,
              ),
              SizedBox(height: 30.h),
              
              // نصائح مهمة
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline, 
                          color: AppColors.warning, size: 28.w),
                        SizedBox(width: 10.w),
                        Text('نصائح لإعلان ناجح'.tr,
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
                    _buildTip('استخدم صورًا واضحة وجذابة من زوايا متعددة'.tr),
                    _buildTip('اكتب وصفًا دقيقًا وشاملاً للإعلان'.tr),
                    _buildTip('حدد السعر المناسب حسب السوق المحلي'.tr),
                    _buildTip('تأكد من صحة معلومات التواصل'.tr),
                    _buildTip('حدد التصنيفات بدقة لتظهر للجمهور المستهدف'.tr),
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
  
  Widget _buildStepCard({
    required String stepNumber,
    required String title,
    required String content,
    required IconData icon,
    required bool isDarkMode,
    required Color cardColor,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: Offset(0, 3),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // رقم الخطوة
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(stepNumber,
                style: TextStyle(
                  fontSize: AppTextStyles.xlarge,

                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: AppTextStyles.appFontFamily,
                ),
              ),
            ),
          ),
          SizedBox(width: 15.w),
          
          // محتوى الخطوة
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: AppColors.primary, size: 24.w),
                    SizedBox(width: 8.w),
                    SizedBox(
                      width: 210.w,
                      child: Text(title,
                        style: TextStyle(
                          fontSize: AppTextStyles.xlarge,

                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          fontFamily: AppTextStyles.appFontFamily,
                          
                        ),
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
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
          ),
        ],
      ),
    );
  }
  
  Widget _buildTip(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.star, color: AppColors.primary, size: 18.w),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(text,
              style: TextStyle(
                fontSize: AppTextStyles.medium,

                height: 1.6,
                color: AppColors.textPrimary(false),
                fontFamily: AppTextStyles.appFontFamily,
              ),
            ),
          ),
        ],
      ),
    );
  }
}