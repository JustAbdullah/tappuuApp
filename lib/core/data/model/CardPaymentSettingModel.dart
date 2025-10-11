// lib/core/data/model/card_payment_setting_model.dart
class CardPaymentSettingModel {
  final int id;
  final bool isEnabled;
  final String? note;

  CardPaymentSettingModel({
    required this.id,
    required this.isEnabled,
    this.note,
  });

  factory CardPaymentSettingModel.fromJson(Map<String, dynamic> json) {
    // دعم صيغ مختلفة: int 0/1 أو boolean true/false
    final raw = json['is_enabled'] ?? json['isEnabled'] ?? json['enabled'];
    bool enabled;
    if (raw is bool) {
      enabled = raw;
    } else if (raw is num) {
      enabled = raw != 0;
    } else if (raw is String) {
      enabled = raw == '1' || raw.toLowerCase() == 'true';
    } else {
      enabled = false;
    }

    return CardPaymentSettingModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      isEnabled: enabled,
      note: json['note']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'is_enabled': isEnabled ? 1 : 0, // backend يتوقع 1/0
      'note': note,
    };
  }
}
