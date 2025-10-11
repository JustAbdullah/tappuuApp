// lib/core/data/model/TermsAndConditions.dart
class TermsAndConditions {
  final int id;
  final String title;
  final String content;
  final String? language;

  TermsAndConditions({
    required this.id,
    required this.title,
    required this.content,
    this.language,
  });

  factory TermsAndConditions.fromJson(Map<String, dynamic> json) {
    return TermsAndConditions(
      id: json['id'] as int,
      title: json['title'] as String,
      content: json['content'] as String,
      language: json['language'] as String?,
    );
  }
}