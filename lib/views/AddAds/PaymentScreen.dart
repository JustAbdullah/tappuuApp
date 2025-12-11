import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../controllers/AdsManageController.dart';
import '../../controllers/CardPaymentController.dart';
import '../../controllers/LoadingController.dart';
import '../../controllers/ThemeController.dart';
import '../../controllers/user_wallet_controller.dart';
import '../../core/constant/app_text_styles.dart';
import '../../core/constant/appcolors.dart';
import '../../core/data/model/PremiumPackage.dart';
import '../../core/data/model/UserWallet.dart';
import '../HomeScreen/home_screen.dart';

class PaymentScreen extends StatefulWidget {
  final dynamic package;
  final String adTitle;
  final String adPrice;

  const PaymentScreen({
    Key? key,
    required this.package,
    required this.adTitle,
    required this.adPrice,
  }) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final ManageAdController adController = Get.find<ManageAdController>();
  final ThemeController themeController = Get.find<ThemeController>();
  final UserWalletController walletController = Get.put(UserWalletController());
  final LoadingController loadingController = Get.find<LoadingController>();
  final CardPaymentController _cardPaymentController = Get.find<CardPaymentController>();
  final _formKey = GlobalKey<FormState>();

  final cardNumberCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final expiryCtrl = TextEditingController();
  final cvvCtrl = TextEditingController();

  String get initialPaymentMethod {
    return _cardPaymentController.isEnabled.value ? 'card' : 'wallet';
  }
  
  String selectedPaymentMethod = 'wallet';
  bool isProcessing = false;
  UserWallet? selectedWallet;

  final fmt = NumberFormat('#,##0', 'en_US');
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchUserWallets();
    selectedPaymentMethod = initialPaymentMethod;
    _cardPaymentController.fetchSetting();
  }

  Future<void> _fetchUserWallets() async {
    final userId = loadingController.currentUser?.id;
    if (userId != null) {
      await walletController.fetchUserWallets(userId);
    }
  }

  List<PremiumPackage> _packageListFromWidget() {
    final p = widget.package;
    final out = <PremiumPackage>[];
    try {
      if (p == null) return out;
      if (p is List) {
        for (var e in p) {
          if (e == null) continue;
          if (e is PremiumPackage) out.add(e);
        }
        return out;
      }
      if (p is PremiumPackage) {
        out.add(p);
        return out;
      }
    } catch (e) {
      print('⚠️ _packageListFromWidget parse error: $e');
    }
    return out;
  }

  List<int> _extractPackageIdsFromWidgetPackage() {
    return _packageListFromWidget().map((e) => e.id ?? 0).where((id) => id > 0).toList();
  }

  double _totalPriceOfSelected() {
    final list = _packageListFromWidget();
    return list.fold(0.0, (p, e) => p + (e.price ?? 0));
  }

  String _namesOfSelected() {
    final list = _packageListFromWidget();
    if (list.isEmpty) return '-';
    return list.map((e) => e.name ?? '-').join(' • ');
  }

  String _typesOfSelected() {
    final list = _packageListFromWidget();
    if (list.isEmpty) return '-';
    return list.map((e) => e.type?.name ?? '-').toSet().join(' • ');
  }

  String _durationText() {
    final list = _packageListFromWidget();
    if (list.isEmpty) return '-';
    if (list.length == 1) return '${list.first.durationDays ?? '-'} يوم';
    final durations = list.map((e) => e.durationDays ?? 0).toSet();
    if (durations.length == 1) return '${durations.first} يوم';
    return 'متعددة';
  }

  String _formatPrice(double price) {
    return '${fmt.format(price)} ليرة سورية';
  }

  bool _hasSufficientBalance() {
    if (selectedWallet == null) return false;
    final totalPrice = _totalPriceOfSelected();
    return (selectedWallet!.balance ?? 0) >= totalPrice;
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

  String _formatWalletUuid(String uuid) {
    if (uuid.length <= 12) return uuid;
    return '${uuid.substring(0, 8)}...${uuid.substring(uuid.length - 4)}';
  }

  Future<void> _processPayment() async {
    FocusScope.of(context).unfocus();
    
    if (selectedPaymentMethod == 'card' && !_formKey.currentState!.validate()) return;

    if (selectedPaymentMethod == 'wallet') {
      if (selectedWallet == null) {
        _showErrorSnackbar('خطأ', 'يرجى اختيار محفظة للدفع');
        return;
      }
      
      if (!_hasSufficientBalance()) {
        _showErrorSnackbar('خطأ', 'ليس لديك رصيد كافي في المحفظة المختارة');
        return;
      }
      
      if ((selectedWallet!.status ?? '').toString().toLowerCase() != 'active') {
        _showErrorSnackbar('خطأ', 'لا يمكن استخدام هذه المحفظة لأنها ليست نشطة');
        return;
      }
    }

    setState(() => isProcessing = true);
    final packageIds = _extractPackageIdsFromWidgetPackage();
    if (packageIds.isEmpty) {
      _showErrorSnackbar('خطأ', 'لا توجد باقات صالحة للاشتراك');
      setState(() => isProcessing = false);
      return;
    }

    try {
      if (selectedPaymentMethod == 'wallet') {
        final bool isSingle = _packageListFromWidget().length == 1;
        final PremiumPackage? firstPkg = isSingle ? _packageListFromWidget().first : null;

        final int? createdAdId = await _submitAdAndGetId(forPackage: firstPkg, isSinglePackage: isSingle);
        if (createdAdId == null) {
          setState(() => isProcessing = false);
          return;
        }

        final result = await walletController.purchasePremium(
          walletUuid: selectedWallet!.uuid, 
          adId: createdAdId, 
          packageIds: packageIds
        );

        if (result != null && result['success'] == true) {
          _showSuccessSnackbar('نجاح', 'تم شراء/تجديد الباقات بنجاح');
          _navigateToHome();
        } else {
          final body = result != null ? result['body'] : null;
          final message = body != null && body['message'] != null ? body['message'] : 'فشل شراء/تجديد الباقات';
          _showErrorSnackbar('خطأ', message);
        }
      } else {
        await Future.delayed(Duration(seconds: 2));
        _showSuccessSnackbar('نجاح', 'تمت عملية الدفع بالبطاقة بنجاح');

        final bool isSingle = _packageListFromWidget().length == 1;
        final PremiumPackage? firstPkg = isSingle ? _packageListFromWidget().first : null;
        final int? createdAdId = await _submitAdAndGetId(forPackage: firstPkg, isSinglePackage: isSingle);
        if (createdAdId == null) {
          setState(() => isProcessing = false);
          return;
        }

        if (!isSingle) {
          _showInfoSnackbar('ملاحظة', 'لقد دفعت بالبطاقة وتم إنشاء الإعلان. لربط الباقات المتعددة يرجى استخدام المحفظة أو التواصل مع الدعم.');
        } else {
          _showSuccessSnackbar('نجاح', 'تم إنشاء الإعلان بنجاح وهو قيد المراجعة');
        }

        _navigateToHome();
      }
    } catch (e, st) {
      print('⚠️ _processPayment exception: $e\n$st');
      _showErrorSnackbar('خطأ', 'حدث خطأ أثناء عملية الدفع: ${e.toString()}');
    } finally {
      setState(() => isProcessing = false);
    }
  }

  void _showErrorSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      margin: EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  void _showSuccessSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      margin: EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  void _showInfoSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      margin: EdgeInsets.all(16),
      borderRadius: 12,
      duration: Duration(seconds: 5),
    );
  }

  void _navigateToHome() {
    if (Navigator.canPop(context)) Navigator.pop(context);
    Get.offAll(HomeScreen());
  }

  Future<int?> _parseCreatedAdId(dynamic result) async {
    try {
      if (result == null) return null;

      if (result is int) return result;
      if (result is String) {
        final val = int.tryParse(result);
        if (val != null) return val;
      }
      if (result is Map) {
        final keys = ['id', 'ad_id', 'created_ad_id', 'createdId', 'data', 'result'];
        for (var k in keys) {
          if (result.containsKey(k)) {
            final v = result[k];
            if (v is int) return v;
            if (v is String) {
              final val = int.tryParse(v);
              if (val != null) return val;
            }
          }
        }
      }
    } catch (e) {
      print('⚠️ _parseCreatedAdId error: $e');
    }
    return null;
  }

  Future<int?> _submitAdAndGetId({required PremiumPackage? forPackage, required bool isSinglePackage}) async {
    _showLoadingDialog();
    try {
      dynamic rawResult;
      if (isSinglePackage && forPackage != null) {
        rawResult = await adController.submitAd();
      } else {
        rawResult = await adController.submitAd(isPay: false);
      }

      while (adController.isSubmitting.value) {
        await Future.delayed(const Duration(milliseconds: 200));
      }

      final int? parsedId = await _parseCreatedAdId(rawResult);
      if (parsedId != null) return parsedId;

      if (adController.hasError.value) {
        _showErrorSnackbar('خطأ', 'فشل إنشاء الإعلان');
      } else {
        _showErrorSnackbar('خطأ', 'لم يتم استلام معرف الإعلان من الخادم');
      }
      return null;
    } catch (e) {
      print('⚠️ _submitAdAndGetId exception: $e');
      _showErrorSnackbar('خطأ', 'حدث خطأ أثناء إنشاء الإعلان: ${e.toString()}');
      return null;
    } finally {
      if (Navigator.canPop(context)) Navigator.pop(context);
    }
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

  @override
  void dispose() {
    cardNumberCtrl.dispose();
    nameCtrl.dispose();
    expiryCtrl.dispose();
    cvvCtrl.dispose();
    _scrollController.dispose();
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
      cardNumberCtrl.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  Widget _buildCreditCardSection(bool isDark) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue.shade50.withOpacity(0.8),
                    Colors.blue.shade100.withOpacity(0.4),
                  ],
                ),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.credit_card, color: Colors.blue, size: 24.w),
                      SizedBox(width: 12.w),
                      Text(
                        'الدفع الآمن بالبطاقة'.tr,
                        style: TextStyle(
                          fontFamily: AppTextStyles.appFontFamily,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'مدفوعات آمنة ومشفرة. سيتم خصم المبلغ من بطاقتك الائتمانية فوراً.'.tr,
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: 13.sp,
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
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(19)
              ],
              decoration: InputDecoration(
                labelText: 'رقم البطاقة'.tr,
                hintText: 'xxxx xxxx xxxx xxxx',
                filled: true,
                fillColor: AppColors.card(isDark),
                prefixIcon: Icon(Icons.credit_card, color: AppColors.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
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
                filled: true,
                fillColor: AppColors.card(isDark),
                prefixIcon: Icon(Icons.person_outline, color: AppColors.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              ),
              validator: (v) => (v ?? '').trim().isEmpty ? 'الرجاء إدخال الاسم'.tr : null,
            ),
            SizedBox(height: 16.h),
            
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: expiryCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4)
                    ],
                    decoration: InputDecoration(
                      labelText: 'انتهاء الصلاحية (MMYY)'.tr,
                      filled: true,
                      fillColor: AppColors.card(isDark),
                      prefixIcon: Icon(Icons.calendar_today, color: AppColors.primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                    ),
                    validator: (v) => (v ?? '').length < 4 ? 'تاريخ غير صحيح'.tr : null,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: cvvCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4)
                    ],
                    decoration: InputDecoration(
                      labelText: 'CVV'.tr,
                      filled: true,
                      fillColor: AppColors.card(isDark),
                      prefixIcon: Icon(Icons.lock, color: AppColors.primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                    ),
                    obscureText: true,
                    validator: (v) => (v ?? '').length < 3 ? 'CVV غير صحيح'.tr : null,
                  ),
                ),
              ],
            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletSection(bool isDark) {
    return Obx(() {
      if (walletController.isLoading.value) {
        return Center(
          child: Padding(
            padding: EdgeInsets.all(20.h),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        );
      }
      
      if (walletController.userWallets.isEmpty) {
        return Container(
          padding: EdgeInsets.all(20.h),
          decoration: BoxDecoration(
            color: AppColors.card(isDark),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            children: [
              Icon(Icons.account_balance_wallet_outlined, size: 48.w, color: Colors.grey),
              SizedBox(height: 12.h),
              Text(
                'لا توجد محافظ متاحة'.tr,
                style: TextStyle(
                  fontFamily: AppTextStyles.appFontFamily,
                  color: AppColors.textSecondary(isDark),
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // تحسين القائمة المنسدلة مع مساحة أكبر
          Container(
            constraints: BoxConstraints(
              minHeight: 70.h,
            ),
            decoration: BoxDecoration(
              color: AppColors.card(isDark),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: DropdownButtonFormField<UserWallet>(
              value: walletController.userWallets.contains(selectedWallet) ? selectedWallet : null,
              isExpanded: true,
              icon: Icon(Icons.arrow_drop_down, size: 28.w),
              iconSize: 32.w,
              elevation: 4,
              dropdownColor: AppColors.card(isDark),
              style: TextStyle(
                fontFamily: AppTextStyles.appFontFamily,
                color: AppColors.textPrimary(isDark),
                fontSize: 14.sp,
              ),
              items: walletController.userWallets.map((wallet) {
                final statusColor = _getWalletStatusColor(wallet.status ?? '');
                final statusText = _getWalletStatusText(wallet.status ?? '');
                final formattedUuid = _formatWalletUuid(wallet.uuid);
                
                return DropdownMenuItem<UserWallet>(
                  value: wallet,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                formattedUuid,
                                style: TextStyle(
                                  fontFamily: AppTextStyles.appFontFamily,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              SizedBox(height: 6.h),
                              Text(
                                'الرصيد: ${_formatPrice(wallet.balance ?? 0)}',
                                style: TextStyle(
                                  fontFamily: AppTextStyles.appFontFamily,
                                  fontSize: 12.sp,
                                  color: AppColors.textSecondary(isDark),
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(color: statusColor.withOpacity(0.3)),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontFamily: AppTextStyles.appFontFamily,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold,
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
                  _showErrorSnackbar('غير مسموح', 'هذه المحفظة ليست نشطة ولا يمكن استخدامها للدفع');
                  return;
                }
                setState(() => selectedWallet = wallet);
              },
              decoration: InputDecoration(
                border: InputBorder.none,
                labelText: 'اختر المحفظة'.tr,
                labelStyle: TextStyle(
                  fontFamily: AppTextStyles.appFontFamily,
                  fontSize: 14.sp,
                  color: AppColors.textSecondary(isDark),
                ),
                prefixIcon: Container(
                  margin: EdgeInsets.only(right: 12.w),
                  child: Icon(Icons.account_balance_wallet, color: AppColors.primary),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
                floatingLabelBehavior: FloatingLabelBehavior.always,
              ),
            ),
          ),
          SizedBox(height: 20.h),

          if (selectedWallet != null)
            AnimatedContainer(
              duration: Duration(milliseconds: 300),
              padding: EdgeInsets.all(18.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _hasSufficientBalance() ? Colors.green.shade50.withOpacity(0.6) : Colors.orange.shade50.withOpacity(0.6),
                    _hasSufficientBalance() ? Colors.green.shade100.withOpacity(0.3) : Colors.orange.shade100.withOpacity(0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: _hasSufficientBalance() ? Colors.green.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _hasSufficientBalance() ? Icons.check_circle : Icons.warning,
                        color: _hasSufficientBalance() ? Colors.green : Colors.orange,
                        size: 22.w,
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          _hasSufficientBalance() ? 'المحفظة المختارة' : 'انتباه! الرصيد غير كافي',
                          style: TextStyle(
                            fontFamily: AppTextStyles.appFontFamily,
                            fontWeight: FontWeight.bold,
                            fontSize: 15.sp,
                            color: _hasSufficientBalance() ? Colors.green.shade800 : Colors.orange.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  _buildWalletDetailRow('معرف المحفظة:', _formatWalletUuid(selectedWallet!.uuid)),
                  SizedBox(height: 10.h),
                  _buildWalletDetailRow('الرصيد:', _formatPrice(selectedWallet!.balance ?? 0)),
                  SizedBox(height: 10.h),
                  _buildWalletDetailRow('المطلوب:', _formatPrice(_totalPriceOfSelected())),
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      Text('الحالة: ', style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: 14.sp,
                      )),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: _getWalletStatusColor(selectedWallet!.status ?? '').withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          _getWalletStatusText(selectedWallet!.status ?? ''),
                          style: TextStyle(
                            color: _getWalletStatusColor(selectedWallet!.status ?? ''),
                            fontWeight: FontWeight.bold,
                            fontFamily: AppTextStyles.appFontFamily,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  if (!_hasSufficientBalance())
                    Container(
                      margin: EdgeInsets.only(top: 16.h),
                      padding: EdgeInsets.all(14.w),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 18.w, color: Colors.orange),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(
                              'الرصيد الحالي غير كافي لشراء الباقات المختارة',
                              style: TextStyle(
                                fontFamily: AppTextStyles.appFontFamily,
                                fontSize: 13.sp,
                                color: Colors.orange.shade800,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
        ],
      );
    });
  }

  Widget _buildWalletDetailRow(String label, String value) {
    final isDark = themeController.isDarkMode.value;
    return Container(
      margin: EdgeInsets.only(bottom: 4.h),
      child: Row(
        children: [
          Text(
            '$label ',
            style: TextStyle(
              fontFamily: AppTextStyles.appFontFamily,
              color: AppColors.textSecondary(isDark),
              fontSize: 14.sp,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: AppTextStyles.appFontFamily,
                fontWeight: FontWeight.w600,
                fontSize: 14.sp,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100.w,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppTextStyles.appFontFamily,
              color: AppColors.textSecondary(themeController.isDarkMode.value),
              fontSize: 14.sp,
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontFamily: AppTextStyles.appFontFamily,
              fontWeight: FontWeight.w700,
              fontSize: 14.sp,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodTile({
    required IconData icon,
    required String title,
    required String value,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = themeController.isDarkMode.value;
    
    return Container(
      margin: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isSelected ? AppColors.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.grey.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: isSelected ? Colors.white : AppColors.primary, size: 20.w),
        ),
        title: Text(title, style: TextStyle(fontFamily: AppTextStyles.appFontFamily)),
        trailing: Container(
          width: 24.w,
          height: 24.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.grey,
              width: 2,
            ),
            color: isSelected ? AppColors.primary : Colors.transparent,
          ),
          child: isSelected
              ? Icon(Icons.check, size: 16.w, color: Colors.white)
              : null,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildDisabledPaymentTile() {
    return Container(
      margin: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: ListTile(
        leading: Icon(Icons.credit_card_off, color: Colors.grey),
        title: Text(
          'الدفع بالبطاقة غير متاح حالياً'.tr,
          style: TextStyle(
            fontFamily: AppTextStyles.appFontFamily,
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
        subtitle: Text(
          'يرجى استخدام المحفظة الإلكترونية للدفع'.tr,
          style: TextStyle(
            fontFamily: AppTextStyles.appFontFamily,
            fontSize: 12.sp,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = themeController.isDarkMode.value;
    final selectedPackages = _packageListFromWidget();
    final totalPrice = _totalPriceOfSelected();
    final priceText = _formatPrice(totalPrice);
    final namesText = _namesOfSelected();
    final typesText = _typesOfSelected();
    final durationText = _durationText();

    final isPaymentEnabled = selectedPaymentMethod == 'card' || 
                            (selectedPaymentMethod == 'wallet' && 
                             selectedWallet != null && 
                             _hasSufficientBalance());

    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      appBar: AppBar(
        backgroundColor: AppColors.appBar(isDark),
        elevation: 0,
        centerTitle: true,
        title: Text(
          'إتمام الشراء'.tr,
          style: TextStyle(
            fontFamily: AppTextStyles.appFontFamily,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(Icons.arrow_back, color: AppColors.onPrimary),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20.r),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [Color(0xFF1e293b), Color(0xFF334155)]
                            : [Colors.white, Colors.grey.shade50],
                      ),
                      borderRadius: BorderRadius.circular(20.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 15,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            'ملخص طلبك'.tr,
                            style: TextStyle(
                              fontFamily: AppTextStyles.appFontFamily,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Divider(color: Colors.grey.withOpacity(0.3)),
                        SizedBox(height: 16.h),
                        
                        _buildSummaryRow('الباقات المختارة:', namesText),
                        SizedBox(height: 12.h),
                        _buildSummaryRow('النوع:', typesText),
                        SizedBox(height: 12.h),
                        _buildSummaryRow('المدة:', durationText),
                        SizedBox(height: 12.h),
                        _buildSummaryRow('عنوان الإعلان:', widget.adTitle),
                        
                        SizedBox(height: 16.h),
                        Divider(color: Colors.grey.withOpacity(0.3)),
                        SizedBox(height: 16.h),
                        
                        Container(
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'الإجمالي:'.tr,
                                style: TextStyle(
                                  fontFamily: AppTextStyles.appFontFamily,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                              Text(
                                priceText,
                                style: TextStyle(
                                  fontFamily: AppTextStyles.appFontFamily,
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24.h),
                  
                  Text(
                    'اختر طريقة الدفع'.tr,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      fontFamily: AppTextStyles.appFontFamily,
                    ),
                  ),
                  SizedBox(height: 16.h),

                  Obx(() {
                    final isCardEnabled = _cardPaymentController.isEnabled.value;
                    
                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.card(isDark),
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          if (isCardEnabled)
                            _buildPaymentMethodTile(
                              icon: Icons.credit_card,
                              title: 'بطاقة ائتمان'.tr,
                              value: 'card',
                              isSelected: selectedPaymentMethod == 'card',
                              onTap: () => setState(() => selectedPaymentMethod = 'card'),
                            ),
                          
                          _buildPaymentMethodTile(
                            icon: Icons.account_balance_wallet,
                            title: 'المحفظة الإلكترونية'.tr,
                            value: 'wallet',
                            isSelected: selectedPaymentMethod == 'wallet',
                            onTap: () => setState(() => selectedPaymentMethod = 'wallet'),
                          ),

                          if (!isCardEnabled)
                            _buildDisabledPaymentTile(),
                        ],
                      ),
                    );
                  }),

                  SizedBox(height: 24.h),

                  AnimatedSwitcher(
                    duration: Duration(milliseconds: 300),
                    child: selectedPaymentMethod == 'card'
                        ? _buildCreditCardSection(isDark)
                        : _buildWalletSection(isDark),
                  ),

                  // مساحة إضافية في الأسفل لمنع التدفق
                  SizedBox(height: 120.h),
                ],
              ),
            ),
          ),

          // زر الدفع الثابت في الأسفل
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.background(isDark),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: isProcessing || !isPaymentEnabled ? null : _processPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: isPaymentEnabled ? AppColors.primary : Colors.grey,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation: 4,
                shadowColor: (isPaymentEnabled ? AppColors.primary : Colors.grey).withOpacity(0.3),
              ),
              child: isProcessing
                  ? SizedBox(
                      height: 24.h,
                      width: 24.h,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isPaymentEnabled ? Icons.payment : Icons.warning,
                          color: Colors.white,
                          size: 20.w,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          isPaymentEnabled ? 'إتمام الدفع'.tr : 'غير متاح',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontFamily: AppTextStyles.appFontFamily,
                            fontSize: 16.sp,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}