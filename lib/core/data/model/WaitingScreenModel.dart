// lib/core/data/model/waiting_screen.dart
class WaitingScreenModel {
  final String? color; // e.g. "#FFFFFF" أو "AARRGGBB"
  final String? imageUrl;

  WaitingScreenModel({this.color, this.imageUrl});

  factory WaitingScreenModel.fromJson(Map<String, dynamic> json) {
    return WaitingScreenModel(
      color: json['color'] as String?,
      imageUrl: json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'color': color,
        'image_url': imageUrl,
      };
}
