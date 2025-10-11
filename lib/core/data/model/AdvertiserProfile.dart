// lib/models/advertiser_profile.dart

class AdvertiserProfile {
  final int? id;
  final int userId;
  final String? logo;
  final String? name;
  final String? description;
  final String? contactPhone;
  final String? whatsappPhone;
  final String? whatsappCallNumber;
  final String accountType;

  static const String TYPE_INDIVIDUAL = 'individual';
  static const String TYPE_COMPANY = 'company';

  AdvertiserProfile({
    this.id,
    required this.userId,
    this.logo,
    this.name,
    this.description,
    this.contactPhone,
    this.whatsappPhone,
    this.whatsappCallNumber,
    String? accountType,
  }) : accountType = (accountType == null || accountType.isEmpty)
            ? TYPE_INDIVIDUAL
            : accountType;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdvertiserProfile && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  factory AdvertiserProfile.fromJson(Map<String, dynamic> json) {
    return AdvertiserProfile(
      id: json['id'] is int ? json['id'] as int : (json['id'] != null ? int.tryParse(json['id'].toString()) : null),
      userId: json['user_id'] is int ? json['user_id'] as int : int.parse(json['user_id'].toString()),
      logo: json['logo']?.toString(),
      name: json['name']?.toString(),
      description: json['description']?.toString(),
      contactPhone: json['contact_phone']?.toString(),
      whatsappPhone: json['whatsapp_phone']?.toString(),
      whatsappCallNumber: json['whatsapp_call_number']?.toString(),
      accountType: (json['account_type'] ?? json['accountType'] ?? TYPE_INDIVIDUAL).toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'user_id': userId,
        'logo': logo,
        'name': name,
        'description': description,
        'contact_phone': contactPhone,
        'whatsapp_phone': whatsappPhone,
        'whatsapp_call_number': whatsappCallNumber,
        'account_type': accountType,
      };

  AdvertiserProfile copyWith({
    int? id,
    int? userId,
    String? logo,
    String? name,
    String? description,
    String? contactPhone,
    String? whatsappPhone,
    String? whatsappCallNumber,
    String? accountType,
  }) {
    return AdvertiserProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      logo: logo ?? this.logo,
      name: name ?? this.name,
      description: description ?? this.description,
      contactPhone: contactPhone ?? this.contactPhone,
      whatsappPhone: whatsappPhone ?? this.whatsappPhone,
      whatsappCallNumber: whatsappCallNumber ?? this.whatsappCallNumber,
      accountType: accountType ?? this.accountType,
    );
  }
}