 class SearchHistory {
  final int id;
  final int userId;
  final String recordName;
  final int categoryId;
  final int? subcategoryId;
  final int? secondSubcategoryId;
  final String createdAt;
  final bool notifyPhone;
  final bool notifyEmail;

  SearchHistory({
    required this.id,
    required this.userId,
    required this.recordName,
    required this.categoryId,
    this.subcategoryId,
    this.secondSubcategoryId,
    required this.createdAt,
    required this.notifyPhone,
    required this.notifyEmail,
  });

  factory SearchHistory.fromJson(Map<String, dynamic> json) {
    return SearchHistory(
      id: json['id'],
      userId: json['user_id'],
      recordName: json['record_name'],
      categoryId: json['category_id'],
      subcategoryId: json['subcategory_id'],
      secondSubcategoryId: json['second_subcategory_id'],
      createdAt: json['created_at'],
      notifyPhone: json['notify_phone'] == 1,
      notifyEmail: json['notify_email'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'record_name': recordName,
      'category_id': categoryId,
      'subcategory_id': subcategoryId,
      'second_subcategory_id': secondSubcategoryId,
      'notify_phone': notifyPhone ? 1 : 0,
      'notify_email': notifyEmail ? 1 : 0,
    };
  }
}