class Category {
  final int id;
  final String slug;
  final String date;
  final String image;
  final int adsCount; // حقل جديد لعدد الإعلانات
  final List<Translation> translations;

  Category({
    required this.id,
    required this.slug,
    required this.image,
    required this.date,
    required this.adsCount, // إضافة هنا
    required this.translations,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int? ?? 0,
      slug: json['slug'] as String? ?? '',
      image: json['image'] as String? ?? '',
      date: json['date'] as String? ?? '',
      adsCount: json['published_ads_count'] as int? ?? 0, // قراءة القيمة الجديدة
      translations: (json['translations'] as List<dynamic>? ?? [])
          .map((t) => Translation.fromJson(t))
          .toList(),
    );
  }

  String get name => translations.firstOrNull?.name ?? '';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class Translation {
  final int id;
  final int categoryId;
  final String language;
  final String name;
  final String description;

  Translation(
      {required this.id,
      required this.categoryId,
      required this.language,
      required this.name,
      required this.description});

  factory Translation.fromJson(Map<String, dynamic> json) {
    return Translation(
      id: json['id'],
      categoryId: json['category_id'],
      language: json['language'],
      name: json['name'],
      description: json['description'],
    );
  }
}
