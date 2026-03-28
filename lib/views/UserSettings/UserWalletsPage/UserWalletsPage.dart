import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../controllers/ThemeController.dart';
import '../../../controllers/user_wallet_controller.dart';
import '../../../core/constant/app_text_styles.dart';
import '../../../core/constant/appcolors.dart';
import '../../../core/data/model/UserWallet.dart';
import 'WalletDetailsPage.dart';

class UserWalletsPage extends StatelessWidget {
  final int userId;
  final UserWalletController walletController = Get.put(UserWalletController());

  UserWalletsPage({required this.userId});

  // ====== عملات بالعربية + تنسيق مبالغ ======
  static const Map<String, String> _currencyNamesAr = {
    'SYP': 'ليرة سورية',
    'LS': 'ليرة سورية',
    'L.S': 'ليرة سورية',
    'SYRIAN POUND': 'ليرة سورية',
    'USD': 'دولار أمريكي',
    'EUR': 'يورو',
    'YER': 'ريال يمني',
    'SAR': 'ريال سعودي',
    'IQD': 'دينار عراقي',
    'LBP': 'ليرة لبنانية',
    'EGP': 'جنيه مصري',
    'TRY': 'ليرة تركية',
    'AED': 'درهم إماراتي',
  };

  final NumberFormat _amountFormat = NumberFormat('#,##0.##', 'ar');

  String _currencyArabic(String? codeOrName) {
    if (codeOrName == null || codeOrName.trim().isEmpty) return 'عملة';
    final raw = codeOrName.trim();
    final key = raw.toUpperCase().replaceAll('.', '').replaceAll(' ', '');
    if (_currencyNamesAr.containsKey(key)) return _currencyNamesAr[key]!;
    // تطبيع شائع لليرة السورية
    if (raw.contains('ل.س') || raw.toUpperCase().contains('SYP') || raw.toUpperCase().contains('LS')) {
      return 'ليرة سورية';
    }
    return raw; // fallback
  }

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    final isDarkMode = themeController.isDarkMode.value;

    // جلب المحافظ عند فتح الصفحة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      walletController.fetchUserWallets(userId);
    });

    return Scaffold(
      backgroundColor: AppColors.background(isDarkMode),
      appBar: AppBar(
        backgroundColor: AppColors.appBar(isDarkMode),
        title: Text(
          'محافظي'.tr,
          style: TextStyle(
            fontFamily: AppTextStyles.appFontFamily,
            color: AppColors.onPrimary,
            fontSize: AppTextStyles.xlarge,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.onPrimary),
          onPressed: () {
            Get.back();
            Get.back();
          },
        ),
      ),
      body: Obx(() {
        if (walletController.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          );
        }

        if (walletController.userWallets.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 64.r,
                  color: AppColors.textSecondary(isDarkMode),
                ),
                SizedBox(height: 16.h),
                Text(
                  'لا توجد محافظ'.tr,
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    fontSize: AppTextStyles.large,
                    color: AppColors.textPrimary(isDarkMode),
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'انقر على زر + لإنشاء محفظة جديدة'.tr,
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    fontSize: AppTextStyles.medium,
                    color: AppColors.textSecondary(isDarkMode),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          itemCount: walletController.userWallets.length,
          itemBuilder: (context, index) {
            final wallet = walletController.userWallets[index];
            return _buildWalletCard(context, wallet, isDarkMode, index + 1);
          },
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateWalletDialog(context, userId),
        backgroundColor: AppColors.primary,
        label: Text(
          'إنشاء محفظة'.tr,
          style: TextStyle(
            fontFamily: AppTextStyles.appFontFamily,
            fontSize: AppTextStyles.xlarge,
            color: AppColors.textSecondary(isDarkMode),
          ),
        ),
        icon: Icon(Icons.account_balance_wallet, color: AppColors.textSecondary(isDarkMode)),
        tooltip: 'إنشاء محفظة جديدة'.tr,
      ),
    );
  }

  Widget _buildWalletCard(BuildContext context, UserWallet wallet, bool isDarkMode, int displayIndex) {
    return Card(
      color: AppColors.card(isDarkMode),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      margin: EdgeInsets.only(bottom: 16.h),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: () => Get.to(() => WalletDetailsPage(wallet: wallet)),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // العنوان + الحالة
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'المحفظة $displayIndex',
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: AppTextStyles.large,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary(isDarkMode),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: _getStatusColor(wallet.status, isDarkMode),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      _getStatusText(wallet.status),
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: AppTextStyles.small,
                        color: _getStatusTextColor(wallet.status),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),

              // UUID
              Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    size: 20.r,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      wallet.uuid,
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: AppTextStyles.small,
                        color: AppColors.textSecondary(isDarkMode),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),

              // الرصيد (استبدال رمز الدولار بأيقونة مالية عامة + اسم عملة بالعربي)
              Row(
                children: [
                  Icon(
                    Icons.payments, // كان attach_money
                    size: 20.r,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'الرصيد:'.tr,
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: AppTextStyles.medium,
                      color: AppColors.textSecondary(isDarkMode),
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    '${_amountFormat.format(wallet.balance)} ${_currencyArabic(wallet.currency)}',
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: AppTextStyles.large,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary(isDarkMode),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),

              // آخر تحديث
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 20.r,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'آخر تحديث:'.tr,
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: AppTextStyles.small,
                      color: AppColors.textSecondary(isDarkMode),
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    _formatDate(wallet.lastChangedAt),
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: AppTextStyles.small,
                      color: AppColors.textSecondary(isDarkMode),
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

  String _getStatusText(String status) {
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

  Color _getStatusColor(String status, bool isDarkMode) {
    switch (status) {
      case 'active':
        return Colors.green.withOpacity(0.2);
      case 'frozen':
        return Colors.orange.withOpacity(0.2);
      case 'closed':
        return Colors.red.withOpacity(0.2);
      default:
        return AppColors.card(isDarkMode);
    }
  }

  Color _getStatusTextColor(String status) {
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

  String _formatDate(DateTime? date) {
    if (date == null) return 'غير محدد'.tr;
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showCreateWalletDialog(BuildContext context, int userId) {
    final ThemeController themeController = Get.find<ThemeController>();

    final currencyController = TextEditingController(text: 'SYP');
    final balanceController = TextEditingController(text: '0.0');

    // خيارات عملات تُعرض بالعربي والقيمة تُرسل ككود
    final List<String> currencyCodes = ['SYP', 'USD'];

    Get.defaultDialog(
      title: 'إنشاء محفظة جديدة'.tr,
      titleStyle: TextStyle(
        fontFamily: AppTextStyles.appFontFamily,
        fontSize: AppTextStyles.large,
        fontWeight: FontWeight.bold,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            value: 'SYP',
            items: currencyCodes.map((code) {
              return DropdownMenuItem(
                value: code,
                child: Text(
                  _currencyArabic(code), // عرض بالعربي
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                  ),
                ),
              );
            }).toList(),
            onChanged: (value) => currencyController.text = value!,
            decoration: InputDecoration(
              labelText: 'العملة'.tr,
              labelStyle: TextStyle(
                fontFamily: AppTextStyles.appFontFamily,
              ),
            ),
          ),
          // (اختياري) حقل رصيد ابتدائي لاحقًا
        ],
      ),
      confirm: ElevatedButton(
        onPressed: () {
          final currency = currencyController.text; // يبقى كود (SYP/USD)
          final balance = double.tryParse(balanceController.text) ?? 0.0;
          walletController.createWallet(userId, currency: currency, initialBalance: balance);
          Get.back();
        },
        child: Text('إنشاء'.tr),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          textStyle: TextStyle(
            fontFamily: AppTextStyles.appFontFamily,
          ),
        ),
      ),
      cancel: TextButton(
        onPressed: () => Get.back(),
        child: Text(
          'إلغاء'.tr,
          style: TextStyle(
            fontFamily: AppTextStyles.appFontFamily,
            color: AppColors.textSecondary(themeController.isDarkMode.value),
          ),
        ),
      ),
    );
  }
}
