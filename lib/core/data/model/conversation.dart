// conversation.dart
import 'message.dart';

class Conversation {
  final User inquirer;                // شريك المحادثة (partner)
  final Ad? ad;                       // الإعلان (قد يكون null)
  final Advertiser advertiser;        // ملف المعلن
  final Message? lastMessage;         // آخر رسالة (مختصرة)
  final Message? firstMessage;        // أول رسالة (مختصرة)
  final int unreadCount;              // عدد غير المقروء
  final DateTime lastMessageAt;       // توقيت آخر رسالة
  final bool isUserInitiated;         // هل بدأها المستخدم
  final String? direction;            // incoming | outgoing

  Conversation({
    required this.inquirer,
    this.ad,
    required this.advertiser,
    this.lastMessage,
    this.firstMessage,
    required this.unreadCount,
    required this.lastMessageAt,
    required this.isUserInitiated,
    this.direction,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    // بعض الـ APIs ترجعها partner وأحياناً inquirer
    final userJson = (json['inquirer'] ?? json['partner']) as Map<String, dynamic>?;
    if (userJson == null) {
      throw FormatException('Missing inquirer/partner in conversation JSON');
    }
    final inquirer = User.fromJson(userJson);

    Ad? ad;
    if (json['ad'] is Map<String, dynamic>) {
      ad = Ad.fromJson(json['ad'] as Map<String, dynamic>);
    }

    final advertiserJson = (json['advertiser'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final advertiser = Advertiser.fromJson(advertiserJson);

    Message? lastMessage;
    if (json['last_message'] is Map<String, dynamic>) {
      try {
        lastMessage = Message.fromJson(json['last_message'] as Map<String, dynamic>);
      } catch (_) {
        lastMessage = _createFallbackMessage(json['last_message'] as Map<String, dynamic>);
      }
    }

    Message? firstMessage;
    if (json['first_message'] is Map<String, dynamic>) {
      try {
        firstMessage = Message.fromJson(json['first_message'] as Map<String, dynamic>);
      } catch (_) {
        firstMessage = _createFallbackMessage(json['first_message'] as Map<String, dynamic>);
      }
    }

    final unread = Message.parseInt(json['unread_count']);
    DateTime lastAt;
    if (json['last_message_at'] != null) {
      lastAt = Message.parseDateTime(json['last_message_at']);
    } else if (lastMessage != null) {
      lastAt = lastMessage.createdAt;
    } else {
      lastAt = DateTime.now();
    }

    final isUserInitiated = (json['is_user_initiated'] == true) || (json['is_user_initiated']?.toString() == '1');
    final direction = json['direction']?.toString();

    return Conversation(
      inquirer: inquirer,
      ad: ad,
      advertiser: advertiser,
      lastMessage: lastMessage,
      firstMessage: firstMessage,
      unreadCount: unread,
      lastMessageAt: lastAt,
      isUserInitiated: isUserInitiated,
      direction: direction,
    );
  } 

  // ======= fallback عند فشل Message.fromJson (نفس فكرتك لكن زودت الحقول) =======
  static Message _createFallbackMessage(Map<String, dynamic> m) {
    // إعلان
    final adId = Message.parseInt(m['ad_id']);
    final adNumber = m['ad_number']?.toString() ?? '';
    final adTitleAr = m['ad_title_ar']?.toString() ?? m['ad_title']?.toString() ?? '';
    final adTitleEn = m['ad_title_en']?.toString() ?? '';
    final adSlug = m['ad_slug']?.toString() ?? '';
    final adDescriptionAr = m['ad_description_ar']?.toString() ?? '';
    final adDescriptionEn = m['ad_description_en']?.toString() ?? '';
    final adPrice = m['ad_price'] != null ? Message.parseDouble(m['ad_price']) : 0.0;
    final adShowTime = Message.parseBool(m['ad_show_time'] ?? false);
    final List<String> adImages = (m['ad_images'] is List)
        ? List<String>.from((m['ad_images'] as List).map((e) => e.toString()))
        : <String>[];

    DateTime? adCreatedAt;
    try {
      if (m['ad_created_at'] != null) {
        adCreatedAt = Message.parseDateTime(m['ad_created_at']);
      }
    } catch (_) {
      adCreatedAt = null;
    }

    // معلن
    final advertiserProfileId = Message.parseInt(m['advertiser_profile_id'] ?? 0);
    final advertiserUserId = Message.parseInt(m['advertiser_user_id'] ?? 0);
    final advertiserName = m['advertiser_name']?.toString() ?? '';
    final advertiserLogo = m['advertiser_logo']?.toString() ?? '';
    final advertiserDescription = m['advertiser_description']?.toString();
    final advertiserContactPhone = m['advertiser_contact_phone']?.toString();
    final advertiserWhatsappPhone = m['advertiser_whatsapp_phone']?.toString();
    final advertiserWhatsappCallNumber = m['advertiser_whatsapp_call_number']?.toString();
    final advertiserLatitude = m['advertiser_latitude'] != null
        ? double.tryParse(m['advertiser_latitude'].toString())
        : null;
    final advertiserLongitude = m['advertiser_longitude'] != null
        ? double.tryParse(m['advertiser_longitude'].toString())
        : null;

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
      id: Message.parseInt(m['id']),
      senderId: Message.parseInt(m['sender_id']),
      senderEmail: m['sender_email']?.toString(),
      recipientId: Message.parseInt(m['recipient_id']),
      recipientEmail: m['recipient_email']?.toString(),
      body: m['body']?.toString(),
      isVoice: Message.parseBool(m['is_voice'] ?? false),
      voiceUrl: m['voice_url']?.toString(),
      isRead: Message.parseBool(m['is_read'] ?? false),
      createdAt: Message.parseDateTime(m['created_at']),
      readAt: m['read_at'] != null ? Message.parseDateTime(m['read_at']) : null,
      updatedAt: m['updated_at'] != null ? Message.parseDateTime(m['updated_at']) : null,

      // إعلان
      adId: adId,
      adNumber: adNumber,
      adTitleAr: adTitleAr,
      adTitleEn: adTitleEn,
      adSlug: adSlug,
      adDescriptionAr: adDescriptionAr,
      adDescriptionEn: adDescriptionEn,
      adPrice: adPrice,
      adShowTime: adShowTime,
      adCreatedAt: adCreatedAt,
      adImages: adImages,

      // معلن
      advertiserProfileId: advertiserProfileId,
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

  static String? _buildWhatsAppUrl(String phone) {
    final clean = phone.replaceAll(RegExp(r'\D+'), '');
    return clean.isEmpty ? null : 'https://wa.me/$clean';
  }

  static String? _buildTelUrl(String phone) {
    final clean = phone.replaceAll(RegExp(r'\s+'), '');
    return clean.isEmpty ? null : 'tel:$clean';
  }
}

// =================== الداتا تايبس ===================

class User {
  final int id;
  final String email;
  final String? name;

  User({required this.id, required this.email, this.name});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: Message.parseInt(json['id']),
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString(),
    );
  }
}

class CompanyMemberUser {
  final int id;
  final String? email;

  CompanyMemberUser({required this.id, this.email});

  factory CompanyMemberUser.fromJson(Map<String, dynamic>? json) {
    if (json == null) return CompanyMemberUser(id: 0, email: null);
    return CompanyMemberUser(
      id: Message.parseInt(json['id']),
      email: json['email']?.toString(),
    );
  }
}

class CompanyMember {
  final int id;
  final int advertiserProfileId;
  final int userId;
  final String? role;               // owner | publisher | viewer
  final String? displayName;
  final String? contactPhone;
  final String? whatsappPhone;
  final String? whatsappCallNumber;
  final String? status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final CompanyMemberUser? user;

  CompanyMember({
    required this.id,
    required this.advertiserProfileId,
    required this.userId,
    this.role,
    this.displayName,
    this.contactPhone,
    this.whatsappPhone,
    this.whatsappCallNumber,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.user,
  });

  factory CompanyMember.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return CompanyMember(
        id: 0,
        advertiserProfileId: 0,
        userId: 0,
      );
    }
    return CompanyMember(
      id: Message.parseInt(json['id']),
      advertiserProfileId: Message.parseInt(json['advertiser_profile_id']),
      userId: Message.parseInt(json['user_id']),
      role: json['role']?.toString(),
      displayName: json['display_name']?.toString(),
      contactPhone: json['contact_phone']?.toString(),
      whatsappPhone: json['whatsapp_phone']?.toString(),
      whatsappCallNumber: json['whatsapp_call_number']?.toString(),
      status: json['status']?.toString(),
      createdAt: json['created_at'] != null ? Message.parseDateTime(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? Message.parseDateTime(json['updated_at']) : null,
      user: CompanyMemberUser.fromJson(json['user'] as Map<String, dynamic>?),
    );
  }
}

class Ad {
  final int id;
  final String? adNumber;
  final int userId;
  final int advertiserProfileId;
  final int? companyMemberId;

  final String? titleAr;
  final String? titleEn;
  final String? slug;
  final String? descriptionAr;
  final String? descriptionEn;

  final double price;
  final double? latitude;
  final double? longitude;

  final String? status;
  final int? views;
  final bool isPremium;
  final String? premiumExpiresAt;
  final double? totalRating;

  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool showTime;

  final List<String> images;

  final CompanyMember? companyMember;

  Ad({
    required this.id,
    this.adNumber,
    required this.userId,
    required this.advertiserProfileId,
    this.companyMemberId,
    this.titleAr,
    this.titleEn,
    this.slug,
    this.descriptionAr,
    this.descriptionEn,
    required this.price,
    this.latitude,
    this.longitude,
    this.status,
    this.views,
    required this.isPremium,
    this.premiumExpiresAt,
    this.totalRating,
    this.createdAt,
    this.updatedAt,
    required this.showTime,
    required this.images,
    this.companyMember,
  });

  String get title {
    return (titleAr?.isNotEmpty ?? false)
        ? titleAr!
        : (titleEn?.isNotEmpty ?? false)
            ? titleEn!
            : '';
  }

  factory Ad.fromJson(Map<String, dynamic> json) {
    final imgs = (json['images'] is List)
        ? List<String>.from((json['images'] as List).map((e) => e?.toString() ?? ''))
        : <String>[];

    return Ad(
      id: Message.parseInt(json['id']),
      adNumber: json['ad_number']?.toString(),
      userId: Message.parseInt(json['user_id']),
      advertiserProfileId: Message.parseInt(json['advertiser_profile_id']),
      companyMemberId: json['company_member_id'] != null ? Message.parseInt(json['company_member_id']) : null,
      titleAr: json['title_ar']?.toString(),
      titleEn: json['title_en']?.toString(),
      slug: json['slug']?.toString(),
      descriptionAr: json['description_ar']?.toString(),
      descriptionEn: json['description_en']?.toString(),
      price: Message.parseDouble(json['price']),
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      status: json['status']?.toString(),
      views: json['views'] != null ? Message.parseInt(json['views']) : null,
      isPremium: Message.parseBool(json['is_premium'] ?? false),
      premiumExpiresAt: json['premium_expires_at']?.toString(),
      totalRating: json['total_rating'] != null ? double.tryParse(json['total_rating'].toString()) : null,
      createdAt: json['created_at'] != null ? Message.parseDateTime(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? Message.parseDateTime(json['updated_at']) : null,
      showTime: Message.parseBool(json['show_time'] ?? false),
      images: imgs,
      companyMember: CompanyMember.fromJson(json['company_member'] as Map<String, dynamic>?),
    );
  }
}

class Advertiser {
  final int id;
  final int userId;
  final String? accountType;     // <<< تمت إضافتها
  final String? name;
  final String? logo;
  final String? description;
  final String? contactPhone;
  final String? whatsappPhone;
  final String? whatsappCallNumber;
  final double? latitude;
  final double? longitude;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // روابط مبنية من الـ API
  final String? whatsappUrl;
  final String? telUrl;

  Advertiser({
    required this.id,
    required this.userId,
    this.accountType,
    this.name,
    this.logo,
    this.description,
    this.contactPhone,
    this.whatsappPhone,
    this.whatsappCallNumber,
    this.latitude,
    this.longitude,
    this.createdAt,
    this.updatedAt,
    this.whatsappUrl,
    this.telUrl,
  });

  factory Advertiser.fromJson(Map<String, dynamic> json) {
    return Advertiser(
      id: Message.parseInt(json['id']),
      userId: Message.parseInt(json['user_id']),
      accountType: json['account_type']?.toString(),
      name: json['name']?.toString(),
      logo: json['logo']?.toString(),
      description: json['description']?.toString(),
      contactPhone: json['contact_phone']?.toString(),
      whatsappPhone: json['whatsapp_phone']?.toString(),
      whatsappCallNumber: json['whatsapp_call_number']?.toString(),
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      createdAt: json['created_at'] != null ? Message.parseDateTime(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? Message.parseDateTime(json['updated_at']) : null,
      whatsappUrl: json['whatsapp_url']?.toString(),
      telUrl: json['tel_url']?.toString(),
    );
  }
}
