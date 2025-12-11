// lib/core/recaptcha/recaptcha_v2_dialog.dart
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class RecaptchaV2Dialog extends StatefulWidget {
  final String pageUrl;
  final String siteKey;

  const RecaptchaV2Dialog({
    super.key,
    required this.pageUrl,
    required this.siteKey,
  });

  @override
  State<RecaptchaV2Dialog> createState() => _RecaptchaV2DialogState();
}

class _RecaptchaV2DialogState extends State<RecaptchaV2Dialog> {
  late final WebViewController _ctrl;
  bool _loading = true;
  bool _tokenReceived = false; // ✅ جديد: علامة أننا استقبلنا التوكن

  Uri _buildUrl() {
    return Uri.parse(widget.pageUrl).replace(queryParameters: {
      'site_key': widget.siteKey,
    });
  }

  @override
  void initState() {
    super.initState();

    _ctrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setUserAgent(
        'Mozilla/5.0 (${kIsWeb ? "X11; Linux x86_64" : (Platform.isIOS ? "iPhone; CPU iPhone OS 15_0 like Mac OS X" : "Linux; Android 13")}) '
        'AppleWebKit/537.36 (KHTML, like Gecko) '
        'Chrome/119.0.0.0 Safari/537.36',
      )
      // ✅ قناة JS باسم Recaptcha
      ..addJavaScriptChannel('Recaptcha', onMessageReceived: (msg) {
        final token = msg.message.trim();
        debugPrint('✅ [RecaptchaV2Dialog] Recaptcha channel token: $token');
        if (token.isNotEmpty && !_tokenReceived) {
          _tokenReceived = true; // ✅ منع معالجة متكررة
          
          // ✅ نرجّع التوكن لفلاتر (AuthController._getV2Token)
          // ✅ ولكن لا نغلق النافذة تلقائياً - المستخدم هو من يغلقها يدوياً
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              Navigator.of(context).pop(token);
            }
          });
        }
      })
      // ✅ قناة JS ثانية باسم recaptcha (لو تم استخدامها من الـ HTML)
      ..addJavaScriptChannel('recaptcha', onMessageReceived: (msg) {
        final token = msg.message.trim();
        debugPrint('✅ [RecaptchaV2Dialog] recaptcha channel token: $token');
        if (token.isNotEmpty && !_tokenReceived) {
          _tokenReceived = true;
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              Navigator.of(context).pop(token);
            }
          });
        }
      })
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) async {
            // أخفِ اللودينغ أولاً
            setState(() => _loading = false);

            // حقن JavaScript يلفّ onCaptchaSuccess بطريقة آمنة لفلاتر
            try {
              await _ctrl.runJavaScript(r"""
                (function () {
                  try {
                    // علامة أن الصفحة تعمل داخل Flutter
                    window.__fromFlutterV2 = true;

                    if (typeof window.onCaptchaSuccess === 'function' &&
                        !window.__v2_patched_flutter) {

                      window.__v2_patched_flutter = true;
                      var original = window.onCaptchaSuccess;

                      window.onCaptchaSuccess = function(token) {
                        try {
                          // 1) أرسل التوكن مباشرة لفلاتر عبر JavaScriptChannel (الأهم)
                          if (window.Recaptcha &&
                              typeof window.Recaptcha.postMessage === 'function') {
                            window.Recaptcha.postMessage(String(token || ''));
                            console.log('[flutter-v2] sent token via Recaptcha.postMessage');
                          }
                        } catch (e2) {
                          console.log('[flutter-v2] Recaptcha.postMessage error', e2);
                        }

                        try {
                          // قناة ثانية اختيارية
                          if (window.recaptcha &&
                              typeof window.recaptcha.postMessage === 'function') {
                            window.recaptcha.postMessage(String(token || ''));
                            console.log('[flutter-v2] sent token via recaptcha.postMessage');
                          }
                        } catch (e3) {
                          console.log('[flutter-v2] recaptcha.postMessage error', e3);
                        }

                        // 2) (اختياري) استدعِ السلوك الأصلي بعدين وبـ setTimeout
                        // ولكن منع الإغلاق التلقائي للنافذة
                        try {
                          if (typeof original === 'function') {
                            setTimeout(function () {
                              try {
                                // نمرر التوكن للدالة الأصلية ولكن نمنع الإغلاق
                                // عن طريق منع window.close()
                                const originalClose = window.close;
                                window.close = function() {
                                  console.log('[flutter-v2] Blocked automatic window.close()');
                                  // لا تفعل شيئاً - منع الإغلاق
                                };
                                original(token);
                                // نعيد window.close بعد 2 ثانية
                                setTimeout(() => {
                                  window.close = originalClose
                                }, 2000);
                              } catch (e4) {
                                console.log('[flutter-v2] original onCaptchaSuccess error', e4);
                              }
                            }, 0);
                          }
                        } catch (eOuter2) {
                          console.log('[flutter-v2] error calling original', eOuter2);
                        }
                      };
                    } else {
                      console.log('[flutter-v2] onCaptchaSuccess not found or already patched');
                    }
                  } catch (eOuter) {
                    console.log('[flutter-v2] error wrapping onCaptchaSuccess', eOuter);
                  }
                })();
              """);
              debugPrint(
                  '✅ [RecaptchaV2Dialog] JS patch for onCaptchaSuccess injected (block-auto-close).');
            } catch (e) {
              debugPrint('❌ [RecaptchaV2Dialog] JS injection failed: $e');
            }
          },
        ),
      )
      ..loadRequest(_buildUrl());
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // ✅ السماح للمستخدم بإغلاق النافذة يدوياً فقط
      onWillPop: () async {
        if (_tokenReceived) {
          // إذا استقبلنا التوكن بالفعل، نرجعه
          return true;
        }
        // إذا لم نستقبل التوكن بعد، نطلب من المستخدم إكمال التحقق
        final shouldClose = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('إلغاء التحقق'),
            content: const Text('إذا خرجت الآن، لن تتمكن من إكمال عملية التسجيل. هل تريد المتابعة؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('البقاء'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('خروج'),
              ),
            ],
          ),
        );
        return shouldClose ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تحقق: أنا لست روبوت (reCAPTCHA v2)'),
          actions: [
            IconButton(
              tooltip: 'إعادة التحميل',
              onPressed: () => _ctrl.reload(),
              icon: const Icon(Icons.refresh),
            ),
            // ✅ زر إغلاق يدوي - يظهر فقط بعد استقبال التوكن
            if (_tokenReceived)
              IconButton(
                icon: const Icon(Icons.check_circle, color: Colors.green),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'تم التحقق - إغلاق',
              ),
          ],
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              if (_tokenReceived) {
                Navigator.of(context).pop();
              } else {
                final shouldClose = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('إلغاء التحقق'),
                    content: const Text('إذا خرجت الآن، لن تتمكن من إكمال عملية التسجيل. هل تريد المتابعة؟'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('البقاء'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('خروج'),
                      ),
                    ],
                  ),
                );
                if (shouldClose == true && mounted) {
                  Navigator.of(context).pop(null);
                }
              }
            },
          ),
        ),
        body: Stack(
          children: [
            Positioned.fill(child: WebViewWidget(controller: _ctrl)),
            if (_loading) const Center(child: CircularProgressIndicator()),
            
            // ✅ رسالة تأكيد بعد استقبال التوكن
            if (_tokenReceived)
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'تم التحقق بنجاح!',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'يمكنك الآن إغلاق هذه النافذة والمتابعة',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}