import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../core/data/model/AdResponse.dart';
import '../core/data/model/CategoryAttributesResponse.dart';
import '../core/data/model/City.dart';
import '../core/localization/changelanguage.dart';
import '../core/data/model/Area.dart' as area;

class AdsController extends GetxController {
  RxBool showMap = false.obs;
  // ==================== متغيرات طريقة العرض ====================
  var viewMode = 'vertical_simple'.obs;
  void changeViewMode(String mode) => viewMode.value = mode;
var currentAttributes = <Map<String, dynamic>>[].obs;


// ==================== إعدادات API ====================
  final String _baseUrl = 'https://stayinme.arabiagroup.net/lar_stayInMe/public/api';
  
  // ==================== قوائم البيانات الرئيسية ====================
  var adsList           = <Ad>[].obs;
  var filteredAdsList   = <Ad>[].obs;
  RxBool isLoadingAds   = false.obs;
  
  // ==================== قائمة الإعلانات المميزة ====================
  var featuredAds            = <Ad>[].obs;
  RxBool isLoadingFeatured   = false.obs;

  // فترة الجلب: '24h', '48h' أو null
  Rxn<String> currentTimeframe = Rxn<String>();
  // هل نريد فقط الإعلانات المميزة؟
  RxBool onlyFeatured = false.obs;

  // ==================== إدارة البحث ====================
  var currentSearch = ''.obs;              // نص البحث الحالي (تم تغيير الاسم من searchQuery)
  TextEditingController searchController = TextEditingController();
  Timer? _searchDebounceTimer;             // مؤقت لإلغاء الطلبات المتكررة
  RxBool isSearching = false.obs;          // حالة البحث الجارية
  RxBool serverSideSearchEnabled = true.obs; // تفعيل/تعطيل البحث من الخادم

  // ==================== معايير الجلب الحالية ====================
  var currentCategoryId = 0.obs;           // التصنيف الرئيسي الحالي
  var currentSubCategoryLevelOneId = Rxn<int>(); // التصنيف الفرعي المستوى الأول
  var currentSubCategoryLevelTwoId = Rxn<int>(); // التصنيف الفرعي المستوى الثاني
  var currentLang =Get.find<ChangeLanguageController>().currentLocale.value.languageCode;             // اللغة الحالية
  
  // ==================== إضافة المتغيرات الناقصة ====================
  var currentSortBy = Rxn<String>();       // طريقة الفرز الحالية (السعر، التاريخ، إلخ)
  var currentOrder = 'desc'.obs;           // اتجاه الفرز (تصاعدي/تنازلي)
  
  // ==================== إدارة الموقع الجغرافي ====================
  Rxn<double> latitude = Rxn<double>();    // خط العرض الحالي
  Rxn<double> longitude = Rxn<double>();   // خط الطول الحالي
  RxBool isLoadingLocation = false.obs;    // حالة تحميل الموقع

  // ==================== إدارة المدن والمناطق ====================
  var citiesList = <TheCity>[].obs;        // قائمة المدن
  var isLoadingCities = false.obs;         // حالة تحميل المدن
  var selectedCity = Rxn<TheCity>();       // المدينة المختارة
  var selectedArea = Rxn<area.Area>();          // المنطقة المختارة

  // ==================== إدارة السمات ====================
  var attributesList = <CategoryAttribute>[].obs; // سمات التصنيف
  RxBool isLoadingAttributes = false.obs;  // حالة تحميل السمات

var allAdsList = <Ad>[].obs;


  @override
  void onInit() {
    super.onInit();

       // أول ما ينفتح، حمّل الإعلانات المميزة
    loadFeaturedAds();
    // تفاعل مع تغيير نص البحث
    currentSearch.listen((query) {
      if (query.isEmpty) {
        filteredAdsList.assignAll(adsList);
      } else {
        if (serverSideSearchEnabled.value) {
          _searchDebounceTimer?.cancel();
          _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
            fetchAds(
              categoryId: currentCategoryId.value,
              subCategoryLevelOneId: currentSubCategoryLevelOneId.value,
              subCategoryLevelTwoId: currentSubCategoryLevelTwoId.value,
              search: query,
              lang: Get.find<ChangeLanguageController>().currentLocale.value.languageCode,
            );
          });
        } else {
          _localSearch(query);
        }
      }
    });
  }

  // ==================== البحث المحلي ====================
  void _localSearch(String query) {
    final lowerQuery = query.toLowerCase();
    filteredAdsList.assignAll(adsList.where((ad) {
      return ad.title.toLowerCase().contains(lowerQuery) ||
             ad.description.toLowerCase().contains(lowerQuery) ||
             (ad.price != null && _formatPrice(ad.price!).toLowerCase().contains(lowerQuery)) ||
             (ad.city?.name.toLowerCase().contains(lowerQuery) ?? false);
    }).toList());
  }
String Thelang = Get.find<ChangeLanguageController>().currentLocale.value.languageCode;
// ==================== جلب الإعلانات (الوظيفة الأساسية) ====================
// ==================== جلب الإعلانات (الوظيفة الأساسية) ====================
Future<void> fetchAds({
  // التصنيفات
  int? categoryId,
  int? subCategoryLevelOneId,
  int? subCategoryLevelTwoId,

  // البحث والفرز
  String? search,
  String? sortBy,        // 'price', 'date', 'views', ...
  String order = 'desc', // 'asc' أو 'desc'

  // الفلترة الجغرافية
  double? latitude,
  double? longitude,
  double? distanceKm,    // مسافة بالكم

  // فلترة السمات
  List<Map<String, dynamic>>? attributes,

  // فلترة المدينة والمنطقة
  int? cityId,
  int? areaId,

  // **الفلاتر الجديدة**
  String? timeframe,     // '24h', '48h' أو null (كل الإعلانات)
  bool onlyFeatured = false, // جلب المميزة فقط؟

  // إعدادات عامة
  required String lang,
  int page = 1,
  int perPage = 15,
}) async {
  // 1) حفظ الحالة بمحاذاة الـ Rx
  currentCategoryId.value            = categoryId ?? 0;
  currentSubCategoryLevelOneId.value = subCategoryLevelOneId;
  currentSubCategoryLevelTwoId.value = subCategoryLevelTwoId;
  currentSearch.value                = search?.trim() ?? '';
  currentSortBy.value                = sortBy;
  currentOrder.value                 = order;
 
  currentAttributes.value            = attributes ?? [];
  
  currentTimeframe.value             = timeframe;
  this.onlyFeatured.value            = onlyFeatured;
  currentLang                        = lang;

  isLoadingAds.value = true;
  try {
    // 2) قرر متى تستخدم POST /ads/filter
    final bool useFilterEndpoint =
         categoryId != null
      || subCategoryLevelOneId != null
      || subCategoryLevelTwoId != null
      || (search?.isNotEmpty ?? false)
      || sortBy != null
      || latitude != null
      || longitude != null
      || distanceKm != null
      || (attributes != null && attributes.isNotEmpty)
      || cityId != null
      || areaId != null
      || onlyFeatured
      || (timeframe != null && timeframe != 'all');

    late http.Response response;

    if (useFilterEndpoint) {
      // === POST إلى /ads/filter ===
      final uri = Uri.parse('$_baseUrl/ads/filter');
      final body = <String, dynamic>{
        if (categoryId != null)            'category_id':             categoryId,
        if (subCategoryLevelOneId != null) 'sub_category_level_one_id': subCategoryLevelOneId,
        if (subCategoryLevelTwoId != null) 'sub_category_level_two_id': subCategoryLevelTwoId,
        if (search?.isNotEmpty ?? false)   'search':                    search!.trim(),
        if (sortBy != null)                'sort_by':                   sortBy,
        'order':                           order,
        if (latitude  != null)             'latitude':                  latitude,
        if (longitude != null)             'longitude':                 longitude,
        if (distanceKm!= null)             'distance':                  distanceKm,
        if (attributes != null && attributes.isNotEmpty)
                                           'attributes':                attributes,
        if (cityId != null)                'city_id':                   cityId,
        if (areaId != null)                'area_id':                   areaId,
        if (timeframe != null && timeframe != 'all')
                                           'timeframe':                 timeframe,
        if (onlyFeatured)                  'only_featured':             true,
        'lang':                            lang,
        'page':                            page,
        'per_page':                        perPage,
      };

      print('📤 [POST REQUEST] URL: $uri');
      print('📤 [POST BODY] ${json.encode(body)}');

      response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );
    } else {
      // === GET إلى /ads ===
      final params = <String, String>{
        'lang':      lang,
        'page':      page.toString(),
        'per_page':  perPage.toString(),
        'order':     order,
      };
      final uri = Uri.parse('$_baseUrl/ads').replace(queryParameters: params);
      print('📤 [GET REQUEST] URL: $uri');
      response = await http.get(uri);
    }

    // 3) المعالجة
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body) as Map<String, dynamic>;
      final rawList = (jsonData['data'] as List<dynamic>);
      var ads = AdResponse.fromJson({'data': rawList}).data;

      // 4) إذا أرسلنا latitude/longitude، احسب المسافة ورتّب القائمة
      if (latitude != null && longitude != null) {
        double _deg2rad(double deg) => deg * pi / 180;
        double haversine(double lat1, double lng1, double lat2, double lng2) {
          const R = 6371; // نصف قطر الأرض بالكلم
          final dLat = _deg2rad(lat2 - lat1);
          final dLon = _deg2rad(lng2 - lng1);
          final a = sin(dLat/2)*sin(dLat/2)
                  + cos(_deg2rad(lat1))*cos(_deg2rad(lat2))
                  * sin(dLon/2)*sin(dLon/2);
          final c = 2*atan2(sqrt(a), sqrt(1 - a));
          return R*c;
        }

        ads.sort((a, b) {
          final da = haversine(latitude, longitude, a.latitude!, a.longitude!);
          final db = haversine(latitude, longitude, b.latitude!, b.longitude!);
          return da.compareTo(db);
        });
      }

     adsList.value         = ads;
  filteredAdsList.value = ads;
  allAdsList.value      = ads; // تأكد من تعيين allAdsList هنا

    } else {
      print('❌ [ERROR] HTTP ${response.statusCode}');
      Get.snackbar("خطأ", "تعذّر جلب الإعلانات (${response.statusCode})");
    }
  } catch (e, st) {
    print('‼️ [EXCEPTION] $e');
    print(st);
    Get.snackbar("خطأ", "حدث خطأ أثناء جلب الإعلانات");
  } finally {
    isLoadingAds.value = false;
  }
}



////
  /// دالة تحميل الإعلانات المميزة (POST /ads/filter)
  Future<void> loadFeaturedAds() async {
    isLoadingFeatured.value = true;
    try {
      final uri = Uri.parse('$_baseUrl/ads/filter');
      final body = {
        'only_featured': true,
        'per_page':      4,
        'lang':          Get.find<ChangeLanguageController>()
                            .currentLocale
                            .value
                            .languageCode,
        'timeframe':     'all',
      };

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'] as List;
        featuredAds.assignAll(AdResponse.fromJson({'data': data}).data);
      }
    } catch (e) {
      print('‼️ Featured exception: $e');
    } finally {
      isLoadingFeatured.value = false;
    }
  }

///
Future<void> searchByImage({
  required File imageFile,
  int page = 1,
  int perPage = 15,
  String lang = 'ar',
  int? categoryId,
  int? cityId,
}) async {
  isLoadingAds.value = true;

  try {
    final uri = Uri.parse('$_baseUrl/ads/search-by-image');
    final request = http.MultipartRequest('POST', uri);

    // ملف الصورة
    request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

    // حقول إضافية (اختياري)
    request.fields['lang'] = lang;
    request.fields['page'] = page.toString();
    request.fields['per_page'] = perPage.toString();
    if (categoryId != null) request.fields['category_id'] = categoryId.toString();
    if (cityId != null) request.fields['city_id'] = cityId.toString();

    // لو تستخدم توكين (Auth) أضفه هنا
    // final token = await someAuth.getToken();
    // request.headers['Authorization'] = 'Bearer $token';

    final streamedResp = await request.send();
    final resp = await http.Response.fromStream(streamedResp);

    if (resp.statusCode == 200) {
      final Map<String, dynamic> jsonData = json.decode(resp.body);
      final List rawList = jsonData['data'] as List<dynamic>;

      // تحويل إلى نماذج Ad (نفس الأسلوب اللي تستخدمه في fetchAds)
      // افترض أن لديك AdResponse.fromJson كما في الكود القديم
      final ads = AdResponse.fromJson({'data': rawList}).data;

      // عيّن القوائم
    
      filteredAdsList.value = ads;      // القائمة التي تُعرض بعد الفلترة
     
      // لو أردت: استخرج واطبع أعلى similarity لكل عنصر
      for (var item in rawList) {
        // بعض الخانات الإضافية قد تكون داخل كل عنصر (مثل 'similarity')
        // قم بطباعتها إن رغبت
        // print('Similarity: ${item['similarity']} for ad ${item['id']}');
      }

    } else {
      print('❌ searchByImage failed: ${resp.statusCode} ${resp.body}');
      Get.snackbar('خطأ', 'خطأ في البحث بالصور (${resp.statusCode})');
    }
  } catch (e, st) {
    print('‼️ searchByImage exception: $e');
    print(st);
    Get.snackbar('خطأ', 'حدث خطأ أثناء البحث بالصورة');
  } finally {
    isLoadingAds.value = false;
  }
}
//
  // ==================== وظائف الموقع الجغرافي ====================
    RxDouble selectedRadius = 1.0.obs;

  
  Future<void> ensureLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || 
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse && 
          permission != LocationPermission.always) {
        Get.snackbar("خطأ", "يرجى منح إذن الوصول إلى الموقع الجغرافي");
      }
    }
  }
  
  Future<void> fetchCurrentLocation() async {
    try {
      isLoadingLocation.value = true;
      await ensureLocationPermission();
      
      if (!await Geolocator.isLocationServiceEnabled()) {
        Get.snackbar("خطأ", "يرجى تفعيل خدمة الموقع الجغرافي");
        return;
      }
      
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(Duration(seconds: 10), onTimeout: () async {
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium
        );
      });
      
      latitude.value = position.latitude;
      longitude.value = position.longitude;
    } catch (e) {
      Get.snackbar("خطأ", "تعذر الحصول على الموقع: ${e.toString()}");
    } finally {
      isLoadingLocation.value = false;
    }
  }
  
  void clearLocation() {
    latitude.value = null;
    longitude.value = null;
  }

  // ==================== وظائف السمات ====================
  Future<void> fetchAttributes({
    required int categoryId,
    String lang = 'ar',
  }) async {
    isLoadingAttributes.value = true;
    try {
      final uri = Uri.parse('$_baseUrl/categories/$categoryId/attributes')
          .replace(queryParameters: {'lang': lang});
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        final resp = CategoryAttributesResponse.fromJson(jsonData);
        if (resp.success) {
          attributesList.value = resp.attributes;
        }
      }
    } catch (e) {
      print('خطأ في جلب السمات: $e');
    } finally {
      isLoadingAttributes.value = false;
    }
  }

  // ==================== وظائف المدن والمناطق ====================
  Future<void> fetchCities(String countryCode, String language) async {
    isLoadingCities.value = true;
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/cities/$countryCode/$language')
      );
      
      if (response.statusCode == 200) {
        final dynamic decodedData = json.decode(response.body);
        
        if (decodedData is List) {
          citiesList.value = decodedData
            .map((jsonCity) => TheCity.fromJson(jsonCity as Map<String, dynamic>))
            .toList();
        } else if (decodedData is Map && decodedData.containsKey('data')) {
          final List<dynamic> listJson = decodedData['data'];
          citiesList.value = listJson
            .map((jsonCity) => TheCity.fromJson(jsonCity as Map<String, dynamic>))
            .toList();
        }
      }
    } catch (e) {
      print("خطأ في جلب المدن: $e");
    } finally {
      isLoadingCities.value = false;
    }
  }
  
  void selectCity(TheCity? city) {
    selectedCity.value = city;
    selectedArea.value = null;
  }
  
  void selectArea(area.Area? area) {
    selectedArea.value = area;
  }

  // ==================== وظائف إضافية ====================
  Future<int> incrementViews(int adId) async {
    try {
      final response = await http.post(
        Uri.parse('${_baseUrl}/ads/$adId/views')
      );
      
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        return body['views'] as int;
      } else {
        throw Exception('فشل في زيادة المشاهدات: ${response.statusCode}');
      }
    } catch (e) {
      print("خطأ في زيادة المشاهدات: $e");
      rethrow;
    }
  }

  // ==================== أدوات مساعدة ====================
  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)} مليون';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)} ألف';
    }
    return price.toStringAsFixed(0);
  }

  @override
  void onClose() {
    _searchDebounceTimer?.cancel();
    super.onClose();
  }
  /// يمسح كل الفلاتر ويعيد القيم إلى الافتراضي
void clearAllFilters() {
  // مسح البحث
  currentSearch.value = '';
  searchController.clear();
  isSearching.value   = false;

  // مسح السمات
  currentAttributes.clear();

  // مسح الفلاتر الجغرافية
  selectedCity.value = null;
  selectedArea.value = null;

  // إعادة الفرز الافتراضي
  currentSortBy.value = null;
  currentOrder.value  = 'desc';
}

String? toTimeframe(int? hours) {
  if (hours == null)   return null;    // كل الإعلانات
  if (hours == 24)     return '24h';
  if (hours == 48)     return '48h';
  // لو حاب تدعم less common periods:
  if (hours == 2*24)   return '2_days';
  return null; // الافتراضي
}




// افترض أن المتغيرات التالية موجودة في الكلاس:
// final RxBool isLoadingAds = false.obs;
// final String _baseUrl = 'https://...';
// final RxList<Ad> adsList = <Ad>[].obs; // مثال

/// Search ads by image (sends data URL base64 to server)
Future<void> searchAdsByImage({
  required XFile imageFile,
  required String lang,
  int page = 1,
  int perPage = 15,
  // حقول التصنيف الإضافية (اختيارية، لن تُرسل إذا كانت null)
  int? categoryId,
  int? subCategoryLevelOneId,
  int? subCategoryLevelTwoId,
  // debug كما كان
  bool debug = false,
}) async {
  try {
    isLoadingAds.value = true; // أو متغير loading خاص
    // اقرأ البايتات (لا تقم بتحويلها إلى string ضخم في الـ UI thread إن كانت كبيرة)
    final bytes = await File(imageFile.path).readAsBytes();
    final base64Str = base64Encode(bytes);

    // حدّد MIME type بسيط من امتداد الصورة
    final lower = imageFile.path.toLowerCase();
    String mime = 'image/jpeg';
    if (lower.endsWith('.png')) mime = 'image/png';
    else if (lower.endsWith('.webp')) mime = 'image/webp';

    final dataUrl = 'data:$mime;base64,$base64Str';

    final uri = Uri.parse('$_baseUrl/ads/search-by-image');

    final body = {
      'image': dataUrl,
      'lang': lang,
      'page': page,
      'per_page': perPage,
      'debug': debug,
    };

    // أضف الحقول الاختيارية فقط إن وُجدت
    if (categoryId != null) {
      body['category_id'] = categoryId;
    }
    if (subCategoryLevelOneId != null) {
      body['sub_category_level_one_id'] = subCategoryLevelOneId;
    }
    if (subCategoryLevelTwoId != null) {
      body['sub_category_level_two_id'] = subCategoryLevelTwoId;
    }

    print('📤 [IMAGE SEARCH] POST $uri, payload size ~ ${ (base64Str.length / 1024).toStringAsFixed(1) } KB');

    final response = await http
        .post(uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(body))
        .timeout(const Duration(seconds: 120)); // زِد المهلة حسب حجم الصور والسيرفر

    print('📥 [IMAGE SEARCH] Response: ${response.statusCode}');

    if (response.statusCode == 200) {
      final map = json.decode(response.body) as Map<String, dynamic>;
      if (map['status'] == 'success') {
        if (debug && map['info'] != null) {
          print("📊 Debug info: ${json.encode(map['info'])}");
        }
        final rawList = (map['data'] as List<dynamic>);
        final ads = AdResponse.fromJson({'data': rawList}).data;

        // ضع النتائج في نفس متغيرات الواجهة
        adsList.value = ads;
        filteredAdsList.value = ads;
        allAdsList.value = ads;

        // لو تريد إظهار الدرجات الأولى
        if (ads.isNotEmpty) {
        }
      } else {
        final msg = map['message'] ?? 'خطأ من السيرفر';
        print('❌ IMAGE SEARCH failed: $msg');
        Get.snackbar('خطأ', msg, snackPosition: SnackPosition.BOTTOM);
      }
    } else {
      print('❌ IMAGE SEARCH HTTP error ${response.statusCode} : ${response.body}');
      Get.snackbar('خطأ', 'تعذّر البحث بالصور (${response.statusCode})', snackPosition: SnackPosition.BOTTOM);
    }
  } catch (e, st) {
    print('⚠️ Exception searchAdsByImage: $e');
    print(st);
    Get.snackbar('خطأ', 'حدث خطأ أثناء البحث بالصور', snackPosition: SnackPosition.BOTTOM);
  } finally {
    isLoadingAds.value = false;
  }
}


RxBool isLoadingAdminAds = false.obs;
  Future<void> deleteAd(int adId) async {
    isLoadingAdminAds.value = true;
    try {
      final uri = Uri.parse('$_baseUrl/ads/$adId');
      final response = await http.delete(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        if (jsonResponse['status'] == 'success') {
          _showSnackbar('نجاح', jsonResponse['message'] ?? 'تم حذف الإعلان بنجاح', false);
        } else {
          _showSnackbar('خطأ', jsonResponse['message'] ?? 'فشل حذف الإعلان', true);
        }
      } else {
        _showSnackbar('خطأ', 'خطأ في الاتصال بالسيرفر (${response.statusCode})', true);
      }
    } catch (e) {
      _showSnackbar('خطأ', 'حدث خطأ أثناء حذف الإعلان: $e', true);
    } finally {
      isLoadingAdminAds.value = false;
    }
  }

  void _showSnackbar(String title, String message, bool isError) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: isError ? Colors.redAccent : Colors.green,
      colorText: Colors.white,
      borderRadius: 10,
      margin: EdgeInsets.all(15),
      duration: Duration(seconds: isError ? 4 : 3),
      icon: Icon(isError ? Icons.error_outline : Icons.check_circle, color: Colors.white),
      shouldIconPulse: true,
      dismissDirection: DismissDirection.horizontal,
    );
  }
}