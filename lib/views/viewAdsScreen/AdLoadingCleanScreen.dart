import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controllers/ThemeController.dart';
import '../../controllers/sharedController.dart';
import '../../controllers/LoadingController.dart';
import '../../core/services/appservices.dart';
import '../../views/HomeScreen/home_screen.dart';
import '../../core/constant/app_text_styles.dart';
import '../../core/constant/appcolors.dart';
import '../../core/constant/images_path.dart';
import 'AdDetailsScreen.dart'; // عدّل المسار إذا لازم

class AdLoadingCleanScreen extends StatefulWidget {
  final String adId;
  const AdLoadingCleanScreen({Key? key, required this.adId}) : super(key: key);

  @override
  State<AdLoadingCleanScreen> createState() => _AdLoadingCleanScreenState();
}

class _AdLoadingCleanScreenState extends State<AdLoadingCleanScreen>
    with SingleTickerProviderStateMixin {
  final SharedController _shared = Get.find<SharedController>();
  final LoadingController _loadingController = Get.put(LoadingController());

  bool _isLoading = true;
  String? _errorMessage;
  late final AnimationController _logoAnimCtr;

  @override
  void initState() {
    super.initState();
    _logoAnimCtr = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) => _startLoad());
  }

  @override
  void dispose() {
    _logoAnimCtr.dispose();
    super.dispose();
  }

  Future<void> _startLoad() async {
    // وضع علامة أن التنقل قيد التنفيذ — لكن لا تنهي الحالة هنا عند النجاح
    _shared.isNavigatingToAd.value = true;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final ad = await _shared.fetchAdDetails(adId: widget.adId);

      if (ad != null) {
        // انتقل إلى صفحة التفاصيل — لا تغيّر حالة الـ deep link هنا، خلي AdDetailsScreen يتعامل معها.
        // استخدم off لكي تحل محل شاشة التحميل فقط.
        Get.off(() => AdDetailsScreen(ad: ad), transition: Transition.fadeIn);
        // بعد هذا السطر لا تقم بعمل reset أو mark هنا!
        return;
      } else {
        // فشل تحميل الإعلان — أعرض رسالة وخلي المستخدم يختار
        setState(() => _errorMessage = 'فشل تحميل الإعلان'.tr);
        _shared.resetDeepLinkState();
        _shared.isNavigatingToAd.value = false;
      }
    } catch (e) {
      setState(() => _errorMessage = 'حدث خطأ في الاتصال'.tr);
      _shared.resetDeepLinkState();
      _shared.isNavigatingToAd.value = false;
    } finally {
      // نوقف الـ loader محليًا فقط (لا نبلّغ أن الـ deep link تم التعامل معه).
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildAnimatedLogo() {
           final appServices = Get.find<AppServices>();
  final logoUrl = appServices.getStoredAppLogoUrl();
    return ScaleTransition(
      scale: Tween(begin: 0.96, end: 1.06).animate(CurvedAnimation(parent: _logoAnimCtr, curve: Curves.easeInOut)),
      child: Container(
        width: 140.w,
        height: 110.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18.r),
          gradient: LinearGradient(
            colors: [AppColors.primary.withOpacity(0.95), AppColors.primary.withOpacity(0.65)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 18, offset: Offset(0, 8))],
        ),
        child: Center(
          child:   logoUrl != null && logoUrl.isNotEmpty
        ? Image.network(
            logoUrl,
            width: double.infinity,
            height: 150,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                Image.asset(ImagesPath.logo,     width: 86.w,
            height:64.w,),
          )
        : Image.asset(
            ImagesPath.logo,
            width: 86.w,
            height:64.w,
            fit: BoxFit.contain,
          ),
          
           
          
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: AppColors.surface(false),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: Offset(0, 6))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('جارٍ تحميل تفاصيل الإعلان'.tr,
              style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.large,
 fontWeight: FontWeight.w700, color: AppColors.textPrimary(false))),
          SizedBox(height: 8.h),
          Text('اسمح لنا بجلب أفضل عرض للتفاصيل — لن يأخذ وقتًا طويلًا.'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.small,
 color: AppColors.textSecondary(false))),
          SizedBox(height: 14.h),
          // Loader مع نقاط متحركة
          AnimatedDotsLoader(),
          SizedBox(height: 12.h),
          // سطر لمعلومات إضافية أو progress hint
          Text('معرّف الإعلان: ${widget.adId}', style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.small,
 color: AppColors.textSecondary(false))),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 12.w),
      decoration: BoxDecoration(
        color: AppColors.surface(false),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.error.withOpacity(0.12)),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 44.r, color: AppColors.error),
          SizedBox(height: 10.h),
          Text(_errorMessage ?? 'حصل خطأ غير متوقع'.tr, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.medium,
 color: AppColors.textPrimary(false))),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // إعادة المحاولة يعيّن الحالة ويعيد المحاولة
                    _startLoad();
                  },
                  style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 12.h), backgroundColor: AppColors.buttonAndLinksColor),
                  child: Text('إعادة المحاولة'.tr, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.medium,
 color: AppColors.onPrimary)),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // إغلاق من اختيار المستخدم فقط — اعتبرنا أنه تعاملنا مع الرابط
                    _shared.resetDeepLinkState();
                    _shared.isNavigatingToAd.value = false;
                    Get.offAll(() => HomeScreen());
                  },
                  style: OutlinedButton.styleFrom(side: BorderSide(color: AppColors.primary), padding: EdgeInsets.symmetric(vertical: 12.h)),
                  child: Text('العودة للرئيسية'.tr, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.medium,
 color: AppColors.primary)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Get.find<ThemeController>().isDarkMode.value;

    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 30.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildAnimatedLogo(),
                SizedBox(height: 18.h),
                if (_isLoading) _buildLoadingCard() else (_errorMessage != null ? _buildErrorCard() : _buildLoadingCard()),
                SizedBox(height: 18.h),
                // Footer hint
                Text(
                  'إذا بقيت هذه الشاشة مدة أطول من المتوقع، استخدم زر "إعادة المحاولة" أو اغلق إلى الرئيسية.'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.small,
 color: AppColors.textSecondary(false)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Simple animated dots loader without external packages.
class AnimatedDotsLoader extends StatefulWidget {
  @override
  State<AnimatedDotsLoader> createState() => _AnimatedDotsLoaderState();
}

class _AnimatedDotsLoaderState extends State<AnimatedDotsLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _ctr;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctr = AnimationController(vsync: this, duration: Duration(milliseconds: 900))..repeat();
    _anim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ctr, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36.h,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              final t = (_anim.value + i * 0.25) % 1.0;
              final scale = 0.6 + (0.8 * (1 - (t - 0.5).abs() * 2)); // pulsing
              return Container(
                margin: EdgeInsets.symmetric(horizontal: 6.w),
                width: 10.w * scale,
                height: 10.w * scale,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.24), blurRadius: 6)],
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
