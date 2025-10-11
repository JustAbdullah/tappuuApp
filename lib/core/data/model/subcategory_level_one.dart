import 'package:collection/collection.dart'; // لاستخدام firstOrNull

class SubcategoryLevelOne {
  final int id;
  final int categoryId;
  final String slug;
  final DateTime? date;
  final int adsCount;
  final List<Translation> translations;
  final String categoryName; // اسم التصنيف الرئيسي
  final String? image; // ← الحقل الجديد

  SubcategoryLevelOne({
    required this.id,
    required this.categoryId,
    required this.slug,
    required this.date,
    required this.adsCount,
    required this.translations,
    required this.categoryName,
    this.image,
  });

  factory SubcategoryLevelOne.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value == null) return 0;
      return int.tryParse(value.toString()) ?? 0;
    }

    DateTime? parseDate(String? dateString) {
      if (dateString == null || dateString.isEmpty) return null;
      return DateTime.tryParse(dateString);
    }

    // الترجمات
    List<Translation> translationsList = [];
    if (json['translations'] is List) {
      translationsList = (json['translations'] as List)
          .map((e) => Translation.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return SubcategoryLevelOne(
      id: parseInt(json['id']),
      categoryId: parseInt(json['category_id']),
      slug: json['slug'] as String? ?? '',
      date: parseDate(json['date'] as String?),
      adsCount: parseInt(json['ads_count']),
      translations: translationsList,
      categoryName: json['category_name'] as String? ?? '',
      image: json['image'] as String?, // قد تكون null
    );
  }

  String get name => translations.firstOrNull?.name ?? '';

  Map<String, dynamic> toJson() => {
        'id': id,
        'category_id': categoryId,
        'slug': slug,
        'date': date?.toIso8601String(),
        'ads_count': adsCount,
        'translations': translations.map((t) => t.toJson()).toList(),
        'category_name': categoryName,
        'image': image,
      };
}

class Translation {
  final int id;
  final int subCategoryLevelOneId;
  final String language;
  final String name;

  Translation({
    required this.id,
    required this.subCategoryLevelOneId,
    required this.language,
    required this.name,
  });

  factory Translation.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value == null) return 0;
      return int.tryParse(value.toString()) ?? 0;
    }

    return Translation(
      id: parseInt(json['id']),
      subCategoryLevelOneId: parseInt(json['sub_category_level_one_id']),
      language: json['language'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sub_category_level_one_id': subCategoryLevelOneId,
        'language': language,
        'name': name,
      };
}
