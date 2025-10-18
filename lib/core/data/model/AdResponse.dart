// ad_models.dart
// نماذج البيانات للـ Ads
// (محدّث: يدعم slug, meta_title, meta_description, premiumExpiresAt, packages
//  + دعم عضو الشركة company_member و company_member_id)

int? _nullableIntFromDynamic(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

double? _nullableDoubleFromDynamic(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

/// ==== دالة مساعدة لتحويل أي تمثيل للتاريخ إلى DateTime بشكل آمن ====
DateTime? _nullableDateTimeFromDynamic(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;

  if (v is int) {
    final value = v;
    // نميز بين ثوانٍ (~10 أرقام) وميلي ثانية (~13)
    if (value.abs() < 100000000000) {
      return DateTime.fromMillisecondsSinceEpoch(value * 1000);
    } else {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
  }
  if (v is double) {
    final asInt = v.toInt();
    if (asInt.abs() < 100000000000) {
      return DateTime.fromMillisecondsSinceEpoch(asInt * 1000);
    } else {
      return DateTime.fromMillisecondsSinceEpoch(asInt);
    }
  }
  if (v is String) {
    final parsed = DateTime.tryParse(v);
    if (parsed != null) return parsed;

    final digits = int.tryParse(v);
    if (digits != null) {
      if (digits.abs() < 100000000000) {
        return DateTime.fromMillisecondsSinceEpoch(digits * 1000);
      }
      return DateTime.fromMillisecondsSinceEpoch(digits);
    }

    try {
      return DateTime.parse(v.replaceFirst(' ', 'T'));
    } catch (_) {
      return null;
    }
  }
  return null;
}

class AdResponse {
  final int currentPage;
  final int perPage;
  final int total;
  final List<Ad> data;

  AdResponse({
    required this.currentPage,
    required this.perPage,
    required this.total,
    required this.data,
  });

  factory AdResponse.fromJson(Map<String, dynamic> json) {
    return AdResponse(
      currentPage: (json['current_page'] as int?) ?? (json['currentPage'] as int?) ?? 1,
      perPage: (json['per_page'] as int?) ?? (json['perPage'] as int?) ?? 15,
      total: (json['total'] as int?) ?? 0,
      data: (json['data'] as List<dynamic>?)
              ?.map((e) => Ad.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class Ad {
  final int id;
  final int userId;
  final int idAdvertiser;
  final bool is_premium;
  final int views;
  final String ad_number;

  // المحتوى
  final String title;
  final String description;

  // SEO / routing fields
  final String? slug;
  final String? meta_title;
  final String? meta_description;
  final String? status;

  final double? price;
  final double? latitude;
  final double? longitude;
  final int? areaId;

  // حقل جديد: معرّف عضو الشركة المرتبط بالإعلان
  final int? companyMemberId;

  final CategoryModel category;
  final SubCategoryModel subCategoryLevelOne;
  final SubCategoryModel? subCategoryLevelTwo;
  final City? city;
  final Advertiser advertiser;

  // علاقة عضو الشركة (اختيارية)
  final CompanyMember? companyMember;

  final List<String> images;
  final List<String> videos;

  final List<AttributeValue> attributes;
  final DateTime createdAt;

  // الحقول الإضافية (nullable)
  final int? inquirers_count;
  final int? favorites_count;
  final int? show_time;

  // كائن المنطقة (اختياري)
  final Area? area;

  // تاريخ انتهاء البريميوم (nullable)
  final DateTime? premiumExpiresAt;

  // باقات الإعلان
  final List<AdPackage> packages;

  Ad({
    required this.id,
    required this.userId,
    required this.idAdvertiser,
    required this.ad_number,
    required this.is_premium,
    required this.views,
    required this.title,
    required this.description,
    this.slug,
    this.meta_title,
    this.meta_description,
    this.price,
    this.latitude,
    this.longitude,
    this.areaId,
    this.status,
    this.companyMemberId,
    required this.category,
    required this.subCategoryLevelOne,
    this.subCategoryLevelTwo,
    this.city,
    required this.advertiser,
    this.companyMember,
    required this.images,
    required this.videos,
    required this.attributes,
    required this.createdAt,
    this.inquirers_count,
    this.favorites_count,
    this.area,
    this.premiumExpiresAt,
    required this.packages,
    this.show_time,
  });

  factory Ad.fromJson(Map<String, dynamic> json) {
    // بناء آمن لكائن Area من عدة صيغ محتملة
    Area? parseArea(Map<String, dynamic> src) => Area.fromJson(src);

    Area? areaResult;
    if (json['area'] is Map<String, dynamic>) {
      areaResult = parseArea(json['area'] as Map<String, dynamic>);
    } else {
      final dynamic areaNameRaw =
          json['area_name'] ?? json['areaName'] ?? (json['area'] is Map ? json['area']['name'] : null);
      final dynamic areaIdRaw =
          json['area_id'] ?? json['areaId'] ?? (json['area'] is Map ? json['area']['id'] : null);

      final int? parsedAreaId = _nullableIntFromDynamic(areaIdRaw);
      final String? parsedAreaName = areaNameRaw != null ? areaNameRaw.toString() : null;

      if (parsedAreaId != null || (parsedAreaName != null && parsedAreaName.isNotEmpty)) {
        areaResult = Area(id: parsedAreaId, name: parsedAreaName);
      } else {
        areaResult = null;
      }
    }

    // parse packages
    List<AdPackage> packagesList = [];
    final rawPackages = json['packages'] ?? json['packages_list'] ?? json['ad_packages'];
    if (rawPackages is List) {
      packagesList = rawPackages.map((e) {
        try {
          return AdPackage.fromJson(e as Map<String, dynamic>);
        } catch (_) {
          if (e is Map<String, dynamic>) return AdPackage.fromJson(e);
          return AdPackage.empty();
        }
      }).whereType<AdPackage>().toList();
    }

    // parse company member (اختياري)
    CompanyMember? cm;
    final dynamic rawCM = json['company_member'] ?? json['companyMember'];
    if (rawCM is Map<String, dynamic>) {
      cm = CompanyMember.fromJson(rawCM);
    }

    return Ad(
      id: (json['id'] as int?) ?? _nullableIntFromDynamic(json['id']) ?? 0,
      userId: (json['user_id'] as int?) ?? _nullableIntFromDynamic(json['user_id']) ?? 0,
      ad_number: (json['ad_number']?.toString()) ?? "0",
      idAdvertiser: (json['advertiser_profile_id'] as int?) ??
          _nullableIntFromDynamic(json['advertiser_profile_id']) ??
          0,
      is_premium: (json['is_premium'] as bool?) ??
          (json['is_premium'] is num ? (json['is_premium'] == 1) : false),
      views: (json['views'] as int?) ?? _nullableIntFromDynamic(json['views']) ?? 0,
      title: (json['title'] as String?) ?? '',
      status: (json['status'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',

      slug: (json['slug'] as String?) ?? json['slug']?.toString(),
      meta_title: (json['meta_title'] as String?) ?? json['metaTitle']?.toString(),
      meta_description: (json['meta_description'] as String?) ?? json['metaDescription']?.toString(),

      price: _nullableDoubleFromDynamic(json['price']),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      areaId: json['area_id'] != null ? _nullableIntFromDynamic(json['area_id']) : null,

      companyMemberId: _nullableIntFromDynamic(json['company_member_id'] ?? json['companyMemberId']),

      category: json['category'] != null
          ? CategoryModel.fromJson(json['category'] as Map<String, dynamic>)
          : CategoryModel(id: 0, name: ''),
      subCategoryLevelOne: json['sub_category_level_one'] != null
          ? SubCategoryModel.fromJson(json['sub_category_level_one'] as Map<String, dynamic>)
          : SubCategoryModel(id: 0, name: ''),
      subCategoryLevelTwo: json['sub_category_level_two'] != null
          ? SubCategoryModel.fromJson(json['sub_category_level_two'] as Map<String, dynamic>)
          : null,
      city: json['city'] != null ? City.fromJson(json['city'] as Map<String, dynamic>) : null,
      advertiser: json['advertiser'] != null
          ? Advertiser.fromJson(json['advertiser'] as Map<String, dynamic>)
          : Advertiser(
              description: '',
              logo: '',
              contactPhone: '',
              whatsappPhone: '',
            ),

      companyMember: cm,

      images: (json['images'] as List<dynamic>?)?.map((e) => e?.toString() ?? '').toList() ?? [],
      videos: (json['videos'] as List<dynamic>?)?.map((e) => e?.toString() ?? '').toList() ?? [],

      attributes: (json['attributes'] as List<dynamic>?)
              ?.map((e) => AttributeValue.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: _nullableDateTimeFromDynamic(json['created_at'] ?? json['createdAt']) ??
          DateTime.now(),

      inquirers_count:
          _nullableIntFromDynamic(json['inquirers_count'] ?? json['inquirersCount']),
      favorites_count:
          _nullableIntFromDynamic(json['favorites_count'] ?? json['favoritesCount']),

      area: areaResult,
      premiumExpiresAt: _nullableDateTimeFromDynamic(
        json['premium_expires_at'] ?? json['premiumExpiresAt'] ?? json['premium_expires'],
      ),
      packages: packagesList,
      show_time: (json['show_time'] as int?) ?? _nullableIntFromDynamic(json['show_time']) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'advertiser_profile_id': idAdvertiser,
      'ad_number': ad_number,
      'is_premium': is_premium,
      'views': views,
      'title': title,
      'description': description,
      'slug': slug,
      'meta_title': meta_title,
      'meta_description': meta_description,
      'price': price,
      'latitude': latitude,
      'longitude': longitude,
      'area_id': areaId,
      'status': status,
      'company_member_id': companyMemberId,
      'category': {'id': category.id, 'name': category.name},
      'sub_category_level_one': {
        'id': subCategoryLevelOne.id,
        'name': subCategoryLevelOne.name
      },
      'sub_category_level_two': subCategoryLevelTwo != null
          ? {'id': subCategoryLevelTwo!.id, 'name': subCategoryLevelTwo!.name}
          : null,
      'city': city != null ? {'id': city!.id, 'slug': city!.slug, 'name': city!.name} : null,
      'advertiser': {
        'name': advertiser.name,
        'description': advertiser.description,
        'logo': advertiser.logo,
        'contact_phone': advertiser.contactPhone,
        'whatsapp_phone': advertiser.whatsappPhone,
        'account_type': advertiser.accountType,
        'created_at': advertiser.createdAt?.toIso8601String(),
      },
      'company_member': companyMember?.toJson(),
      'images': images,
      'videos': videos,
      'attributes': attributes.map((a) => {'name': a.name, 'value': a.value}).toList(),
      'created_at': createdAt.toIso8601String(),
      'inquirers_count': inquirers_count,
      'favorites_count': favorites_count,
      'area': area?.toJson(),
      'premium_expires_at': premiumExpiresAt?.toIso8601String(),
      'packages': packages.map((p) => p.toJson()).toList(),
      'show_time': show_time,
    };
  }
}

/// نموذج عضو الشركة (company_members)
class CompanyMember {
  final int id;
  final int advertiserProfileId;
  final int userId;
  final String role; // 'owner' | 'publisher' | 'viewer'
  final String displayName;
  final String? contactPhone;
  final String? whatsappPhone;
  final String? whatsappCallNumber;
  final String status; // 'active' | 'removed'

  CompanyMember({
    required this.id,
    required this.advertiserProfileId,
    required this.userId,
    required this.role,
    required this.displayName,
    this.contactPhone,
    this.whatsappPhone,
    this.whatsappCallNumber,
    required this.status,
  });

  factory CompanyMember.fromJson(Map<String, dynamic> json) {
    return CompanyMember(
      id: (json['id'] as int?) ?? _nullableIntFromDynamic(json['id']) ?? 0,
      advertiserProfileId: (json['advertiser_profile_id'] as int?) ??
          _nullableIntFromDynamic(json['advertiser_profile_id']) ??
          0,
      userId: (json['user_id'] as int?) ?? _nullableIntFromDynamic(json['user_id']) ?? 0,
      role: (json['role'] as String?) ?? '',
      displayName: (json['display_name'] as String?) ?? '',
      contactPhone: (json['contact_phone'] as String?) ?? json['contactPhone'] as String?,
      whatsappPhone:
          (json['whatsapp_phone'] as String?) ?? json['whatsappPhone'] as String?,
      whatsappCallNumber: (json['whatsapp_call_number'] as String?) ??
          json['whatsappCallNumber'] as String?,
      status: (json['status'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'advertiser_profile_id': advertiserProfileId,
        'user_id': userId,
        'role': role,
        'display_name': displayName,
        'contact_phone': contactPhone,
        'whatsapp_phone': whatsappPhone,
        'whatsapp_call_number': whatsappCallNumber,
        'status': status,
      };
}

/// نموذج الباقة المرتبطة بالإعلان (ad_packages)
class AdPackage {
  final int id;
  final int adId;
  final int premiumPackageId;
  final int? userId;
  final DateTime? startedAt;
  final DateTime? expiresAt;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  final PremiumPackage? premiumPackage; // relation to premium_packages (may be null)

  AdPackage({
    required this.id,
    required this.adId,
    required this.premiumPackageId,
    this.userId,
    this.startedAt,
    this.expiresAt,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
    this.premiumPackage,
  });

  factory AdPackage.fromJson(Map<String, dynamic> json) {
    PremiumPackage? pp;
    if (json['premium_package'] is Map<String, dynamic>) {
      pp = PremiumPackage.fromJson(json['premium_package'] as Map<String, dynamic>);
    } else if (json['premium_package'] is Map) {
      pp = PremiumPackage.fromJson(Map<String, dynamic>.from(json['premium_package'] as Map));
    } else {
      pp = null;
    }

    return AdPackage(
      id: (json['id'] as int?) ?? _nullableIntFromDynamic(json['id']) ?? 0,
      adId: (json['ad_id'] as int?) ?? _nullableIntFromDynamic(json['ad_id']) ?? 0,
      premiumPackageId:
          (json['premium_package_id'] as int?) ?? _nullableIntFromDynamic(json['premium_package_id']) ?? 0,
      userId: _nullableIntFromDynamic(json['user_id']),
      startedAt: _nullableDateTimeFromDynamic(json['started_at'] ?? json['startedAt']),
      expiresAt: _nullableDateTimeFromDynamic(json['expires_at'] ?? json['expiresAt']),
      isActive: (json['is_active'] as bool?) ??
          (json['isActive'] as bool?) ??
          (json['is_active'] is num ? (json['is_active'] == 1) : false),
      createdAt: _nullableDateTimeFromDynamic(json['created_at'] ?? json['createdAt']),
      updatedAt: _nullableDateTimeFromDynamic(json['updated_at'] ?? json['updatedAt']),
      premiumPackage: pp,
    );
  }

  AdPackage.empty()
      : id = 0,
        adId = 0,
        premiumPackageId = 0,
        userId = null,
        startedAt = null,
        expiresAt = null,
        isActive = false,
        createdAt = null,
        updatedAt = null,
        premiumPackage = null;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ad_id': adId,
      'premium_package_id': premiumPackageId,
      'user_id': userId,
      'started_at': startedAt?.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'premium_package': premiumPackage?.toJson(),
    };
  }
}

/// نموذج الباقة الفعلية (premium_packages)
class PremiumPackage {
  final int id;
  final String? name;
  final String? slug;
  final String? description;
  final int? durationDays;
  final double? price;
  final String? currency;
  final bool? isActive;
  final int? sortOrder;
  final int? packageTypeId;

  final PackageType? type; // relation to package_types

  PremiumPackage({
    required this.id,
    this.name,
    this.slug,
    this.description,
    this.durationDays,
    this.price,
    this.currency,
    this.isActive,
    this.sortOrder,
    this.packageTypeId,
    this.type,
  });

  factory PremiumPackage.fromJson(Map<String, dynamic> json) {
    PackageType? pt;
    if (json['type'] is Map<String, dynamic>) {
      pt = PackageType.fromJson(json['type'] as Map<String, dynamic>);
    } else if (json['package_type'] is Map<String, dynamic>) {
      pt = PackageType.fromJson(json['package_type'] as Map<String, dynamic>);
    } else {
      pt = null;
    }

    return PremiumPackage(
      id: (json['id'] as int?) ?? _nullableIntFromDynamic(json['id']) ?? 0,
      name: (json['name'] as String?) ?? json['title'] as String?,
      slug: (json['slug'] as String?) ?? null,
      description: (json['description'] as String?) ?? null,
      durationDays: _nullableIntFromDynamic(json['duration_days'] ?? json['durationDays']),
      price: _nullableDoubleFromDynamic(json['price']),
      currency: (json['currency'] as String?) ?? null,
      isActive: (json['is_active'] as bool?) ?? (json['isActive'] as bool?),
      sortOrder: _nullableIntFromDynamic(json['sort_order'] ?? json['sortOrder']),
      packageTypeId: _nullableIntFromDynamic(json['package_type_id'] ?? json['packageTypeId']),
      type: pt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'duration_days': durationDays,
      'price': price,
      'currency': currency,
      'is_active': isActive,
      'sort_order': sortOrder,
      'package_type_id': packageTypeId,
      'type': type?.toJson(),
    };
  }
}

/// نموذج نوع الباقة (package_types)
class PackageType {
  final int id;
  final String? name;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PackageType({
    required this.id,
    this.name,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  factory PackageType.fromJson(Map<String, dynamic> json) {
    return PackageType(
      id: (json['id'] as int?) ?? _nullableIntFromDynamic(json['id']) ?? 0,
      name: (json['name'] as String?) ?? null,
      description: (json['description'] as String?) ?? null,
      createdAt: _nullableDateTimeFromDynamic(json['created_at'] ?? json['createdAt']),
      updatedAt: _nullableDateTimeFromDynamic(json['updated_at'] ?? json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

/* ---------- النماذج المساعدة المتبقية ---------- */

class CategoryModel {
  final int id;
  final String name;

  CategoryModel({
    required this.id,
    required this.name,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: (json['id'] as int?) ?? _nullableIntFromDynamic(json['id']) ?? 0,
      name: (json['name'] as String?) ?? '',
    );
  }
}

class SubCategoryModel {
  final int id;
  final String name;

  SubCategoryModel({
    required this.id,
    required this.name,
  });

  factory SubCategoryModel.fromJson(Map<String, dynamic> json) {
    return SubCategoryModel(
      id: (json['id'] as int?) ?? _nullableIntFromDynamic(json['id']) ?? 0,
      name: (json['name'] as String?) ?? '',
    );
  }
}

class City {
  final int id;
  final String slug;
  final String name;

  City({
    required this.id,
    required this.slug,
    required this.name,
  });

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: (json['id'] as int?) ?? _nullableIntFromDynamic(json['id']) ?? 0,
      slug: (json['slug'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'slug': slug,
        'name': name,
      };
}

class Advertiser {
  final String? name;
  final String description;
  final String logo;
  final String contactPhone;
  final String whatsappPhone;
  final String accountType; // 'individual' or 'company'
  final DateTime? createdAt;

  static const String TYPE_INDIVIDUAL = 'individual';
  static const String TYPE_COMPANY = 'company';

  Advertiser({
    this.name,
    required this.description,
    required this.logo,
    required this.contactPhone,
    required this.whatsappPhone,
    this.createdAt,
    String? accountType,
  }) : accountType = (accountType == null || accountType.isEmpty) ? TYPE_INDIVIDUAL : accountType;

  factory Advertiser.fromJson(Map<String, dynamic> json) {
    return Advertiser(
      name: json['name'] as String?,
      description: (json['description'] as String?) ?? '',
      logo: (json['logo'] as String?) ?? '',
      contactPhone:
          (json['contact_phone'] as String?) ?? (json['contactPhone'] as String?) ?? '',
      whatsappPhone:
          (json['whatsapp_phone'] as String?) ?? (json['whatsappPhone'] as String?) ?? '',
      accountType:
          (json['account_type'] ?? json['accountType'] ?? TYPE_INDIVIDUAL).toString(),
      createdAt:
          _nullableDateTimeFromDynamic(json['created_at'] ?? json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'logo': logo,
      'contact_phone': contactPhone,
      'whatsapp_phone': whatsappPhone,
      'account_type': accountType,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

class AttributeValue {
  final String name;
  final String value;

  AttributeValue({
    required this.name,
    required this.value,
  });

  factory AttributeValue.fromJson(Map<String, dynamic> json) {
    return AttributeValue(
      name: (json['name'] as String?) ?? '',
      value: (json['value'] as String?) ?? '',
    );
  }
}

/// نموذج المنطقة (area)
class Area {
  final int? id;
  final String? name;

  Area({this.id, this.name});

  factory Area.fromJson(Map<String, dynamic> json) {
    final int? id =
        _nullableIntFromDynamic(json['id'] ?? json['area_id'] ?? json['areaId']);
    final String? name =
        (json['name'] ?? json['area_name'] ?? json['areaName'])?.toString();
    if (id == null && (name == null || name.isEmpty)) {
      return Area(id: null, name: null);
    }
    return Area(id: id, name: name);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };
}
