// lib/core/data/model/EditableTextModel.dart
class EditableTextModel {
  final int id;
  final String keyName;
  final String textContent;
  final String? fontUrl;
  final int fontSize;
  final String color;
  final String? createdAt;
  final String? updatedAt;

  EditableTextModel({
    required this.id,
    required this.keyName,
    required this.textContent,
    this.fontUrl,
    required this.fontSize,
    required this.color,
    this.createdAt,
    this.updatedAt,
  });

  factory EditableTextModel.fromJson(Map<String, dynamic> json) {
    return EditableTextModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      keyName: json['key_name'] ?? json['keyName'] ?? '',
      textContent: json['text_content'] ?? json['textContent'] ?? '',
      fontUrl: json['font_url']?.toString(),
      fontSize: json['font_size'] is int
          ? json['font_size']
          : int.tryParse(json['font_size']?.toString() ?? '') ?? 16,
      color: json['color']?.toString() ?? '#000000',
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'key_name': keyName,
      'text_content': textContent,
      'font_url': fontUrl,
      'font_size': fontSize,
      'color': color,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  EditableTextModel copyWith({
    String? textContent,
    int? fontSize,
    String? color,
    String? fontUrl,
  }) {
    return EditableTextModel(
      id: id,
      keyName: keyName,
      textContent: textContent ?? this.textContent,
      fontUrl: fontUrl ?? this.fontUrl,
      fontSize: fontSize ?? this.fontSize,
      color: color ?? this.color,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
