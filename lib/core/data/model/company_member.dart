class CompanyMember {
  final int id;
  final int advertiserProfileId;
  final int userId;
  final String role; // owner | publisher | viewer
  final String displayName;
  final String? contactPhone;
  final String? whatsappPhone;
  final String? whatsappCallNumber;
  final String status; // active | removed
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // جديد: صورة العضو
  final String? avatarUrl;

  // علاقات اختيارية للعرض
  final String? userEmail;   // لو رجعت من API مع user
  final String? companyName; // لو رجعت من API مع company

  CompanyMember({
    required this.id,
    required this.advertiserProfileId,
    required this.userId,
    required this.role,
    required this.displayName,
    required this.status,
    this.contactPhone,
    this.whatsappPhone,
    this.whatsappCallNumber,
    this.createdAt,
    this.updatedAt,
    this.avatarUrl,
    this.userEmail,
    this.companyName,
  });

  factory CompanyMember.fromJson(Map<String, dynamic> j) {
    return CompanyMember(
      id: j['id'] as int,
      advertiserProfileId: j['advertiser_profile_id'] as int,
      userId: j['user_id'] as int,
      role: j['role'] as String,
      displayName: j['display_name'] as String,
      contactPhone: j['contact_phone'] as String?,
      whatsappPhone: j['whatsapp_phone'] as String?,
      whatsappCallNumber: j['whatsapp_call_number'] as String?,
      status: j['status'] as String,
      createdAt: j['created_at'] != null ? DateTime.tryParse(j['created_at']) : null,
      updatedAt: j['updated_at'] != null ? DateTime.tryParse(j['updated_at']) : null,
      avatarUrl: j['avatar_url'] as String?,
      userEmail: j['user'] != null ? j['user']['email'] as String? : j['user_email'] as String?,
      companyName: j['company'] != null ? j['company']['name'] as String? : j['company_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'advertiser_profile_id': advertiserProfileId,
      'user_id': userId,
      'role': role,
      'display_name': displayName,
      'contact_phone': contactPhone,
      'whatsapp_phone': whatsappPhone,
      'whatsapp_call_number': whatsappCallNumber,
      'status': status,
      'avatar_url': avatarUrl,
    };
  }
}
