// lib/core/data/model/favorite_group.dart

class FavoriteGroup {
  final int id;
  final int userId;
  final String name;
  final int? favoritesCount; // يأتي من withCount إن طلبت

  FavoriteGroup({
    required this.id,
    required this.userId,
    required this.name,
    this.favoritesCount,
  });

  factory FavoriteGroup.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      return int.tryParse('$v') ?? 0;
    }

    return FavoriteGroup(
      id: parseInt(json['id']),
      userId: json.containsKey('user_id') ? parseInt(json['user_id']) : 0,
      name: json['name']?.toString() ?? '',
      favoritesCount: json.containsKey('favorites_count') ? parseInt(json['favorites_count']) : null,
    );
  }

  Map<String, String> toRequestBody() {
    final map = <String, String>{};
    map['name'] = name;
    map['user_id'] = userId.toString();
    return map;
  }
}
