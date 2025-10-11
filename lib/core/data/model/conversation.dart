
import 'package:tappuu_app/core/data/model/Message.dart';

class Conversation {
  final User inquirer;
  final Ad? ad;
  final Advertiser advertiser;
  final Message? lastMessage;
  final Message? firstMessage;
  final int unreadCount;
  final DateTime lastMessageAt;
  final bool isUserInitiated;
  final String? direction;

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
    final userJson = (json['inquirer'] ?? json['partner']) as Map<String, dynamic>?;
    if (userJson == null) {
      throw FormatException('Missing inquirer/partner in conversation JSON');
    }
    final inquirer = User.fromJson(userJson);

    Ad? ad;
    if (json['ad'] is Map<String, dynamic>) {
      ad = Ad.fromJson(json['ad'] as Map<String, dynamic>);
    } else {
      ad = null;
    }

    final advertiserJson = (json['advertiser'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final advertiser = Advertiser.fromJson(advertiserJson);

    Message? lastMessage;
    if (json['last_message'] is Map<String, dynamic>) {
      try {
        lastMessage = Message.fromJson(json['last_message'] as Map<String, dynamic>);
      } catch (_) {
        final lm = json['last_message'] as Map<String, dynamic>;
        lastMessage = _createFallbackMessage(lm);
      }
    }

    Message? firstMessage;
    if (json['first_message'] is Map<String, dynamic>) {
      try {
        firstMessage = Message.fromJson(json['first_message'] as Map<String, dynamic>);
      } catch (_) {
        final fm = json['first_message'] as Map<String, dynamic>;
        firstMessage = _createFallbackMessage(fm);
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

  // دالة مساعدة لإنشاء رسالة بديلة عند فشل التحليل
  static Message _createFallbackMessage(Map<String, dynamic> messageMap) {
    // تحليل بيانات الإعلان
    final adId = Message.parseInt(messageMap['ad_id']);
    final adNumber = messageMap['ad_number']?.toString() ?? '';
    final adTitleAr = messageMap['ad_title_ar']?.toString() ?? messageMap['ad_title']?.toString() ?? '';
    final adTitleEn = messageMap['ad_title_en']?.toString() ?? '';
    final adSlug = messageMap['ad_slug']?.toString() ?? '';
    final adDescriptionAr = messageMap['ad_description_ar']?.toString() ?? '';
    final adDescriptionEn = messageMap['ad_description_en']?.toString() ?? '';
    final adPrice = messageMap['ad_price'] != null ? Message.parseDouble(messageMap['ad_price']) : 0.0;
    final adShowTime = Message.parseBool(messageMap['ad_show_time'] ?? false);
    
    // تحليل صور الإعلان
    List<String> adImages = [];
    try {
      if (messageMap['ad_images'] is List) {
        adImages = List<String>.from(messageMap['ad_images'].map((e) => e.toString()));
      }
    } catch (_) {
      adImages = [];
    }

    DateTime? adCreatedAt;
    try {
      if (messageMap['ad_created_at'] != null) {
        adCreatedAt = Message.parseDateTime(messageMap['ad_created_at']);
      }
    } catch (_) {
      adCreatedAt = null;
    }

    // تحليل بيانات المعلن
    final advertiserProfileId = Message.parseInt(messageMap['advertiser_profile_id'] ?? 0);
    final advertiserUserId = Message.parseInt(messageMap['advertiser_user_id'] ?? 0);
    final advertiserName = messageMap['advertiser_name']?.toString() ?? '';
    final advertiserLogo = messageMap['advertiser_logo']?.toString() ?? '';
    final advertiserDescription = messageMap['advertiser_description']?.toString();
    final advertiserContactPhone = messageMap['advertiser_contact_phone']?.toString();
    final advertiserWhatsappPhone = messageMap['advertiser_whatsapp_phone']?.toString();
    final advertiserWhatsappCallNumber = messageMap['advertiser_whatsapp_call_number']?.toString();
    
    // إنشاء روابط الاتصال
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

    final advertiserLatitude = messageMap['advertiser_latitude'] != null ? 
        double.tryParse(messageMap['advertiser_latitude'].toString()) : null;
    final advertiserLongitude = messageMap['advertiser_longitude'] != null ? 
        double.tryParse(messageMap['advertiser_longitude'].toString()) : null;

    return Message(
      id: Message.parseInt(messageMap['id']),
      senderId: Message.parseInt(messageMap['sender_id']),
      senderEmail: messageMap['sender_email']?.toString(),
      recipientId: Message.parseInt(messageMap['recipient_id']),
      recipientEmail: messageMap['recipient_email']?.toString(),
      body: messageMap['body']?.toString(),
      isVoice: Message.parseBool(messageMap['is_voice'] ?? false),
      voiceUrl: messageMap['voice_url']?.toString(),
      isRead: Message.parseBool(messageMap['is_read'] ?? false),
      createdAt: Message.parseDateTime(messageMap['created_at']),
      readAt: messageMap['read_at'] != null ? Message.parseDateTime(messageMap['read_at']) : null,
      updatedAt: messageMap['updated_at'] != null ? Message.parseDateTime(messageMap['updated_at']) : null,
      // بيانات الإعلان المطلوبة
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
      // بيانات المعلن المطلوبة
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

  // دوال مساعدة لإنشاء روابط الاتصال
  static String? _buildWhatsAppUrl(String phone) {
    if (phone.isEmpty) return null;
    final clean = phone.replaceAll(RegExp(r'\D+'), '');
    if (clean.isEmpty) return null;
    return 'https://wa.me/$clean';
  }

  static String? _buildTelUrl(String phone) {
    if (phone.isEmpty) return null;
    final clean = phone.replaceAll(RegExp(r'\s+'), '');
    if (clean.isEmpty) return null;
    return 'tel:$clean';
  }
}

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

class Ad {
  final int id;
  final String title;
  final int userId;
  final List<String> images;
  final double price;

  Ad({
    required this.id,
    required this.title,
    required this.userId,
    required this.images,
    required this.price,
  });

  factory Ad.fromJson(Map<String, dynamic> json) {
    List<String> images = [];
    if (json['images'] != null && json['images'] is List) {
      images = (json['images'] as List).map((e) => e?.toString() ?? '').toList();
    }
    final title = json['title_ar']?.toString() ?? json['title']?.toString() ?? '';
    return Ad(
      id: Message.parseInt(json['id']),
      title: title,
      userId: Message.parseInt(json['user_id']),
      images: images,
      price: Message.parseDouble(json['price']),
    );
  }
}

class Advertiser {
  final int id;
  final String name;
  final String logo;
  final String contactPhone;
  final String whatsappPhone;
  final String whatsappCallNumber;

  Advertiser({
    required this.id,
    required this.name,
    required this.logo,
    required this.contactPhone,
    required this.whatsappPhone,
    required this.whatsappCallNumber,
  });

  factory Advertiser.fromJson(Map<String, dynamic> json) {
    return Advertiser(
      id: Message.parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      logo: json['logo']?.toString() ?? '',
      contactPhone: json['contact_phone']?.toString() ?? '',
      whatsappPhone: json['whatsapp_phone']?.toString() ?? '',
      whatsappCallNumber: json['whatsapp_call_number']?.toString() ?? '',
    );
  }
}