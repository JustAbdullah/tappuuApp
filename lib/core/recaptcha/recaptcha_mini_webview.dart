// lib/core/recaptcha/recaptcha_mini_webview.dart
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'recaptcha_token_cache.dart';

class RecaptchaMiniWebView extends StatefulWidget {
  final String baseUrl; // مثل: https://testing.arabiagroup.net/recaptcha.html
  final String action;  // مثل: login | signup | reset_password
  final ValueChanged<String>? onToken;
  final bool invisible; // 1×1 شبه مخفي

  const RecaptchaMiniWebView({
    super.key,
    required this.baseUrl,
    required this.action,
    this.onToken,
    this.invisible = true,
  });

  @override
  State<RecaptchaMiniWebView> createState() => _RecaptchaMiniWebViewState();
}

class _RecaptchaMiniWebViewState extends State<RecaptchaMiniWebView> {
  late final WebViewController _ctrl;
  bool _fixedOnce = false; // حارس لمنع إعادة التحميل المتكرر

  Uri _withParams() {
    return Uri.parse(widget.baseUrl).replace(queryParameters: {
      'action': widget.action,
      // لا نكسر الكاش كل ثانية — يكفي مرة عند الإنشاء
    });
  }

  @override
  void initState() {
    super.initState();

    _ctrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('Recaptcha', onMessageReceived: (msg) {
        final token = msg.message;
        if (token.isNotEmpty) {
          RecaptchaTokenCache.set(token);
          widget.onToken?.call(token);
        }
      })
      ..addJavaScriptChannel('recaptcha', onMessageReceived: (msg) {
        final token = msg.message;
        if (token.isNotEmpty) {
          RecaptchaTokenCache.set(token);
          widget.onToken?.call(token);
        }
      })
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) async {
            // أصلِح مرة واحدة فقط لو اختفت action= بسبب ريدايـركت
            if (!_fixedOnce && !url.contains('action=')) {
              _fixedOnce = true;
              _ctrl.loadRequest(_withParams());
            }
          },
        ),
      )
      ..loadRequest(_withParams());
  }

  @override
  Widget build(BuildContext context) {
    final view = WebViewWidget(controller: _ctrl);

    if (!widget.invisible) {
      // وضع مرئي للتشخيص
      return SizedBox(width: 300, height: 300, child: view);
    }

    // وضع 1×1 شبه مخفي — مهم جدًا يكون الـ WebView نفسه معروض
    return IgnorePointer(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Opacity(
          opacity: 0.001,
          child: SizedBox(width: 1, height: 1, child: view),
        ),
      ),
    );
  }
}
