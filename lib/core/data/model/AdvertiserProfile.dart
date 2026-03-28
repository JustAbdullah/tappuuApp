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

  /// هل المستخدم الحالي مالك هذا الملف (يعني يقدر يغيّر بيانات الشركة)؟
  final bool isOwner;

  /// مالك الملف (كما ترسله الـ API: {id,email})
  final UserLite? user;

  /// العضو داخل الشركة لهذا المستخدم (إن وجد) — يظهر فقط عندما يكون accountType=company
  final CompanyMemberLite? companyMember;

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
    this.isOwner = false,
    this.user,
    this.companyMember,
  }) : accountType = (accountType == null || accountType.isEmpty)
            ? TYPE_INDIVIDUAL
            : accountType;

  /// مساواة بالـ id لسهولة التعامل بالقوائم
  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is AdvertiserProfile && other.id == id);

  @override
  int get hashCode => id.hashCode;

  /// هل الملف نوعه شركة؟
  bool get isCompany => accountType == TYPE_COMPANY;

  /// صلاحية تعديل بيانات الشركة (فقط المالك)
  bool get canEditCompany => isOwner;

  /// صلاحية تعديل بيانات العضو داخل الشركة (لو كان عضوًا بأي دور)
  bool get canEditSelfAsMember => companyMember != null;

  factory AdvertiserProfile.fromJson(Map<String, dynamic> json) {
    CompanyMemberLite? cm;
    if (json['company_member'] is Map<String, dynamic>) {
      cm = CompanyMemberLite.fromJson(json['company_member'] as Map<String, dynamic>);
    }

    UserLite? ownerUser;
    if (json['user'] is Map<String, dynamic>) {
      ownerUser = UserLite.fromJson(json['user'] as Map<String, dynamic>);
    }

    return AdvertiserProfile(
      id: json['id'] is int
          ? json['id'] as int
          : (json['id'] != null ? int.tryParse(json['id'].toString()) : null),
      userId: _toInt(json['user_id']),
      logo: json['logo']?.toString(),
      name: json['name']?.toString(),
      description: json['description']?.toString(),
      contactPhone: json['contact_phone']?.toString(),
      whatsappPhone: json['whatsapp_phone']?.toString(),
      whatsappCallNumber: json['whatsapp_call_number']?.toString(),
      accountType:
          (json['account_type'] ?? json['accountType'] ?? TYPE_INDIVIDUAL).toString(),
      isOwner: _toBool(json['is_owner']),
      user: ownerUser,
      companyMember: cm,
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
        // مبدئيًا لا نرسل is_owner لأنه يُحتسب من السيرفر
        if (companyMember != null) 'company_member': companyMember!.toJson(),
        if (user != null) 'user': user!.toJson(),
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
    bool? isOwner,
    UserLite? user,
    CompanyMemberLite? companyMember,
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
      isOwner: isOwner ?? this.isOwner,
      user: user ?? this.user,
      companyMember: companyMember ?? this.companyMember,
    );
  }
}

/// موديل خفيف لعضو الشركة المرتبط بالمستخدم الحالي ضمن الشركة
class CompanyMemberLite {
  final int id;
  final int advertiserProfileId;
  final int userId;
  final String role; // owner | publisher | viewer
  final String? displayName;
  final String? contactPhone;
  final String? whatsappPhone;
  final String? whatsappCallNumber;
  final String status; // active | removed

  /// جديد: رابط صورة العضو (avatar)
  final String? avatarUrl;

  /// جديد: التواريخ من السيرفر
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// علاقة اختيارية
  final UserLite? user;

  CompanyMemberLite({
    required this.id,
    required this.advertiserProfileId,
    required this.userId,
    required this.role,
    this.displayName,
    this.contactPhone,
    this.whatsappPhone,
    this.whatsappCallNumber,
    required this.status,
    this.avatarUrl,
    this.createdAt,
    this.updatedAt,
    this.user,
  });

  factory CompanyMemberLite.fromJson(Map<String, dynamic> json) {
    return CompanyMemberLite(
      id: _toInt(json['id']),
      advertiserProfileId: _toInt(json['advertiser_profile_id']),
      userId: _toInt(json['user_id']),
      role: (json['role'] ?? '').toString(),
      displayName: json['display_name']?.toString(),
      contactPhone: json['contact_phone']?.toString(),
      whatsappPhone: json['whatsapp_phone']?.toString(),
      whatsappCallNumber: json['whatsapp_call_number']?.toString(),
      status: (json['status'] ?? '').toString(),
      avatarUrl: json['avatar_url']?.toString(),
      createdAt: _toDateTime(json['created_at']),
      updatedAt: _toDateTime(json['updated_at']),
      user: (json['user'] is Map<String, dynamic>)
          ? UserLite.fromJson(json['user'] as Map<String, dynamic>)
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
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
        if (user != null) 'user': user!.toJson(),
      };
}

class UserLite {
  final int id;
  final String email;

  UserLite({
    required this.id,
    required this.email,
  });

  factory UserLite.fromJson(Map<String, dynamic> json) {
    return UserLite(
      id: _toInt(json['id']),
      email: (json['email'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
      };
}

// ========= أدوات تحويل صغيرة =========

int _toInt(dynamic v) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

bool _toBool(dynamic v) {
  if (v is bool) return v;
  if (v == null) return false;
  final s = v.toString().toLowerCase().trim();
  // يدعم 1/0 و "true"/"false"
  return s == '1' || s == 'true' || s == 'yes';
}

DateTime? _toDateTime(dynamic v) {
  if (v == null) return null;
  try {
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  } catch (_) {
    return null;
  }
}
