import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
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
          } 
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
            return _buildWalletCard(wallet, isDarkMode);
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

  Widget _buildWalletCard(UserWallet wallet, bool isDarkMode) {
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'المحفظة ${walletController.userWallets.indexOf(wallet) + 1}',
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
              Row(
                children: [
                  Icon(
                    Icons.attach_money,
                    size: 20.r,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'الرصيد:',
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: AppTextStyles.medium,

                      color: AppColors.textSecondary(isDarkMode),
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    '${wallet.balance} ${wallet.currency}',
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
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 20.r,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'آخر تحديث:',
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
      case 'active': return 'نشطة'.tr;
      case 'frozen': return 'مجمدة'.tr;
      case 'closed': return 'مغلقة'.tr;
      default: return status;
    }
  }

  Color _getStatusColor(String status, bool isDarkMode) {
    switch (status) {
      case 'active': return Colors.green.withOpacity(0.2);
      case 'frozen': return Colors.orange.withOpacity(0.2);
      case 'closed': return Colors.red.withOpacity(0.2);
      default: return AppColors.card(isDarkMode);
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status) {
      case 'active': return Colors.green;
      case 'frozen': return Colors.orange;
      case 'closed': return Colors.red;
      default: return Colors.grey;
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
            items: ['SYP','USD'].map((currency) {
              return DropdownMenuItem(
                value: currency,
                child: Text(
                  currency,
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
        
        ],
      ),
      confirm: ElevatedButton(
        onPressed: () {
          final currency = currencyController.text;
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