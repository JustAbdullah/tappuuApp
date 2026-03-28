import 'BankAccountModel.dart';
import 'UserWallet.dart';
import 'user.dart';

class TransferProofModel {
  final int id;
  final int bankAccountId;
  final int? walletId;
  final int? userId; // الجديد
  final double amount;
  final String? proofImage; // رابط الصورة
  final String? sourceAccountNumber;
  final String status; // pending|approved|rejected
  final String? createdAt;
  final String? approvedAt;
  final int? approvedBy;
  final String? comment;

  final BankAccountModel? bankAccount;
  final UserWallet? wallet; // full wallet info إذا عاد السيرفر
  final User? user;     // بيانات المستخدم (id, name, email...) إن عاد السيرفر

  TransferProofModel({
    required this.id,
    required this.bankAccountId,
    this.walletId,
    this.userId,
    required this.amount,
    this.proofImage,
    this.sourceAccountNumber,
    required this.status,
    this.createdAt,
    this.approvedAt,
    this.approvedBy,
    this.comment,
    this.bankAccount,
    this.wallet,
    this.user,
  });

  factory TransferProofModel.fromJson(Map<String, dynamic> json) {
    return TransferProofModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      bankAccountId: json['bank_account_id'] is int
          ? json['bank_account_id']
          : int.parse(json['bank_account_id'].toString()),
      walletId: json['wallet_id'] != null
          ? (json['wallet_id'] is int ? json['wallet_id'] : int.parse(json['wallet_id'].toString()))
          : null,
      userId: json['user_id'] != null
          ? (json['user_id'] is int ? json['user_id'] : int.parse(json['user_id'].toString()))
          : null,
      amount: (json['amount'] is num) ? (json['amount'] as num).toDouble() : double.parse(json['amount'].toString()),
      proofImage: json['proof_image']?.toString(),
      sourceAccountNumber: json['source_account_number']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      createdAt: json['created_at']?.toString(),
      approvedAt: json['approved_at']?.toString(),
      approvedBy: json['approved_by'] != null ? (json['approved_by'] is int ? json['approved_by'] : int.parse(json['approved_by'].toString())) : null,
      comment: json['comment']?.toString(),
      bankAccount: json['bank_account'] != null && json['bank_account'] is Map
          ? BankAccountModel.fromJson(json['bank_account'] as Map<String, dynamic>)
          : null,
      wallet: json['wallet'] != null && json['wallet'] is Map
          ? UserWallet.fromJson(json['wallet'] as Map<String, dynamic>)
          : null,
      user: json['user'] != null && json['user'] is Map
          ? User.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bank_account_id': bankAccountId,
      'wallet_id': walletId,
      'user_id': userId,
      'amount': amount,
      'proof_image': proofImage,
      'source_account_number': sourceAccountNumber,
      'status': status,
      'created_at': createdAt,
      'approved_at': approvedAt,
      'approved_by': approvedBy,
      'comment': comment,
      'bank_account': bankAccount != null ? bankAccount!.toJson() : null,
      'wallet': wallet != null ? wallet!.toJson() : null,
      'user': user != null ? user!.toJson() : null,
    };
  }
}
