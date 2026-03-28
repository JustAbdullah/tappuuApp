import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/font_service.dart';
import '../services/font_size_service.dart';

class AppTextStyles {
  /// 🔤 الخط المستخدم (من FontService أو fallback)
  static String get appFontFamily =>
      FontService.instance.getActiveFamily() ?? 'Tajawal';

  /// 📏 الأحجام (من FontSizeService أو fallback)
  static double get small =>
      FontSizeService.instance.get("small")?.sp ?? 12.sp;

  static double get medium =>
      FontSizeService.instance.get("medium")?.sp ?? 14.sp;

  static double get large =>
      FontSizeService.instance.get("large")?.sp ?? 16.sp;

  static double get xlarge =>
      FontSizeService.instance.get("xlarge")?.sp ?? 18.sp;

  static double get xxlarge =>
      FontSizeService.instance.get("xxlarge")?.sp ?? 20.sp;

  static double get xxxlarge =>
      FontSizeService.instance.get("xxxlarge")?.sp ?? 22.sp;
}
