import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:tappuu_app/views/AddAds/PaymentScreen.dart';

import '../../controllers/AdsManageController.dart';
import '../../controllers/CardPaymentController.dart';
import '../../controllers/LoadingController.dart';
import '../../controllers/PremiumPackageController.dart';
import '../../controllers/ThemeController.dart';
import '../../core/constant/app_text_styles.dart';
import '../../core/constant/appcolors.dart';
import '../../core/data/model/PremiumPackage.dart';
import '../HomeScreen/home_screen.dart';
import 'AddAdScreen.dart';

class PremiumPackagesScreen extends StatefulWidget {
  const PremiumPackagesScreen({Key? key}) : super(key: key);

  @override
  State<PremiumPackagesScreen> createState() => _PremiumPackagesScreenState();
}

class _PremiumPackagesScreenState extends State<PremiumPackagesScreen> {
  final PremiumPackageController controller = Get.put(PremiumPackageController());
  final ThemeController themeController = Get.find<ThemeController>();
  final ManageAdController adController = Get.find<ManageAdController>();
  final LoadingController loadingController = Get.find<LoadingController>();
  final CardPaymentController _cardPaymentController = Get.put(CardPaymentController());
  final NumberFormat _fmt = NumberFormat('#,##0', 'en_US');
  final ScrollController _scrollController = ScrollController();

  Map<String, int> selectedPackagesByType = {};

  @override
  void initState() {
    super.initState();
    controller.fetchPackages();
    _cardPaymentController.fetchSetting();
  }

  String _formatPrice(double price) {
    return '${_fmt.format(price)} ليرة سورية';
  }

  int _extractDaysFromName(String name) {
    final regExp = RegExp(r'(\d+)');
    final match = regExp.firstMatch(name);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '') ?? 0;
    }
    return 0;
  }

  Map<String, List<PremiumPackage>> _groupPackagesByType(List<PremiumPackage> packages) {
    Map<String, List<PremiumPackage>> groupedPackages = {};
    for (var package in packages) {
      if (package.isActive == true) {
        String typeName = package.type?.name ?? 'باقات أخرى';
        groupedPackages.putIfAbsent(typeName, () => []);
        groupedPackages[typeName]!.add(package);
      }
    }
    groupedPackages.forEach((key, value) {
      value.sort((a, b) {
        int aDays = _extractDaysFromName(a.name ?? '');
        int bDays = _extractDaysFromName(b.name ?? '');
        if (aDays != bDays) return aDays.compareTo(bDays);
        final da = (a.price ?? 0).compareTo((b.price ?? 0));
        if (da != 0) return da;
        return (a.name ?? '').compareTo((b.name ?? ''));
      });
    });
    return groupedPackages;
  }

  void _togglePackageSelection(String typeName, int packageId) {
    setState(() {
      if (selectedPackagesByType[typeName] == packageId) {
        selectedPackagesByType.remove(typeName);
      } else {
        selectedPackagesByType[typeName] = packageId;
      }
    });
  }

  Set<int> get selectedPackageIds => selectedPackagesByType.values.toSet();

  List<PremiumPackage> get _selectedPackages {
    return controller.packagesList.where((p) => selectedPackageIds.contains(p.id)).toList();
  }

  String _buildSelectedSummary() {
    final selected = _selectedPackages;
    if (selected.isEmpty) return 'لم يتم اختيار باقات بعد';
    final total = selected.fold<double>(0.0, (prev, el) => prev + (el.price ?? 0));
    final types = selected.map((e) => e.type?.name ?? '').toSet().join(' • ');
    final names = selected.map((e) => e.name ?? '').join(' • ');
    return '$names · $types · ${_formatPrice(total)}';
  }

  void _onProceedToPayment() {
    final selectedIds = selectedPackageIds;
    if (selectedIds.isEmpty) {
      Get.snackbar(
        'خطأ', 
        'يرجى اختيار باقة واحدة على الأقل', 
        backgroundColor: Colors.red, 
        colorText: Colors.white,
        margin: EdgeInsets.all(16),
        borderRadius: 12,
      );
      return;
    }

    final selectedPackages = _selectedPackages;

    Get.to(() => PaymentScreen(
          package: selectedPackages,
          adTitle: adController.titleArController.text,
          adPrice: '${adController.priceController.text} ليرة سورية',
        ));
  }

  Future<void> _submitAdWithoutPremium() async {
    try {
      _showLoadingDialog();
      await Future.delayed(const Duration(milliseconds: 100));
      await adController.submitAd();
      while (adController.isSubmitting.value) {
        await Future.delayed(const Duration(milliseconds: 200));
      }
      Get.offAll(() => HomeScreen());
    } catch (e) {
      print('⚠️ _submitAdWithoutPremium exception: $e');
      Get.back();
    } finally {
      if (mounted && Navigator.canPop(context)) {
        try {
          Navigator.pop(context);
        } catch (_) {}
      }
    }
  }

  void _confirmCreateWithoutPackage() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        child: Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: themeController.isDarkMode.value ? Color(0xFF1e293b) : Colors.white,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline, size: 48.w, color: AppColors.primary),
              SizedBox(height: 16.h),
              Text(
                'تأكيد'.tr,
                style: TextStyle(
                  fontFamily: AppTextStyles.appFontFamily,
                  color: AppColors.textPrimary(themeController.isDarkMode.value),
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'هل تريد إنشاء الإعلان دون أي باقة مميزة؟'.tr,
                style: TextStyle(
                  fontFamily: AppTextStyles.appFontFamily,
                  color: AppColors.textSecondary(themeController.isDarkMode.value),
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        side: BorderSide(color: AppColors.primary),
                      ),
                      child: Text(
                        'إلغاء'.tr,
                        style: TextStyle(
                          fontFamily: AppTextStyles.appFontFamily,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _submitAdWithoutPremium();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'تأكيد'.tr,
                        style: TextStyle(
                          fontFamily: AppTextStyles.appFontFamily,
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPackageDetailsSheet(PremiumPackage pkg, String typeName) {
    final currentlySelected = _selectedPackages;
    final currentTotal = currentlySelected.fold<double>(0.0, (p, e) => p + (e.price ?? 0));
    final willAdd = selectedPackagesByType[typeName] != pkg.id;
    final predictedTotal = currentTotal + (willAdd ? (pkg.price ?? 0) : 0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          margin: EdgeInsets.only(top: 50.h),
          decoration: BoxDecoration(
            color: themeController.isDarkMode.value ? Color(0xFF0b1220) : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
          ),
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: EdgeInsets.only(top: 12.h, bottom: 8.h),
                  width: 60.w,
                  height: 6.h,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                  child: Column(
                    children: [
                      Text(
                        pkg.name ?? '',
                        style: TextStyle(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w900,
                          fontFamily: AppTextStyles.appFontFamily,
                          color: AppColors.textPrimary(themeController.isDarkMode.value),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          '${_formatPrice(pkg.price ?? 0)} • ${pkg.durationDays ?? '-'} يوم',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontFamily: AppTextStyles.appFontFamily,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if ((pkg.description ?? '').isNotEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
                    child: Text(
                      pkg.description!,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.textSecondary(themeController.isDarkMode.value),
                        fontFamily: AppTextStyles.appFontFamily,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                SizedBox(height: 16.h),

                Container(
                  margin: EdgeInsets.symmetric(horizontal: 24.w),
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: themeController.isDarkMode.value ? Colors.black.withOpacity(0.3) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'المجموع بعد الاختيار',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: AppTextStyles.appFontFamily,
                          fontSize: 14.sp,
                        ),
                      ),
                      Text(
                        _formatPrice(predictedTotal),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18.sp,
                          color: AppColors.primary,
                          fontFamily: AppTextStyles.appFontFamily,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24.h),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            _togglePackageSelection(typeName, pkg.id!);
                            Navigator.of(ctx).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: (selectedPackagesByType[typeName] == pkg.id) 
                                ? Colors.grey 
                                : AppColors.primary,
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            elevation: 2,
                          ),
                          child: Text(
                            (selectedPackagesByType[typeName] == pkg.id) 
                                ? 'إلغاء الاختيار' 
                                : 'اختيار هذه الباقة',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w800,
                              fontFamily: AppTextStyles.appFontFamily,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            if (selectedPackagesByType[typeName] != pkg.id) {
                              _togglePackageSelection(typeName, pkg.id!);
                            }
                            Navigator.of(ctx).pop();
                            _onProceedToPayment();
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.primary, width: 2),
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          child: Text(
                            'الدفع الآن',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              fontFamily: AppTextStyles.appFontFamily,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: MediaQuery.of(ctx).viewInsets.bottom + 24.h),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: AppColors.card(themeController.isDarkMode.value),
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    'جاري إنشاء/معالجة الإعلان...',
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary(themeController.isDarkMode.value),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'يرجى الانتظار قليلاً',
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: 13.sp,
                      color: AppColors.textSecondary(themeController.isDarkMode.value),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            strokeWidth: 3,
          ),
          SizedBox(height: 16.h),
          Text(
            'جاري تحميل الباقات...',
            style: TextStyle(
              fontFamily: AppTextStyles.appFontFamily,
              fontSize: 16.sp,
              color: AppColors.textSecondary(themeController.isDarkMode.value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = themeController.isDarkMode.value;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64.w, color: Colors.grey),
          SizedBox(height: 16.h),
          Text(
            'لا توجد باقات متاحة حالياً'.tr,
            style: TextStyle(
              fontFamily: AppTextStyles.appFontFamily,
              fontSize: 16.sp,
              color: AppColors.textSecondary(isDark),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'يرجى المحاولة مرة أخرى لاحقاً',
            style: TextStyle(
              fontFamily: AppTextStyles.appFontFamily,
              fontSize: 14.sp,
              color: AppColors.textSecondary(isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageTypeSection(String typeName, List<PremiumPackage> typePackages, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(bottom: 16.h),
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  typeName,
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
              if (typePackages.isNotEmpty && (typePackages.first.type?.description ?? '').isNotEmpty)
                IconButton(
                  onPressed: () {
                    Get.dialog(
                      Dialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
                        child: Container(
                          padding: EdgeInsets.all(24.w),
                          decoration: BoxDecoration(
                            color: isDark ? Color(0xFF1e293b) : Colors.white,
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                typeName,
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: AppTextStyles.appFontFamily,
                                  color: AppColors.primary,
                                ),
                              ),
                              SizedBox(height: 16.h),
                              Text(
                                typePackages.first.type!.description ?? '',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontFamily: AppTextStyles.appFontFamily,
                                  color: AppColors.textSecondary(isDark),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 24.h),
                              ElevatedButton(
                                onPressed: () => Get.back(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                ),
                                child: Text('حسناً', style: TextStyle(fontFamily: AppTextStyles.appFontFamily)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  icon: Icon(Icons.info_outline, color: AppColors.textSecondary(isDark), size: 22.w),
                ),
            ],
          ),
        ),

        SizedBox(
          height: 200.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: typePackages.length,
            separatorBuilder: (_, __) => SizedBox(width: 16.w),
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            itemBuilder: (context, idx) {
              final pkg = typePackages[idx];
              final isSelected = selectedPackagesByType[typeName] == pkg.id;
              return HorizontalPackageCard(
                pkg: pkg,
                isDark: isDark,
                priceText: _formatPrice(pkg.price ?? 0),
                isSelected: isSelected,
                onSelect: () => _showPackageDetailsSheet(pkg, typeName),
              );
            },
          ),
        ),
        SizedBox(height: 32.h),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = themeController.isDarkMode.value;
      final activePackages = controller.packagesList.where((pkg) => pkg.isActive == true).toList();
      final groupedPackages = _groupPackagesByType(activePackages);
      final hasSelectedPackages = selectedPackageIds.isNotEmpty;

      return Scaffold(
        backgroundColor: AppColors.background(isDark),
        appBar: AppBar(
          backgroundColor: AppColors.appBar(isDark),
          centerTitle: true,
          elevation: 0,
          title: Text(
            'الباقات المميزة'.tr,
            style: TextStyle(
              fontFamily: AppTextStyles.appFontFamily,
              color: AppColors.onPrimary,
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.onPrimary),
            onPressed: () => Get.back(),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(20.r),
            ),
          ),
        ),
        body: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primary.withOpacity(0.1),
                          AppColors.primary.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.star, color: Colors.white, size: 24.w),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Text(
                            'اختر الباقات المناسبة لإبراز إعلانك',
                            style: TextStyle(
                              fontFamily: AppTextStyles.appFontFamily,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),

                  Expanded(
                    child: controller.isLoadingPackages.value
                        ? _buildLoadingState()
                        : activePackages.isEmpty
                            ? _buildEmptyState()
                            : ListView(
                                controller: _scrollController,
                                padding: EdgeInsets.only(bottom: hasSelectedPackages ? 160.h : 120.h),
                                children: [
                                  ...groupedPackages.entries.map((entry) {
                                    final typeName = entry.key;
                                    final typePackages = entry.value;
                                    return _buildPackageTypeSection(typeName, typePackages, isDark);
                                  }).toList(),
                                ],
                              ),
                  ),
                ],
              ),
            ),

            Positioned(
              left: 16.w,
              right: 16.w,
              bottom: 16.h,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasSelectedPackages)
                    AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      margin: EdgeInsets.only(bottom: 12.h),
                      decoration: BoxDecoration(
                        color: isDark ? Color(0xFF0b1220) : Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 20,
                            spreadRadius: 2,
                            offset: Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.2),
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16.r),
                          onTap: _onProceedToPayment,
                          child: Padding(
                            padding: EdgeInsets.all(16.w),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8.w),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.shopping_cart_checkout,
                                    color: AppColors.primary,
                                    size: 20.w,
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${selectedPackageIds.length} ${'باقات مختارة'.tr}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16.sp,
                                          fontFamily: AppTextStyles.appFontFamily,
                                          color: AppColors.textPrimary(isDark),
                                        ),
                                      ),
                                      SizedBox(height: 4.h),
                                      Text(
                                        _buildSelectedSummary(),
                                        style: TextStyle(
                                          fontFamily: AppTextStyles.appFontFamily,
                                          fontSize: 12.sp,
                                          color: AppColors.textSecondary(isDark),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'الدفع الآن'.tr,
                                        style: TextStyle(
                                          fontFamily: AppTextStyles.appFontFamily,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14.sp,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(width: 8.w),
                                      Icon(Icons.arrow_forward, size: 16.w, color: Colors.white),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                  Material(
                    color: Colors.transparent,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 20,
                            spreadRadius: 2,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _confirmCreateWithoutPackage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? Color(0xFF1e293b) : Colors.white,
                          foregroundColor: AppColors.primary,
                          padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 24.w),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.post_add_outlined, size: 20.w),
                            SizedBox(width: 12.w),
                            Text(
                              'إنشاء دون باقة'.tr,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontFamily: AppTextStyles.appFontFamily,
                                fontSize: 16.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

class HorizontalPackageCard extends StatelessWidget {
  final PremiumPackage pkg;
  final bool isDark;
  final String priceText;
  final bool isSelected;
  final VoidCallback onSelect;

  const HorizontalPackageCard({
    Key? key,
    required this.pkg,
    required this.isDark,
    required this.priceText,
    required this.isSelected,
    required this.onSelect,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected ? AppColors.primary : Colors.grey.withOpacity(0.2);
    final bg = isSelected 
        ? AppColors.primary.withOpacity(0.08)
        : (isDark ? Color(0xFF141722) : Colors.white);

    return GestureDetector(
      onTap: onSelect,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        width: 180.w,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: borderColor, width: isSelected ? 2.5 : 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isSelected ? 0.1 : 0.05),
              blurRadius: isSelected ? 15 : 8,
              offset: Offset(0, isSelected ? 6 : 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              right: 0,
              child: AnimatedContainer(
                duration: Duration(milliseconds: 300),
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(20.r),
                    bottomLeft: Radius.circular(12.r),
                  ),
                ),
                child: Text(
                  isSelected ? 'محدد' : '',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: AppTextStyles.appFontFamily,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          pkg.name ?? '',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w800,
                            fontFamily: AppTextStyles.appFontFamily,
                            color: AppColors.textPrimary(isDark),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      GestureDetector(
                        onTap: onSelect,
                        child: Container(
                          padding: EdgeInsets.all(6.w),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.info_outline,
                            size: 16.w,
                            color: AppColors.textSecondary(isDark),
                          ),
                        ),
                      )
                    ],
                  ),

                  SizedBox(height: 16.h),

                  Text(
                    priceText,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                      fontFamily: AppTextStyles.appFontFamily,
                    ),
                  ),
                  SizedBox(height: 8.h),

                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14.w, color: AppColors.textSecondary(isDark)),
                      SizedBox(width: 6.w),
                      Text(
                        '${pkg.durationDays ?? '-'} يوم',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.textSecondary(isDark),
                          fontFamily: AppTextStyles.appFontFamily,
                        ),
                      ),
                    ],
                  ),

                  Spacer(),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onSelect,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected ? AppColors.primary : Colors.transparent,
                        foregroundColor: isSelected ? Colors.white : AppColors.buttonAndLinksColor,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          side: BorderSide(
                            color: isSelected ? AppColors.primary : Colors.grey.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        isSelected ? 'محدد' : 'عرض التفاصيل',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          fontFamily: AppTextStyles.appFontFamily,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}