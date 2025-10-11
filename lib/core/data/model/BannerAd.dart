class BannerAd {
  final int?
      bannerId; // يمكن أن يكون null عند الإنشاء لأنه يتم توليده من السيرفر
  final String bannerImage;
  final DateTime bannerDate;

  BannerAd({
    this.bannerId,
    required this.bannerImage,
    required this.bannerDate,
  });

  // تحويل البيانات من JSON إلى كائن Dart
  factory BannerAd.fromJson(Map<String, dynamic> json) {
    return BannerAd(
      bannerId: json['banner_id'],
      bannerImage: json['banner_image'],
      bannerDate: DateTime.parse(json['banner_date']),
    );
  }

  // تحويل الكائن إلى JSON لإرساله عبر HTTP
  Map<String, dynamic> toJson() {
    return {
      'banner_image': bannerImage,
      // تأكد من تنسيق التاريخ بالشكل المناسب (YYYY-MM-DD)
      'banner_date': bannerDate.toIso8601String().substring(0, 10),
    };
  }
}
