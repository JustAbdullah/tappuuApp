import 'package:get/get.dart';
import '../services/appservices.dart'; // عدّل المسار حسب مشروعك

class ImagesPath {
  static const String RootPath = "assets/images";
  static const String _defaultLogo = "$RootPath/logo.png";

  // ديناميكي: يرجع رابط شبكة لو محفوظ، وإلا يعيد المسار المحلي
  static String get logo {
    try {
      if (Get.isRegistered<AppServices>()) {
        final svc = Get.find<AppServices>();
        final url = svc.getStoredAppLogoUrl();
        if (url != null && url.isNotEmpty) return url;
      }
    } catch (_) {}
    return _defaultLogo;
  }

  static const String Favorites = "$RootPath/Favorites.png";
  static const String history = "$RootPath/history.png";
  static const String lists = "$RootPath/lists.png";
    static const String wait = "$RootPath/screenWait.jpg";

}
