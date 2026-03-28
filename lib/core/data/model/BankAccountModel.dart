// lib/core/data/model/bank_account_model.dart
class BankAccountModel {
  final int id;
  final String bankName;
  final String accountNumber;
  final String? createdAt;

  BankAccountModel({
    required this.id,
    required this.bankName,
    required this.accountNumber,
    this.createdAt,
  });

  factory BankAccountModel.fromJson(Map<String, dynamic> json) {
    return BankAccountModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      bankName: json['bank_name'] ?? json['bankName'] ?? '',
      accountNumber: json['account_number'] ?? json['accountNumber'] ?? '',
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bank_name': bankName,
      'account_number': accountNumber,
      'created_at': createdAt,
    };
  }
}
