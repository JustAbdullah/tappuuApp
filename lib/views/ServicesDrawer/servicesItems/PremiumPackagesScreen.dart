import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:tappuu_app/core/data/model/PremiumPackage.dart';

import '../../../controllers/PremiumPackageController.dart';
import '../../../controllers/ThemeController.dart';
import '../../../core/constant/app_text_styles.dart';
import '../../../core/constant/appcolors.dart';

class PremiumPackagesScreen extends StatefulWidget {
  const PremiumPackagesScreen({Key? key}) : super(key: key);

  @override
  State<PremiumPackagesScreen> createState() => _PremiumPackagesScreenState();
}

class _PremiumPackagesScreenState extends State<PremiumPackagesScreen> {
  final PremiumPackageController controller = Get.put(PremiumPackageController());
  final ThemeController themeController = Get.find<ThemeController>();
  final NumberFormat _fmt = NumberFormat('#,##0', 'en_US');
  Map<String, int> selectedPackagesByType = {};

  @override
  void initState() {
    super.initState();
    controller.fetchPackages();
  }

  String _removeNumberTokens(String input) {
    if (input.trim().isEmpty) return '';

    final withoutNumberTokens = input.replaceAll(RegExp(r'\S*[0-9\u0660-\u0669]\S*'), '');
    var cleaned = withoutNumberTokens.replaceAll(RegExp(r'\s+'), ' ').trim();

    const List<String> punct = ['.', ',', ';', ':', '!', '?', '«', '»', '"', '\'', '،'];
    int start = 0;
    int end = cleaned.length;

    while (start < end && punct.contains(cleaned[start])) {
      start++;
    }
    while (end > start && punct.contains(cleaned[end - 1])) {
      end--;
    }

    cleaned = (start >= end) ? '' : cleaned.substring(start, end).trim();
    return cleaned;
  }

  String _unifiedDescription() {
    final items = controller.packagesList;
    if (items.isEmpty) return 'اختر الباقة الأنسب لعرض إعلانك بسرعة وفعالية.';

    final List<String> descs = [];
    for (var p in items) {
      try {
        final raw = (p.description ?? '').toString().trim();
        if (raw.isEmpty) continue;
        final sanitized = _removeNumberTokens(raw);
        if (sanitized.isNotEmpty) descs.add(sanitized);
      } catch (_) {}
    }

    if (descs.isEmpty) return 'اختر الباقة الأنسب لعرض إعلانك بسرعة وفعالية.';

    final unique = descs.toSet();
    if (unique.length == 1) return descs.first;

    final Map<String, int> freq = {};
    for (var d in descs) {
      freq[d] = (freq[d] ?? 0) + 1;
    }
    final entriesSorted = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (entriesSorted.isNotEmpty && entriesSorted.first.value > 1) {
      return entriesSorted.first.key;
    }

    return descs.first;
  }

  // دالة لتجميع الباقات حسب نوعها وترتيبها من الأصغر إلى الأكبر
  Map<String, List<PremiumPackage>> _groupPackagesByType(List<PremiumPackage> packages) {
    Map<String, List<PremiumPackage>> groupedPackages = {};
    
    for (var package in packages) {
      if (package.isActive) {
        String typeName = package.type?.name ?? 'باقات أخرى';
        if (!groupedPackages.containsKey(typeName)) {
          groupedPackages[typeName] = [];
        }
        groupedPackages[typeName]!.add(package);
      }
    }
    
    // ترتيب الباقات داخل كل مجموعة من الأصغر إلى الأكبر
    groupedPackages.forEach((key, value) {
      value.sort((a, b) {
        int aDays = _extractDaysFromName(a.name);
        int bDays = _extractDaysFromName(b.name);
        return aDays.compareTo(bDays);
      });
    });
    
    return groupedPackages;
  }

  // دالة لاستخراج عدد الأيام من اسم الباقة
  int _extractDaysFromName(String name) {
    RegExp regExp = RegExp(r'(\d+)');
    Match? match = regExp.firstMatch(name);
    if (match != null) {
      return int.parse(match.group(1)!);
    }
    return 0;
  }

 
  // دالة لتبديل اختيار الباقة (تسمح باختيار باقة واحدة فقط من كل نوع)
  void _togglePackageSelection(String typeName, int packageId) {
    setState(() {
      if (selectedPackagesByType[typeName] == packageId) {
        // إذا كانت الباقة المختارة بالفعل، قم بإلغاء اختيارها
        selectedPackagesByType.remove(typeName);
      } else {
        // خلاف ذلك، اختر الباقة الجديدة (سيتم إلغاء أي اختيار سابق لهذا النوع تلقائياً)
        selectedPackagesByType[typeName] = packageId;
      }
    });
  }

  // الحصول على جميع الباقات المحددة
  Set<int> get selectedPackageIds {
    return selectedPackagesByType.values.toSet();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = themeController.isDarkMode.value;
      final bg = AppColors.background(isDark);
      final primaryColor = AppColors.primary;

      final headerDescription = _unifiedDescription();

      // الحصول على الباقات النشطة فقط
      final activePackages = controller.packagesList.where((pkg) => pkg.isActive == true).toList();
      
      // تجميع الباقات حسب النوع
      final groupedPackages = _groupPackagesByType(activePackages);

      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: AppColors.appBar(isDark),
          centerTitle: true,
          elevation: 0,
          title: Text('الباقات المميزة'.tr,
              style: TextStyle(
                fontFamily: AppTextStyles.appFontFamily,
                color: AppColors.onPrimary,
                fontSize: AppTextStyles.xxlarge,
                fontWeight: FontWeight.w700,
              )),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.onPrimary),
            onPressed: () => Get.back(),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: isDark
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
                  )
                : LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFf8f9fa), Color(0xFFe9ecef)],
                  ),
          ),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                _promoHeader(isDark, headerDescription),
                SizedBox(height: 24.h),

                Expanded(
                  child: controller.isLoadingPackages.value
                      ? Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                            strokeWidth: 2.0,
                          ),
                        )
                      : activePackages.isEmpty
                          ? _noActivePackagesState(isDark)
                          : Stack(
                              children: [
                                ListView(
                                  padding: EdgeInsets.only(bottom: 80.h),
                                  children: [
                                    // عرض كل مجموعة من الباقات حسب النوع
                                    ...groupedPackages.entries.map((entry) {
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // عنوان مجموعة الباقات
                                          Padding(
                                            padding: EdgeInsets.only(bottom: 2.h, top: 8.h),
                                            child: Text(
                                              entry.key,
                                              style: TextStyle(
                                                fontFamily: AppTextStyles.appFontFamily,
                                                fontSize: AppTextStyles.xlarge,
                                                fontWeight: FontWeight.w800,
                                                color: primaryColor,
                                              ),
                                            ),
                                          ),
                                          
                                          // وصف نوع الباقة
                                          if (entry.value.isNotEmpty && entry.value.first.type != null)
                                            Padding(
                                              padding: EdgeInsets.only(bottom: 7.h),
                                              child: Text(
                                                entry.value.first.type!.description,
                                                style: TextStyle(
                                                  fontSize: AppTextStyles.medium,
                                                  color: AppColors.textSecondary(isDark),
                                                  fontFamily: AppTextStyles.appFontFamily,
                                                ),
                                              ),
                                            ),
                                          
                                          // عرض الباقات بشكل أفقي
                                          Container(
                                            height: 180.h,
                                            child: ListView.separated(
                                              scrollDirection: Axis.horizontal,
                                              itemCount: entry.value.length,
                                              separatorBuilder: (context, index) => SizedBox(width: 16.w),
                                              itemBuilder: (context, index) {
                                                final pkg = entry.value[index];
                                                final isSelected = selectedPackagesByType[entry.key] == pkg.id;
                                                return HorizontalPackageCard(
                                                  pkg: pkg,
                                                  isDark: isDark,
                                                  priceText: '${_fmt.format(pkg.price ?? 0)} ل.س',
                                                  isSelected: isSelected,
                                                  onSelect: () => _togglePackageSelection(entry.key, pkg.id!),
                                                );
                                              },
                                            ),
                                          ),
                                          
                                          SizedBox(height: 24.h),
                                        ],
                                      );
                                    }).toList(),
                                  ],
                                ),
                                
                                // زر الدفع في الأسفل
                                if (selectedPackageIds.isNotEmpty)
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(vertical: 10.h),
                                      decoration: BoxDecoration(
                                        color: isDark ? Color(0xFF1a1a2e) : Colors.white,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 10,
                                            offset: Offset(0, -5),
                                          ),
                                        ],
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                                        child: SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            onPressed: () {
                                              print('البدء في عملية الدفع للباقات: $selectedPackageIds');
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.primary,
                                              padding: EdgeInsets.symmetric(vertical: 16.h),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12.r),
                                              ),
                                            ),
                                            child: Text(
                                              'الدفع الآن'.tr,
                                              style: TextStyle(
                                                fontSize: AppTextStyles.large,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
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
        ),
      );
    });
  }

  Widget _promoHeader(bool isDark, String headerDescription) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.9),
            AppColors.primary.withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.star, color: Colors.white, size: 28.w),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ارتقِ بإعلاناتك — اجذب الزبائن الآن'.tr,
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: AppTextStyles.large,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    )),
                SizedBox(height: 6.h),
                Text(
                  "أختر وشاهد نوع الباقة المناسب لك والسعر المناسب والمدة من الخيارات التى بالأسفل",
                  style: TextStyle(
                    fontSize: AppTextStyles.small,
                    color: Colors.white.withOpacity(0.9),
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

  Widget _noActivePackagesState(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined, size: 72.w, color: AppColors.primary.withOpacity(0.7)),
          SizedBox(height: 16.h),
          Text('لا توجد باقات نشطة حاليًا'.tr, 
            style: TextStyle(
              fontSize: AppTextStyles.large, 
              fontWeight: FontWeight.w600, 
              color: AppColors.textPrimary(isDark)
            )),
          SizedBox(height: 12.h),
          Text('يرجى التحقق لاحقًا أو التواصل مع الدعم'.tr,
              textAlign: TextAlign.center, 
              style: TextStyle(
                fontSize: AppTextStyles.small, 
                color: AppColors.textSecondary(isDark)
              )),
        ],
      ),
    );
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
    return Container(
      width: 170.w,
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withOpacity(0.1)
            : isDark
                ? Color(0xFF2a2d3e)
                : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isSelected ? AppColors.primary : Colors.grey.withOpacity(0.3),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // علامة الباقة الشائعة (تصميم جديد أنيق)
       
          Padding(
            padding: EdgeInsets.all(12.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              
                  Padding(
                      padding: EdgeInsets.only(top: 0),
                      child: Text(
                        pkg.name,
                        style: TextStyle(
                          fontSize: AppTextStyles.large,
                          fontWeight: FontWeight.w800,
                          fontFamily: AppTextStyles.appFontFamily,
                          color: AppColors.textPrimary(isDark),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                      
                      ),
                    ),
                    SizedBox(height: 15.h,),
                Container(
                
             
                  child: Center(
                    child: Text(
                      priceText,
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: AppTextStyles.large,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary ,
                      ),
                    ),
                  ),
                ),
                
                SizedBox(height:5.h),
                
                // زر اختيار الباقة
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: onSelect,
                    style: TextButton.styleFrom(
                      backgroundColor: isSelected ? AppColors.primary : Colors.transparent,
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                        side: BorderSide(
                          color: isSelected ? AppColors.primary : Colors.grey.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Text(
                      isSelected ? 'محدد' : 'اختيار',
                      style: TextStyle(
                        fontSize: AppTextStyles.small,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.buttonAndLinksColor,
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
  }
}

// رسام مخصص لشريط "شائعة"
class _RibbonPainter extends CustomPainter {
  final Color color;
  final String text;
  final Color textColor;

  _RibbonPainter({required this.color, required this.text, required this.textColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),    );
    textPainter.layout();

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.7, 0)
      ..lineTo(size.width, size.height * 0.7)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);

    // رسم النص في منتصف الشريط
    final textX = size.width * 0.35 - textPainter.width / 2;
    final textY = size.height * 0.35 - textPainter.height / 2;
    canvas.save();
    canvas.translate(textX, textY);
    textPainter.paint(canvas, Offset.zero);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}