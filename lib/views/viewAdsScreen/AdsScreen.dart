// lib/views/ads/AdsScreen.dart
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tappuu_app/core/constant/appcolors.dart';
import '../../controllers/AdsManageSearchController.dart';
import '../../controllers/LoadingController.dart';
import '../../controllers/SearchHistoryController.dart';
import '../../controllers/ThemeController.dart';
import '../../controllers/listing_share_controller.dart';
import '../../core/constant/app_text_styles.dart';
import '../../core/localization/changelanguage.dart';
import '../HomeScreen/menubar.dart';
import 'AdItem.dart';
import 'AdsMapFromListScreen.dart';
import 'FilterScreen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class AdsScreen extends StatefulWidget {
  final String titleOfpage;
  final int? categoryId;
  final int? subCategoryId;
  final int? subTwoCategoryId;
  final String? nameOfMain;
  final String? nameOFsub;
  final String? nameOFsubTwo;
  final String? currentTimeframe;
  final bool onlyFeatured;
  final int? cityId;
  final int? areaId;
  final int countofAds;
  final bool? openVoiceSearch;
  final bool? openImageSearch;
  final bool? openTextSearch;

  const AdsScreen({
    super.key,
    required this.titleOfpage,
    required this.categoryId,
    this.subCategoryId,
    this.subTwoCategoryId,
    this.nameOfMain,
    this.nameOFsub,
    this.currentTimeframe,
    this.nameOFsubTwo,
    this.onlyFeatured = false,
    this.countofAds = 0,
    this.cityId,
    this.areaId,
    this.openVoiceSearch = false,
    this.openImageSearch = false,
    this.openTextSearch = false,
  });

  @override
  State<AdsScreen> createState() => _AdsScreenState();
}

class _AdsScreenState extends State<AdsScreen> with SingleTickerProviderStateMixin {
  late AdsController adsController;
  late ThemeController themeController;
  late TextEditingController _searchController;
  late FocusNode _searchFocus;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _showSearch = false;

  // image search
  final ImagePicker _imagePicker = ImagePicker();

  // speech state
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _recognizedText = '';
  bool _speechInitialized = false;

  // Arabic support detection
  String? _speechLocaleId;
  bool _isArabicAvailable = false;
  bool _isDeviceInArabic = false; // جديد: لتتبع إذا كان الجهاز بالعربية

  // notifiers for immediate UI updates
  final ValueNotifier<String> _recognizedTextNotifier = ValueNotifier('');
  final ValueNotifier<bool> _isListeningNotifier = ValueNotifier(false);

 @override
void initState() {
  super.initState();

  // التحقق من لغة الجهاز
  _checkDeviceLanguage();

  // تهيئة ال controllers
  adsController = Get.put(AdsController());
  themeController = Get.find<ThemeController>();
  _searchController = TextEditingController();
  Get.put(ListingShareController(), permanent: false);
  _speech = stt.SpeechToText();
  _searchFocus = FocusNode();

  // تهيئة animations
  _animController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );
  _fadeAnim = Tween(begin: 0.0, end: 1.0).animate(
    CurvedAnimation(parent: _animController, curve: Curves.easeOut),
  );
  _slideAnim = Tween<Offset>(begin: const Offset(0, -0.18), end: Offset.zero).animate(
    CurvedAnimation(parent: _animController, curve: Curves.easeOut),
  );

  // جلب البيانات دون انتظار
  _fetchAdsData();

  // تهيئة الصوت بشكل منفصل وغير متزامن
 //_initializeSpeech();

  // العمليات المتعلقة بالواجهة بعد اكتمال البناء
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;
    _handlePostFrameOperations();
  });
}

// دالة منفصلة لجلب البيانات
void _fetchAdsData() {
  try {
    adsController.fetchAds(
      categoryId: widget.categoryId,
      subCategoryLevelOneId: widget.subCategoryId,
      subCategoryLevelTwoId: widget.subTwoCategoryId,
      lang: Get.find<ChangeLanguageController>().currentLocale.value.languageCode,
      timeframe: widget.currentTimeframe,
      onlyFeatured: widget.onlyFeatured,
      cityId: widget.cityId,
      areaId: widget.areaId,
    );
    if (kDebugMode) debugPrint('fetchAds triggered from initState');
  } catch (e) {
    if (kDebugMode) debugPrint('fetchAds initState error: $e');
  }
}

// دالة منفصلة لتهيئة الصوت
Future<void> _initializeSpeech() async {
  try {
    final ok = await _initSpeech();
    if (kDebugMode) debugPrint('initSpeech result: $ok');
  } catch (e) {
    if (kDebugMode) debugPrint('initSpeech error: $e');
  }
}

// معالجة العمليات بعد اكتمال بناء الواجهة
void _handlePostFrameOperations() {
  // العمليات المتعلقة بالبحث
  if (widget.openTextSearch == true) {
    _openSearch();
  }

  if (widget.openVoiceSearch == true) {
    _openSearch();
    _showDelayedVoiceSearch();
  }

  if (widget.openImageSearch == true) {
    _openSearch();
    _showDelayedImageSearch();
  }
}

// عرض بحث الصوت بعد تأخير
void _showDelayedVoiceSearch() {
  Future.delayed(const Duration(milliseconds: 120), () {
    if (mounted) _showVoiceSearchDialog();
  });
}

// عرض بحث الصورة بعد تأخير
void _showDelayedImageSearch() {
  Future.delayed(const Duration(milliseconds: 120), () {
    if (mounted) _showImageSearchDialog();
  });
}

  // دالة جديدة: التحقق من لغة الجهاز
  void _checkDeviceLanguage() {
    try {
      final deviceLocales = ui.PlatformDispatcher.instance.locales;
      if (deviceLocales.isNotEmpty) {
        final primaryLocale = deviceLocales.first;
        _isDeviceInArabic = primaryLocale.languageCode.toLowerCase() == 'ar';
        if (kDebugMode) debugPrint('Device language is Arabic: $_isDeviceInArabic');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error checking device language: $e');
    }
  }

  /// Helper: detect Arabic availability using multiple signals
  Future<void> _detectArabicSupport() async {
    bool found = false;
    String? chosen;

    try {
      // 1) check locales provided by speech_to_text
      final locales = await _speech.locales();
      if (locales.isNotEmpty) {
        for (final l in locales) {
          final id = (l.localeId ?? '').toLowerCase();
          final name = (l.name ?? '').toLowerCase();
          if (id.startsWith('ar') || name.contains('arabic') || name.contains('عرب')) {
            chosen = l.localeId;
            found = true;
            break;
          }
        }
      }

      // 2) if not found, check systemLocale() provided by plugin
      if (!found) {
        try {
          final sys = await _speech.systemLocale();
          final sid = (sys?.localeId ?? '').toLowerCase();
          if (sid.startsWith('ar')) {
            chosen = sys?.localeId;
            found = true;
          }
        } catch (_) {}
      }

      // 3) if device is in Arabic, assume Arabic is available even if not detected
      if (!found && _isDeviceInArabic) {
        found = true;
        chosen = 'ar'; // Use generic Arabic locale
        if (kDebugMode) debugPrint('Forcing Arabic support based on device language');
      }

      // 4) as a hint: check device preferred locales
      if (!found) {
        try {
          final deviceLocales = ui.PlatformDispatcher.instance.locales;
          final prefersArabic = deviceLocales.any((l) => l.languageCode.toLowerCase() == 'ar');
          if (prefersArabic) {
            chosen = chosen ?? 'ar';
          }
        } catch (_) {}
      }
    } catch (e) {
      if (kDebugMode) debugPrint('detectArabicSupport error: $e');
    }

    _isArabicAvailable = found;
    _speechLocaleId = chosen;
    if (kDebugMode) debugPrint('Arabic available: $_isArabicAvailable, localeId=$_speechLocaleId');
  }

  // function: initialize speech and detect arabic
  Future<bool> _initSpeech() async {
    try {
      _speechInitialized = await _speech.initialize(
        onStatus: (status) {
          final listening = status == 'listening';
          if (mounted) {
            _isListening = listening;
            _isListeningNotifier.value = listening;
          }
        },
        onError: (error) {
          if (mounted) {
            _isListening = false;
            _isListeningNotifier.value = false;
          }
          if (kDebugMode) debugPrint('speech initialize error: $error');
        },
      );

      if (!_speechInitialized) return false;

      await _detectArabicSupport();
      return _speechInitialized;
    } catch (e) {
      if (kDebugMode) debugPrint('Error initializing speech: $e');
      if (mounted) {
        _speechInitialized = false;
        _isListening = false;
        _isListeningNotifier.value = false;
      }
      return false;
    }
  }

 


  /// Toggle listening; prefer using Arabic localeId if available.
  Future<void> toggleListening() async {
    if (_isListening) {
      _stopListening();
      return;
    }

    // ensure initialized
    if (!_speechInitialized) {
      final ok = await _initSpeech();
      if (!ok) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('التعرف على الكلام غير متاح'.tr)));
        return;
      }
    }

    // permission check
    bool hasPermission = await _speech.hasPermission;
    if (!hasPermission) {
      final ok = await _speech.initialize(
        onStatus: (status) {
          final listening = status == 'listening';
          if (mounted) {
            _isListening = listening;
            _isListeningNotifier.value = listening;
          }
        },
        onError: (error) {
          if (mounted) {
            _isListening = false;
            _isListeningNotifier.value = false;
          }
        },
      );
      if (!ok) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم رفض إذن استخدام الميكروفون'.tr)));
        return;
      }
    }

    // If Arabic not available, prompt user for action
  

    if (mounted) {
      _isListening = true;
      _recognizedText = '';
      _isListeningNotifier.value = true;
      _recognizedTextNotifier.value = '';
    }

    try {
      await _speech.listen(
        onResult: (result) {
          if (mounted) {
            try {
              final recognized = (result.recognizedWords ?? '').toString();
              _recognizedText = recognized;
              _recognizedTextNotifier.value = recognized;
            } catch (e) {
              if (kDebugMode) debugPrint('onResult parse error: $e');
            }
          }
        },
        listenFor: const Duration(seconds: 30),
        cancelOnError: true,
        partialResults: true,
        localeId: _isArabicAvailable ? _speechLocaleId : null,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('listen error: $e');
      if (mounted) {
        _isListening = false;
        _isListeningNotifier.value = false;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ أثناء الاستماع'.tr)));
      }
    }
  }

  void _stopListening() {
    try {
      _speech.stop();
    } catch (_) {}
    if (mounted) {
      _isListening = false;
      _isListeningNotifier.value = false;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _animController.dispose();
    try {
      _speech.stop();
      _speech.cancel();
    } catch (_) {}
    _recognizedTextNotifier.dispose();
    _isListeningNotifier.dispose();
    super.dispose();
  }

  void _openSearch() {
    if (!mounted) return;
    setState(() {
      _showSearch = true;
    });
    _animController.forward();
    Future.delayed(const Duration(milliseconds: 180), () {
      if (mounted) FocusScope.of(context).requestFocus(_searchFocus);
    });
  }

  void _showVoiceSearchDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final isDarkMode = themeController.isDarkMode.value;
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          child: Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(color: AppColors.surface(isDarkMode), borderRadius: BorderRadius.circular(16.0)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('البحث الصوتي'.tr, style: TextStyle(fontSize: AppTextStyles.xlarge, fontWeight: FontWeight.bold, color: AppColors.textPrimary(isDarkMode))),
                SizedBox(height: 20.h),
                ValueListenableBuilder<bool>(
                  valueListenable: _isListeningNotifier,
                  builder: (context, isListening, _) {
                    return Icon(Icons.mic, size: 36.w, color: isListening ? Colors.green : AppColors.textSecondary(isDarkMode));
                  },
                ),
                SizedBox(height: 16.h),
                ValueListenableBuilder<bool>(
                  valueListenable: _isListeningNotifier,
                  builder: (context, isListening, _) {
                    return Text(isListening ? 'جاري الاستماع...'.tr : 'انقر على الميكروفون وابدأ الكلام'.tr, style: TextStyle(color: AppColors.textSecondary(isDarkMode), fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.medium));
                  },
                ),
                SizedBox(height: 16.h),
                ValueListenableBuilder<String>(
                  valueListenable: _recognizedTextNotifier,
                  builder: (context, recognized, _) {
                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                      decoration: BoxDecoration(color: AppColors.card(isDarkMode), borderRadius: BorderRadius.circular(8.r)),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(recognized.isEmpty ? 'لا يوجد نص بعد...'.tr : recognized, style: TextStyle(color: AppColors.textPrimary(isDarkMode), fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.medium)),
                          ),
                          if (recognized.isNotEmpty)
                            IconButton(
                              icon: Icon(Icons.clear, size: 20.w),
                              onPressed: () {
                                _recognizedText = '';
                                _recognizedTextNotifier.value = '';
                              },
                            ),
                        ],
                      ),
                    );
                  },
                ),
                SizedBox(height: 20.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        _stopListening();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.redId),
                      child: Text('إلغاء'.tr, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, color: AppColors.onPrimary)),
                    ),
                    ValueListenableBuilder<bool>(
                      valueListenable: _isListeningNotifier,
                      builder: (context, isListening, _) {
                        return ElevatedButton(
                          onPressed: () async {
                            await toggleListening();
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: isListening ? Colors.red : AppColors.primary),
                          child: Text(isListening ? 'إيقاف'.tr : 'بدء'.tr, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, color: Colors.white)),
                        );
                      },
                    ),
                    ValueListenableBuilder<String>(
                      valueListenable: _recognizedTextNotifier,
                      builder: (context, recognized, _) {
                        return ElevatedButton(
                          onPressed: recognized.isEmpty
                              ? null
                              : () {
                                  _stopListening();
                                  Navigator.pop(context);
                                  _searchController.text = recognized;
                                  _performSearch();
                                },
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.buttonAndLinksColor),
                          child: Text('بحث'.tr, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, color: AppColors.onPrimary)),
                        );
                      },
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                Padding(
                  padding: EdgeInsets.only(top: 8.h),
                  child: Text(
                    _isArabicAvailable ? 'سيتم الاستماع باللغة العربية.'.tr : 'سيتم محاولة الاستماع بلغة النظام لذا إذا كان نظامك لايدعم العربية فلن تحصل على نتيجة صحيحة؛ للحصول على أفضل نتيجة، ثبّت حزمة اللغة العربية أو غيّر لغة الجهاز.'.tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary(isDarkMode), fontSize: 12.sp),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      if (_isListeningNotifier.value) _stopListening();
    });
  }


  void _performSearch({String? searchText}) {
    final q = (searchText ?? _searchController.text).trim();
    adsController.currentSearch.value = q;
    adsController.fetchAds(
      categoryId: widget.categoryId,
      subCategoryLevelOneId: adsController.currentSubCategoryLevelOneId.value,
      subCategoryLevelTwoId: adsController.currentSubCategoryLevelTwoId.value,
      search: q.isNotEmpty ? q : null,
      cityId: adsController.selectedCity.value?.id,
      areaId: adsController.selectedArea.value?.id,
      attributes: adsController.currentAttributes.isNotEmpty ? adsController.currentAttributes : null,
      lang: Get.find<ChangeLanguageController>().currentLocale.value.languageCode,
      timeframe: widget.currentTimeframe,
      onlyFeatured: widget.onlyFeatured,
      page: 1,
    );

    // اغلاق الحقل بعد البحث (لو تريد إبقائه مفتوح احذف هذا السطر)
    _closeSearch();
  }

  String _formatCount(int count) {
    return count.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');
  }

  void _closeSearch() {
    _animController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _showSearch = false;
        });
      }
    });
    _searchController.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = themeController.isDarkMode.value;

    // بقية بناء الواجهة كما كانت في ملفك الأصلي...
    // (أضف هنا بقية الواجهة—القسم هذا لم يتغير منطقياً لذا لم أعد كتابته كاملاً)
   

  // ------------------------------
  // ملاحظة: تأكد أن لديك تعريف _showImageSearchDialog() في نفس الملف
  // إن لم يكن موجودًا، رجاء أعطني النسخة وأنا أعدلها لك أيضاً.



    return Stack(
      children: [
        Scaffold(
          key: _scaffoldKey,
          drawer: Menubar(), // بدل drawer العادي
          backgroundColor: AppColors.background(isDarkMode),

          // ===== AppBar مخصّص مشابه للصورة =====
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(70.h),
            child: SafeArea(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                decoration: BoxDecoration(color: AppColors.primary),
                child: Row(
                  children: [
                    // menu / hamburger
                    IconButton(
                      icon: Icon(Icons.menu, color: Colors.white, size: 26.w),
                      onPressed: () {
                        try {
                          _scaffoldKey.currentState?.openDrawer();
                        } catch (_) {}
                      },
                    ),

                    SizedBox(width: 6.w),

                    // Title + subtitle (count)
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.titleOfpage,
                            style: TextStyle(
                              fontFamily: AppTextStyles.appFontFamily,
                              fontSize: AppTextStyles.xlarge,

                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                                                            height: 1,

                            ),
                            maxLines: 2,
                            
                            overflow: TextOverflow.ellipsis,
                            
                          ),
                          Obx(() {
                            final count = adsController.filteredAdsList.length;
                            return Text(
                              '${_formatCount(count)} ${'إعلان'.tr}',
                              style: TextStyle(
                                fontFamily: AppTextStyles.appFontFamily,
                                fontSize: AppTextStyles.small,

                                color: Colors.white.withOpacity(0.9),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),

                    // actions: search, share, favorite
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.search, color: Colors.white, size: 24.w),
                          onPressed: _openSearch,
                        ),
                        IconButton(
                          icon: Icon(Icons.share, color: Colors.white, size: 24.w),
                          onPressed: () {
                            try {
                              final shareCtrl = Get.find<ListingShareController>();
                              final lang = Get.find<ChangeLanguageController>().currentLocale.value.languageCode;

                              // جمع الفلاتر الحالية لتمريرها
                              final categoryId = widget.categoryId;
                              final sub1 = widget.subCategoryId;
                              final sub2 = widget.subTwoCategoryId;
                              final search = adsController.currentSearch.value.isNotEmpty ? adsController.currentSearch.value : null;
                              final sortBy = adsController.currentSortBy.value;
                              final order = adsController.currentOrder.value;
                              final attributes = (adsController.currentAttributes != null && adsController.currentAttributes.isNotEmpty)
                                  ? adsController.currentAttributes
                                  : null;
                              final cityId = widget.cityId ?? adsController.selectedCity.value?.id;
                              final areaId = widget.areaId ?? adsController.selectedArea.value?.id;
                              final timeframe = widget.currentTimeframe;
                              final onlyFeatured = widget.onlyFeatured;

                              // عنوان ونص دعائي قصير
                              final title = widget.titleOfpage;
                              final subtitle = onlyFeatured
                                  ? 'اطّلع على الإعلانات المميزة في $title'
                                  : (search != null ? 'نتائج البحث عن: "$search"' : 'اكتشف أحدث الإعلانات في $title');

                              // عدد النتائج الحالية (لإظهار في الرسالة)
                              final resultsCount = adsController.filteredAdsList.length;

                              shareCtrl.shareListing(
                                categoryId: categoryId,
                                subCategoryLevelOneId: sub1,
                                subCategoryLevelTwoId: sub2,
                                search: search,
                                sortBy: sortBy,
                                order: order,
                                attributes: attributes,
                                cityId: cityId,
                                areaId: areaId,
                                timeframe: timeframe,
                                onlyFeatured: onlyFeatured,
                                lang: lang,
                                title: title,
                                subtitle: subtitle,
                                resultsCount: resultsCount,
                              );
                            } catch (e) {
                              // لو لم يتم تسجيل الـ ListingShareController، سجّله الآن وحاول مجددًا
                              debugPrint('Share error: $e');
                              final shareCtrl = Get.put(ListingShareController());
                              final lang = Get.find<ChangeLanguageController>().currentLocale.value.languageCode;
                              shareCtrl.shareListing(
                                categoryId: widget.categoryId,
                                subCategoryLevelOneId: widget.subCategoryId,
                                subCategoryLevelTwoId: widget.subTwoCategoryId,
                                lang: lang,
                                title: widget.titleOfpage,
                                subtitle: 'تصفّح الإعلانات',
                                resultsCount: adsController.filteredAdsList.length,
                              );
                            }
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.star_border, color: Colors.white, size: 24.w),
                          onPressed: () {
                            _showSaveSearchDialog(context);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ===== Body =====
          body: SafeArea(
            child: Obx(() {
              final isLoading = adsController.isLoadingAds.value;
              final empty = adsController.filteredAdsList.isEmpty;

              return Column(
                children: [
                  // ===== Toolbar تحت العنوان — مشابه للصورة =====
      Container(
  height: 52.h,
  decoration: BoxDecoration(
    color: AppColors.backGroundButton(isDarkMode),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.09),
        blurRadius: 9,
        offset: const Offset(0, 7),
      )
    ],
  ),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      // حفظ البحث - أكبر حجماً
      Expanded(
        flex: 3,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 2.w), // تقليل المساحة
          child: _toolItem(
            label: 'حفظ البحث'.tr,
            onTap: () => _showSaveSearchDialog(context),
            isDarkMode: isDarkMode,
          ),
        ),
      ),

      // ديفايدر ثابت
      _verticalToolDivider(isDarkMode),

      // فرز حسب - أصغر
      Expanded(
        flex: 2,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 1.w), // تقليل المساحة
          child: _toolItem(
            label: 'فرز حسب'.tr,
            onTap: () => _showSortOptions(context, adsController),
            isDarkMode: isDarkMode,
          ),
        ),
      ),

      _verticalToolDivider(isDarkMode),

      // فلترة - أصغر
      Expanded(
        flex: 2,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 1.w), // تقليل المساحة
          child: Obx(() {
            int activeFilters = 0;
            try {
              if (adsController.currentAttributes != null && adsController.currentAttributes.isNotEmpty) activeFilters += adsController.currentAttributes.length;
            } catch (_) {}
            try {
              if (adsController.selectedCity.value != null) activeFilters += 1;
            } catch (_) {}
            try {
              if (adsController.selectedArea.value != null) activeFilters += 1;
            } catch (_) {}
            return _toolItem(
              label: 'فلترة'.tr,
              onTap: () {
                if (widget.categoryId != null) {
                  Get.to(() => FilterScreen(categoryId: widget.categoryId!, currentTimeframe: widget.currentTimeframe, onlyFeatured: widget.onlyFeatured));
                } else {
                  Get.to(() => FilterScreen(categoryId: 0, currentTimeframe: widget.currentTimeframe, onlyFeatured: widget.onlyFeatured));
                }
              },
              isDarkMode: isDarkMode,
              badgeCount: activeFilters,
            );
          }),
        ),
      ),

      _verticalToolDivider(isDarkMode),

      // طريقة العرض - أكبر حجماً
      Expanded(
        flex: 3,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 2.w), // تقليل المساحة
          child: _toolItem(
            label: 'طريقة العرض'.tr,
            onTap: () => _showViewOptions(context, adsController),
            isDarkMode: isDarkMode,
          ),
        ),
      ),
    ],
  ),
),





                  SizedBox(height: 7.h),

                  // ===== المحتوى: شيمر / رسالة فارغة / قائمة الإعلانات =====
                  Expanded(
                    child: isLoading
                        ? _buildShimmerLoader()
                        : empty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.search_off, size: 48.w, color: AppColors.grey),
                                    SizedBox(height: 16.h),
                                    Text(
                                      'لا توجد إعلانات مطابقة'.tr,
                                      style: TextStyle(
                                        fontFamily: AppTextStyles.appFontFamily,
                                        fontSize: AppTextStyles.xlarge,

                                        color: AppColors.textSecondary(isDarkMode),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : _buildAdsList(adsController),
                  ),
                ],
              );
            }),
          ),

          // زر الخريطة أسفل يمين مثل الصورة
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Get.to(() => AdsMapFromListScreen(
                    ads: adsController.filteredAdsList,
                  ));
            },
            backgroundColor: AppColors.primary,
            child: Icon(Icons.location_on, color: Colors.white, size: 28.w),
          ),
        ),

        // ===== Search Overlay (dark background full screen + top aligned search box) =====
        if (_showSearch)
          Positioned.fill(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Stack(
                children: [
                  // dim background (tap outside to close)
                  GestureDetector(
                    onTap: _closeSearch,
                    child: Container(color: Colors.black.withOpacity(0.45)),
                  ),

                  // top-aligned search box (under the status bar / appbar)
                  SafeArea(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: SlideTransition(
                        position: _slideAnim,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 0),
                          child: Material(
                            color: Colors.transparent,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                              decoration: BoxDecoration(
                                color: AppColors.surface(themeController.isDarkMode.value),
                                borderRadius: BorderRadius.circular(12.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.12),
                                    blurRadius: 12,
                                    offset: Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _searchController,
                                      focusNode: _searchFocus,
                                      textInputAction: TextInputAction.search,
                                      onSubmitted: (v) => _performSearch(searchText: v),
                                      decoration: InputDecoration(
                                        hintText: 'ابحث عن إعلان، ادخل عنوان البحث هنا '.tr,
                                        hintStyle: TextStyle(
                                          fontFamily: AppTextStyles.appFontFamily,
                                          fontSize: AppTextStyles.medium,

                                          color: AppColors.textSecondary(themeController.isDarkMode.value),
                                        ),
                                        isDense: true,
                                        border: InputBorder.none,
                                      ),
                                      style: TextStyle(
                                        fontFamily: AppTextStyles.appFontFamily,
                                        fontSize: AppTextStyles.medium,

                                        color: AppColors.textPrimary(themeController.isDarkMode.value),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8.w),

                                  // ---- image search icon ----
                                  IconButton(
                                    icon: Icon(Icons.image_search_outlined, color: AppColors.textPrimary(themeController.isDarkMode.value), size: 22.w),
                                    onPressed: () => _showImageSearchDialog(),
                                    tooltip: 'بحث بواسطة صورة'.tr,
                                  ),
                                  SizedBox(width: 6.w),
                                  // ----------------------------
                                  IconButton(
                                    icon: Icon(Icons.mic, color: AppColors.textPrimary(themeController.isDarkMode.value), size: 22.w),
                                    onPressed: _showVoiceSearchDialog,
                                    tooltip: 'بحث بالصوت'.tr,
                                  ),
                                  SizedBox(width: 6.w),
                                  InkWell(
                                    onTap: () => _performSearch(),
                                    borderRadius: BorderRadius.circular(8.r),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(8.r),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.search, color: Colors.white, size: 20.w),
                                          SizedBox(width: 6.w),
                                          Text(
                                            'بحث'.tr,
                                            style: TextStyle(
                                              fontFamily: AppTextStyles.appFontFamily,
                                              fontSize: AppTextStyles.medium,

                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  InkWell(
                                    onTap: _closeSearch,
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 6.h),
                                      child: Icon(Icons.close, size: 22.w, color: AppColors.textSecondary(themeController.isDarkMode.value)),
                                    ),
                                  ),
                                ],
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
          ),
      ],
    );
  }

  // ===== Helper widget for toolbar items =====
// دالة الـ Divider المعدلة مع الحفاظ على التصميم الأصلي
Widget _verticalToolDivider(bool isDarkMode, {double width = 1.0}) {
  return Container(
    width: width,
    margin: EdgeInsets.symmetric(vertical: 10.h),
    color: isDarkMode ? Colors.white12 : Colors.black12,
  );
}

// دالة _toolItem المعدلة لدعم النقاط (...) والتقليل من المسافات
Widget _toolItem({
  required String label,
  required VoidCallback onTap,
  required bool isDarkMode,
  int badgeCount = 0,
}) {
  return InkWell(
    onTap: onTap,
    child: Container(
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: 2.w), // تقليل المساحة الداخلية
      height: double.infinity,
      constraints: BoxConstraints(minWidth: 20.w), // حد أدنى للعرض
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min, // يسمح بالتقلص عند الحاجة
        children: [
          Flexible( // يمنع تجاوز النص للحدود
            child: Text(
              label,
              style: TextStyle(
                fontFamily: AppTextStyles.appFontFamily,
                fontSize: AppTextStyles.small,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary(isDarkMode),
              ),
              overflow: TextOverflow.ellipsis, // نقطة ... عند عدم كفاية المساحة
              maxLines: 1,
              softWrap: false,
            ),
          ),
          if (badgeCount > 0) ...[
            SizedBox(width: 3.w), // تقليل المسافة بين النص والبادج
            Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h), // تصغير البادج
              decoration: BoxDecoration(
                color: Colors.red, 
                borderRadius: BorderRadius.circular(10.r) // تقليل نصف القطر
              ),
              child: Text(
                badgeCount > 99 ? '99+' : badgeCount.toString(),
                style: TextStyle(
                  fontSize: 9.sp, // تصغير حجم خط البادج
                  color: Colors.white, 
                  fontWeight: FontWeight.bold
                ),
              ),
            )
          ],
        ],
      ),
    ),
  );
}


  // ========== باقي الدوال كما عندك (قوائم، شيمر، مودالات) ==========
  Widget _buildAdsList(AdsController controller) {
    final viewMode = controller.viewMode.value;

    if (viewMode.startsWith('grid')) {
      return GridView.builder(
        padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.w),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8.w,
          mainAxisSpacing: 8.h,
          childAspectRatio: viewMode == 'grid_simple' ? 1.17 : 0.85,
        ),
        itemCount: controller.filteredAdsList.length,
        itemBuilder: (context, index) {
          return AdItem(ad: controller.filteredAdsList[index], viewMode: viewMode);
        },
      );
    } else if (viewMode.startsWith('vertical')) {
      return ListView.builder(
        padding: EdgeInsets.symmetric(vertical: 0.h),
        itemCount: controller.filteredAdsList.length,
        itemBuilder: (context, index) {
          return AdItem(ad: controller.filteredAdsList[index], viewMode: viewMode);
        },
      );
    } else {
      return AdsMapFromListScreen(ads: controller.filteredAdsList);
    }
  }

  Widget _buildShimmerLoader() {
    final isDarkMode = themeController.isDarkMode.value;

    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: EdgeInsets.only(bottom: 16.h),
          decoration: BoxDecoration(
            color: AppColors.surface(isDarkMode),
            borderRadius: BorderRadius.circular(0.r),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, spreadRadius: 1, offset: Offset(0, 2)),
            ],
          ),
          child: Shimmer.fromColors(
            baseColor: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
            highlightColor: isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
            child: Padding(
              padding: EdgeInsets.all(10.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // simplified shimmer row (title + image)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(height: 18.h, width: double.infinity, color: Colors.white),
                            SizedBox(height: 6.h),
                            Container(height: 16.h, width: 160.w, color: Colors.white),
                            SizedBox(height: 12.h),
                            Container(height: 14.h, width: 100.w, color: Colors.white),
                          ],
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Container(width: 110.w, height: 80.h, color: Colors.white),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSaveSearchDialog(BuildContext context) {
    SearchHistoryController searchHistoryController = Get.put(SearchHistoryController());

    final isDarkMode = themeController.isDarkMode.value;
    TextEditingController searchNameController = TextEditingController();
    bool emailNotifications = true;
    bool mobileNotifications = true;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              insetPadding: EdgeInsets.all(16.w),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                decoration: BoxDecoration(
                  color: AppColors.surface(isDarkMode),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        'حفظ البحث'.tr,
                        style: TextStyle(
                          fontFamily: AppTextStyles.appFontFamily,
                          fontSize: AppTextStyles.xlarge,

                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary(isDarkMode),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    TextField(
                      controller: searchNameController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.card(isDarkMode),
                        hintText: 'اسم البحث'.tr,
                        hintStyle: TextStyle(
                          fontFamily: AppTextStyles.appFontFamily,
                          fontSize: AppTextStyles.medium,

                          color: AppColors.grey,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 14.h,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: AppTextStyles.medium,

                        color: AppColors.textPrimary(isDarkMode),
                      ),
                    ),
                    SizedBox(height: 20.h),
                    _buildNotificationOption(
                      title: 'إشعار البريد الإلكتروني'.tr,
                      value: emailNotifications,
                      isDarkMode: isDarkMode,
                      onChanged: (value) {
                        setState(() {
                          emailNotifications = value!;
                        });
                      },
                    ),
                    SizedBox(height: 12.h),
                    _buildNotificationOption(
                      title: 'إشعارات الهاتف المحمول'.tr,
                      value: mobileNotifications,
                      isDarkMode: isDarkMode,
                      onChanged: (value) {
                        setState(() {
                          mobileNotifications = value!;
                        });
                      },
                    ),

                    SizedBox(height: 10.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              side: BorderSide(
                                color: AppColors.buttonAndLinksColor,
                                width: 1.2,
                              ),
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                            ),
                            child: Text(
                              'إلغاء'.tr,
                              style: TextStyle(
                                fontFamily: AppTextStyles.appFontFamily,
                                fontSize: AppTextStyles.medium,

                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              final userId = Get.find<LoadingController>().currentUser?.id;
                              if (userId == null) {
                                Get.snackbar('تنبيه'.tr, 'يجب تسجيل الدخول '.tr);
                                return;
                              } else if (widget.categoryId == null) {
                                Get.snackbar('تنبيه'.tr, 'لايمكنك حفظ البحث في عمليات البحث او الاعلانات المميزة او العاجلة'.tr);
                              } else {
                                print(userId);
                                searchHistoryController.addSearchHistory(
                                    userId: Get.find<LoadingController>().currentUser?.id ?? 0,
                                    recordName: searchNameController.text,
                                    categoryId: widget.categoryId!,
                                    subcategoryId: widget.subCategoryId,
                                    secondSubcategoryId: widget.subCategoryId,
                                    notifyPhone: mobileNotifications,
                                    notifyEmail: emailNotifications);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.buttonAndLinksColor,
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                            ),
                            child: Text(
                              'حفظ'.tr,
                              style: TextStyle(
                                fontFamily: AppTextStyles.appFontFamily,
                                fontSize: AppTextStyles.medium,

                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNotificationOption({
    required String title,
    required bool value,
    required bool isDarkMode,
    required ValueChanged<bool?> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: AppTextStyles.appFontFamily,
            fontSize: AppTextStyles.medium,

            color: AppColors.textPrimary(isDarkMode),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.buttonAndLinksColor,
          activeTrackColor: AppColors.buttonAndLinksColor.withOpacity(0.4),
        ),
      ],
    );
  }

void _showViewOptions(BuildContext context, AdsController controller) {
  final isDarkMode = themeController.isDarkMode.value;
  final List<Map<String, dynamic>> viewOptions = [
    {'value': 'vertical_simple', 'label': 'عرض طولي (مختصر)'.tr, 'icon': Icons.view_agenda_outlined},
    {'value': 'grid_simple', 'label': 'عرض شبكي (مختصر)'.tr, 'icon': Icons.grid_view_outlined},
    {'value': 'map', 'label': 'العرض على الخريطة'.tr, 'icon': Icons.map_outlined},
  ];

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.30,
        margin: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.surface(isDarkMode),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(vertical: 14.h),
              child: Text(
                'خيارات العرض'.tr,
                style: TextStyle(
                  fontFamily: AppTextStyles.appFontFamily,
                  fontSize: AppTextStyles.xlarge,

                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(isDarkMode),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: viewOptions.length,
                itemBuilder: (context, index) {
                  final option = viewOptions[index];
                  return ListTile(
                    leading: Icon(option['icon'], color: AppColors.primary),
                    title: Text(
                      option['label'],
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: AppTextStyles.medium,

                        color: AppColors.textPrimary(isDarkMode),
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      if (option['value'] == 'map') {
                        // افتح شاشة الخريطة كاملة
                        Get.to(() => AdsMapFromListScreen(
                              ads: controller.filteredAdsList,
                              embedded: false,
                            ));
                      } else {
                        controller.changeViewMode(option['value']);
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

void _showSortOptions(BuildContext context, AdsController controller) {
  final isDarkMode = themeController.isDarkMode.value;
  final Map<String, String> sortMap = {
    'الأحدث إلى الأقدم'.tr: 'newest',
    'الأقدم إلى الأحدث'.tr: 'oldest',
    'الأغلى إلى الأرخص'.tr: 'price_desc',
    'الأرخص إلى الأغلى'.tr: 'price_asc',
    'الأكثر مشاهدة'.tr: 'most_viewed',
    'الأقل مشاهدة'.tr: 'least_viewed',
  };
  final sortOptions = sortMap.keys.toList();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.45,
        margin: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.surface(isDarkMode),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(vertical: 14.h),
              child: Text(
                'خيارات الفرز'.tr,
                style: TextStyle(
                  fontFamily: AppTextStyles.appFontFamily,
                  fontSize: AppTextStyles.xlarge,

                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(isDarkMode),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: sortOptions.length,
                itemBuilder: (context, index) {
                  final label = sortOptions[index];
                  return ListTile(
                    title: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: AppTextStyles.medium,

                        color: AppColors.textPrimary(isDarkMode),
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      final sortValue = sortMap[label] ?? 'newest';
                      controller.fetchAds(
                        categoryId: widget.categoryId,
                        subCategoryLevelOneId: controller.currentSubCategoryLevelOneId.value,
                        subCategoryLevelTwoId: controller.currentSubCategoryLevelTwoId.value,
                        search: controller.currentSearch.value.isNotEmpty ? controller.currentSearch.value : null,
                        sortBy: sortValue,
                        cityId: controller.selectedCity.value?.id,
                        areaId: controller.selectedArea.value?.id,
                        attributes: controller.currentAttributes.isNotEmpty ? controller.currentAttributes : null,
                        lang: Get.find<ChangeLanguageController>().currentLocale.value.languageCode,
                        timeframe: widget.currentTimeframe,
                        onlyFeatured: widget.onlyFeatured,
                        page: 1,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

// ---------------- Image search UI & logic ----------------

/// يعرض مودال لاختيار/التقاط صورة ثم زر "ابحث الآن"
void _showImageSearchDialog() {
  XFile? pickedXFile;
  File? _pickedImage;
  bool isSearching = false;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      final isDark = themeController.isDarkMode.value;
      return StatefulBuilder(builder: (context, setState) {
        return Dialog(
          insetPadding: EdgeInsets.all(16.w),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: AppColors.surface(isDark),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'بحث بالصور'.tr,
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    fontSize: AppTextStyles.xlarge,

                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary(isDark),
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  'التقط صورة أو اختر من المعرض ثم اضغط "ابحث الآن"'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    fontSize: AppTextStyles.small,

                    color: AppColors.textSecondary(isDark),
                  ),
                ),
                SizedBox(height: 12.h),

                // معاينة الصورة لو موجودة
                Container(
                  height: 160.h,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.card(isDark),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: AppColors.grey.withOpacity(0.12)),
                  ),
                  child: _pickedImage == null
                      ? Center(
                          child: Text(
                            'لم يتم اختيار صورة'.tr,
                            style: TextStyle(
                              fontFamily: AppTextStyles.appFontFamily,
                              color: AppColors.grey,
                            ),
                          ),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(8.r),
                          child: Image.file(_pickedImage!, fit: BoxFit.cover),
                        ),
                ),

                SizedBox(height: 12.h),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: Icon(Icons.photo_camera),
                        label: Text(
                          'كاميرا'.tr,
                          style: TextStyle(
                            fontFamily: AppTextStyles.appFontFamily,
                            color: Colors.black,
                          ),
                        ),
                        onPressed: isSearching
                            ? null
                            : () async {
                                try {
                                  final XFile? x = await _imagePicker.pickImage(
                                    source: ImageSource.camera,
                                    imageQuality: 80,
                                    maxWidth: 1024,
                                  );
                                  if (x != null) {
                                    setState(() {
                                      pickedXFile = x;
                                      _pickedImage = File(x.path);
                                    });
                                  }
                                } catch (e) {
                                  print('Camera pick error: $e');
                                  Get.snackbar(
                                    'خطأ',
                                    'فشل اختيار الصورة من الكاميرا',
                                    snackPosition: SnackPosition.BOTTOM,
                                  );
                                }
                              },
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: Icon(Icons.photo_library),
                        label: Text(
                          'معرض'.tr,
                          style: TextStyle(
                            fontFamily: AppTextStyles.appFontFamily,
                            color: Colors.black,
                          ),
                        ),
                        onPressed: isSearching
                            ? null
                            : () async {
                                try {
                                  final XFile? x = await _imagePicker.pickImage(
                                    source: ImageSource.gallery,
                                    imageQuality: 80,
                                    maxWidth: 1024,
                                  );
                                  if (x != null) {
                                    setState(() {
                                      pickedXFile = x;
                                      _pickedImage = File(x.path);
                                    });
                                  }
                                } catch (e) {
                                  print('Gallery pick error: $e');
                                  Get.snackbar(
                                    'خطأ',
                                    'فشل اختيار الصورة من المعرض',
                                    snackPosition: SnackPosition.BOTTOM,
                                  );
                                }
                              },
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 12.h),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isSearching
                            ? null
                            : () {
                                Navigator.pop(context);
                              },
                        child: Text(
                          'إلغاء'.tr,
                          style: TextStyle(
                            fontFamily: AppTextStyles.appFontFamily,
                            color: AppColors.redId,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: (isSearching || pickedXFile == null)
                            ? null
                            : () async {
                                // 1) فعل حالة البحث داخل الـ dialog
                                setState(() => isSearching = true);

                                try {
                                  // 2) استدعاء الكنترولر
                                  final adsController = Get.find<AdsController>();

                                  // 3) استدعاء عملية البحث بالصورة
                                  await adsController.searchAdsByImage(
                                    imageFile: pickedXFile!,
                                    lang: Get.find<ChangeLanguageController>()
                                        .currentLocale
                                        .value
                                        .languageCode,
                                    page: 1,
                                    perPage: 15,
                                    categoryId: widget.categoryId,
                                    subCategoryLevelOneId: widget.subCategoryId,
                                    subCategoryLevelTwoId: widget.subTwoCategoryId,
                                    debug: false,
                                  );

                                  // 4) إغلاق المودال بعد النجاح وإظهار رسالة خفيفة
                                  Navigator.pop(context);
                                  Get.snackbar(
                                    'نجاح',
                                    'تم جلب النتائج',
                                    snackPosition: SnackPosition.BOTTOM,
                                  );
                                } catch (e, st) {
                                  // معالجة الأخطاء وعرض رسالة مفصّلة للمستخدم
                                  print('searchByImage error: $e');
                                  print(st);
                                  final errMsg = (e is Exception) ? e.toString() : 'حدث خطأ غير متوقع';
                                  Get.snackbar(
                                    'خطأ',
                                    errMsg,
                                    snackPosition: SnackPosition.BOTTOM,
                                  );
                                  setState(() => isSearching = false);
                                }
                              },
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.buttonAndLinksColor),
                        child: isSearching
                            ? SizedBox(
                                height: 20.h,
                                width: 20.h,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.onPrimary),
                                ),
                              )
                            : Text(
                                'ابحث الآن'.tr,
                                style: TextStyle(
                                  fontFamily: AppTextStyles.appFontFamily,
                                  color: AppColors.onPrimary,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      });
    },
  );
}
}