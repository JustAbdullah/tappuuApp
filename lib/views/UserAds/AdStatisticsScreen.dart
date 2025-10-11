import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tappuu_app/controllers/ThemeController.dart';
import 'package:tappuu_app/core/constant/appcolors.dart';
import 'package:tappuu_app/core/constant/app_text_styles.dart';
import 'package:intl/intl.dart';
import 'package:tappuu_app/core/data/model/PremiumPackage.dart' as prm;

import '../../controllers/AdsManageController.dart';
import '../../controllers/CardPaymentController.dart';
import '../../controllers/LoadingController.dart';
import '../../controllers/PremiumPackageController.dart';
import '../../controllers/user_wallet_controller.dart';
import '../../core/data/model/AdResponse.dart';
import '../../core/data/model/UserWallet.dart';
import '../viewAdsScreen/AdDetailsScreen.dart';
import 'EditAdScreen.dart';



class AdStatisticsScreen extends StatefulWidget {
  final Ad ad;

  const AdStatisticsScreen({super.key, required this.ad});

  @override
  State<AdStatisticsScreen> createState() => _AdStatisticsScreenState();
}

class _AdStatisticsScreenState extends State<AdStatisticsScreen> {
  @override
  void initState() {
    super.initState();
    initializeDateFormatting('ar', null);
  }

  // ---------- Helpers: parsing & formatting ----------
  DateTime? _parseDateSafe(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is int) {
      try {
        return DateTime.fromMillisecondsSinceEpoch(v).toLocal();
      } catch (_) {
        return null;
      }
    }
    if (v is String && v.isNotEmpty) {
      try {
        return DateTime.parse(v).toLocal();
      } catch (_) {
        try {
          return DateTime.parse(v.replaceAll(' ', 'T')).toLocal();
        } catch (_) {
          return null;
        }
      }
    }
    return null;
  }

  String _formatDetailedDateFromDynamic(dynamic v) {
    final dt = _parseDateSafe(v);
    if (dt == null) return '-';
    final dateFormat = DateFormat('yyyy/MM/dd', 'ar');
    final timeFormat = DateFormat('h:mm a', 'ar');
    String formattedDate = dateFormat.format(dt);
    String formattedTime = timeFormat.format(dt).replaceAll('AM', 'ص').replaceAll('PM', 'م');
    return '$formattedDate - $formattedTime';
  }

  String _formatShortDateFromDynamic(dynamic v) {
    final dt = _parseDateSafe(v);
    if (dt == null) return '-';
    final df = DateFormat.yMd('ar');
    return df.format(dt);
  }

  String _formatRelative(dynamic v) {
    final dt = _parseDateSafe(v);
    if (dt == null) return '-';
    final now = DateTime.now();
    final diff = dt.difference(now);
    if (diff.inDays >= 1) return 'ينتهي بعد ${diff.inDays} يوم';
    if (diff.inHours >= 1) return 'ينتهي بعد ${diff.inHours} ساعة';
    if (diff.inMinutes >= 1) return 'ينتهي بعد ${diff.inMinutes} دقيقة';
    return 'قريبًا';
  }

  // ---------- defensive read helpers ----------
  List<dynamic> _rawPackages() {
    try {
      final pk = widget.ad.packages;
      if (pk == null) return [];
      if (pk is List) return pk;
      if (pk is String) return [];
      return [];
    } catch (_) {
      return [];
    }
  }

  List<Map<String, dynamic>> _getAllPackages() {
    final raw = _rawPackages();
    final List<Map<String, dynamic>> out = [];
    for (final e in raw) {
      if (e == null) continue;
      if (e is Map<String, dynamic>) out.add(e);
      else if (e is Map) out.add(Map<String, dynamic>.from(e));
      else {
        try {
          final json = (e as dynamic).toJson();
          if (json is Map) out.add(Map<String, dynamic>.from(json));
        } catch (_) {}
      }
    }
    return out;
  }

  List<Map<String, dynamic>> _getActivePackages() {
    final now = DateTime.now();
    return _getAllPackages().where((p) {
      try {
        final isActiveRaw = p['is_active'];
        final isActive = (isActiveRaw == true) || (isActiveRaw == 1) || (isActiveRaw == '1') || (isActiveRaw == 'true');
        if (!isActive) return false;
        final expires = _parseDateSafe(p['expires_at']);
        if (expires == null) return false;
        return expires.isAfter(now);
      } catch (_) {
        return false;
      }
    }).toList();
  }

  bool get _hasPremiumType1 {
    final active = _getActivePackages();
    for (final p in active) {
      final premium = p['premium_package'] ?? p['premiumPackage'];
      if (premium == null) continue;
      final typeId = premium['package_type_id'] ?? (premium['type']?['id']);
      final parsed = int.tryParse(typeId?.toString() ?? '');
      if (parsed != null && parsed == 1) return true;
    }
    return false;
  }

  String _packageTypeLabel(dynamic packageTypeId) {
    final id = int.tryParse(packageTypeId?.toString() ?? '') ?? 0;
    switch (id) {
      case 1:
        return 'مميز';
      case 2:
        return 'عرض مميز';
      case 3:
        return 'متجدد';
      default:
        return 'باقه';
    }
  }

  Color _packageTypeColor(dynamic packageTypeId) {
    final id = int.tryParse(packageTypeId?.toString() ?? '') ?? 0;
    switch (id) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.deepPurple;
      case 3:
        return Colors.teal;
      default:
        return AppColors.primary;
    }
  }

  // ---------- Buttons: professional styles (unchanged look) ----------
  Widget _primaryButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    double width = double.infinity,
  }) {
    final themeController = Get.find<ThemeController>();
    final isDark = themeController.isDarkMode.value;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        width: width,
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 14.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFFFFC857), Color(0xFFFF8A00)]),
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: Colors.black87, size: 18.sp),
          SizedBox(width: 8.w),
          Text(label, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: 14.sp, fontWeight: FontWeight.w800, color: Colors.black87)),
        ]),
      ),
    );
  }

  Widget _outlineButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    double width = double.infinity,
  }) {
    final themeController = Get.find<ThemeController>();
    final isDark = themeController.isDarkMode.value;
    return SizedBox(
      width: width,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: AppColors.primary),
        label: Text(label, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontWeight: FontWeight.w700, color: AppColors.primary)),
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          side: BorderSide(color: AppColors.primary, width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          backgroundColor: isDark ? AppColors.card(isDark).withOpacity(0.02) : Colors.transparent,
        ),
      ),
    );
  }

  Widget _dangerButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    double width = double.infinity,
  }) {
    return SizedBox(
      width: width,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(label, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontWeight: FontWeight.w700, color: Colors.white)),
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          backgroundColor: Colors.red.shade600,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          elevation: 6,
          shadowColor: Colors.red.withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _ghostButton({required String label, required IconData icon, required VoidCallback onPressed}) {
    final themeController = Get.find<ThemeController>();
    final isDark = themeController.isDarkMode.value;
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: AppColors.textSecondary(isDark)),
      label: Text(label, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, color: AppColors.textSecondary(isDark))),
      style: TextButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 8.w)),
    );
  }

  // ---------- Build ----------
  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final isDarkMode = themeController.isDarkMode.value;

    final allPackages = _getAllPackages();
    final activePackages = _getActivePackages();
    final hasAny = allPackages.isNotEmpty;
    final hasActive = activePackages.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background(isDarkMode),
      appBar: AppBar(
        title: Text('إحصاءات الإعلان'.tr,
            style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.xlarge, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildAdInfoCard(isDarkMode),
          SizedBox(height: 20.h),
          _buildPublishStatusCard(isDarkMode),
          SizedBox(height: 20.h),
          _buildStatisticsCard(isDarkMode),
          SizedBox(height: 20.h),
          _buildPremiumCard(isDarkMode, allPackages, activePackages, hasAny, hasActive),
          SizedBox(height: 20.h),
          _buildActionsCard(isDarkMode),
        ]),
      ),
    );
  }

  // ---------- Sub-widgets (UI) ----------
  Widget _buildAdInfoCard(bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(color: AppColors.card(isDarkMode), borderRadius: BorderRadius.circular(16.r), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: Offset(0, 3))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('معلومات الإعلان'.tr,
            style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.xlarge, fontWeight: FontWeight.bold, color: AppColors.textPrimary(isDarkMode))),
        SizedBox(height: 12.h),
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.ad.title,
                  style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.large, fontWeight: FontWeight.w700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              SizedBox(height: 8.h),
              if (widget.ad.description.isNotEmpty)
                Text(widget.ad.description,
                    maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, color: AppColors.textSecondary(isDarkMode))),
              SizedBox(height: 8.h),
              if (widget.ad.price != null)
                Text('${widget.ad.price} ${'ل.س'.tr}',
                    style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.xlarge, color: AppColors.primary, fontWeight: FontWeight.bold)),
              SizedBox(height: 8.h),
              Row(children: [
                Icon(Icons.calendar_today, size: 14.sp, color: AppColors.grey),
                SizedBox(width: 6.w),
                Flexible(
                  child: Text('نشر في ${_formatDetailedDateFromDynamic(widget.ad.createdAt)}',
                      style: TextStyle(fontFamily: AppTextStyles.appFontFamily, color: AppColors.textSecondary(isDarkMode))),
                ),
              ]),
            ]),
          ),
          if (widget.ad.images.isNotEmpty)
            Container(
              width: 100.w,
              height: 100.h,
              margin: EdgeInsets.only(left: 12.w),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: Image.network(widget.ad.images.first, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: AppColors.grey.withOpacity(0.2), child: Icon(Icons.broken_image))),
              ),
            ),
        ]),
      ]),
    );
  }

  Widget _buildPublishStatusCard(bool isDarkMode) {
    Color statusColor;
    IconData statusIcon;
    String statusText;
    switch (widget.ad.status) {
      case 'published':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'منشور';
        break;
      case 'under_review':
        statusColor = Colors.orange;
        statusIcon = Icons.access_time;
        statusText = 'تحت المراجعة';
        break;
      case 'expired':
        statusColor = Colors.red;
        statusIcon = Icons.error;
        statusText = 'منتهي الصلاحية';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
        statusText = 'غير معروف';
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(color: AppColors.card(isDarkMode), borderRadius: BorderRadius.circular(12.r), border: Border.all(color: statusColor.withOpacity(0.12))),
      child: Row(children: [
        Container(padding: EdgeInsets.all(6.w), decoration: BoxDecoration(color: statusColor.withOpacity(0.12), shape: BoxShape.circle), child: Icon(statusIcon, color: statusColor)),
        SizedBox(width: 12.w),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('حالة النشر'.tr, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, color: AppColors.textSecondary(isDarkMode))),
          SizedBox(height: 4.h),
          Text(statusText.tr, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, color: statusColor, fontWeight: FontWeight.bold)),
        ]),
      ]),
    );
  }

  Widget _buildStatisticsCard(bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(color: AppColors.card(isDarkMode), borderRadius: BorderRadius.circular(12.r)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('إحصائيات الإعلان'.tr, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.xlarge, fontWeight: FontWeight.bold)),
        SizedBox(height: 12.h),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _buildStatCard(icon: Icons.remove_red_eye, value: widget.ad.views, label: 'مشاهدة'),
          _buildStatCard(icon: Icons.favorite, value: widget.ad.favorites_count ?? 0, label: 'مفضلة'),
          _buildStatCard(icon: Icons.chat, value: widget.ad.inquirers_count ?? 0, label: 'تواصل'),
        ]),
      ]),
    );
  }

  Widget _buildStatCard({required IconData icon, required int value, required String label}) {
    final themeController = Get.find<ThemeController>();
    final isDarkMode = themeController.isDarkMode.value;
    return Container(
      width: 90.w,
      padding: EdgeInsets.symmetric(vertical: 12.h),
      decoration: BoxDecoration(color: AppColors.surface(isDarkMode), borderRadius: BorderRadius.circular(10.r)),
      child: Column(children: [
        Icon(icon, color: AppColors.primary),
        SizedBox(height: 8.h),
        Text(_formatStatValue(value), style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontWeight: FontWeight.bold)),
        SizedBox(height: 4.h),
        Text(label.tr, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, color: AppColors.textSecondary(isDarkMode))),
      ]),
    );
  }

  Widget _buildPremiumCard(bool isDarkMode, List<Map<String, dynamic>> allPackages, List<Map<String, dynamic>> activePackages, bool hasAny, bool hasActive) {
    final borderColor = hasActive ? Colors.amber : (hasAny ? AppColors.primary : AppColors.grey.withOpacity(0.3));

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(color: AppColors.card(isDarkMode), borderRadius: BorderRadius.circular(12.r), border: Border.all(color: borderColor), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: Offset(0, 4))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: EdgeInsets.all(6.w), decoration: BoxDecoration(color: hasActive ? Colors.amber.withOpacity(0.12) : AppColors.grey.withOpacity(0.08), shape: BoxShape.circle), child: Icon(hasActive ? Icons.star : Icons.star_outline, color: hasActive ? Colors.amber : AppColors.grey)),
          SizedBox(width: 10.w),
          Text(hasActive ? 'باقات نشطة' : (hasAny ? 'باقات مسجلة' : 'لا توجد باقات'), style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.large, fontWeight: FontWeight.bold)),
        ]),
        SizedBox(height: 8.h),
        Text('هنا تظهر الباقات المسجلة للإعلان، الحالة وتاريخ الانتهاء.'.tr, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, color: AppColors.textSecondary(isDarkMode))),
        SizedBox(height: 12.h),

        if (!hasAny) ...[
          Center(child: Text('لا توجد باقات مسجلة لهذا الإعلان'.tr, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, color: AppColors.textSecondary(isDarkMode)))),
          SizedBox(height: 12.h),
          _primaryButton(
            label: 'إنشاء/شراء باقة لهذا الإعلان'.tr,
            icon: Icons.add_card,
            onPressed: () => Get.to(() => PremiumPackagesScreen(adTitle: widget.ad.title, adId: widget.ad.id)),
          ),
        ] else ...[
          // القائمة: كل الباقات (تفصيل فقط، بلا أزرار خاصة لكل باقة)
          Column(children: [
            ...allPackages.map((p) {
              final premium = (p['premium_package'] ?? p['premiumPackage']) as dynamic;
              final packageName = (premium != null ? (premium['name'] ?? premium['title'] ?? premium['type']?['name']) : null) ?? 'باقه';
              final packagePrice = (premium != null ? (premium['price'] ?? '') : '');
              final duration = premium != null ? (premium['duration_days'] ?? '-') : '-';
              final packageTypeId = premium != null ? (premium['package_type_id'] ?? (premium['type']?['id'])) : null;
              final typeLabel = _packageTypeLabel(packageTypeId);
              final typeColor = _packageTypeColor(packageTypeId);
              final isActiveRaw = p['is_active'];
              final isActive = (isActiveRaw == true) || (isActiveRaw == 1) || (isActiveRaw == '1') || (isActiveRaw == 'true');
              final startedAt = p['started_at'];
              final expiresAt = p['expires_at'];
              final expiresDt = _parseDateSafe(expiresAt);
              final isExpired = expiresDt == null ? true : !expiresDt.isAfter(DateTime.now());

              return Container(
                key: ValueKey(p['id'] ?? p.hashCode),
                margin: EdgeInsets.symmetric(vertical: 8.h),
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(color: AppColors.surface(isDarkMode), borderRadius: BorderRadius.circular(10.r), border: Border.all(color: isActive ? typeColor.withOpacity(0.12) : AppColors.grey.withOpacity(0.12))),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Left: details (expandable)
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h), decoration: BoxDecoration(color: typeColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8.r)), child: Text(typeLabel, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, color: typeColor, fontWeight: FontWeight.bold))),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(packageName.toString(),
                              style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.large, fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ]),
                      SizedBox(height: 8.h),
                      // price + duration in vertical layout to avoid horizontal overflow
                      Wrap(spacing: 12.w, runSpacing: 6.h, children: [
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          Text('السعر: '.tr, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, color: AppColors.textSecondary(isDarkMode))),
                          Text('${packagePrice ?? '-'}', style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontWeight: FontWeight.bold)),
                        ]),
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          Text('المدة: '.tr, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, color: AppColors.textSecondary(isDarkMode))),
                          Text('$duration يوم', style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontWeight: FontWeight.bold)),
                        ]),
                      ]),
                      SizedBox(height: 8.h),
                      Row(children: [
                        Icon(Icons.access_time, size: 14.sp, color: AppColors.textSecondary(isDarkMode)),
                        SizedBox(width: 6.w),
                        Flexible(child: Text('من: ${startedAt != null ? _formatShortDateFromDynamic(startedAt) : '-'}', style: TextStyle(fontFamily: AppTextStyles.appFontFamily, color: AppColors.textSecondary(isDarkMode)))),
                        SizedBox(width: 12.w),
                        Flexible(child: Text('حتى: ${expiresAt != null ? _formatShortDateFromDynamic(expiresAt) : '-'}', style: TextStyle(fontFamily: AppTextStyles.appFontFamily, color: isExpired ? Colors.red : AppColors.textSecondary(isDarkMode), fontWeight: isExpired ? FontWeight.bold : FontWeight.normal))),
                      ]),
                    ]),
                  ),

                  // Right: status (compact)
                  SizedBox(width: 12.w),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                      decoration: BoxDecoration(color: isActive ? typeColor.withOpacity(0.12) : AppColors.grey.withOpacity(0.08), borderRadius: BorderRadius.circular(8.r)),
                      child: Text(isActive ? 'نشطة' : (isExpired ? 'منتهية' : 'غير نشطة'), style: TextStyle(fontFamily: AppTextStyles.appFontFamily, color: isActive ? typeColor : AppColors.textSecondary(isDarkMode), fontWeight: FontWeight.bold)),
                    ),
                    SizedBox(height: 8.h),
                    Text(_formatRelative(expiresAt), style: TextStyle(fontFamily: AppTextStyles.appFontFamily, color: AppColors.textSecondary(isDarkMode))),
                  ]),
                ]),
              );
            }).toList(),

            SizedBox(height: 12.h),

            // common actions (single renew/manage buttons)
            Row(children: [
              Expanded(
                child: _primaryButton(
                  label: hasActive ? 'تجديد الباقات'.tr : 'ترقية/شراء باقات'.tr,
                  icon: Icons.autorenew,
                  onPressed: () => Get.to(() => PremiumPackagesScreen(adTitle: widget.ad.title, adId: widget.ad.id)),
                ),
              ),
              
            ]),
          ]),
        ],
      ]),
    );
  }

  Widget _buildActionsCard(bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(color: AppColors.card(isDarkMode), borderRadius: BorderRadius.circular(12.r)),
      child: Column(children: [
        Row(children: [
          Expanded(
            child: _outlineButton(
              label: 'تعديل الإعلان'.tr,
              icon: Icons.edit,
              onPressed: () => Get.to(() => EditAdScreen(adId: widget.ad.id)),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: _dangerButton(
              label: 'حذف الإعلان'.tr,
              icon: Icons.delete,
              onPressed: () async {
                final confirmed = await Get.dialog<bool?>(AlertDialog(
                  title: Text('تأكيد الحذف'.tr, style: TextStyle(fontFamily: AppTextStyles.appFontFamily)),
                  content: Text('هل أنت متأكد من حذف هذا الإعلان؟'.tr, style: TextStyle(fontFamily: AppTextStyles.appFontFamily)),
                  actions: [
                    TextButton(onPressed: () => Get.back(result: false), child: Text('إلغاء'.tr)),
                    ElevatedButton(onPressed: () => Get.back(result: true), child: Text('حذف'.tr)),
                  ],
                ));
                if (confirmed == true) {
              Get.find<ManageAdController>().deleteAd( widget.ad.id);
                  Get.back();
                }
              },
            ),
          ),
        ]),
        SizedBox(height: 12.h),
        Row(children: [
          Expanded(
            child: _ghostButton(
              label: 'عرض الإعلان'.tr,
              icon: Icons.visibility,
              onPressed: () => Get.to(() => AdDetailsScreen(ad: widget.ad)),
            ),
          ),
       
        ]),

        SizedBox(height: 
        20.h,)
      ]),
    );
  }

  // ---------- small helpers ----------
  String _formatStatValue(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toString();
  }
}



/// ============================
/// PremiumPackagesScreen (مثل تصميم إنشاء الإعلان)
/// ============================
class PremiumPackagesScreen extends StatefulWidget {
  final String adTitle;
  final int adId;

  const PremiumPackagesScreen({
    Key? key,
    required this.adTitle,
    required this.adId,
  }) : super(key: key);

  @override
  State<PremiumPackagesScreen> createState() => _PremiumPackagesScreenState();
}

class _PremiumPackagesScreenState extends State<PremiumPackagesScreen> {
  final PremiumPackageController controller = Get.put(PremiumPackageController());
  final ThemeController themeController = Get.find<ThemeController>();
  final ManageAdController adController = Get.find<ManageAdController>();
  final LoadingController loadingController = Get.find<LoadingController>();
  final NumberFormat _fmt = NumberFormat('#,##0', 'en_US');

  /// خريطة تحدد الباقة المختارة لكل نوع: { 'نوع A' : packageId, 'نوع B' : packageId }
  Map<String, int> selectedPackagesByType = {};

  @override
  void initState() {
    super.initState();
    controller.fetchPackages();
  }

  // ------------------ Helpers ------------------
  int _extractDaysFromName(String name) {
    final regExp = RegExp(r'(\d+)');
    final match = regExp.firstMatch(name);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '') ?? 0;
    }
    return 0;
  }

  Map<String, List<prm. PremiumPackage>> _groupPackagesByType(List<prm. PremiumPackage> packages) {
    Map<String, List< prm.PremiumPackage>> groupedPackages = {};
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

  List<prm. PremiumPackage> get _selectedPackages {
    return controller.packagesList.where((p) => selectedPackageIds.contains(p.id)).toList();
  }

  String _buildSelectedSummary() {
    final selected = _selectedPackages;
    if (selected.isEmpty) return 'لم يتم اختيار باقات بعد';
    final total = selected.fold<double>(0.0, (prev, el) => prev + (el.price ?? 0));
    final types = selected.map((e) => e.type?.name ?? '').toSet().join(' • ');
    final names = selected.map((e) => e.name ?? '').join(' • ');
    return '$names · $types · ${_fmt.format(total)} ل.س';
  }

  // عند الضغط على زر الدفع: جهّز قائمة الحزم المختارة واذهب إلى شاشة الدفع
  void _onProceedToPayment() {
    final selectedIds = selectedPackageIds;
    if (selectedIds.isEmpty) {
      Get.snackbar('خطأ', 'يرجى اختيار باقة واحدة على الأقل', backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    final selectedPackages = _selectedPackages;

    // مرّر قائمة الباقات للـ PaymentScreen (الإعلان موجود مسبقاً لذا نمرر adId)
    Get.to(() => PaymentScreen(
          packageList: selectedPackages,
          adTitle: widget.adTitle,
          adId: widget.adId,
        ));
  }

  // bottom sheet لعرض تفاصيل الباقة (مبسّط، مع ملخّص المتوقّع)
  void _showPackageDetailsSheet(prm. PremiumPackage pkg, String typeName) {
    final currentlySelected = _selectedPackages;
    final currentTotal = currentlySelected.fold<double>(0.0, (p, e) => p + (e.price ?? 0));
    final willAdd = selectedPackagesByType[typeName] != pkg.id;
    final predictedTotal = currentTotal + (willAdd ? (pkg.price ?? 0) : 0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: themeController.isDarkMode.value ? Color(0xFF0b1220) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 60, height: 6, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
                SizedBox(height: 12),
                Text(pkg.name ?? '', style: TextStyle(fontSize: AppTextStyles.xlarge, fontWeight: FontWeight.w900, fontFamily: AppTextStyles.appFontFamily)),
                SizedBox(height: 8),
                Text('${_fmt.format(pkg.price ?? 0)} ل.س • ${pkg.durationDays ?? '-'} يوم', style: TextStyle(fontSize: AppTextStyles.medium, color: AppColors.textSecondary(themeController.isDarkMode.value))),
                SizedBox(height: 10),
                if ((pkg.description ?? '').isNotEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Text(pkg.description!, style: TextStyle(fontSize: AppTextStyles.small, color: AppColors.textSecondary(themeController.isDarkMode.value)), textAlign: TextAlign.center),
                  ),
                SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('المجموع بعد الاختيار', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('${_fmt.format(predictedTotal)} ل.س', style: TextStyle(fontWeight: FontWeight.bold, fontSize: AppTextStyles.large)),
                  ],
                ),
                SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _togglePackageSelection(typeName, pkg.id!);
                          Navigator.of(ctx).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: (selectedPackagesByType[typeName] == pkg.id) ? Colors.grey : AppColors.primary,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text((selectedPackagesByType[typeName] == pkg.id) ? 'إلغاء الاختيار' : 'اختيار هذه الباقة', style: TextStyle(fontSize: AppTextStyles.medium, fontWeight: FontWeight.w800)),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          if (selectedPackagesByType[typeName] != pkg.id) _togglePackageSelection(typeName, pkg.id!);
                          Navigator.of(ctx).pop();
                          _onProceedToPayment();
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.primary, width: 2),
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('الدفع الآن لهذه الباقة', style: TextStyle(fontSize: AppTextStyles.medium, fontWeight: FontWeight.w800, color: AppColors.primary)),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 18),
              ],
            ),
          ),
        );
      },
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = themeController.isDarkMode.value;
      final activePackages = controller.packagesList.where((pkg) => pkg.isActive == true).toList();
      final groupedPackages = _groupPackagesByType(activePackages);

      return Scaffold(
        backgroundColor: AppColors.background(isDark),
        appBar: AppBar(
          backgroundColor: AppColors.appBar(isDark),
          centerTitle: true,
          elevation: 0,
          title: Text('الباقات المميزة'.tr, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, color: AppColors.onPrimary, fontSize: AppTextStyles.xxlarge, fontWeight: FontWeight.w700)),
          leading: IconButton(icon: Icon(Icons.arrow_back, color: AppColors.onPrimary), onPressed: () => Get.back()),
        ),
        body: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Icon(Icons.star, color: AppColors.primary),
                    SizedBox(width: 12),
                    Expanded(child: Text('اختر الباقات المناسبة لإبراز إعلانك', style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.large, fontWeight: FontWeight.w700, color: AppColors.primary))),
                  ],
                ),
              ),
              SizedBox(height: 18),

              Expanded(
                child: controller.isLoadingPackages.value
                    ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primary)))
                    : activePackages.isEmpty
                        ? Center(child: Text('لا توجد باقات متاحة حالياً'.tr))
                        : ListView(
                            padding: EdgeInsets.only(bottom: 120),
                            children: [
                              ...groupedPackages.entries.map((entry) {
                                final typeName = entry.key;
                                final typePackages = entry.value;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.symmetric(vertical: 8),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(typeName, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.xlarge, fontWeight: FontWeight.w800, color: AppColors.primary)),
                                          if (typePackages.isNotEmpty && (typePackages.first.type?.description ?? '').isNotEmpty)
                                            IconButton(
                                              onPressed: () {
                                                Get.defaultDialog(title: typeName, content: Text(typePackages.first.type!.description ?? ''));
                                              },
                                              icon: Icon(Icons.info_outline, color: AppColors.textSecondary(isDark)),
                                            ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      height: 190,
                                      child: ListView.separated(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: typePackages.length,
                                        separatorBuilder: (_, __) => SizedBox(width: 14),
                                        padding: EdgeInsets.symmetric(horizontal: 4),
                                        itemBuilder: (context, idx) {
                                          final pkg = typePackages[idx];
                                          final isSelected = selectedPackagesByType[typeName] == pkg.id;
                                          return HorizontalPackageCard(
                                            pkg: pkg,
                                            isDark: isDark,
                                            priceText: '${_fmt.format(pkg.price ?? 0)} ل.س',
                                            isSelected: isSelected,
                                            onSelect: () => _showPackageDetailsSheet(pkg, typeName),
                                          );
                                        },
                                      ),
                                    ),
                                    SizedBox(height: 22),
                                  ],
                                );
                              }).toList(),
                            ],
                          ),
              ),
            ],
          ),
        ),

        // FAB bottom: شريط ملخّص + زر إنشاء دون باقة
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selectedPackageIds.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.95,
                  decoration: BoxDecoration(color: isDark ? Color(0xFF0b1220) : Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 12, offset: Offset(0, 6))]),
                  child: Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${selectedPackageIds.length} ${'باقات مختارة'.tr}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: AppTextStyles.large)),
                              SizedBox(height: 6),
                              Text(_buildSelectedSummary(), style: TextStyle(fontSize: AppTextStyles.small, color: AppColors.textSecondary(isDark)), maxLines: 2, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(right: 8),
                        child: ElevatedButton(
                          onPressed: _onProceedToPayment,
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: EdgeInsets.symmetric(horizontal: 22, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: Text('الدفع الآن'.tr, style: TextStyle(fontWeight: FontWeight.bold, fontSize: AppTextStyles.large)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // زر إغلاق/عودة
            FloatingActionButton.extended(
              heroTag: 'create_no_pkg',
              onPressed: () => Get.back(),
              label: Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('إغلاق'.tr, style: TextStyle(fontWeight: FontWeight.w800))),
              icon: Icon(Icons.close),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ],
        ),
      );
    });
  }
}

/// ============================
/// HorizontalPackageCard
/// ============================
class HorizontalPackageCard extends StatelessWidget {
  final prm. PremiumPackage pkg;
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
    final borderColor = isSelected ? AppColors.primary : Colors.grey.withOpacity(0.25);
    final bg = isSelected ? AppColors.primary.withOpacity(0.06) : (isDark ? Color(0xFF141722) : Colors.white);

    return GestureDetector(
      onTap: onSelect,
      child: Container(
        width: 170,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: Offset(0, 4))],
        ),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(pkg.name ?? '', style: TextStyle(fontSize: AppTextStyles.large, fontWeight: FontWeight.w800, fontFamily: AppTextStyles.appFontFamily, color: AppColors.textPrimary(isDark)), maxLines: 2, overflow: TextOverflow.ellipsis)),
              SizedBox(width: 6),
              InkWell(onTap: onSelect, child: Icon(Icons.info_outline, size: 20, color: AppColors.textSecondary(isDark))),
            ]),
            SizedBox(height: 10),
            Text(priceText, style: TextStyle(fontSize: AppTextStyles.xlarge, fontWeight: FontWeight.w900, color: AppColors.primary)),
            SizedBox(height: 6),
            Text('${pkg.durationDays ?? '-'} يوم', style: TextStyle(fontSize: AppTextStyles.small, color: AppColors.textSecondary(isDark))),
            Spacer(),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: onSelect,
                style: TextButton.styleFrom(
                  backgroundColor: isSelected ? AppColors.primary : Colors.transparent,
                  padding: EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: isSelected ? AppColors.primary : Colors.grey.withOpacity(0.2)),
                  ),
                ),
                child: Text(isSelected ? 'محدد' : 'عرض التفاصيل', style: TextStyle(fontSize: AppTextStyles.small, fontWeight: FontWeight.w700, color: isSelected ? Colors.white : AppColors.buttonAndLinksColor)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}


/// ============================
/// PaymentScreen (لإعلان موجود — يستدعي purchasePremium)
/// ============================
class PaymentScreen extends StatefulWidget {
  final List<prm.PremiumPackage> packageList;
  final int adId;
  final String adTitle;

  const PaymentScreen({
    Key? key,
    required this.packageList,
    required this.adId,
    required this.adTitle,
  }) : super(key: key);

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final ThemeController themeController = Get.find<ThemeController>();
  final UserWalletController walletController = Get.put(UserWalletController());
  final LoadingController loadingController = Get.find<LoadingController>();
  final CardPaymentController _cardPaymentController = Get.put(CardPaymentController()); // إضافة المتحكم بالبطاقة

  // تحديد طريقة الدفع الافتراضية بناءً على حالة البطاقة
  String get initialPaymentMethod {
    return _cardPaymentController.isEnabled.value ? 'card' : 'wallet';
  }
  
  String selectedPaymentMethod = 'wallet'; // سيتم تحديثها في initState
  bool isProcessing = false;
  UserWallet? selectedWallet;
  final fmt = NumberFormat('#,##0', 'en_US');

  // متحكمات نموذج البطاقة
  final _formKey = GlobalKey<FormState>();
  final cardNumberCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final expiryCtrl = TextEditingController();
  final cvvCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserWallets();
    
    // تعيين طريقة الدفع الافتراضية بناءً على حالة البطاقة
    selectedPaymentMethod = initialPaymentMethod;
    
    // التأكد من جلب أحدث إعدادات البطاقة
    _cardPaymentController.fetchSetting();
  }

  Future<void> _fetchUserWallets() async {
    final userId = loadingController.currentUser?.id;
    if (userId != null) await walletController.fetchUserWallets(userId);
  }

  double _totalPrice() => widget.packageList.fold(0.0, (p, e) => p + (e.price ?? 0));
  String _namesOfSelected() => widget.packageList.map((e) => e.name ?? '-').join(' • ');
  String _typesOfSelected() => widget.packageList.map((e) => e.type?.name ?? '-').toSet().join(' • ');
  String _durationText() {
    if (widget.packageList.isEmpty) return '-';
    if (widget.packageList.length == 1) return '${widget.packageList.first.durationDays ?? '-'} يوم';
    final durations = widget.packageList.map((e) => e.durationDays ?? 0).toSet();
    if (durations.length == 1) return '${durations.first} يوم';
    return 'متعددة';
  }

  String _getWalletStatusText(String status) {
    switch (status) {
      case 'active':
        return 'نشطة'.tr;
      case 'frozen':
        return 'مجمدة'.tr;
      case 'closed':
        return 'مغلقة'.tr;
      default:
        return status;
    }
  }

  Color _getWalletStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'frozen':
        return Colors.orange;
      case 'closed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _onCardNumberChanged(String val) {
    final digits = val.replaceAll(RegExp(r'\D'), '');
    final groups = <String>[];
    for (int i = 0; i < digits.length; i += 4) {
      groups.add(digits.substring(i, i + 4 > digits.length ? digits.length : i + 4));
    }
    final formatted = groups.join(' ');
    if (formatted != cardNumberCtrl.text) {
      cardNumberCtrl.value = TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
    }
  }

  Future<void> _processPayment() async {
    FocusScope.of(context).unfocus();

    if (selectedPaymentMethod == 'card' && !_formKey.currentState!.validate()) {
      return;
    }

    if (selectedPaymentMethod == 'wallet') {
      if (selectedWallet == null) {
        Get.snackbar('خطأ', 'يرجى اختيار محفظة للدفع', backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }
      final st = (selectedWallet!.status ?? '').toString().toLowerCase();
      if (st != 'active') {
        Get.snackbar('غير مسموح', 'لا يمكن استخدام هذه المحفظة لأنها ليست نشطة', backgroundColor: Colors.orange, colorText: Colors.white);
        return;
      }

      final total = _totalPrice();
      final balance = (selectedWallet!.balance ?? 0).toDouble();
      if (balance < total) {
        Get.snackbar('رصيد غير كافٍ', 'رصيد المحفظة أقل من سعر الباقات المختارة', backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }
    }

    setState(() => isProcessing = true);
    _showLoadingDialog();

    try {
      if (selectedPaymentMethod == 'wallet') {
        final packageIds = widget.packageList.map((e) => e.id ?? 0).where((id) => id > 0).toList();
        final res = await walletController.purchasePremium(walletUuid: selectedWallet!.uuid, adId: widget.adId, packageIds: packageIds);

        if (res != null && res['success'] == true) {
          Get.back();
          Get.snackbar('نجاح', res['message'] ?? 'تم شراء/تجديد الباقات بنجاح', backgroundColor: Colors.green, colorText: Colors.white);

          await walletController.fetchUserWallets(Get.find<LoadingController>().currentUser?.id ?? 0);

          Future.delayed(Duration(milliseconds: 300), () {
            if (Navigator.canPop(context)) Navigator.pop(context);
            if (Navigator.canPop(context)) Navigator.pop(context);
          });
        } else {
          Get.back();
          final body = res != null ? (res['body'] ?? res) : null;
          final msg = body != null && body['message'] != null ? body['message'] : 'فشل شراء/تجديد الباقات';
          Get.snackbar('خطأ', msg, backgroundColor: Colors.red, colorText: Colors.white);
        }
      } else if (selectedPaymentMethod == 'card') {
        // محاكاة عملية الدفع بالبطاقة
        await Future.delayed(Duration(seconds: 2));
        
        Get.back();
        Get.snackbar(
          'نجاح', 
          'تمت عملية الدفع بالبطاقة بنجاح. سيتم تفعيل الباقات المميزة على إعلانك قريباً.', 
          backgroundColor: Colors.green, 
          colorText: Colors.white,
          duration: Duration(seconds: 5)
        );

        // محاكاة نجاح العملية والعودة للشاشة السابقة
        Future.delayed(Duration(milliseconds: 500), () {
          if (Navigator.canPop(context)) Navigator.pop(context);
          if (Navigator.canPop(context)) Navigator.pop(context);
        });
      }
    } catch (e, st) {
      Get.back();
      print('_processPayment exception: $e\n$st');
      Get.snackbar('خطأ', 'حدث خطأ أثناء الدفع: ${e.toString()}', backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      setState(() => isProcessing = false);
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            content: Center(
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppColors.card(themeController.isDarkMode.value), borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 12)]),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('جاري معالجة الدفع...', style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary(themeController.isDarkMode.value))),
                  SizedBox(height: 8),
                  Text('يرجى الانتظار قليلاً', style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: 13, color: AppColors.textSecondary(themeController.isDarkMode.value))),
                ]),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCreditCardSection(bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.credit_card, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'الدفع الآمن بالبطاقة'.tr,
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: AppTextStyles.medium,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'مدفوعات آمنة ومشفرة. سيتم خصم المبلغ من بطاقتك الائتمانية فوراً.'.tr,
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    fontSize: AppTextStyles.small,
                    color: AppColors.textSecondary(isDark),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),

          TextFormField(
            controller: cardNumberCtrl,
            keyboardType: TextInputType.number,
            onChanged: _onCardNumberChanged,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(19)],
            decoration: InputDecoration(
              labelText: 'رقم البطاقة'.tr, 
              hintText: 'xxxx xxxx xxxx xxxx', 
              filled: true, 
              fillColor: AppColors.card(isDark), 
              prefixIcon: Icon(Icons.credit_card, color: AppColors.primary), 
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
            ),
            validator: (v) {
              final digits = (v ?? '').replaceAll(RegExp(r'\s+'), '');
              if (digits.isEmpty) return 'الرجاء إدخال رقم البطاقة'.tr;
              if (digits.length < 12) return 'رقم البطاقة غير صحيح'.tr;
              return null;
            },
          ),
          SizedBox(height: 12),
          
          TextFormField(
            controller: nameCtrl, 
            keyboardType: TextInputType.name, 
            decoration: InputDecoration(
              labelText: 'اسم صاحب البطاقة'.tr, 
              filled: true, 
              fillColor: AppColors.card(isDark), 
              prefixIcon: Icon(Icons.person_outline, color: AppColors.primary), 
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
            ), 
            validator: (v) => (v ?? '').trim().isEmpty ? 'الرجاء إدخال الاسم'.tr : null
          ),
          SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: expiryCtrl, 
                  keyboardType: TextInputType.number, 
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)], 
                  decoration: InputDecoration(
                    labelText: 'انتهاء الصلاحية (MMYY)'.tr, 
                    filled: true, 
                    fillColor: AppColors.card(isDark), 
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
                  ), 
                  validator: (v) => (v ?? '').length < 4 ? 'تاريخ غير صحيح'.tr : null
                ),
              ),
              SizedBox(width: 12),
              SizedBox(
                width: 120, 
                child: TextFormField(
                  controller: cvvCtrl, 
                  keyboardType: TextInputType.number, 
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)], 
                  decoration: InputDecoration(
                    labelText: 'CVV'.tr, 
                    filled: true, 
                    fillColor: AppColors.card(isDark), 
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
                  ), 
                  obscureText: true, 
                  validator: (v) => (v ?? '').length < 3 ? 'CVV غير صحيح'.tr : null
                ),
              ),
            ]
          ),
          SizedBox(height: 18),
        ],
      ),
    );
  }

  Widget _buildWalletSection(bool isDark) {
    return Obx(() {
      if (walletController.isLoading.value) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: CircularProgressIndicator(),
          ),
        );
      }
      if (walletController.userWallets.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            'لا توجد محافظ متاحة'.tr,
            style: TextStyle(
              fontFamily: AppTextStyles.appFontFamily,
              color: AppColors.textSecondary(isDark),
            ),
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'اختر المحفظة:'.tr,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: AppTextStyles.appFontFamily,
            ),
          ),
          SizedBox(height: 8),
          Container(
            width: double.infinity,
            child: DropdownButtonFormField<UserWallet>(
              isExpanded: true,
              value: selectedWallet,
              items: walletController.userWallets.map((wallet) {
                final statusColor = _getWalletStatusColor(wallet.status ?? '');
                final statusText = _getWalletStatusText(wallet.status ?? '');
                return DropdownMenuItem<UserWallet>(
                  value: wallet,
                  child: Container(
                    width: double.infinity,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            '${wallet.uuid}',
                            style: TextStyle(fontFamily: AppTextStyles.appFontFamily),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontFamily: AppTextStyles.appFontFamily,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              onChanged: (wallet) {
                if (wallet == null) {
                  setState(() => selectedWallet = null);
                  return;
                }
                final st = (wallet.status ?? '').toString().toLowerCase();
                if (st != 'active') {
                  Get.snackbar('غير مسموح', 'هذه المحفظة ليست نشطة ولا يمكن استخدامها للدفع', backgroundColor: Colors.orange, colorText: Colors.white);
                  return;
                }
                setState(() => selectedWallet = wallet);
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'اختر المحفظة'.tr,
                prefixIcon: Icon(Icons.account_balance_wallet),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              ),
            ),
          ),
          SizedBox(height: 12),
          if (selectedWallet != null)
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.card(isDark),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تفاصيل المحفظة:'.tr,
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${'معرف المحفظة:'.tr} ${selectedWallet!.uuid}',
                    style: TextStyle(fontFamily: AppTextStyles.appFontFamily),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '${'الرصيد:'.tr} ${selectedWallet!.balance} ${selectedWallet!.currency}',
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        '${'الحالة:'.tr} ',
                        style: TextStyle(fontFamily: AppTextStyles.appFontFamily),
                      ),
                      Text(
                        '${_getWalletStatusText(selectedWallet!.status ?? '')}',
                        style: TextStyle(
                          fontFamily: AppTextStyles.appFontFamily,
                          fontWeight: FontWeight.bold,
                          color: _getWalletStatusColor(selectedWallet!.status ?? ''),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      );
    });
  }

  @override
  void dispose() {
    cardNumberCtrl.dispose();
    nameCtrl.dispose();
    expiryCtrl.dispose();
    cvvCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = themeController.isDarkMode.value;
    final totalPrice = _totalPrice();
    final namesText = _namesOfSelected();
    final typesText = _typesOfSelected();
    final durationText = _durationText();
    final priceText = '${fmt.format(totalPrice)} ل.س';

    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      appBar: AppBar(
        backgroundColor: AppColors.appBar(isDark),
        elevation: 0,
        centerTitle: true,
        title: Text('إتمام الشراء'.tr, style: TextStyle(fontFamily: AppTextStyles.appFontFamily)),
        leading: IconButton(onPressed: () => Get.back(), icon: Icon(Icons.arrow_back)),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ملخص الطلب
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.card(isDark),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        'ملخص طلبك'.tr,
                        style: TextStyle(
                          fontFamily: AppTextStyles.appFontFamily,
                          fontSize: AppTextStyles.xlarge,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    Divider(),
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'الباقات المختارة:'.tr,
                          style: TextStyle(
                            fontFamily: AppTextStyles.appFontFamily,
                            color: AppColors.textSecondary(isDark),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            namesText,
                            textAlign: TextAlign.end,
                            style: TextStyle(
                              fontFamily: AppTextStyles.appFontFamily,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'النوع:'.tr,
                          style: TextStyle(
                            fontFamily: AppTextStyles.appFontFamily,
                            color: AppColors.textSecondary(isDark),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            typesText,
                            textAlign: TextAlign.end,
                            style: TextStyle(
                              fontFamily: AppTextStyles.appFontFamily,
                              fontWeight: FontWeight.w700,
                            ),
                            softWrap: true,
                            maxLines: 5,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'المدة:'.tr,
                          style: TextStyle(
                            fontFamily: AppTextStyles.appFontFamily,
                            color: AppColors.textSecondary(isDark),
                          ),
                        ),
                        Text(
                          durationText,
                          style: TextStyle(
                            fontFamily: AppTextStyles.appFontFamily,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'عنوان الإعلان:'.tr,
                          style: TextStyle(
                            fontFamily: AppTextStyles.appFontFamily,
                            color: AppColors.textSecondary(isDark),
                          ),
                        ),
                        SizedBox(
                          width: 200,
                          child: Text(
                            widget.adTitle,
                            textAlign: TextAlign.end,
                            style: TextStyle(
                              fontFamily: AppTextStyles.appFontFamily,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Divider(),
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'الإجمالي:'.tr,
                          style: TextStyle(
                            fontFamily: AppTextStyles.appFontFamily,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          priceText,
                          style: TextStyle(
                            fontFamily: AppTextStyles.appFontFamily,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 22),
              Text(
                'اختر طريقة الدفع'.tr,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: AppTextStyles.appFontFamily,
                ),
              ),
              SizedBox(height: 12),

              // استخدام Obx لتحديث واجهة طرق الدفع بناءً على حالة البطاقة
              Obx(() {
                final isCardEnabled = _cardPaymentController.isEnabled.value;
                
                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.card(isDark),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      // عرض خيار البطاقة فقط إذا كان مفعلاً
                      if (isCardEnabled)
                      ListTile(
                        leading: Icon(Icons.credit_card, color: AppColors.primary),
                        title: Text('بطاقة ائتمان'.tr, style: TextStyle(fontFamily: AppTextStyles.appFontFamily)),
                        trailing: Radio(
                          value: 'card',
                          groupValue: selectedPaymentMethod,
                          onChanged: (value) => setState(() => selectedPaymentMethod = value.toString()),
                          activeColor: AppColors.primary,
                        ),
                        onTap: () => setState(() => selectedPaymentMethod = 'card'),
                      ),
                      
                      // خيار المحفظة (متاح دائماً)
                      ListTile(
                        leading: Icon(Icons.account_balance_wallet, color: AppColors.primary),
                        title: Text('المحفظة الإلكترونية'.tr, style: TextStyle(fontFamily: AppTextStyles.appFontFamily)),
                        trailing: Radio(
                          value: 'wallet',
                          groupValue: selectedPaymentMethod,
                          onChanged: (value) => setState(() => selectedPaymentMethod = value.toString()),
                          activeColor: AppColors.primary,
                        ),
                        onTap: () => setState(() => selectedPaymentMethod = 'wallet'),
                      ),

                      // رسالة إذا كانت البطاقة معطلة
                      if (!isCardEnabled)
                      ListTile(
                        leading: Icon(Icons.credit_card_off, color: Colors.grey),
                        title: Text(
                          'الدفع بالبطاقة غير متاح حالياً'.tr, 
                          style: TextStyle(
                            fontFamily: AppTextStyles.appFontFamily, 
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          )
                        ),
                        subtitle: Text(
                          'يرجى استخدام المحفظة الإلكترونية للدفع'.tr,
                          style: TextStyle(
                            fontFamily: AppTextStyles.appFontFamily,
                            fontSize: AppTextStyles.small,
                            color: Colors.grey,
                          )
                        ),
                      ),
                    ],
                  ),
                );
              }),

              SizedBox(height: 18),

              // عرض القسم المناسب بناءً على طريقة الدفع المختارة
              if (selectedPaymentMethod == 'card') 
                _buildCreditCardSection(isDark),

              if (selectedPaymentMethod == 'wallet') 
                _buildWalletSection(isDark),

              // زر الدفع النهائي
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isProcessing ? null : _processPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isProcessing
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'إتمام الدفع'.tr,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontFamily: AppTextStyles.appFontFamily,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}