class TheCity {
  int id;
  String slug;
  String country;
  String createdAt;
  String updatedAt;
  List<Translation> translations;

  TheCity({
    required this.id,
    required this.slug,
    required this.country,
    required this.createdAt,
    required this.updatedAt,
    required this.translations,
  });

  factory TheCity.fromJson(Map<String, dynamic> json) {
    return TheCity(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      slug: json['slug']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
      translations: (json['translations'] as List<dynamic>?)
          ?.map((t) => Translation.fromJson(t))
          .toList() ?? [],
    );
  }
}

class Translation {
  int id;
  int cityId;
  String language;
  String name;

  Translation({
    required this.id,
    required this.cityId,
    required this.language,
    required this.name,
  });

  factory Translation.fromJson(Map<String, dynamic> json) {
    return Translation(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      cityId: int.tryParse(json['city_id']?.toString() ?? '') ?? 0,
      language: json['language']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}