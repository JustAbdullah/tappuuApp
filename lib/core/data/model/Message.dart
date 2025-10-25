// message.dart

class Message {
  final int id;
  final int senderId;
  final String? senderEmail;
  final int recipientId;
  final String? recipientEmail;
  final String? body;
  final bool isVoice;
  final String? voiceUrl;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;
  final DateTime? updatedAt;

  // advertisement (may be null)
  final int adId;
  final String adNumber;
  final String adTitleAr;
  final String adTitleEn;
  final String adSlug;
  final String adDescriptionAr;
  final String adDescriptionEn;
  final double adPrice;
  final bool adShowTime;
  final DateTime? adCreatedAt;
  final List<String> adImages;

  /// بيانات عضو الشركة المرتبط بالإعلان (إن وُجد)
  final CompanyMemberMessage? adCompanyMember;

  // advertiser profile
  final int advertiserProfileId;
  final int advertiserUserId;
  final String advertiserName;
  final String advertiserLogo;
  final String? advertiserDescription;
  final String? advertiserContactPhone;
  final String? advertiserWhatsappPhone;
  final String? advertiserWhatsappCallNumber;
  final String? advertiserWhatsappUrl; // generated
  final String? advertiserTelUrl; // generated
  final double? advertiserLatitude;
  final double? advertiserLongitude;

  Message({
    required this.id,
    required this.senderId,
    this.senderEmail,
    required this.recipientId,
    this.recipientEmail,
    this.body,
    required this.isVoice,
    this.voiceUrl,
    required this.isRead,
    required this.createdAt,
    this.readAt,
    this.updatedAt,
    required this.adId,
    required this.adNumber,
    required this.adTitleAr,
    required this.adTitleEn,
    required this.adSlug,
    required this.adDescriptionAr,
    required this.adDescriptionEn,
    required this.adPrice,
    required this.adShowTime,
    this.adCreatedAt,
    required this.adImages,
    this.adCompanyMember,
    required this.advertiserProfileId,
    required this.advertiserUserId,
    required this.advertiserName,
    required this.advertiserLogo,
    this.advertiserDescription,
    this.advertiserContactPhone,
    this.advertiserWhatsappPhone,
    this.advertiserWhatsappCallNumber,
    this.advertiserWhatsappUrl,
    this.advertiserTelUrl,
    this.advertiserLatitude,
    this.advertiserLongitude,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    // ---------- ad ----------
    Map<String, dynamic> adMap = {};
    if (json['ad'] is Map<String, dynamic>) {
      adMap = json['ad'] as Map<String, dynamic>;
    }

    // fallback top-level fields
    final int topAdId = Message.parseInt(json['ad_id']);
    final String topAdTitle = (json['ad_title']?.toString() ?? '');
    final double topAdPrice = Message.parseDouble(json['ad_price']);

    final int adId = adMap.isNotEmpty ? Message.parseInt(adMap['id']) : (topAdId != 0 ? topAdId : 0);
    final String adNumber = adMap['ad_number']?.toString() ?? (json['ad_number']?.toString() ?? '');
    final String adTitleAr = adMap['title_ar']?.toString() ?? topAdTitle;
    final String adTitleEn = adMap['title_en']?.toString() ?? (json['title_en']?.toString() ?? '');
    final String adSlug = adMap['slug']?.toString() ?? (json['slug']?.toString() ?? '');
    final String adDescAr = adMap['description_ar']?.toString() ?? (json['description_ar']?.toString() ?? '');
    final String adDescEn = adMap['description_en']?.toString() ?? (json['description_en']?.toString() ?? '');
    final double adPrice = adMap.isNotEmpty ? Message.parseDouble(adMap['price']) : topAdPrice;
    final bool adShowTime = adMap['show_time'] != null ? Message.parseBool(adMap['show_time']) : Message.parseBool(json['show_time']);

    DateTime? adCreatedAt;
    try {
      final created = adMap['created_at'] ?? json['ad_created_at'] ?? json['created_at'];
      if (created != null) {
        adCreatedAt = Message.parseDateTime(created);
      }
    } catch (_) {
      adCreatedAt = null;
    }

    // ad images
    List<String> adImages = [];
    try {
      if (adMap['images'] is List) {
        adImages = List<String>.from((adMap['images'] as List).map((e) {
          if (e is Map && e.containsKey('image_url')) return e['image_url'].toString();
          return e.toString();
        }));
      } else if (json['ad_images'] is List) {
        adImages = List<String>.from((json['ad_images'] as List).map((e) => e.toString()));
      } else if (json['ad'] is Map && (json['ad']['images'] is List)) {
        adImages = List<String>.from((json['ad']['images'] as List).map((e) {
          if (e is Map && e.containsKey('image_url')) return e['image_url'].toString();
          return e.toString();
        }));
      }
    } catch (_) {
      adImages = [];
    }

    // --------- company_member داخل ad (إن وُجد) ----------
    CompanyMemberMessage? adCompanyMember;
    try {
      if (adMap['company_member'] is Map<String, dynamic>) {
        adCompanyMember = CompanyMemberMessage.fromJson(adMap['company_member'] as Map<String, dynamic>);
      }
    } catch (_) {
      adCompanyMember = null;
    }

    // ---------- advertiser_profile ----------
    Map<String, dynamic> advMap = {};
    if (json['advertiser_profile'] is Map<String, dynamic>) {
      advMap = json['advertiser_profile'] as Map<String, dynamic>;
    } else if (json['advertiser'] is Map<String, dynamic>) {
      advMap = json['advertiser'] as Map<String, dynamic>;
    } else {
      advMap = {
        'id': json['advertiser_profile_id'] ?? json['advertiser_id'],
        'user_id': json['advertiser_user_id'] ?? json['advertiser_user'],
        'name': json['advertiser_name'] ?? json['advertiser_profile_name'],
        'logo': json['advertiser_logo'] ?? json['advertiser_profile_logo'],
        'description': json['advertiser_description'] ?? json['advertiser_profile_description'],
        'contact_phone': json['advertiser_contact_phone'] ?? json['contact_phone'],
        'whatsapp_phone': json['advertiser_whatsapp_phone'] ?? json['whatsapp_phone'],
        'whatsapp_call_number': json['advertiser_whatsapp_call_number'] ?? json['whatsapp_call_number'],
        'latitude': json['advertiser_latitude'] ?? json['latitude'],
        'longitude': json['advertiser_longitude'] ?? json['longitude'],
      };
    }

    final advertiserId = Message.parseInt(advMap['id']);
    final advertiserUserId = Message.parseInt(advMap['user_id']);
    final advertiserName = advMap['name']?.toString() ?? '';
    final advertiserLogo = advMap['logo']?.toString() ?? '';
    final advertiserDescription = advMap['description']?.toString();
    final advertiserContactPhone = advMap['contact_phone']?.toString();
    final advertiserWhatsappPhone = advMap['whatsapp_phone']?.toString();
    final advertiserWhatsappCallNumber = advMap['whatsapp_call_number']?.toString();
    final advertiserLatitude = advMap['latitude'] != null ? double.tryParse(advMap['latitude'].toString()) : null;
    final advertiserLongitude = advMap['longitude'] != null ? double.tryParse(advMap['longitude'].toString()) : null;

    // روابط جاهزة
    String? whatsappUrl;
    if ((advertiserWhatsappPhone?.isNotEmpty ?? false)) {
      whatsappUrl = _buildWhatsAppUrl(advertiserWhatsappPhone!);
    } else if ((advertiserWhatsappCallNumber?.isNotEmpty ?? false)) {
      whatsappUrl = _buildWhatsAppUrl(advertiserWhatsappCallNumber!);
    }

    String? telUrl;
    if ((advertiserContactPhone?.isNotEmpty ?? false)) {
      telUrl = _buildTelUrl(advertiserContactPhone!);
    }

    return Message(
      id: Message.parseInt(json['id']),
      senderId: Message.parseInt(json['sender_id']),
      senderEmail: json['sender_email']?.toString(),
      recipientId: Message.parseInt(json['recipient_id']),
      recipientEmail: json['recipient_email']?.toString(),
      body: json['body']?.toString(),
      isVoice: Message.parseBool(json['is_voice']),
      voiceUrl: json['voice_url']?.toString(),
      isRead: Message.parseBool(json['is_read']),
      createdAt: Message.parseDateTime(json['created_at']),
      readAt: json['read_at'] != null ? Message.parseDateTime(json['read_at']) : null,
      updatedAt: json['updated_at'] != null ? Message.parseDateTime(json['updated_at']) : null,
      adId: adId,
      adNumber: adNumber,
      adTitleAr: adTitleAr,
      adTitleEn: adTitleEn,
      adSlug: adSlug,
      adDescriptionAr: adDescAr,
      adDescriptionEn: adDescEn,
      adPrice: adPrice,
      adShowTime: adShowTime,
      adCreatedAt: adCreatedAt,
      adImages: adImages,
      adCompanyMember: adCompanyMember,
      advertiserProfileId: advertiserId,
      advertiserUserId: advertiserUserId,
      advertiserName: advertiserName,
      advertiserLogo: advertiserLogo,
      advertiserDescription: advertiserDescription,
      advertiserContactPhone: advertiserContactPhone,
      advertiserWhatsappPhone: advertiserWhatsappPhone,
      advertiserWhatsappCallNumber: advertiserWhatsappCallNumber,
      advertiserWhatsappUrl: whatsappUrl,
      advertiserTelUrl: telUrl,
      advertiserLatitude: advertiserLatitude,
      advertiserLongitude: advertiserLongitude,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sender_id': senderId,
        'sender_email': senderEmail,
        'recipient_id': recipientId,
        'recipient_email': recipientEmail,
        'body': body,
        'is_voice': isVoice,
        'voice_url': voiceUrl,
        'is_read': isRead,
        'created_at': createdAt.toIso8601String(),
        'read_at': readAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'ad': {
          'id': adId,
          'ad_number': adNumber,
          'title_ar': adTitleAr,
          'title_en': adTitleEn,
          'slug': adSlug,
          'description_ar': adDescriptionAr,
          'description_en': adDescriptionEn,
          'price': adPrice,
          'show_time': adShowTime,
          'created_at': adCreatedAt?.toIso8601String(),
          'images': adImages,
          if (adCompanyMember != null) 'company_member': adCompanyMember!.toJson(),
        },
        'advertiser_profile': {
          'id': advertiserProfileId,
          'user_id': advertiserUserId,
          'name': advertiserName,
          'logo': advertiserLogo,
          'description': advertiserDescription,
          'contact_phone': advertiserContactPhone,
          'whatsapp_phone': advertiserWhatsappPhone,
          'whatsapp_call_number': advertiserWhatsappCallNumber,
          'whatsapp_url': advertiserWhatsappUrl,
          'tel_url': advertiserTelUrl,
          'latitude': advertiserLatitude,
          'longitude': advertiserLongitude,
        },
      };

  // ================= Helpers (public) =================
  static int parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static bool parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      final s = value.toLowerCase();
      return s == 'true' || s == '1';
    }
    return false;
  }

  static DateTime parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is int) {
      if (value > 1000000000000) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      } else {
        return DateTime.fromMillisecondsSinceEpoch(value * 1000);
      }
    }
    if (value is String) {
      String s = value;
      s = s.replaceAll(RegExp(r'\.0+Z$'), 'Z');
      if (!s.contains('T') && s.contains(' ')) s = s.replaceFirst(' ', 'T');
      try {
        return DateTime.parse(s);
      } catch (_) {
        try {
          if (s.length >= 19) return DateTime.parse(s.substring(0, 19));
        } catch (_) {}
      }
    }
    return DateTime.now();
  }

  // توليد رابط واتساب محليًا (مثل wa.me/number)
  static String? _buildWhatsAppUrl(String phone) {
    if (phone.isEmpty) return null;
    final clean = phone.replaceAll(RegExp(r'\D+'), '');
    if (clean.isEmpty) return null;
    return 'https://wa.me/$clean';
  }

  // توليد رابط الاتصال الهاتفي
  static String? _buildTelUrl(String phone) {
    if (phone.isEmpty) return null;
    final clean = phone.replaceAll(RegExp(r'\s+'), '');
    if (clean.isEmpty) return null;
    return 'tel:$clean';
  }
}

/// نموذج عضو الشركة كما يرجع من API داخل ad.company_member
class CompanyMemberMessage {
  final int id;
  final int advertiserProfileId;
  final int userId;
  final String role; // owner | publisher | viewer
  final String? displayName;
  final String? contactPhone;
  final String? whatsappPhone;
  final String? whatsappCallNumber;
  final String status; // active | removed
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// رابط صورة العضو (يأتي من avatar_url في الـ API)
  final String? avatarUrl;

  // كائن مستخدم مختصر (اختياري)
  final CompanyMemberUser? user;

  CompanyMemberMessage({
    required this.id,
    required this.advertiserProfileId,
    required this.userId,
    required this.role,
    this.displayName,
    this.contactPhone,
    this.whatsappPhone,
    this.whatsappCallNumber,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.avatarUrl,
    this.user,
  });

  factory CompanyMemberMessage.fromJson(Map<String, dynamic> json) {
    return CompanyMemberMessage(
      id: Message.parseInt(json['id']),
      advertiserProfileId: Message.parseInt(json['advertiser_profile_id']),
      userId: Message.parseInt(json['user_id']),
      role: (json['role']?.toString() ?? ''),
      displayName: json['display_name']?.toString(),
      contactPhone: json['contact_phone']?.toString(),
      whatsappPhone: json['whatsapp_phone']?.toString(),
      whatsappCallNumber: json['whatsapp_call_number']?.toString(),
      status: (json['status']?.toString() ?? ''),
      createdAt: json['created_at'] != null ? Message.parseDateTime(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? Message.parseDateTime(json['updated_at']) : null,
      avatarUrl: json['avatar_url']?.toString(), // ✅ جديد
      user: (json['user'] is Map<String, dynamic>)
          ? CompanyMemberUser.fromJson(json['user'] as Map<String, dynamic>)
          : null,
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
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'avatar_url': avatarUrl, // ✅ جديد
        if (user != null) 'user': user!.toJson(),
      };
}

class CompanyMemberUser {
  final int? id;
  final String? email;

  CompanyMemberUser({this.id, this.email});

  factory CompanyMemberUser.fromJson(Map<String, dynamic> json) {
    return CompanyMemberUser(
      id: Message.parseInt(json['id']),
      email: json['email']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
      };
}
