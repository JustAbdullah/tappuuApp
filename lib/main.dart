// lib/main.dart
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tappuu_app/views/LoadingScreen/loading.dart';

import 'controllers/ColorController.dart';
import 'controllers/CurrencyController.dart';
import 'controllers/ThemeController.dart';
import 'controllers/home_controller.dart';
import 'controllers/sharedController.dart';
import 'core/localization/changelanguage.dart';
import 'core/localization/AppTranslation.dart';
import 'core/services/appservices.dart';
import 'core/services/font_service.dart';
import 'core/services/font_size_service.dart';
import 'firebase_options.dart';

// --- import AppColors (عدل المسار إذا كان مختلفاً) ---
import 'core/constant/appcolors.dart';

/// هذا الـ handler سيتم استدعاؤه عندما تصل رسالة في الخلفية/عند ميت التطبيق (يجب أن يكون top-level)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Handling background message: ${message.messageId}');
  debugPrint('Background message data: ${message.data}');
  if (message.notification != null) {
    debugPrint('Background notification title: ${message.notification?.title}');
  }
}

String _normalizeStoredTopic(String raw) {
  if (raw == 'all') return 'all';
  if (raw.startsWith('category_')) {
    final parts = raw.split('_');
    return parts.isNotEmpty ? parts.last : raw;
  }
  return raw; // مفترض أن يكون رقم مثل '2'
}

// ------------ Helpers لإدارة المواضيع (topics) في SharedPreferences ------------
Future<Set<String>> _getSavedTopics() async {
  final prefs = await SharedPreferences.getInstance();
  final list = prefs.getStringList('subscribed_topics') ?? [];
  final normalized = list.map((e) => _normalizeStoredTopic(e)).toSet();
  return normalized;
}

Future<void> _resubscribeSavedTopics() async {
  try {
    final topics = await _getSavedTopics(); // مصفاة: ['all','2','3']
    for (final stored in topics) {
      final fcmTopic = _fcmTopicFromStored(stored); // 'all' أو 'category_2'
      try {
        await FirebaseMessaging.instance.subscribeToTopic(fcmTopic);
        debugPrint('Re-subscribed to topic: $fcmTopic (stored as $stored)');
      } catch (e) {
        debugPrint('Failed to re-subscribe to $fcmTopic: $e');
      }
    }
  } catch (e) {
    debugPrint('Error resubscribing saved topics: $e');
  }
}

String _fcmTopicFromStored(String stored) {
  if (stored == 'all') return 'all';
  return 'category_$stored'; // stored هنا رقم مثل '2'
}
// ------------------------------------------------------------------------------

Future<void> initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized');

    // سجل الـ background handler (لا تضع هذا داخل callbacks أخرى)
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }
}

Future<void> setupFirebaseMessaging() async {
  try {
    final messaging = FirebaseMessaging.instance;

    // اعرض الإشعارات في الـ foreground (iOS)
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // طلب تصريح الإشعارات
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('Permission status: ${settings.authorizationStatus}');

    // احصل على التوكن
    final token = await messaging.getToken();
    debugPrint('FCM Token: $token');

    // اشترك بالقناة الرئيسية "all"
    try {
      await messaging.subscribeToTopic("all");
      debugPrint('Subscribed to topic: all');
    } catch (e) {
      debugPrint('Failed to subscribe to "all": $e');
    }

    // إذا كان لدينا مواضيع محفوظة سابقًا فنعيد الاشتراك بها
    await _resubscribeSavedTopics();

    // استمع لتغيير التوكن (عند تحديثه أعد الاشتراك في المواضيع المحفوظة)
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      debugPrint('FCM onTokenRefresh: $newToken - re-subscribing saved topics');
      await _resubscribeSavedTopics();
    });

    // استمع للإشعارات أثناء كون التطبيق في الـ foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground message received: ${message.messageId}');
      debugPrint('Message data: ${message.data}');
      if (message.notification != null) {
        debugPrint('Notification title: ${message.notification?.title}');
        debugPrint('Notification body: ${message.notification?.body}');
      }
    });

    // استمع عند فتح التطبيق من خلال الضغط على إشعار
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('onMessageOpenedApp: ${message.messageId}');
      debugPrint('Payload data: ${message.data}');
    });
  } catch (e) {
    debugPrint('FCM Error: $e');
  }
}

// ============= Deep Links Handling =============
class DeepLinkHandler {
  static const _channel = MethodChannel('com.stay_in_me/deeplink');
  static final instance = DeepLinkHandler._internal();
  DeepLinkHandler._internal();

  final StreamController<String> _linkStreamController = StreamController<String>.broadcast();
  Stream<String> get linkStream => _linkStreamController.stream;

  void init() {
    // الحصول على الرابط الأولي
    _getInitialLink().then((link) {
      if (link != null) {
        _linkStreamController.add(link);
      }
    });

    // الاستماع للروابط الجديدة
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onNewLink') {
        final link = call.arguments as String?;
        if (link != null) {
          _linkStreamController.add(link);
        }
      }
    });
  }

  Future<String?> _getInitialLink() async {
    try {
      return await _channel.invokeMethod('getInitialLink');
    } on PlatformException catch (e) {
      debugPrint('Failed to get initial link: ${e.message}');
      return null;
    }
  }

  Future<String?> getLatestLink() async {
    try {
      return await _channel.invokeMethod('getLatestLink');
    } on PlatformException catch (e) {
      debugPrint('Failed to get latest link: ${e.message}');
      return null;
    }
  }

  void dispose() {
    _linkStreamController.close();
  }
}
// ==============================================

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تسجيل متحكم الألوان وجلب اللون الأساسي أولاً
  final colorController = Get.put(ColorController());

  // تهيئة Firebase أولاً
  await initializeFirebase();

  // تهيئة الخدمات الأساسية (AppServices يتم تسجيله داخل الدالة)
  await _setSystemUI();
  await _initializeEssentialServices();

  // قم بتشغيل تهيئة FCM بشكل غير محجوز لكي لا تؤخر بدء التطبيق.
  unawaited(setupFirebaseMessaging());

  // تهيئة معالج الروابط العميقة
  final deepLinkHandler = DeepLinkHandler.instance;
  deepLinkHandler.init();

  // انتظار جلب اللون الأساسي لمدة 3 ثواني كحد أقصى
  await Future.any([
    // افترض أن ColorController لديه دالة fetchPrimaryColor() كما في كودك
    colorController.fetchPrimaryColor(),
    Future.delayed(const Duration(seconds: 3))
  ]);

  runApp(const MyApp());
}

Future<void> _setSystemUI() async {
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
    overlays: [SystemUiOverlay.top],
  );

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Color(0xFFE0E0E0),
    systemNavigationBarDividerColor: Color(0xFFE0E0E0),
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
}

Future<void> _initializeEssentialServices() async {
  try {
    // 1) تهيئة AppServices وتسجيله في Get (مهم: حتى يتمكن ImagesPath وغيره من الوصول)
    final appServices = await AppServices.init();
    Get.put(appServices, permanent: true);

    // 2) جلب شعار التطبيق من الـ API وحفظه في SharedPreferences
    try {
      await Future.any([
        appServices.fetchAndStoreAppLogo(),
        Future.delayed(const Duration(seconds: 3)),
      ]);
      debugPrint('Attempted to fetch app logo (with timeout).');
    } catch (e) {
      debugPrint('Error while fetching app logo (ignored): $e');
    }

    // 2.b) جلب شاشة الانتظار من الـ API
    try {
      await Future.any([
        appServices.fetchAndStoreWaitingScreen(),
        Future.delayed(const Duration(seconds: 3)),
      ]);
      debugPrint('Attempted to fetch waiting screen (with timeout).');
    } catch (e) {
      debugPrint('Error while fetching waiting screen (ignored): $e');
    }

    // 2.c) جلب وتطبيق أحجام الخطوط (FontSizeService)
    try {
      await Future.any([
        FontSizeService.instance.init(),
        Future.delayed(const Duration(seconds: 3)),
      ]);
      debugPrint('FontSizeService init attempted.');
    } catch (e) {
      debugPrint('FontSizeService init failed (ignored): $e');
    }

    // 2.d) تحميل وتسجيل الخط النشط (FontService)
    try {
      await Future.any([
        FontService.instance.init(),
        Future.delayed(const Duration(seconds: 5)),
      ]);
      debugPrint('FontService init attempted.');
    } catch (e) {
      debugPrint('FontService init failed (ignored): $e');
    }

    // 3) تسجيل بقية الخدمات والمتغيرات
    Get.lazyPut(() => HomeController(), fenix: true);
    Get.lazyPut(() => ThemeController(), fenix: true);
    Get.lazyPut(() => ChangeLanguageController(), fenix: true);
    Get.lazyPut(() => CurrencyController(), fenix: true);
    Get.put(SharedController(), permanent: true);

    // لا حاجة للانتظار — مجرد استدعاء للحصول على رابط الشعار المحفوظ
    appServices.getStoredAppLogoUrl();
  } catch (e) {
    debugPrint("❌ AppServices error: $e");
  }
}

// ==============================================
// Helper: استخراج اللون من ColorController (يدعم Color, Rx<Color>, String hex)
Color? _extractPrimaryColorFromController(dynamic controller) {
  try {
    if (controller == null) return null;

    // تحقق أسماء شائعة لحقل اللون داخل الكنترولر
    dynamic candidate;
    try {
      candidate = (controller as dynamic).primaryColor;
    } catch (_) {}
    if (candidate == null) {
      try {
        candidate = (controller as dynamic).appColor;
      } catch (_) {}
    }
    if (candidate == null) {
      try {
        candidate = (controller as dynamic).mainColor;
      } catch (_) {}
    }
    if (candidate == null) {
      try {
        candidate = (controller as dynamic).color;
      } catch (_) {}
    }

    if (candidate == null) return null;

    // إذا كان Rx (GetX) أعد القيمة
    if (candidate is Rx) {
      final v = (candidate as Rx).value;
      if (v is Color) return v;
      if (v is String) {
        return _colorFromHexString(v);
      }
    }

    // إذا كانت Rxn أو Rx<Color?>
    try {
      if (candidate is Rx<Color?>) {
        return (candidate as Rx<Color?>).value;
      }
    } catch (_) {}

    if (candidate is Color) return candidate;
    if (candidate is String) return _colorFromHexString(candidate);

    return null;
  } catch (e) {
    return null;
  }
}

Color? _colorFromHexString(String s) {
  try {
    var hex = s.trim();
    if (hex.startsWith('#')) hex = hex.substring(1);
    if (hex.length == 6) hex = 'FF$hex';
    if (hex.length == 8) {
      final intVal = int.parse(hex, radix: 16);
      return Color(intVal);
    }
  } catch (_) {}
  return null;
}

/// استخراج ThemeMode بشكل مرن من ThemeController (يتعامل مع حقول شائعة)
ThemeMode _resolveThemeMode(dynamic controller) {
  try {
    if (controller == null) return ThemeMode.system;

    // 1) تحقق إذا فيه themeMode مباشرة
    try {
      final cand = (controller as dynamic).themeMode;
      if (cand is ThemeMode) return cand;
      if (cand is Rx<ThemeMode>) return cand.value;
      if (cand is String) {
        final s = cand.toLowerCase();
        if (s.contains('dark')) return ThemeMode.dark;
        if (s.contains('light')) return ThemeMode.light;
        return ThemeMode.system;
      }
    } catch (_) {}

    // 2) تحقق خواص بوليانية شائعة: isDark / isDarkMode / darkMode / value
    try {
      final isDarkCandidates = [
        (controller as dynamic).isDark,
        (controller as dynamic).isDarkMode,
        (controller as dynamic).darkMode,
        (controller as dynamic).dark,
        (controller as dynamic).value,
      ];
      for (final c in isDarkCandidates) {
        if (c == null) continue;
        if (c is bool) return c ? ThemeMode.dark : ThemeMode.light;
        if (c is Rx<bool>) return c.value ? ThemeMode.dark : ThemeMode.light;
        if (c is int) return c == 1 ? ThemeMode.dark : ThemeMode.light;
      }
    } catch (_) {}

    // 3) تحقق إذا فيه حقل theme بعنوان نصي مثل 'light'/'dark'
    try {
      final t = (controller as dynamic).theme;
      if (t is String) {
        final s = t.toLowerCase();
        if (s.contains('dark')) return ThemeMode.dark;
        if (s.contains('light')) return ThemeMode.light;
      }
    } catch (_) {}

    // 4) fallback system
    return ThemeMode.system;
  } catch (_) {
    return ThemeMode.system;
  }
}

// ==============================================

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late StreamSubscription<String> _deepLinkSubscription;
  final DeepLinkHandler _deepLinkHandler = DeepLinkHandler.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setSystemUI();

    // الاستماع للروابط العميقة
    _deepLinkSubscription = _deepLinkHandler.linkStream.listen((link) {
      // تمرير الرابط إلى SharedController لمعالجته
      Get.find<SharedController>().handleDeepLink(link);
    });
  }

  @override
  void dispose() {
    _deepLinkSubscription.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _setSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFFE0E0E0),
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
  }

  Future<bool> _onWillPop() async {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return false;
    } else {
      final shouldExit = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('هل تريد الخروج؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('لا'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('نعم'),
            ),
          ],
        ),
      );
      return shouldExit ?? false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorController = Get.find<ColorController>();

    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (_, __) {
        return GetBuilder<ChangeLanguageController>(
          builder: (langController) {
            return GetBuilder<ThemeController>(
              builder: (themeController) {
                // إعداد الثيم الفاتح مستخدماً AppColors
                final ThemeData lightTheme = ThemeData(
                  brightness: Brightness.light,
                  primaryColor: AppColors.primary,
                  scaffoldBackgroundColor: AppColors.background(false),
                  appBarTheme: AppBarTheme(
                    backgroundColor: AppColors.appBar(false),
                    iconTheme: IconThemeData(color: AppColors.onPrimary),
                    titleTextStyle: TextStyle(color: AppColors.onPrimary, fontSize: 18.sp, fontFamily: 'Tajawal'),
                    systemOverlayStyle: SystemUiOverlayStyle.dark,
                    elevation: 0,
                  ),
                  colorScheme: ColorScheme.light(
                    primary: AppColors.primary,
                    secondary: AppColors.primarySecond,
                    background: AppColors.background(false),
                    surface: AppColors.surface(false),
                    onBackground: AppColors.onBackground,
                  ),
                  iconTheme: IconThemeData(color: AppColors.icon(false)),
                  textTheme: ThemeData.light().textTheme.apply(
                        bodyColor: AppColors.textPrimary(false),
                        displayColor: AppColors.textPrimary(false),
                      ),
                  cardColor: AppColors.card(false),
                  dividerColor: AppColors.divider(false),
                  elevatedButtonTheme: ElevatedButtonThemeData(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      textStyle: TextStyle(fontFamily: 'Tajawal'),
                    ),
                  ),
                );

                // إعداد الثيم الداكن مستخدماً AppColors
                final ThemeData darkTheme = ThemeData(
                  brightness: Brightness.dark,
                  primaryColor: AppColors.primary,
                  scaffoldBackgroundColor: AppColors.background(true),
                  appBarTheme: AppBarTheme(
                    backgroundColor: AppColors.appBar(true),
                    iconTheme: IconThemeData(color: AppColors.onPrimary),
                    titleTextStyle: TextStyle(color: AppColors.onPrimary, fontSize: 18.sp, fontFamily: 'Tajawal'),
                    systemOverlayStyle: SystemUiOverlayStyle.light,
                    elevation: 0,
                  ),
                  colorScheme: ColorScheme.dark(
                    primary: AppColors.primary,
                    secondary: AppColors.primarySecond,
                    background: AppColors.background(true),
                    surface: AppColors.surface(true),
                    onBackground: AppColors.onSurfaceDark,
                  ),
                  iconTheme: IconThemeData(color: AppColors.icon(true)),
                  textTheme: ThemeData.dark().textTheme.apply(
                        bodyColor: AppColors.textPrimary(true),
                        displayColor: AppColors.textPrimary(true),
                      ),
                  cardColor: AppColors.card(true),
                  dividerColor: AppColors.divider(true),
                  elevatedButtonTheme: ElevatedButtonThemeData(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      textStyle: TextStyle(fontFamily: 'Tajawal'),
                    ),
                  ),
                );

                // استخرج ThemeMode بشكل مرن من الكنترولر (آمن)
                final ThemeMode themeMode = _resolveThemeMode(themeController);

                return WillPopScope(
                  onWillPop: _onWillPop,
                  child: GetMaterialApp(
                    debugShowCheckedModeBanner: false,
                    translations: AppTranslation(),
                    // نستخدم locale من الكنترولر، والكنترولر نفسه يضمن أنها عربية دائماً.
                    locale: langController.currentLocale.value,
                    fallbackLocale: const Locale('ar'),
                    title: "طابوو",
                    home: const Loading(),
                    theme: lightTheme,
                    darkTheme: darkTheme,
                    themeMode: themeMode,
                    builder: (context, child) {
                      final langCode = langController.currentLocale.value.languageCode;
                      final isRtl = ['ar', 'ku', 'fa', 'ur'].contains(langCode);
                      return Directionality(
                        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                        child: MediaQuery(
                          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
                          child:
                              // مجرد قراءة اللون لتشغيل التفاعلية
                              child!,
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
