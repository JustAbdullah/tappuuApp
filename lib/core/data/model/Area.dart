// lib/core/data/model/area.dart
class Area {
  final int id;
  final int cityId;
  final String name;
  final String? cityName; // اسم المدينة (بالعربي إذا موجود)، قد يكون null
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Area({
    required this.id,
    required this.cityId,
    required this.name,
    this.cityName,
    this.createdAt,
    this.updatedAt,
  });

  /// يحاول استخراج تاريخ من أي قيمة قد تأتي من الـ JSON
  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }

  /// منشئ من JSON — يدعم أشكال متعددة لحقول المدينة
  factory Area.fromJson(Map<String, dynamic> json) {
    // cityName ممكن يجي داخل كائن city: { id, name }
    String? resolvedCityName;
    if (json['city'] != null) {
      final city = json['city'];
      if (city is Map && city['name'] != null) {
        resolvedCityName = city['name'].toString();
      }
    }

    // أو ممكن يجي مباشرة كـ city_name أو cityName
    resolvedCityName ??= json['city_name']?.toString();
    resolvedCityName ??= json['cityName']?.toString();
    resolvedCityName ??= json['city_name_ar']?.toString(); // fallback محتمل

    return Area(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      cityId: json['city_id'] is int
          ? json['city_id']
          : int.parse(json['city_id'].toString()),
      name: json['name']?.toString() ?? '',
      cityName: resolvedCityName,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'city_id': cityId,
        'name': name,
        'city_name': cityName,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  @override
  String toString() =>
      'Area(id: $id, cityId: $cityId, cityName: ${cityName ?? "—"}, name: $name)';
}
