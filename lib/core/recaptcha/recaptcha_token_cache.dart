// lib/core/recaptcha/recaptcha_token_cache.dart
class RecaptchaTokenCache {
  static String? _last;

  /// خزّن آخر توكن
  static void set(String token) => _last = token;

  /// اسحب التوكن لمرة واحدة (ثم يفرّغ)
  static String? take() {
    final t = _last;
    _last = null;
    return t;
  }

  /// اقرأ بدون تفريغ (اختياري) — لا ننصح به للاستخدام مع v3
  static String? peek() => _last;
}
