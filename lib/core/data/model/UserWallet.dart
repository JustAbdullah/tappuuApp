// lib/models/user_wallet.dart
class UserWallet {
  int? id;
  String uuid;
  int userId;
  double balance;
  String currency;
  String status; // active, frozen, closed
  DateTime? createdAt;
  DateTime? lastChangedAt;

  UserWallet({
    this.id,
    required this.uuid,
    required this.userId,
    required this.balance,
    this.currency = 'SYP',
    this.status = 'active',
    this.createdAt,
    this.lastChangedAt,
  });

  factory UserWallet.fromJson(Map<String, dynamic> json) {
    return UserWallet(
      id: json['id'] is int ? json['id'] : (json['id'] != null ? int.parse(json['id'].toString()) : null),
      uuid: json['uuid'] ?? '',
      userId: json['user_id'] is int ? json['user_id'] : int.parse(json['user_id'].toString()),
      balance: json['balance'] != null ? double.parse(json['balance'].toString()) : 0.0,
      currency: json['currency'] ?? 'SYP',
      status: json['status'] ?? 'active',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      lastChangedAt: json['last_changed_at'] != null ? DateTime.tryParse(json['last_changed_at']) : null,
    );
  }
//..//
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'uuid': uuid,
      'user_id': userId,
      'balance': balance,
      'currency': currency,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'last_changed_at': lastChangedAt?.toIso8601String(),
    };
  }

  // دوال مساعدة للتحقق من حالة المحفظة
  bool get isActive => status == 'active';
  bool get isFrozen => status == 'frozen';
  bool get isClosed => status == 'closed';
  bool get canPerformTransactions => isActive;
}