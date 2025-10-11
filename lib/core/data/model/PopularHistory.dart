class PopularHistory {
  final int categoryId; // معرف التصنيف الرئيسي
  final String category;
  final int subcat1Id; // معرف التصنيف الفرعي
  final String subcategory;
  final int? subcat2Id; // معرف التصنيف الثانوي
  final String? subcatLv2;
  final int count;

  PopularHistory({
    required this.categoryId,
    required this.category,
    required this.subcat1Id,
    required this.subcategory,
    this.subcat2Id,
    this.subcatLv2,
    required this.count,
  });

  factory PopularHistory.fromJson(Map<String, dynamic> json) {
    return PopularHistory(
      categoryId: json['category_id'] as int? ?? 0,
      category: json['category'] as String? ?? '',
      subcat1Id: json['subcat1_id'] as int? ?? 0,
      subcategory: json['subcategory'] as String? ?? '',
      subcat2Id: json['subcat2_id'] as int?,
      subcatLv2: json['subcat_lv2'] as String?,
      count: json['count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category_id': categoryId,
      'category': category,
      'subcat1_id': subcat1Id,
      'subcategory': subcategory,
      'subcat2_id': subcat2Id,
      'subcat_lv2': subcatLv2,
      'count': count,
    };
  }
}