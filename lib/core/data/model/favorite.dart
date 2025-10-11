// lib/core/data/model/favorite.dart

import 'AdResponse.dart'; // تأكد أن المسار صحيح في مشروعك

class NotificationSettings {
  final bool notifyEmail;
  final bool notifyPush;
  final bool notifyOnAnyChange;
  final double? minPrice;
  final double? maxPrice;
  final double? priceChangePct;
  final double? lastNotifiedPrice;

  NotificationSettings({
    required this.notifyEmail,
    required this.notifyPush,
    required this.notifyOnAnyChange,
    this.minPrice,
    this.maxPrice,
    this.priceChangePct,
    this.lastNotifiedPrice,
  });

  factory NotificationSettings.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return NotificationSettings(
        notifyEmail: false,
        notifyPush: false,
        notifyOnAnyChange: false,
      );
    }

    double? _toDouble(dynamic v) {
      if (v == null) return null;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is String && v.isNotEmpty) return double.tryParse(v);
      return null;
    }

    bool _toBool(dynamic v) {
      if (v == null) return false;
      if (v is bool) return v;
      if (v is int) return v == 1;
      if (v is String) return v == '1' || v.toLowerCase() == 'true';
      return false;
    }

    return NotificationSettings(
      notifyEmail: _toBool(json['notify_email']),
      notifyPush: _toBool(json['notify_push']),
      notifyOnAnyChange: _toBool(json['notify_on_any_change']),
      minPrice: _toDouble(json['min_price']),
      maxPrice: _toDouble(json['max_price']),
      priceChangePct: _toDouble(json['price_change_pct']),
      lastNotifiedPrice: _toDouble(json['last_notified_price']),
    );
  }

  Map<String, String> toRequestBody() {
    final Map<String, String> body = {};
    body['notify_email'] = notifyEmail ? '1' : '0';
    body['notify_push'] = notifyPush ? '1' : '0';
    body['notify_on_any_change'] = notifyOnAnyChange ? '1' : '0';
    if (minPrice != null) body['min_price'] = minPrice!.toString();
    if (maxPrice != null) body['max_price'] = maxPrice!.toString();
    if (priceChangePct != null) body['price_change_pct'] = priceChangePct!.toString();
    if (lastNotifiedPrice != null) body['last_notified_price'] = lastNotifiedPrice!.toString();
    return body;
  }
}

class FavoriteGroup {
  final int id;
  final String name;
  final int? userId;
  final int? favoritesCount;

  FavoriteGroup({
    required this.id,
    required this.name,
    this.userId,
    this.favoritesCount,
  });

  factory FavoriteGroup.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      throw ArgumentError('FavoriteGroup.fromJson received null');
    }
    return FavoriteGroup(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      name: json['name']?.toString() ?? '',
      userId: json.containsKey('user_id') ? (json['user_id'] is int ? json['user_id'] : int.tryParse('${json['user_id']}')) : null,
      favoritesCount: json.containsKey('favorites_count') ? (json['favorites_count'] is int ? json['favorites_count'] : int.tryParse('${json['favorites_count']}')) : null,
    );
  }
}

class Favorite {
  final int favoriteId;
  final String addedAt; // نص التاريخ كما يأتي من السيرفر
  final int? favoriteGroupId;
  final FavoriteGroup? group;
  final NotificationSettings notificationSettings;
  final Ad ad;

  Favorite({
    required this.favoriteId,
    required this.addedAt,
    required this.notificationSettings,
    required this.ad,
    this.favoriteGroupId,
    this.group,
  });

  factory Favorite.fromJson(Map<String, dynamic> json) {
    final adJson = json['ad'] as Map<String, dynamic>? ?? {};
    final notif = NotificationSettings.fromJson(json['notification_settings'] as Map<String, dynamic>?);
    FavoriteGroup? grp;
    int? grpId;

    // بعض الردود قد ترجع 'group' و/أو 'favorite_group_id'
    if (json.containsKey('group') && json['group'] != null) {
      try {
        grp = FavoriteGroup.fromJson(json['group'] as Map<String, dynamic>);
      } catch (_) {
        grp = null;
      }
    }

    if (json.containsKey('favorite_group_id')) {
      final raw = json['favorite_group_id'];
      if (raw != null) {
        grpId = raw is int ? raw : int.tryParse('$raw');
      }
    } else if (grp != null) {
      grpId = grp.id;
    }

    return Favorite(
      favoriteId: (json['favorite_id'] is int) ? json['favorite_id'] : int.tryParse('${json['favorite_id']}') ?? 0,
      addedAt: json['added_at']?.toString() ?? '',
      notificationSettings: notif,
      ad: Ad.fromJson(adJson),
      favoriteGroupId: grpId,
      group: grp,
    );
  }
}
