// lib/core/data/model/AboutUs.dart
class AboutUs {
  final int id;
  final String title;
  final String description;
  final String? facebook;
  final String? twitter;
  final String? instagram;
  final String? youtube;
  final String? whatsapp;
  final String? contactNumber; // جديد
  final String? contactEmail;  // جديد

  AboutUs({
    required this.id,
    required this.title,
    required this.description,
    this.facebook,
    this.twitter,
    this.instagram,
    this.youtube,
    this.whatsapp,
    this.contactNumber,
    this.contactEmail,
  });

  factory AboutUs.fromJson(Map<String, dynamic> json) {
    return AboutUs(
      id: (json['id'] is int) ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      facebook: json['facebook']?.toString(),
      twitter: json['twitter']?.toString(),
      instagram: json['instagram']?.toString(),
      youtube: json['youtube']?.toString(),
      whatsapp: json['whatsapp']?.toString(),
      contactNumber: json['contact_number']?.toString() ?? json['contactNumber']?.toString(),
      contactEmail: json['contact_email']?.toString() ?? json['contactEmail']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'facebook': facebook,
      'twitter': twitter,
      'instagram': instagram,
      'youtube': youtube,
      'whatsapp': whatsapp,
      'contact_number': contactNumber,
      'contact_email': contactEmail,
    };
  }

  AboutUs copyWith({
    int? id,
    String? title,
    String? description,
    String? facebook,
    String? twitter,
    String? instagram,
    String? youtube,
    String? whatsapp,
    String? contactNumber,
    String? contactEmail,
  }) {
    return AboutUs(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      facebook: facebook ?? this.facebook,
      twitter: twitter ?? this.twitter,
      instagram: instagram ?? this.instagram,
      youtube: youtube ?? this.youtube,
      whatsapp: whatsapp ?? this.whatsapp,
      contactNumber: contactNumber ?? this.contactNumber,
      contactEmail: contactEmail ?? this.contactEmail,
    );
  }
}
