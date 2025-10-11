// lib/controllers/listing_share_controller.dart

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

/// Controller مسؤول عن بناء روابط صفحة الإعلانات وإنشاء نصوص المشاركة.
/// يمكنه بناء روابط تحتوي على معظم الفلاتر: التصنيفات، البحث، المدينة/المنطقة،
/// الفلاتر الجغرافية، السمات (attributes)، timeframe، featured، وقائمة ad_ids.
class ListingShareController extends GetxController {
  /// المضيف الأساسي المستخدم في الروابط (غير مُنقّح)
  final String baseHost = 'https://testing.arabiagroup.net';

  /// يبني رابط /ads مع query params من المعطيات.
  /// - attributes: قائمة من خرائط key/value ستُحول إلى JSON ثم تُشفر.
  /// - adIds: قائمة معرفات إعلانات (ستمرر كـ ad_ids=1,2,3)
  String buildListingUrl({
    int? categoryId,
    int? subCategoryLevelOneId,
    int? subCategoryLevelTwoId,
    String? search,
    String? sortBy,
    String order = 'desc',
    double? latitude,
    double? longitude,
    double? distanceKm,
    List<Map<String, dynamic>>? attributes,
    int? cityId,
    int? areaId,
    String? timeframe,
    bool onlyFeatured = false,
    String? preset, // 'latest' أو 'featured' أو أي قيمة مُتفق عليها
    int page = 1,
    int perPage = 15,
    String? lang,
    List<int>? adIds, // لو تريد مشاركة مجموعة إعلانات محددة
  }) {
    final params = <String, String>{};

    void add(String key, Object? value) {
      if (value == null) return;
      params[key] = value.toString();
    }

    add('lang', lang ?? 'ar');
    add('page', page);
    add('per_page', perPage);
    add('order', order);

    add('category_id', categoryId);
    add('sub_category_level_one_id', subCategoryLevelOneId);
    add('sub_category_level_two_id', subCategoryLevelTwoId);

    if (search != null && search.trim().isNotEmpty) {
      add('search', search.trim());
    }

    add('sort_by', sortBy);

    add('latitude', latitude);
    add('longitude', longitude);
    add('distance', distanceKm);

    add('city_id', cityId);
    add('area_id', areaId);

    if (timeframe != null && timeframe.trim().isNotEmpty) {
      add('timeframe', timeframe.trim());
    }

    if (onlyFeatured) {
      params['only_featured'] = '1';
    }

    if (preset != null && preset.trim().isNotEmpty) {
      add('preset', preset.trim());
    }

    // attributes -> JSON encode then URI encode
    if (attributes != null && attributes.isNotEmpty) {
      try {
        final encoded = Uri.encodeComponent(jsonEncode(attributes));
        params['attributes'] = encoded;
      } catch (e) {
        // إذا فشل الترميز نتجاهل السمات وتسجيل للأخطاء ممكن في المستقبل
        // لا نرمي استثناء لأن الرابط يجب أن يبقى صالحًا
      }
    }

    // adIds -> CSV
    if (adIds != null && adIds.isNotEmpty) {
      params['ad_ids'] = adIds.join(',');
    }

    final uri = Uri.parse('$baseHost/ads').replace(queryParameters: params);
    return uri.toString();
  }

  /// يبني رسالة قابلة للمشاركة (title + optional subtitle + url + optional details)
  /// يمكنك تعديل النص الدعائي هنا ليتماشى مع أسلوب تطبيقك
  String buildShareMessage({
    required String title,
    String? subtitle,
    required String url,
    int? resultsCount,
    String? footer, // نص ختامي اختياري
  }) {
    final buffer = StringBuffer();
    buffer.writeln(title.trim());
    if (subtitle != null && subtitle.trim().isNotEmpty) {
      buffer.writeln();
      buffer.writeln(subtitle.trim());
    }
    if (resultsCount != null) {
      buffer.writeln();
      buffer.write('عدد النتائج: $resultsCount');
    }
    buffer.writeln();
    buffer.writeln(url);
    if (footer != null && footer.trim().isNotEmpty) {
      buffer.writeln();
      buffer.writeln(footer.trim());
    }
    return buffer.toString();
  }

  /// دالة للمشاركة الفعلية.
  /// - copyToClipboard: إذا true سيتم نسخ الرابط إلى الحافظة بدل المشاركة الفورية.
  /// - attributes و adIds تُحفظان في الرابط (مشفّرة إن لزم).
  Future<void> shareListing({
    int? categoryId,
    int? subCategoryLevelOneId,
    int? subCategoryLevelTwoId,
    String? search,
    String? sortBy,
    String order = 'desc',
    double? latitude,
    double? longitude,
    double? distanceKm,
    List<Map<String, dynamic>>? attributes,
    int? cityId,
    int? areaId,
    String? timeframe,
    bool onlyFeatured = false,
    String? preset,
    required String lang,
    int page = 1,
    int perPage = 15,
    String? title, // عنوان الدعوة في الرسالة
    String? subtitle, // نص دعائي قصير
    int? resultsCount,
    bool copyToClipboard = false,
    String? footer,
    List<int>? adIds,
  }) async {
    final url = buildListingUrl(
      categoryId: categoryId,
      subCategoryLevelOneId: subCategoryLevelOneId,
      subCategoryLevelTwoId: subCategoryLevelTwoId,
      search: search,
      sortBy: sortBy,
      order: order,
      latitude: latitude,
      longitude: longitude,
      distanceKm: distanceKm,
      attributes: attributes,
      cityId: cityId,
      areaId: areaId,
      timeframe: timeframe,
      onlyFeatured: onlyFeatured,
      preset: preset,
      page: page,
      perPage: perPage,
      lang: lang,
      adIds: adIds,
    );

    final finalTitle = title ?? _buildDefaultTitle(
      onlyFeatured: onlyFeatured,
      preset: preset,
      categoryId: categoryId,
    );

    final finalSubtitle = subtitle ?? _buildDefaultSubtitle(
      search: search,
      timeframe: timeframe,
      cityId: cityId,
      areaId: areaId,
      onlyFeatured: onlyFeatured,
    );

    final message = buildShareMessage(
      title: finalTitle,
      subtitle: finalSubtitle,
      url: url,
      resultsCount: resultsCount,
      footer: footer,
    );

    if (copyToClipboard) {
      await Clipboard.setData(ClipboardData(text: url));
      Get.snackbar('تم النسخ', 'تم نسخ رابط المشاركة إلى الحافظة', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    await Share.share(message);
  }

  // -------------------- Helpers لنصوص افتراضية دعائية --------------------

  String _buildDefaultTitle({
    bool onlyFeatured = false,
    String? preset,
    int? categoryId,
  }) {
    if (onlyFeatured) {
      return 'اطّلع على أفضل الإعلانات المميزة الآن';
    }
    if (preset != null && preset == 'latest') {
      return 'اكتشف أحدث الإعلانات الآن';
    }
    if (categoryId != null) {
      // يمكنك استبدال هذا بنطق اسم التصنيف الفعلي لو متوفر
      return 'اكتشف إعلانات الفئة المختارة';
    }
    return 'إلقِ نظرة على الإعلانات المتاحة';
  }

  String _buildDefaultSubtitle({
    String? search,
    String? timeframe,
    int? cityId,
    int? areaId,
    bool onlyFeatured = false,
  }) {
    final parts = <String>[];
    if (search != null && search.trim().isNotEmpty) {
      parts.add('بحث: "${search.trim()}"');
    }
    if (timeframe != null && timeframe.trim().isNotEmpty) {
      parts.add('خلال: $timeframe');
    }
    if (cityId != null) {
      parts.add('المدينة: $cityId');
    }
    if (areaId != null) {
      parts.add('المنطقة: $areaId');
    }
    if (onlyFeatured) {
      parts.add('مميزة فقط');
    }
    if (parts.isEmpty) return 'تصفّح الآن أفضل العروض';
    return parts.join(' • ');
  }
}
