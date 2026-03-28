class CompanyInvite {
  final int id;

  /// بعض الـ endpoints ترجع company_id، وبعضها advertiser_profile_id
  final int advertiserProfileId;

  /// قد لا تعود في /invites/my
  final int? inviterUserId;

  /// قد لا تعود في /invites/my
  final String? inviteeEmail;

  final String role;   // publisher | viewer
  final String status; // pending | accepted | rejected

  final DateTime? acceptedAt;
  final DateTime? rejectedAt;
  final DateTime? createdAt;

  // للعرض
  final String? companyName;

  CompanyInvite({
    required this.id,
    required this.advertiserProfileId,
    required this.role,
    required this.status,
    this.inviterUserId,
    this.inviteeEmail,
    this.acceptedAt,
    this.rejectedAt,
    this.createdAt,
    this.companyName,
  });

  // محوّل آمن للـ int (يدعم String/int/null)
  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
    if (v is num) return v.toInt();
    return null;
    }

  static DateTime? _asDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
    return null;
  }

  factory CompanyInvite.fromJson(Map<String, dynamic> j) {
    // حاول التقاط id الشركة من أكثر من مفتاح
    final compId =
        _asInt(j['company_id']) ??
        _asInt(j['advertiser_profile_id']) ??
        0;

    return CompanyInvite(
      id: _asInt(j['id']) ?? 0,
      advertiserProfileId: compId,

      // هذان الحقلان قد لا يعودان من /invites/my
      inviterUserId: _asInt(j['inviter_user_id']),
      inviteeEmail: j['invitee_email']?.toString(),

      role: (j['role'] ?? '').toString(),
      status: (j['status'] ?? '').toString(),

      acceptedAt: _asDate(j['accepted_at']),
      rejectedAt: _asDate(j['rejected_at']),
      createdAt: _asDate(j['created_at']),

      companyName: j['company_name']?.toString()
          ?? (j['company'] is Map<String, dynamic> ? j['company']['name']?.toString() : null),
    );
  }
}
