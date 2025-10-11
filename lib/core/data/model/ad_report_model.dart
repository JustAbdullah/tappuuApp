import 'dart:convert';

class UserShortModel {
  final int id;
  final String? email;

  UserShortModel({required this.id, this.email});

  factory UserShortModel.fromJson(Map<String, dynamic> json) {
    return UserShortModel(
      id: (json['id'] as int?) ?? 0,
      email: json['email'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
    };
  }
}

class AdImageModel {
  final int? id;
  final String? imageUrl;

  AdImageModel({this.id, this.imageUrl});

  factory AdImageModel.fromJson(Map<String, dynamic> json) {
    return AdImageModel(
      id: (json['id'] as int?) ?? 0,
      imageUrl: json['image_url'] as String? ?? json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image_url': imageUrl,
    };
  }
}

class AdvertiserModel {
  final String? name;
  final String? description;
  final String? logo;
  final String? contactPhone;
  final String? whatsappPhone;
  final String? accountType;

  AdvertiserModel({
    this.name,
    this.description,
    this.logo,
    this.contactPhone,
    this.whatsappPhone,
    this.accountType,
  });

  factory AdvertiserModel.fromJson(Map<String, dynamic> json) {
    return AdvertiserModel(
      name: json['name'] as String?,
      description: json['description'] as String?,
      logo: json['logo'] as String?,
      contactPhone: json['contact_phone'] as String?,
      whatsappPhone: json['whatsapp_phone'] as String?,
      accountType: json['account_type'] as String?,
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
    };
  }
}

class AttributeModel {
  final String? name;
  final dynamic value;

  AttributeModel({this.name, this.value});

  factory AttributeModel.fromJson(Map<String, dynamic> json) {
    return AttributeModel(
      name: json['name'] as String?,
      value: json['value'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
    };
  }
}

class AdModel {
  final int id;
  final String? slug;
  final String? metaTitle;
  final String? metaDescription;
  final UserShortModel? user;
  final dynamic advertiserProfileId;
  final String? title;
  final String? description;
  final dynamic price;
  final String? adNumber;
  final double? latitude;
  final double? longitude;
  final bool isPremium;
  final String? premiumExpiresAt;
  final int? views;
  final String? status;
  final Map<String, dynamic>? category;
  final Map<String, dynamic>? subCategoryOne;
  final Map<String, dynamic>? subCategoryTwo;
  final Map<String, dynamic>? city;
  final Map<String, dynamic>? area;
  final AdvertiserModel? advertiser;
  final List<AdImageModel> images;
  final List<String> videos;
  final List<AttributeModel> attributes;
  final String? createdAt;

  AdModel({
    required this.id,
    this.slug,
    this.metaTitle,
    this.metaDescription,
    this.user,
    this.advertiserProfileId,
    this.title,
    this.description,
    this.price,
    this.adNumber,
    this.latitude,
    this.longitude,
    this.isPremium = false,
    this.premiumExpiresAt,
    this.views,
    this.status,
    this.category,
    this.subCategoryOne,
    this.subCategoryTwo,
    this.city,
    this.area,
    this.advertiser,
    this.images = const [],
    this.videos = const [],
    this.attributes = const [],
    this.createdAt,
  });

  factory AdModel.fromJson(Map<String, dynamic> json, {String lang = 'ar'}) {
    // parse images
    List<AdImageModel> imgs = [];
    try {
      if (json['images'] is List) {
        imgs = (json['images'] as List)
            .where((e) => e != null)
            .map((e) => AdImageModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      print('Error parsing images: $e');
    }

    // videos may be list of urls
    List<String> vids = [];
    try {
      if (json['videos'] is List) {
        vids = (json['videos'] as List).map((e) => e.toString()).toList();
      }
    } catch (e) {
      print('Error parsing videos: $e');
    }

    // attributes
    List<AttributeModel> attrs = [];
    try {
      if (json['attributes'] is List) {
        attrs = (json['attributes'] as List)
            .map((e) => AttributeModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      print('Error parsing attributes: $e');
    }

    // category translations object may be present as translations list; we just accept what backend returns
    Map<String, dynamic>? category;
    try {
      if (json['category'] != null) {
        category = {
          'id': json['category']['id'] ?? json['category_id'],
          'name': json['category']['name'] ?? json['category_name'] ?? null,
        };
      }
    } catch (e) {
      print('Error parsing category: $e');
    }

    return AdModel(
      id: (json['id'] as int?) ?? 0,
      slug: json['slug'] as String?,
      metaTitle: json['meta_title'] as String?,
      metaDescription: json['meta_description'] as String?,
      user: json['user'] != null ? UserShortModel.fromJson(json['user']) : null,
      advertiserProfileId: json['advertiser_profile_id'],
      title: json['title'] as String? ?? json['title_ar'] as String? ?? json['title_en'] as String?,
      description: json['description'] as String? ?? json['description_ar'] as String? ?? json['description_en'] as String?,
      price: json['price'],
      adNumber: json['ad_number']?.toString(),
      latitude: json['latitude'] != null ? (double.tryParse(json['latitude'].toString())) : null,
      longitude: json['longitude'] != null ? (double.tryParse(json['longitude'].toString())) : null,
      isPremium: (json['is_premium'] == 1 || json['is_premium'] == true),
      premiumExpiresAt: json['premium_expires_at']?.toString(),
      views: json['views'] is int ? json['views'] as int : int.tryParse(json['views']?.toString() ?? ''),
      status: json['status'] as String?,
      category: category,
      subCategoryOne: json['sub_category_level_one'] is Map ? Map<String, dynamic>.from(json['sub_category_level_one']) : null,
      subCategoryTwo: json['sub_category_level_two'] is Map ? Map<String, dynamic>.from(json['sub_category_level_two']) : null,
      city: json['city'] is Map ? Map<String, dynamic>.from(json['city']) : null,
      area: json['area'] is Map ? Map<String, dynamic>.from(json['area']) : null,
      advertiser: json['advertiser'] != null ? AdvertiserModel.fromJson(json['advertiser']) : null,
      images: imgs,
      videos: vids,
      attributes: attrs,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson({String lang = 'ar'}) {
    return {
      'id': id,
      'slug': slug,
      'meta_title': metaTitle,
      'meta_description': metaDescription,
      'user': user?.toJson(),
      'advertiser_profile_id': advertiserProfileId,
      'title': title,
      'description': description,
      'price': price,
      'ad_number': adNumber,
      'latitude': latitude,
      'longitude': longitude,
      'is_premium': isPremium,
      'premium_expires_at': premiumExpiresAt,
      'views': views,
      'status': status,
      'category': category,
      'sub_category_level_one': subCategoryOne,
      'sub_category_level_two': subCategoryTwo,
      'city': city,
      'area': area,
      'advertiser': advertiser?.toJson(),
      'images': images.map((e) => e.toJson()).toList(),
      'videos': videos,
      'attributes': attributes.map((e) => e.toJson()).toList(),
      'created_at': createdAt,
    };
  }
}

class AdReportModel {
  final int id;
  final String? reason;
  final String? details;
  final List<String> evidence;
  final String? status;
  final bool isAnonymous;
  final DateTime? date;
  final DateTime? handledAt;
  final UserShortModel? handledBy;
  final UserShortModel? reporter;
  final AdModel? ad;

  AdReportModel({
    required this.id,
    this.reason,
    this.details,
    this.evidence = const [],
    this.status,
    this.isAnonymous = false,
    this.date,
    this.handledAt,
    this.handledBy,
    this.reporter,
    this.ad,
  });

  factory AdReportModel.fromJson(Map<String, dynamic> json, {String lang = 'ar'}) {
    // evidence might be array or json string
    List<String> ev = [];
    try {
      if (json['evidence'] is List) {
        ev = (json['evidence'] as List).map((e) => e.toString()).toList();
      } else if (json['evidence'] is String) {
        try {
          final parsed = jsonDecode(json['evidence']);
          if (parsed is List) ev = parsed.map((e) => e.toString()).toList();
        } catch (_) {
          // ignore
        }
      }
    } catch (e) {
      print('Error parsing evidence: $e');
    }

    // Parse dates safely
    DateTime? parseDate(dynamic dateValue) {
      if (dateValue == null) return null;
      try {
        return DateTime.tryParse(dateValue.toString());
      } catch (e) {
        print('Error parsing date: $e');
        return null;
      }
    }

    return AdReportModel(
      id: (json['id'] as int?) ?? 0,
      reason: json['reason'] as String?,
      details: json['details'] as String?,
      evidence: ev,
      status: json['status'] as String?,
      isAnonymous: (json['is_anonymous'] == 1 || json['is_anonymous'] == true),
      date: parseDate(json['date']),
      handledAt: parseDate(json['handled_at']),
      handledBy: json['handled_by'] != null && json['handled_by'] is Map 
          ? UserShortModel.fromJson(json['handled_by'] as Map<String, dynamic>) 
          : null,
      reporter: json['reporter'] != null && json['reporter'] is Map 
          ? UserShortModel.fromJson(json['reporter'] as Map<String, dynamic>) 
          : null,
      ad: json['ad'] != null && json['ad'] is Map 
          ? AdModel.fromJson(json['ad'] as Map<String, dynamic>, lang: lang) 
          : null,
    );
  }

  Map<String, dynamic> toJson({String lang = 'ar'}) {
    return {
      'id': id,
      'reason': reason,
      'details': details,
      'evidence': evidence,
      'status': status,
      'is_anonymous': isAnonymous,
      'date': date?.toIso8601String(),
      'handled_at': handledAt?.toIso8601String(),
      'handled_by': handledBy?.toJson(),
      'reporter': reporter?.toJson(),
      'ad': ad?.toJson(lang: lang),
    };
  }
}