
// Model for BrowsingHistory
class BrowsingHistory {
  final int id;
  final int userId;
  final int categoryId;
  final int subcat1Id;
  final int? subcat2Id;
  final String visitedAt;

  BrowsingHistory({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.subcat1Id,
    this.subcat2Id,
    required this.visitedAt,
  });

  factory BrowsingHistory.fromJson(Map<String, dynamic> json) {
    return BrowsingHistory(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      categoryId: json['category_id'] as int,
      subcat1Id: json['subcat1_id'] as int,
      subcat2Id: json['subcat2_id'] as int?,
      visitedAt: json['visited_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'category_id': categoryId,
      'subcat1_id': subcat1Id,
      'subcat2_id': subcat2Id,
    };
  }
}