import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';

// Import your controllers
import '../../../controllers/BankAccountController.dart';
import '../../../controllers/CardPaymentController.dart';
import '../../../controllers/ThemeController.dart';
import '../../../controllers/TransferProofController.dart';
import '../../../controllers/user_wallet_controller.dart';
import '../../../core/constant/app_text_styles.dart';
import '../../../core/constant/appcolors.dart';
import '../../../core/data/model/UserWallet.dart';
import '../../../core/data/model/BankAccountModel.dart';

class WalletDetailsPage extends StatefulWidget {
  final UserWallet wallet;
  const WalletDetailsPage({Key? key, required this.wallet}) : super(key: key);

  @override
  State<WalletDetailsPage> createState() => _WalletDetailsPageState();
}

class _WalletDetailsPageState extends State<WalletDetailsPage> {
  final ThemeController themeController = Get.find<ThemeController>();
  final UserWalletController walletController = Get.find<UserWalletController>();
  final BankAccountController bankAccountController = Get.put(BankAccountController());
  final TransferProofController _transferProofController = Get.put(TransferProofController());
  final CardPaymentController _cardPaymentController = Get.put(CardPaymentController());

  final _formKey = GlobalKey<FormState>();
  final _bankFormKey = GlobalKey<FormState>();

  final amountCtrl = TextEditingController();
  final cardNumberCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final expiryCtrl = TextEditingController();
  final cvvCtrl = TextEditingController();
  final userAccountNumberCtrl = TextEditingController();

  String get initialPaymentMethod {
    return _cardPaymentController.isEnabled.value ? 'card' : 'bank';
  }
  
  String selectedPaymentMethod = 'bank';
  BankAccountModel? selectedBankAccount;
  File? transferProofImage;
  bool isProcessing = false;
  bool showChargeScreen = false;

  @override
  void initState() {
    super.initState();
    bankAccountController.fetchAccounts();
    selectedPaymentMethod = initialPaymentMethod;
    
    amountCtrl.addListener(_updateButtonState);
    cardNumberCtrl.addListener(_updateButtonState);
    nameCtrl.addListener(_updateButtonState);
    expiryCtrl.addListener(_updateButtonState);
    cvvCtrl.addListener(_updateButtonState);
    userAccountNumberCtrl.addListener(_updateButtonState);
  }

  void _updateButtonState() {
    setState(() {});
  }

  bool get _isFormValid {
    if (amountCtrl.text.isEmpty || double.tryParse(amountCtrl.text) == null) {
      return false;
    }

    if (selectedPaymentMethod == 'card') {
      return _formKey.currentState?.validate() ?? false;
    } else if (selectedPaymentMethod == 'bank') {
      return selectedBankAccount != null &&
          userAccountNumberCtrl.text.isNotEmpty &&
          transferProofImage != null;
    }
    return false;
  }

  @override
  void dispose() {
    amountCtrl.removeListener(_updateButtonState);
    cardNumberCtrl.removeListener(_updateButtonState);
    nameCtrl.removeListener(_updateButtonState);
    expiryCtrl.removeListener(_updateButtonState);
    cvvCtrl.removeListener(_updateButtonState);
    userAccountNumberCtrl.removeListener(_updateButtonState);
    
    amountCtrl.dispose();
    cardNumberCtrl.dispose();
    nameCtrl.dispose();
    expiryCtrl.dispose();
    cvvCtrl.dispose();
    userAccountNumberCtrl.dispose();
    super.dispose();
  }

  void _onCardNumberChanged(String val) {
    final digits = val.replaceAll(RegExp(r'\D'), '');
    final groups = <String>[];
    for (int i = 0; i < digits.length; i += 4) {
      groups.add(digits.substring(i, i + 4 > digits.length ? digits.length : i + 4));
    }
    final formatted = groups.join(' ');
    if (formatted != cardNumberCtrl.text) {
      cardNumberCtrl.value =
          TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        transferProofImage = File(image.path);
        _updateButtonState();
      });
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    Get.snackbar(
      'تم النسخ'.tr,
      'تم نسخ رقم الحساب إلى الحافظة'.tr,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  Future<void> _processPayment() async {
    FocusScope.of(context).unfocus();

    if (selectedPaymentMethod == 'card' && !_formKey.currentState!.validate()) {
      return;
    }

    if (selectedPaymentMethod == 'bank') {
      if (selectedBankAccount == null) {
        Get.snackbar(
          'خطأ', 
          'الرجاء اختيار حساب بنكي', 
          snackPosition: SnackPosition.BOTTOM, 
          backgroundColor: Colors.red, 
          colorText: Colors.white
        );
        return;
      }

      if (transferProofImage == null) {
        Get.snackbar(
          'خطأ', 
          'الرجاء رفع صورة إثبات التحويل', 
          snackPosition: SnackPosition.BOTTOM, 
          backgroundColor: Colors.red, 
          colorText: Colors.white
        );
        return;
      }

      if (userAccountNumberCtrl.text.isEmpty) {
        Get.snackbar(
          'خطأ', 
          'الرجاء إدخال رقم حسابك', 
          snackPosition: SnackPosition.BOTTOM, 
          backgroundColor: Colors.red, 
          colorText: Colors.white
        );
        return;
      }
    }

    setState(() => isProcessing = true);

    try {
      final amount = double.tryParse(amountCtrl.text) ?? 0;
      
      if (selectedPaymentMethod == 'card') {
        await Future.delayed(Duration(seconds: 2));
        
        if (amount > 0) {
          walletController.creditWallet(
            walletUuid: widget.wallet.uuid,
            amount: amount,
            note: "شحن محفظة:${widget.wallet.uuid}, مبلغ الشحن هو:$amount"
          );
        }
        
        Get.snackbar(
          'نجاح', 
          'تم شحن المحفظة بمبلغ ${amountCtrl.text} ل.س',
          snackPosition: SnackPosition.BOTTOM, 
          backgroundColor: Colors.green, 
          colorText: Colors.white
        );
        _backToWalletDetails();
        
      } else if (selectedPaymentMethod == 'bank') {
        final TransferProofController proofController = Get.find<TransferProofController>();
        
        final bool success = await proofController.createProof(
          bankAccountId: selectedBankAccount!.id,
          walletId: int.parse(widget.wallet.id.toString()),
          amount: amount,
          sourceAccountNumber: userAccountNumberCtrl.text,
          proofFile: transferProofImage,
        );

        setState(() => isProcessing = false);

        if (success) {
          await Get.dialog(
            AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
              title: Column(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 60.r),
                  SizedBox(height: 16.h),
                  Text(
                    'تم إرسال إثبات التحويل بنجاح'.tr,
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: AppTextStyles.large,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'عزيزي المستخدم'.tr,
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: AppTextStyles.medium,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'لقد تم إرسال إثبات عملية التحويل بنجاح. سيتم التحقق منها وإبلاغك في النتيجة خلال 24 ساعة.'.tr,
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: AppTextStyles.medium,
                      color: AppColors.textSecondary(themeController.isDarkMode.value),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'رقم العملية: ${DateTime.now().millisecondsSinceEpoch}'.tr,
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: AppTextStyles.small,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              actions: [
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Get.back();
                      _backToWalletDetails();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
                    ),
                    child: Text(
                      'موافق'.tr,
                      style: TextStyle(
                          color: AppColors.textSecondary(themeController.isDarkMode.value),
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: AppTextStyles.medium,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
              actionsPadding: EdgeInsets.only(bottom: 20.h),
            ),
            barrierDismissible: false,
          );
        } else {
          Get.snackbar(
            'خطأ', 
            'فشل في إرسال إثبات التحويل. يرجى المحاولة مرة أخرى.'.tr,
            snackPosition: SnackPosition.BOTTOM, 
            backgroundColor: Colors.red, 
            colorText: Colors.white,
            duration: Duration(seconds: 5),
          );
        }
      }
    } catch (e) {
      setState(() => isProcessing = false);
      
      Get.snackbar(
        'خطأ', 
        'حدث خطأ غير متوقع: $e'.tr,
        snackPosition: SnackPosition.BOTTOM, 
        backgroundColor: Colors.red, 
        colorText: Colors.white,
        duration: Duration(seconds: 5),
      );
    }
  }

  void _backToWalletDetails() {
    setState(() {
      showChargeScreen = false;
      // Reset form fields
      amountCtrl.clear();
      cardNumberCtrl.clear();
      nameCtrl.clear();
      expiryCtrl.clear();
      cvvCtrl.clear();
      userAccountNumberCtrl.clear();
      selectedBankAccount = null;
      transferProofImage = null;
      isProcessing = false;
    });
  }

  Widget _buildWalletDetails(bool isDark) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
      child: Card(
        color: AppColors.card(isDark),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailItem(
                icon: Icons.account_balance_wallet,
                title: 'معرف المحفظة'.tr,
                value: widget.wallet.uuid,
                isDarkMode: isDark,
              ),
              SizedBox(height: 16.h),
              _buildDetailItem(
                icon: Icons.attach_money,
                title: 'الرصيد'.tr,
                value: '${widget.wallet.balance} ${widget.wallet.currency}',
                isDarkMode: isDark,
              ),
              SizedBox(height: 16.h),
              _buildDetailItem(
                icon: Icons.calendar_today,
                title: 'تاريخ الإنشاء'.tr,
                value: _formatDate(widget.wallet.createdAt),
                isDarkMode: isDark,
              ),
              SizedBox(height: 16.h),
              _buildDetailItem(
                icon: Icons.update,
                title: 'آخر تحديث'.tr,
                value: _formatDate(widget.wallet.lastChangedAt),
                isDarkMode: isDark,
              ),
              SizedBox(height: 16.h),
              _buildDetailItem(
                icon: Icons.account_circle,
                title: 'معرف المستخدم'.tr,
                value: widget.wallet.userId.toString(),
                isDarkMode: isDark,
              ),
              SizedBox(height: 16.h),
              _buildDetailItem(
                icon: Icons.info,
                title: 'حالة المحفظة'.tr,
                value: _getStatusText(widget.wallet.status),
                isDarkMode: isDark,
                status: widget.wallet.status,
              ),
              SizedBox(height: 24.h),
              if (widget.wallet.isActive) _buildActionButtons(),
              if (widget.wallet.isFrozen) _buildFrozenActions(),
              if (widget.wallet.isClosed) _buildClosedMessage(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String title,
    required String value,
    required bool isDarkMode,
    String? status,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: status != null ? _getStatusColor(status, isDarkMode) : AppColors.primary,
          size: 24.r,
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: AppTextStyles.appFontFamily,
                  fontSize: 14.sp,
                  color: AppColors.textSecondary(isDarkMode),
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                value,
                style: TextStyle(
                  fontFamily: AppTextStyles.appFontFamily,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: status != null ? _getStatusTextColor(status) : AppColors.textPrimary(isDarkMode),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    showChargeScreen = true;
                  });
                },
                icon: Icon(Icons.add, size: 20.r),
                label: Text('شحن'.tr),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  textStyle: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: 14.sp),
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => walletController.freezeWallet(widget.wallet.uuid),
                icon: Icon(Icons.close, size: 20.r),
                label: Text('تجميد'.tr),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  textStyle: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: 14.sp),
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        if (widget.wallet.balance == 0)
          Column(
            children: [
              SizedBox(height: 8.h),
              OutlinedButton.icon(
                onPressed: () => _showDeleteConfirmation(),
                icon: Icon(Icons.delete, size: 20.r),
                label: Text('حذف المحفظة'.tr),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: BorderSide(color: Colors.red),
                  textStyle: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: 14.sp),
                  padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 10.w),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildFrozenActions() {
    return Column(
      children: [
        Text(
          'المحفظة مجمدة ولا يمكن إجراء عمليات عليها'.tr,
          style: TextStyle(
            fontFamily: AppTextStyles.appFontFamily,
            fontSize: 14.sp,
            color: Colors.orange,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 16.h),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => walletController.activateWallet(widget.wallet.uuid),
                icon: Icon(Icons.lock_open, size: 20.r),
                label: Text('تفعيل'.tr),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  textStyle: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: 14.sp),
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                ),
              ),
            ),
            SizedBox(width: 8.w),
          ],
        ),
      ],
    );
  }

  Widget _buildClosedMessage() {
    return Column(
      children: [
        Icon(Icons.lock_outline, size: 48.r, color: Colors.red),
        SizedBox(height: 16.h),
        Text(
          'المحفظة مغلقة ولا يمكن إجراء أي عمليات عليها'.tr,
          style: TextStyle(
            fontFamily: AppTextStyles.appFontFamily,
            fontSize: 16.sp,
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8.h),
        if (widget.wallet.balance == 0)
          OutlinedButton.icon(
            onPressed: () => _showDeleteConfirmation(),
            icon: Icon(Icons.delete, size: 20.r),
            label: Text('حذف المحفظة'.tr),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: BorderSide(color: Colors.red),
              textStyle: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: 14.sp),
              padding: EdgeInsets.symmetric(vertical: 12.h),
            ),
          ),
      ],
    );
  }

  Widget _buildBankTransferSection(bool isDark) {
    return Form(
      key: _bankFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.primary, size: 20.r),
                    SizedBox(width: 8.w),
                    Text(
                      'تعليمات التحويل البنكي'.tr,
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: AppTextStyles.medium,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  'قم بتحويل مالي من خلال اختيار اسم البنك المتوفر مع إثبات دليل التحويل. سيتم التحقق من عملية التحويل ثم شحن المحفظة. ملاحظة: تأكد من المبلغ ورقم حسابك واختيار صورة الدليل بشكل واضح.'.tr,
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
          SizedBox(height: 20.h),
          
          Text(
            'اختر الحساب البنكي للتحويل'.tr,
            style: TextStyle(
              fontFamily: AppTextStyles.appFontFamily,
              fontSize: AppTextStyles.medium,
              fontWeight: FontWeight.w600, 
               color: AppColors.textSecondary(themeController.isDarkMode.value),
            ),
          ),
          SizedBox(height: 8.h),
          
          Obx(() {
            if (bankAccountController.isLoading.value) {
              return Center(child: CircularProgressIndicator());
            }
            
            return Container(
              decoration: BoxDecoration(
                color: AppColors.card(isDark),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: DropdownButton<BankAccountModel>(
                value: selectedBankAccount,
                isExpanded: true,
                underline: SizedBox(),
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                hint: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  child: Text('اختر الحساب البنكي'.tr),
                ),
                items: bankAccountController.accounts.map((BankAccountModel account) {
                  return DropdownMenuItem<BankAccountModel>(
                    value: account,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          account.bankName,
                          style: TextStyle(
                            fontFamily: AppTextStyles.appFontFamily,
                            fontSize: AppTextStyles.medium,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          account.accountNumber,
                          style: TextStyle(
                            fontFamily: AppTextStyles.appFontFamily,
                            fontSize: AppTextStyles.small,
                            color: AppColors.textSecondary(isDark),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (BankAccountModel? newValue) {
                  setState(() {
                    selectedBankAccount = newValue;
                    _updateButtonState();
                  });
                },
              ),
            );
          }),
          
          if (selectedBankAccount != null) ...[
            SizedBox(height: 16.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.green),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'رقم الحساب للتحويل:'.tr,
                        style: TextStyle(
                          fontFamily: AppTextStyles.appFontFamily,
                          fontSize: AppTextStyles.medium,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      IconButton(
                        onPressed: () => _copyToClipboard(selectedBankAccount!.accountNumber),
                        icon: Icon(Icons.copy, color: Colors.green, size: 20.r),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    selectedBankAccount!.accountNumber,
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: AppTextStyles.xlarge,
                      fontWeight: FontWeight.w900,
                      color: Colors.green,
                      letterSpacing: 1.5,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '${selectedBankAccount!.bankName}',
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: AppTextStyles.small,
                      color: AppColors.textSecondary(isDark),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          SizedBox(height: 16.h),
          
          TextFormField(
            controller: userAccountNumberCtrl,
            decoration: InputDecoration(
              labelText: 'رقم حسابك للمرجع'.tr,
              hintText: 'أدخل رقم حسابك الذي ستقوم بالتحويل منه',
              filled: true,
              fillColor: AppColors.card(isDark),
              prefixIcon: Icon(Icons.account_balance, color: AppColors.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
            ),
            validator: selectedPaymentMethod == 'bank' ? (v) {
              if (v == null || v.isEmpty) return 'الرجاء إدخال رقم حسابك'.tr;
              return null;
            } : null,
          ),
          
          SizedBox(height: 16.h),
          
          Text(
            'إثبات التحويل'.tr,
            style: TextStyle(
              fontFamily: AppTextStyles.appFontFamily,
              fontSize: AppTextStyles.medium,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: double.infinity,
              height: 150.h,
              decoration: BoxDecoration(
                color: AppColors.card(isDark),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: transferProofImage == null ? Colors.grey : AppColors.primary,
                  width: 2,
                ),
              ),
              child: transferProofImage == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_upload, size: 40.r, color: Colors.grey),
                        SizedBox(height: 8.h),
                        Text('اضغط لرفع صورة إثبات التحويل'.tr,
                            style: TextStyle(color: Colors.grey)),
                        SizedBox(height: 4.h),
                        Text(
                          'يجب أن تكون الصورة واضحة وتظهر تفاصيل التحويل'.tr,
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: AppTextStyles.small,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    )
                  : Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12.r),
                          child: Image.file(
                            transferProofImage!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                        Positioned(
                          top: 8.h,
                          right: 8.w,
                          child: Container(
                            padding: EdgeInsets.all(4.w),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Icon(Icons.check_circle, color: Colors.white, size: 20.r),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          
          if (transferProofImage != null) ...[
            SizedBox(height: 8.h),
            TextButton(
              onPressed: _pickImage,
              child: Text('تغيير الصورة'.tr),
            ),
          ],
        ],
      ),
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
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.credit_card, color: Colors.blue, size: 20.r),
                    SizedBox(width: 8.w),
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
                SizedBox(height: 8.h),
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
          SizedBox(height: 20.h),

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
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none)
            ),
            validator: (v) {
              final digits = (v ?? '').replaceAll(RegExp(r'\s+'), '');
              if (digits.isEmpty) return 'الرجاء إدخال رقم البطاقة'.tr;
              if (digits.length < 12) return 'رقم البطاقة غير صحيح'.tr;
              return null;
            },
          ),
          SizedBox(height: 16.h),
          
          TextFormField(
            controller: nameCtrl, 
            keyboardType: TextInputType.name, 
            decoration: InputDecoration(
              labelText: 'اسم صاحب البطاقة'.tr, 
              hintText: 'xxxx', 
              filled: true, 
              fillColor: AppColors.card(isDark), 
              prefixIcon: Icon(Icons.person_outline, color: AppColors.primary), 
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none)
            ), 
            validator: (v) => (v ?? '').trim().isEmpty ? 'الرجاء إدخال الاسم'.tr : null
          ),
          SizedBox(height: 16.h),
          
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
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none)
                  ), 
                  validator: (v) => (v ?? '').length < 4 ? 'تاريخ غير صحيح'.tr : null
                ),
              ),
              SizedBox(width: 16.w),
              SizedBox(
                width: 120.w, 
                child: TextFormField(
                  controller: cvvCtrl, 
                  keyboardType: TextInputType.number, 
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)], 
                  decoration: InputDecoration(
                    labelText: 'CVV'.tr, 
                    filled: true, 
                    fillColor: AppColors.card(isDark), 
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none)
                  ), 
                  obscureText: true, 
                  validator: (v) => (v ?? '').length < 3 ? 'CVV غير صحيح'.tr : null
                ),
              ),
            ]
          ),
          SizedBox(height: 24.h),
        ],
      ),
    );
  }

  Widget _buildChargeScreen(bool isDark) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: [
            // Order summary
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: AppColors.card(isDark),
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, 
                children: [
                Center(
                  child: Text(
                    'ملخص عملية الشحن'.tr, 
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily, 
                      fontSize: AppTextStyles.xlarge,
                      fontWeight: FontWeight.w800
                    )
                  )
                ),
                SizedBox(height: 16.h),
                Divider(),
                SizedBox(height: 16.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                  children: [
                  Text('المحفظة:'.tr, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, color: AppColors.textSecondary(isDark))),
                  Text(widget.wallet.uuid, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontWeight: FontWeight.w700, fontSize: AppTextStyles.small,)),
                ]),
                SizedBox(height: 12.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                  children: [
                  Text('الرصيد الحالي:'.tr, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, color: AppColors.textSecondary(isDark))),
                  Text('${widget.wallet.balance} ${widget.wallet.currency}', style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontWeight: FontWeight.w700)),
                ]),
                SizedBox(height: 12.h),
                Divider(),
                SizedBox(height: 12.h),
                TextFormField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'مبلغ الشحن'.tr,
                    hintText: 'أدخل المبلغ المراد شحنه',
                    filled: true,
                    fillColor: AppColors.background(isDark),
                    prefixIcon: Icon(Icons.attach_money, color: AppColors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none),
                  ),
                  validator: (v) {
                    final amount = double.tryParse(v ?? '');
                    if (amount == null || amount <= 0) return 'الرجاء إدخال مبلغ صحيح'.tr;
                    return null;
                  },
                ),
                SizedBox(height: 12.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                  children: [
                  Text('الإجمالي:'.tr, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.large, fontWeight: FontWeight.w800)),
                  Text('${amountCtrl.text.isNotEmpty ? amountCtrl.text : '0'} ${widget.wallet.currency}', style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.xxlarge, fontWeight: FontWeight.w900, color: AppColors.primary)),
                ]),
              ]),
            ),
            SizedBox(height: 24.h),

            // Payment methods - Dynamic based on card payment settings
            Text('اختر طريقة الشحن'.tr, style: TextStyle(fontSize: AppTextStyles.xlarge, fontWeight: FontWeight.w700, fontFamily: AppTextStyles.appFontFamily)),
            SizedBox(height: 16.h),

            // Use Obx to reactively update based on card payment settings
            Obx(() {
              final isCardEnabled = _cardPaymentController.isEnabled.value;
              
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.card(isDark), 
                  borderRadius: BorderRadius.circular(16.r)
                ),
                child: Column(
                  children: [
                    // Show bank transfer always
                    ListTile(
                      leading: Icon(Icons.account_balance, color: AppColors.primary),
                      title: Text('تحويل بنكي'.tr, style: TextStyle(fontFamily: AppTextStyles.appFontFamily)),
                      trailing: Radio(
                        value: 'bank', 
                        groupValue: selectedPaymentMethod, 
                        onChanged: (value) => setState(() => selectedPaymentMethod = value.toString()), 
                        activeColor: AppColors.primary
                      ),
                      onTap: () => setState(() => selectedPaymentMethod = 'bank'),
                    ),
                    
                    // Show credit card only if enabled
                    if (isCardEnabled) 
                    ListTile(
                      leading: Icon(Icons.credit_card, color: AppColors.primary),
                      title: Text('بطاقة ائتمان'.tr, style: TextStyle(fontFamily: AppTextStyles.appFontFamily)),
                      trailing: Radio(
                        value: 'card', 
                        groupValue: selectedPaymentMethod, 
                        onChanged: (value) => setState(() => selectedPaymentMethod = value.toString()), 
                        activeColor: AppColors.primary
                      ),
                      onTap: () => setState(() => selectedPaymentMethod = 'card'),
                    ),
                    
                    // Show message if card payment is disabled
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
                    ),
                  ],
                ),
              );
            }),
            SizedBox(height: 24.h),

            // Show appropriate form based on selection
            if (selectedPaymentMethod == 'card') 
              _buildCreditCardSection(isDark),

            if (selectedPaymentMethod == 'bank') 
              _buildBankTransferSection(isDark),

            // Payment button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isFormValid && !isProcessing ? _processPayment : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isFormValid ? AppColors.primary : Colors.grey,
                  padding: EdgeInsets.symmetric(vertical: 16.h), 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r))
                ),
                child: isProcessing 
                    ? SizedBox(
                        height: 20.h, 
                        width: 20.h, 
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      ) 
                    : Text(
                        'إتمام الشحن'.tr, 
                        style: TextStyle(
                          color: Colors.white, 
                          fontWeight: FontWeight.w900, 
                          fontFamily: AppTextStyles.appFontFamily
                        )
                      ),
              ),
            ),
            
            SizedBox(height: 16.h),
            
            // Back button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _backToWalletDetails,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  side: BorderSide(color: AppColors.primary),
                ),
                child: Text(
                  'رجوع إلى تفاصيل المحفظة'.tr,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontFamily: AppTextStyles.appFontFamily,
                  ),
                ),
              ),
            ),
            
            if (!_isFormValid) ...[
              SizedBox(height: 16.h),
              Center(
                child: Text(
                  'يرجى ملء جميع الحقول المطلوبة'.tr,
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    fontSize: AppTextStyles.small,
                    color: Colors.orange,
                  ),
                ),
              ),
            ],
          ]),
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
      case 'active': return Colors.green;
      case 'frozen': return Colors.orange;
      case 'closed': return Colors.red;
      default: return AppColors.primary;
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

  void _showDeleteConfirmation() {
    final ThemeController themeController = Get.find<ThemeController>();

    Get.defaultDialog(
      title: 'تأكيد الحذف'.tr,
      titleStyle: TextStyle(
        fontFamily: AppTextStyles.appFontFamily,
        fontSize: 16.sp,
        fontWeight: FontWeight.bold,
      ),
      content: Text(
        'هل أنت متأكد من رغبتك في حذف هذه المحفظة؟'.tr,
        style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: 14.sp),
        textAlign: TextAlign.center,
      ),
      confirm: ElevatedButton(
        onPressed: () {
          walletController.deleteWallet(widget.wallet.uuid);
          Get.back();
          Get.back();
        },
        child: Text('نعم، احذف'.tr),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          textStyle: TextStyle(fontFamily: AppTextStyles.appFontFamily),
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

  @override
  Widget build(BuildContext context) {
    final isDark = themeController.isDarkMode.value;

    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      appBar: AppBar(
        backgroundColor: AppColors.appBar(isDark),
        elevation: 0,
        centerTitle: true,
        title: Text(
          showChargeScreen ? 'شحن المحفظة'.tr : 'تفاصيل المحفظة'.tr,
          style: TextStyle(fontFamily: AppTextStyles.appFontFamily, color: AppColors.onPrimary),
        ),
        leading: IconButton(
          onPressed: () {
            if (showChargeScreen) {
              _backToWalletDetails();
            } else {
              Get.back();
            }
          },
          icon: Icon(Icons.arrow_back, color: AppColors.onPrimary),
        ),
      ),
      body: showChargeScreen ? _buildChargeScreen(isDark) : _buildWalletDetails(isDark),
    );
  }
}