import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../controllers/ThemeController.dart';
import '../../../controllers/TransferProofController.dart';
import '../../../core/constant/app_text_styles.dart';
import '../../../core/constant/appcolors.dart';
import '../../../core/data/model/TransferProofModel.dart';

class TransferProofsPage extends StatelessWidget {
  final int userId;
  final TransferProofController proofController = Get.put(TransferProofController());

  TransferProofsPage({required this.userId});

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    final isDarkMode = themeController.isDarkMode.value;

    // جلب الإثباتات عند فتح الصفحة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      proofController.fetchProofsByUser(userId: userId);
    });

    return Scaffold(
      backgroundColor: AppColors.background(isDarkMode),
      appBar: AppBar(
        backgroundColor: AppColors.appBar(isDarkMode),
        title: Text(
          'إثباتات التحويل'.tr,
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
      body: Obx(() {
        if (proofController.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          );
        }

        if (proofController.proofs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 64.r,
                  color: AppColors.textSecondary(isDarkMode),
                ),
                SizedBox(height: 16.h),
                Text(
                  'لا توجد إثباتات تحويل'.tr,
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    fontSize: AppTextStyles.large,
                    color: AppColors.textPrimary(isDarkMode),
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'سيتم عرض إثباتات التحويل هنا'.tr,
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
          itemCount: proofController.proofs.length,
          itemBuilder: (context, index) {
            final proof = proofController.proofs[index];
            return _buildProofCard(proof, isDarkMode);
          },
        );
      }),
    
    );
  }

  Widget _buildProofCard(TransferProofModel proof, bool isDarkMode) {
    return Card(
      color: AppColors.card(isDarkMode),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      margin: EdgeInsets.only(bottom: 16.h),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Status and Amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'المبلغ: ${proof.amount} ليرة',
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    fontSize: AppTextStyles.large,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(isDarkMode),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: _getStatusColor(proof.status, isDarkMode),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    _getStatusText(proof.status),
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: AppTextStyles.small,
                      fontWeight: FontWeight.bold,
                      color: _getStatusTextColor(proof.status),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // Bank Account Info
            if (proof.bankAccount != null) ...[
              Row(
                children: [
                  Icon(
                    Icons.account_balance,
                    size: 18.r,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'الحساب البنكي: ${proof.bankAccount!.accountNumber}',
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: AppTextStyles.small,
                        color: AppColors.textSecondary(isDarkMode),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
            ],

            // Source Account Number
            if (proof.sourceAccountNumber != null && proof.sourceAccountNumber!.isNotEmpty) ...[
              Row(
                children: [
                  Icon(
                    Icons.credit_card,
                    size: 18.r,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'رقم الحساب المحول منه: ${proof.sourceAccountNumber}',
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: AppTextStyles.small,
                        color: AppColors.textSecondary(isDarkMode),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
            ],

            // Proof Image
            if (proof.proofImage != null && proof.proofImage!.isNotEmpty) ...[
              Text(
                'صورة الإثبات:',
                style: TextStyle(
                  fontFamily: AppTextStyles.appFontFamily,
                  fontSize: AppTextStyles.small,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(isDarkMode),
                ),
              ),
              SizedBox(height: 8.h),
              Container(
                width: double.infinity,
                height: 150.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: CachedNetworkImage(
                    imageUrl: proof.proofImage!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppColors.background(isDarkMode),
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.background(isDarkMode),
                      child: Center(
                        child: Icon(
                          Icons.error_outline,
                          color: AppColors.textSecondary(isDarkMode),
                          size: 40.r,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
            ],

            // Comment
            if (proof.comment != null && proof.comment!.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColors.background(isDarkMode),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.comment,
                          size: 16.r,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          'التعليق:',
                          style: TextStyle(
                            fontFamily: AppTextStyles.appFontFamily,
                            fontSize: AppTextStyles.small,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary(isDarkMode),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      proof.comment!,
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: AppTextStyles.small,
                        color: AppColors.textSecondary(isDarkMode),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
            ],

            // Dates and Footer Info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تاريخ الإنشاء:',
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: AppTextStyles.small,
                        color: AppColors.textSecondary(isDarkMode),
                      ),
                    ),
                    Text(
                      _formatDate(proof.createdAt),
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: AppTextStyles.small,
                        color: AppColors.textPrimary(isDarkMode),
                      ),
                    ),
                  ],
                ),
                if (proof.approvedAt != null) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'تاريخ المراجعة:',
                        style: TextStyle(
                          fontFamily: AppTextStyles.appFontFamily,
                          fontSize: AppTextStyles.small,
                          color: AppColors.textSecondary(isDarkMode),
                        ),
                      ),
                      Text(
                        _formatDate(proof.approvedAt),
                        style: TextStyle(
                          fontFamily: AppTextStyles.appFontFamily,
                          fontSize: AppTextStyles.small,
                          color: AppColors.textPrimary(isDarkMode),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending': return 'في الانتظار'.tr;
      case 'approved': return 'مقبولة'.tr;
      case 'rejected': return 'مرفوضة'.tr;
      default: return status;
    }
  }

  Color _getStatusColor(String status, bool isDarkMode) {
    switch (status) {
      case 'pending': return Colors.orange.withOpacity(0.2);
      case 'approved': return Colors.green.withOpacity(0.2);
      case 'rejected': return Colors.red.withOpacity(0.2);
      default: return AppColors.card(isDarkMode);
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'approved': return Colors.green;
      case 'rejected': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'غير محدد'.tr;
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  void _showAddProofDialog(BuildContext context, int userId) {
    final ThemeController themeController = Get.find<ThemeController>();
    final isDarkMode = themeController.isDarkMode.value;

    final bankAccountIdController = TextEditingController();
    final walletIdController = TextEditingController();
    final amountController = TextEditingController();
    final sourceAccountController = TextEditingController();

    Get.defaultDialog(
      title: 'إضافة إثبات تحويل جديد'.tr,
      titleStyle: TextStyle(
        fontFamily: AppTextStyles.appFontFamily,
        fontSize: AppTextStyles.large,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary(isDarkMode),
      ),
      backgroundColor: AppColors.background(isDarkMode),
      content: Container(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: bankAccountIdController,
                decoration: InputDecoration(
                  labelText: 'معرف الحساب البنكي'.tr,
                  labelStyle: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    color: AppColors.textPrimary(isDarkMode),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: walletIdController,
                decoration: InputDecoration(
                  labelText: 'معرف المحفظة'.tr,
                  labelStyle: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    color: AppColors.textPrimary(isDarkMode),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: amountController,
                decoration: InputDecoration(
                  labelText: 'المبلغ'.tr,
                  labelStyle: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    color: AppColors.textPrimary(isDarkMode),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: sourceAccountController,
                decoration: InputDecoration(
                  labelText: 'رقم الحساب المحول منه (اختياري)'.tr,
                  labelStyle: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    color: AppColors.textPrimary(isDarkMode),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Obx(() {
                if (proofController.imageBytes.value != null) {
                  return Column(
                    children: [
                      Container(
                        width: 120.w,
                        height: 120.h,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: AppColors.primary),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12.r),
                          child: Image.memory(
                            proofController.imageBytes.value!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      TextButton(
                        onPressed: () => proofController.removeImage(),
                        child: Text(
                          'إزالة الصورة'.tr,
                          style: TextStyle(
                            fontFamily: AppTextStyles.appFontFamily,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  );
                } else {
                  return ElevatedButton.icon(
                    onPressed: () => proofController.pickImage(),
                    icon: Icon(Icons.add_photo_alternate),
                    label: Text('اختيار صورة الإثبات'.tr),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  );
                }
              }),
            ],
          ),
        ),
      ),
      confirm: Obx(() => proofController.isSaving.value
          ? CircularProgressIndicator()
          : ElevatedButton(
              onPressed: () async {
                if (bankAccountIdController.text.isEmpty ||
                    walletIdController.text.isEmpty ||
                    amountController.text.isEmpty) {
                  Get.snackbar(
                    'خطأ'.tr,
                    'يرجى ملء جميع الحقول المطلوبة'.tr,
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                  return;
                }

                final success = await proofController.createProof(
                  bankAccountId: int.parse(bankAccountIdController.text),
                  walletId: int.parse(walletIdController.text),
                  amount: double.parse(amountController.text),
                  sourceAccountNumber: sourceAccountController.text.isEmpty 
                      ? null 
                      : sourceAccountController.text,
                  userId: userId,
                );

                if (success) {
                  Get.back();
                }
              },
              child: Text('حفظ'.tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            )),
      cancel: TextButton(
        onPressed: () => Get.back(),
        child: Text(
          'إلغاء'.tr,
          style: TextStyle(
            fontFamily: AppTextStyles.appFontFamily,
            color: AppColors.textSecondary(isDarkMode),
          ),
        ),
      ),
    );
  }
}