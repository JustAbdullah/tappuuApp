import 'package:collection/collection.dart'; // لاستخدام firstOrNull

class SubcategoryLevelTwo {
  final int id;
  final int subCategoryLevelOneId;
  final String slug;
  final String date; // كـ ISO string
  final int adsCount;
  final List<Translation> translations;
  final String parent1Name;
  final String parentCategoryName;
  final String? image; // ← الحقل الجديد (nullable)

  SubcategoryLevelTwo({
    required this.id,
    required this.subCategoryLevelOneId,
    required this.slug,
    required this.date,
    required this.adsCount,
    required this.translations,
    required this.parent1Name,
    required this.parentCategoryName,
    this.image,
  });

  factory SubcategoryLevelTwo.fromJson(Map<String, dynamic> json) {
    return SubcategoryLevelTwo(
      id: int.tryParse(json['id'].toString()) ?? 0,
      subCategoryLevelOneId: int.tryParse(json['sub_category_level_one_id'].toString()) ?? 0,
      slug: json['slug'] as String? ?? '',
      date: json['date'] as String? ?? '',
      adsCount: int.tryParse(json['ads_count']?.toString() ?? '0') ?? 0,
      translations: (json['translations'] as List? ?? [])
          .map((t) => Translation.fromJson(t as Map<String, dynamic>))
          .toList(),
      parent1Name: json['parent1_name'] as String? ?? '',
      parentCategoryName: json['parent_category_name'] as String? ?? '',
      image: json['image'] as String?, // ممكن null
    );
  }

  String get name => translations.firstOrNull?.name ?? '';

  Map<String, dynamic> toJson() => {
        'id': id,
        'sub_category_level_one_id': subCategoryLevelOneId,
        'slug': slug,
        'date': date,
        'ads_count': adsCount,
        'translations': translations.map((t) => t.toJson()).toList(),
        'parent1_name': parent1Name,
        'parent_category_name': parentCategoryName,
        'image': image,
      };
}

class Translation {
  final int id;
  final int subCategoryLevelTwoId;
  final String language;
  final String name;

  Translation({
    required this.id,
    required this.subCategoryLevelTwoId,
    required this.language,
    required this.name,
  });

  factory Translation.fromJson(Map<String, dynamic> json) {
    return Translation(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      subCategoryLevelTwoId: int.tryParse(json['sub_category_level_two_id']?.toString() ?? '0') ?? 0,
      language: json['language'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sub_category_level_two_id': subCategoryLevelTwoId,
        'language': language,
        'name': name,
      };
}
