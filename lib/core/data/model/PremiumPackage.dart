class PremiumPackage {
  int? id;
  String name;
  String? slug;
  String? description;
  int durationDays;
  double price;
  String currency;
  bool isActive;
  int sortOrder;
  int packageTypeId;
  PackageType? type;

  PremiumPackage({
    this.id,
    required this.name,
    this.slug,
    this.description,
    required this.durationDays,
    required this.price,
    this.currency = 'SYP',
    this.isActive = false,
    this.sortOrder = 0,
    required this.packageTypeId,
    this.type,
  });

  factory PremiumPackage.fromJson(Map<String, dynamic> json) {
    return PremiumPackage(
      id: json['id'] as int?,
      name: json['name'] ?? '',
      slug: json['slug'],
      description: json['description'],
      durationDays: (json['duration_days'] ?? 0) is int 
          ? json['duration_days'] 
          : int.parse((json['duration_days'] ?? 0).toString()),
      price: (json['price'] != null) 
          ? double.parse(json['price'].toString()) 
          : 0.0,
      currency: json['currency'] ?? 'SYP',
      isActive: (json['is_active'] == 1 || json['is_active'] == true),
      sortOrder: json['sort_order'] ?? 0,
      packageTypeId: json['package_type_id'] ?? 0,
      type: json['type'] != null 
          ? PackageType.fromJson(json['type']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'duration_days': durationDays,
      'price': price,
      'currency': currency,
      'is_active': isActive ? 1 : 0,
      'sort_order': sortOrder,
      'package_type_id': packageTypeId,
      if (type != null) 'type': type!.toJson(),
    };
  }
}

class PackageType {
  int id;
  String name;
  String description;
  String createdAt;
  String updatedAt;

  PackageType({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PackageType.fromJson(Map<String, dynamic> json) {
    return PackageType(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}