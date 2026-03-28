class CompanySummary {
  final int id;
  final String? name;
  final String? logo;
  final int membersCount;
  final int pendingInvitesCount;
  final int? ownerUserId;
  final String? contactPhone;
  final String? whatsappPhone;
  final String? ownerEmail;

  CompanySummary({
    required this.id,
    this.name,
    this.logo,
    this.membersCount = 0,
    this.pendingInvitesCount = 0,
    this.ownerUserId,
    this.contactPhone,
    this.whatsappPhone,
    this.ownerEmail,
  });

  factory CompanySummary.fromJson(Map<String, dynamic> j) {
    return CompanySummary(
      id: j['id'] as int,
      name: j['name'] as String?,
      logo: j['logo'] as String?,
      membersCount: (j['members_count'] ?? 0) as int,
      pendingInvitesCount: (j['pending_invites_count'] ?? 0) as int,
      ownerUserId: j['owner_user_id'] as int?,
      contactPhone: j['contact_phone'] as String?,
      whatsappPhone: j['whatsapp_phone'] as String?,
      ownerEmail: j['owner_email'] as String?,
    );
  }
}
