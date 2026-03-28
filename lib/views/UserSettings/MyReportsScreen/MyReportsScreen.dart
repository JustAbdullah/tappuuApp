// my_reports_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:tappuu_app/controllers/LoadingController.dart';

import '../../../controllers/ThemeController.dart';
import '../../../controllers/ad_report_controller.dart';
import '../../../core/constant/app_text_styles.dart';
import '../../../core/constant/appcolors.dart';
import '../../../core/data/model/ad_report_model.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({Key? key}) : super(key: key);

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  final AdReportController reportController = Get.put(AdReportController());
  final ThemeController themeController = Get.find<ThemeController>();


  @override
  void initState() {
    super.initState();
     initializeDateFormatting('ar', null); // تهيئة اللغة العربية
    // جلب بلاغات المستخدم عند فتح الشاشة
    reportController.fetchUserReports(
      userId:  Get.find<LoadingController>().currentUser?.id?? 0,
      direction: 'both', // أو 'made' حسب ما تريد
      lang: 'ar',
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'غير محدد';
    return DateFormat('yyyy/MM/dd - hh:mm a', 'ar').format(date);
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'pending':
        return 'قيد المراجعة';
      case 'in_review':
        return 'قيد المعالجة';
      case 'resolved':
        return 'تم الحل';
      case 'rejected':
        return 'مرفوض';
      default:
        return 'غير معروف';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'pending':
        return AppColors.warning;
      case 'in_review':
        return Colors.purple;
      case 'resolved':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.textSecondary(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = themeController.isDarkMode.value;
      final bg = AppColors.background(isDark);
      final cardColor = AppColors.card(isDark);

      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: AppColors.appBar(isDark),
          centerTitle: true,
          title: Text('بلاغاتي'.tr,
              style: TextStyle(
                fontFamily: AppTextStyles.appFontFamily,
                color: AppColors.onPrimary,
                fontSize: AppTextStyles.xxlarge,

                fontWeight: FontWeight.w700,
              )),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.onPrimary),
            onPressed: () {

 Get.back();
  Get.back(); 
            }
          ),
        ),
        body: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              // عنوان وصفي
              _headerSection(isDark),
              SizedBox(height: 16.h),

              // قائمة البلاغات
              Expanded(
                child: reportController.isLoadingReports.value
                    ? Center(child: CircularProgressIndicator())
                    : reportController.reports.isEmpty
                        ? _emptyState(cardColor, isDark)
                        : ListView.separated(
                            padding: EdgeInsets.only(bottom: 24.h),
                            itemCount: reportController.reports.length,
                            separatorBuilder: (_, __) => SizedBox(height: 12.h),
                            itemBuilder: (context, index) {
                              final report = reportController.reports[index];
                              return ReportCard(
                                report: report,
                                isDark: isDark,
                                cardColor: cardColor,
                                statusText: _getStatusText(report.status),
                                statusColor: _getStatusColor(report.status),
                                formattedDate: _formatDate(report.date),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _headerSection(bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.primary.withOpacity(0.14)),
      ),
      child: Row(
        children: [
          Container(width: 6.w, height: 48.h, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(6.r))),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('إدارة البلاغات'.tr,
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: AppTextStyles.large,

                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    )),
                SizedBox(height: 6.h),
                Text(
                  'هنا يمكنك تتبع حالة البلاغات التي قدمتها على الإعلانات'.tr,
                  style: TextStyle(
                    fontSize: AppTextStyles.small,

                    color: AppColors.textSecondary(isDark),
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

  Widget _emptyState(Color cardColor, bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.report_problem_outlined, size: 64.w, color: AppColors.primary.withOpacity(0.9)),
          SizedBox(height: 12.h),
          Text('لا توجد بلاغات'.tr, style: TextStyle(fontSize: AppTextStyles.large,
 fontWeight: FontWeight.w600, color: AppColors.textPrimary(isDark))),
          SizedBox(height: 8.h),
          Text('لم تقم بتقديم أي بلاغات حتى الآن'.tr,
              textAlign: TextAlign.center, style: TextStyle(fontSize: AppTextStyles.small,
 color: AppColors.textSecondary(isDark))),
        ],
      ),
    );
  }
}

/// بطاقة البلاغ
class ReportCard extends StatelessWidget {
  final AdReportModel report;
  final bool isDark;
  final Color cardColor;
  final String statusText;
  final Color statusColor;
  final String formattedDate;

  const ReportCard({
    Key? key,
    required this.report,
    required this.isDark,
    required this.cardColor,
    required this.statusText,
    required this.statusColor,
    required this.formattedDate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عنوان الإعلان
          Text(
            report.ad?.title ?? 'إعلان بدون عنوان',
            style: TextStyle(
              fontSize: AppTextStyles.large,

              fontWeight: FontWeight.w800,
              fontFamily: AppTextStyles.appFontFamily,
              color: AppColors.textPrimary(isDark),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 12.h),
          
          // حالة البلاغ وتاريخه
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // حالة البلاغ
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: AppTextStyles.small,

                    fontFamily: AppTextStyles.appFontFamily,
                  ),
                ),
              ),
              
              // تاريخ البلاغ
              Text(
                formattedDate,
                style: TextStyle(
                  fontSize: AppTextStyles.small,

                  color: AppColors.textSecondary(isDark),
                  fontFamily: AppTextStyles.appFontFamily,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          
          // سبب البلاغ (إذا كان موجودًا)
          if (report.reason != null && report.reason!.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'سبب البلاغ:',
                  style: TextStyle(
                    fontSize: AppTextStyles.small,

                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary(isDark),
                    fontFamily: AppTextStyles.appFontFamily,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  report.reason!,
                  style: TextStyle(
                    fontSize: AppTextStyles.small,

                    color: AppColors.textSecondary(isDark),
                    fontFamily: AppTextStyles.appFontFamily,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
        ],
      ),
    );
  }
}