// lib/models/favorite_seller.dart


import 'AdResponse.dart';

class FavoriteSeller {
  final int followId;
  final int advertiserProfileId;
  final Advertiser advertiser; // نفس الكلاس الموجود مع Ad
  final DateTime followedAt;

  FavoriteSeller({
    required this.followId,
    required this.advertiserProfileId,
    required this.advertiser,
    required this.followedAt,
  });

  factory FavoriteSeller.fromJson(Map<String, dynamic> json) {
    return FavoriteSeller(
      followId: (json['follow_id'] as int?) ?? 0,
      advertiserProfileId: (json['advertiser_profile_id'] as int?) ??
          (json['advertiser']?['id'] as int?) ??
          0,
      advertiser: json['advertiser'] != null
          ? Advertiser.fromJson(json['advertiser'] as Map<String, dynamic>)
          : Advertiser(
              name: json['name'] as String?,
              description: (json['description'] as String?) ?? '',
              logo: (json['logo'] as String?) ?? '',
              contactPhone: (json['contact_phone'] as String?) ?? '',
              whatsappPhone: (json['whatsapp_phone'] as String?) ?? '',
            ),
      followedAt: json['followed_at'] != null
          ? DateTime.parse(json['followed_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJsonToggle(int userId) {
    return {
      'user_id': userId,
      'advertiser_profile_id': advertiserProfileId,
    };
  }
}
