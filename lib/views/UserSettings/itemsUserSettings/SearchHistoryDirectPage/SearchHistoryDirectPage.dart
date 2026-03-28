// SearchHistoryPage.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:tappuu_app/controllers/SearchHistoryController.dart';
import 'package:tappuu_app/controllers/LoadingController.dart';
import 'package:tappuu_app/core/constant/app_text_styles.dart';
import 'package:tappuu_app/core/constant/appcolors.dart';
import 'package:tappuu_app/controllers/ThemeController.dart';
import 'package:tappuu_app/core/data/model/SearchHistory.dart';

import '../../../viewAdsScreen/AdsScreen.dart';

class SearchHistoryDirectPage extends StatefulWidget {
  const SearchHistoryDirectPage({Key? key}) : super(key: key);

  @override
  State<SearchHistoryDirectPage> createState() => _SearchHistoryDirectPageState();
}

class _SearchHistoryDirectPageState extends State<SearchHistoryDirectPage> {
  final SearchHistoryController historyController =
      Get.put(SearchHistoryController());
  final ThemeController themeController = Get.find<ThemeController>();
  late final LoadingController loadingController = Get.find<LoadingController>();
  bool _dataInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (loadingController.currentUser != null && !_dataInitialized) {
        setState(() => _dataInitialized = true);
        historyController.fetchSearchHistory(
          userId: loadingController.currentUser?.id??0,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = themeController.isDarkMode.value;

    return Scaffold(
      backgroundColor: AppColors.background(isDarkMode),
      appBar: AppBar(
        backgroundColor: AppColors.appBar(isDarkMode),
        title: Text(
          'سجلات البحث'.tr,
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
        actions: [
          Obx(() {
            if (historyController.searchHistoryList.isNotEmpty) {
              return IconButton(
                icon: Icon(Icons.delete_sweep, color: AppColors.onPrimary),
                onPressed: () => _confirmDeleteAll(isDarkMode),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
      body: _buildBodyContent(isDarkMode),
    );
  }

  Widget _buildBodyContent(bool isDarkMode) {
    // حالة التهيئة الأولية
    if (!_dataInitialized) {
      return Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      );
    }

    return Obx(() {
      // حالة جلب البيانات
      if (historyController.isLoadingHistory.value) {
        return Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        );
      }

      // حالة عدم وجود سجلات
      if (historyController.searchHistoryList.isEmpty) {
        return Center(
          child: Text(
            'لا توجد سجلات بحث'.tr,
            style: TextStyle(
              fontFamily: AppTextStyles.appFontFamily,
              fontSize: AppTextStyles.large,

              color: AppColors.textPrimary(isDarkMode),
            ),
          ),
        );
      }

      // عرض السجلات
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 7.h),
        child: Column(
          children: [
            SizedBox(height: 16.h),
            Expanded(
              child: ListView.separated(
                itemCount: historyController.searchHistoryList.length,
                separatorBuilder: (context, index) => SizedBox(height: 12.h),
                itemBuilder: (context, index) {
                  final record = historyController.searchHistoryList[index];
                  return _buildRecordCard(record, isDarkMode);
                },
              ),
            ),
          ],
        ),
      );
    });
  }

Widget _buildRecordCard(SearchHistory record, bool isDarkMode) {
  return 
     Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 0),
          title: Text(
            record.recordName,
            style: TextStyle(
              fontFamily: AppTextStyles.appFontFamily,
              fontSize: AppTextStyles.large,

              color: AppColors.textPrimary(isDarkMode),
            ),
          ),
          subtitle: Text(
            _currentUserate(record.createdAt),
            style: TextStyle(
              fontFamily: AppTextStyles.appFontFamily,
              fontSize: AppTextStyles.medium,

              color: Colors.green.shade700,
            ),
          ),
          trailing: IconButton(
            icon: Icon(Icons.more_vert, color: AppColors.textSecondary(isDarkMode)),
            onPressed: () {
              _showRecordOptions(record, isDarkMode);
            },
          ),
          onTap: () {
         
       Get.to(() => AdsScreen(
              titleOfpage: record.recordName,
              categoryId:record.categoryId,
              subCategoryId:record.subcategoryId,
              subTwoCategoryId: record.secondSubcategoryId,
             
       ));
          },
        ),
        Divider(height: 1, color: Colors.grey.shade300),
      ],
   
  );
}

void _showRecordOptions(SearchHistory record, bool isDarkMode) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.card(isDarkMode),
    builder: (context) {
      return Wrap(
        children: [
          ListTile(
            leading: Icon(Icons.delete, color: AppColors.error),
            title: Text(
              'حذف'.tr,
              style: TextStyle(fontFamily: AppTextStyles.appFontFamily),
            ),
            onTap: () {
              Navigator.pop(context);
              _confirmDeleteRecord(record, isDarkMode);
            },
          ),
        ],
      );
    },
  );
}
  void _confirmDeleteRecord(SearchHistory record, bool isDarkMode) {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.card(isDarkMode),
        title: Text(
          'تأكيد الحذف'.tr,
          style: TextStyle(
            fontFamily: AppTextStyles.appFontFamily,
            color: AppColors.textPrimary(isDarkMode),
          ),
        ),
        content: Text(
          'هل أنت متأكد من حذف سجل البحث "${record.recordName}"؟'.tr,
          style: TextStyle(
            fontFamily: AppTextStyles.appFontFamily,
            color: AppColors.textSecondary(isDarkMode),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'إلغاء'.tr,
              style: TextStyle(
                fontFamily: AppTextStyles.appFontFamily,
                color: AppColors.textSecondary(isDarkMode),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              historyController.deleteSearchHistory(
                id: record.id,
                userId: record.userId,
              );
            },
            child: Text(
              'حذف'.tr,
              style: TextStyle(
                fontFamily: AppTextStyles.appFontFamily,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAll(bool isDarkMode) {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.card(isDarkMode),
        title: Text(
          'حذف جميع السجلات'.tr,
          style: TextStyle(
            fontFamily: AppTextStyles.appFontFamily,
            color: AppColors.textPrimary(isDarkMode),
          ),
        ),
        content: Text(
          'هل أنت متأكد من حذف جميع سجلات البحث؟'.tr,
          style: TextStyle(
            fontFamily: AppTextStyles.appFontFamily,
            color: AppColors.textSecondary(isDarkMode),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'إلغاء'.tr,
              style: TextStyle(
                fontFamily: AppTextStyles.appFontFamily,
                color: AppColors.textSecondary(isDarkMode),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              if (historyController.searchHistoryList.isNotEmpty) {
                historyController.deleteAllSearchHistory(
                  userId: historyController.searchHistoryList.first.userId,
                );
              }
            },
            child: Text(
              'حذف الكل'.tr,
              style: TextStyle(
                fontFamily: AppTextStyles.appFontFamily,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}String _currentUserate(String dateString) {
  try {
    // نحاول نحول النص إلى DateTime
    final date = DateTime.parse(dateString);

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${'قبل'.tr} ${difference.inDays} ${'يوم'.tr}';
    } else if (difference.inHours > 0) {
      return '${'قبل'.tr} ${difference.inHours} ${'ساعة'.tr}';
    } else if (difference.inMinutes > 0) {
      return '${'قبل'.tr} ${difference.inMinutes} ${'دقيقة'.tr}';
    } else {
      return 'الآن'.tr;
    }
  } catch (e) {
    // في حال فشل التحويل نرجع نص افتراضي
    return '';
  }
}
