// lib/enhanced_navigator_observer.dart

import 'dart:html' as html;
import 'package:flutter/widgets.dart';

/// مراقب مخصص للتنقل في تطبيق Flutter Web:
/// عند كل Push/Pop يحدّث سجل المتصفح عبر History API
class EnhancedNavigatorObserver extends NavigatorObserver {
  /// آخر مسار تم التنقل إليه
  String _lastRoute = '/';

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final name = route.settings.name;
    if (name != null) {
      _lastRoute = name;
      _updateBrowserHistory(name, push: true);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final name = previousRoute?.settings.name;
    if (name != null) {
      _lastRoute = name;
      _updateBrowserHistory(name, push: false);
    }
  }

  void _updateBrowserHistory(String route, {required bool push}) {
    final url = route; // يمكنك تعديل هذا إذا احتجت مسارًا أكثر تعقيدًا
    if (push) {
      html.window.history.pushState({'route': route}, '', url);
    } else {
      html.window.history.replaceState({'route': route}, '', url);
    }
  }
}
