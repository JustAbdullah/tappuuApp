import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import 'package:image_picker/image_picker.dart';
import 'package:translator/translator.dart';
import 'package:video_player/video_player.dart';
import '../core/data/model/AdResponse.dart';
import '../core/data/model/AdvertiserProfile.dart';
import '../core/data/model/Attribute.dart';
import '../core/data/model/Area.dart' as area;
import '../core/data/model/City.dart';
import '../core/data/model/category.dart';
import '../core/data/model/subcategory_level_one.dart';
import '../core/data/model/subcategory_level_two.dart';
import '../core/localization/changelanguage.dart';
import 'AuthController.dart';
import 'LoadingController.dart';
import 'NotificationController.dart';
import 'areaController.dart';

class ManageAdController extends GetxController {
  String _baseUrl = "https://stayinme.arabiagroup.net/lar_stayInMe/public/api";
  RxInt currentImageIndex = 0.obs;
  // Main categories
  var categoriesList = <Category>[].obs;
  var isLoadingCategories = false.obs;
  var selectedMainCategory = Rxn<Category>();
  
  // Subcategories level one
  var subCategories = <SubcategoryLevelOne>[].obs;
  var isLoadingSubcategoryLevelOne = false.obs;
  var selectedSubcategoryLevelOne = Rxn<SubcategoryLevelOne>();
  
  // Subcategories level two
  var subCategoriesLevelTwo = <SubcategoryLevelTwo>[].obs;
  var isLoadingSubcategoryLevelTwo = false.obs;
  var selectedSubcategoryLevelTwo = Rxn<SubcategoryLevelTwo>();
  
  // Attributes
  var attributes = <Attribute>[].obs;
  var isLoadingAttributes = false.obs;
  
  // المدن والمناطق
  var citiesList = <TheCity>[].obs;
  var isLoadingCities = false.obs;
  var selectedCity = Rxn<TheCity>();
  var selectedArea = Rxn<area.Area>();
  
  // بيانات الإعلان
  var titleArController = TextEditingController();
  var titleEnController = TextEditingController();
  var descriptionArController = TextEditingController();
  var descriptionEnController = TextEditingController();
  var priceController = TextEditingController();
  
  // الصور
  var loadingImages = false.obs;
  var uploadedImageUrls = "".obs;
  var images = <File>[].obs;
  
  // الموقع الجغرافي
  Rxn<double> latitude = Rxn<double>();
  Rxn<double> longitude = Rxn<double>();
  RxBool isLoadingLocation = false.obs;
  
  // حالة الإرسال
  var isSubmitting = false.obs;
  
  // قيم الخصائص الديناميكية
  var attributeValues = <int, dynamic>{}.obs;
  
  // تحكم المناطق
  final areaController = Get.put(AreaController());
  
  // المترجم
  final translator = GoogleTranslator();
  final translationCache = <String, String>{};
  
  // حالة الترجمة
  var isTranslating = false.obs;
  var translationProgress = 0.0.obs;
  var totalItemsToTranslate = 0.obs;
  
  @override
  void onInit() {
    super.onInit();
    fetchCategories(Get.find<ChangeLanguageController>().currentLocale.value.languageCode);
    fetchCities('SY', Get.find<ChangeLanguageController>().currentLocale.value.languageCode);
  }

  // جلب التصنيفات الرئيسية
  Future<void> fetchCategories(String language) async {
    isLoadingCategories.value = true;
    try {
      final response = await http.get(Uri.parse('$_baseUrl/categories/$language'));
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        var fetchedCategories = (data['data'] as List)
            .map((category) => Category.fromJson(category))
            .toList();
        categoriesList.value = fetchedCategories;
      }
    } catch (e) {
      print("Error fetching categories: $e");
    } finally {
      isLoadingCategories.value = false;
    }
  }
  
  void selectMainCategory(Category category) {
    selectedMainCategory.value = category;
    selectedSubcategoryLevelOne.value = null;
    selectedSubcategoryLevelTwo.value = null;
    subCategoriesLevelTwo.clear();
    fetchSubcategories(category.id, 'ar');
    fetchAttributes(category.id, 'ar');
  }
  
  // جلب التصنيفات الفرعية
Future<void> fetchSubcategories(int Theid, String language) async {
  subCategories.clear();
  isLoadingSubcategoryLevelOne.value = true;
  try {
    final response = await http.get(Uri.parse(
      '$_baseUrl/subcategories?category_id=$Theid&language=${Get.find<ChangeLanguageController>().currentLocale.value.languageCode}',
    ));

    if (response.statusCode == 200) {
      // 1) نحول الرد إلى خريطة
      final Map<String, dynamic> jsonMap = json.decode(response.body);

      // 2) نتأكد إنه success
      if (jsonMap['success'] == true) {
        // 3) نأخذ قائمة البيانات من المفتاح 'data'
        final List<dynamic> list = jsonMap['data'] as List<dynamic>;

        // 4) نحول كل عنصر في القائمة إلى موديل
        final fetchedSubCategories = list
            .map((e) => SubcategoryLevelOne.fromJson(e as Map<String, dynamic>))
            .toList();

        subCategories.value = fetchedSubCategories;
      } else {
        subCategories.clear();
      }
    } else {
      print('Error ${response.statusCode}');
    }
  } catch (e) {
    print('Exception fetchSubcategories: $e');
  } finally {
    isLoadingSubcategoryLevelOne.value = false;
  }
}
  
  void selectSubcategoryLevelOne(SubcategoryLevelOne subcategory) {
    selectedSubcategoryLevelOne.value = subcategory;
    selectedSubcategoryLevelTwo.value = null;
    fetchSubcategoriesLevelTwo(subcategory.id, Get.find<ChangeLanguageController>().currentLocale.value.languageCode);
  }
  
  // جلب التصنيفات الثانوية
 Future<void> fetchSubcategoriesLevelTwo(int Theid, String language) async {
  subCategoriesLevelTwo.clear();
  isLoadingSubcategoryLevelTwo.value = true;
  try {
    final response = await http.get(Uri.parse(
      '$_baseUrl/subcategories-level-two?sub_category_level_one_id=$Theid&language=${Get.find<ChangeLanguageController>().currentLocale.value.languageCode}',
    ));

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonMap = json.decode(response.body);

      if (jsonMap['success'] == true) {
        final List<dynamic> list = jsonMap['data'] as List<dynamic>;
        
        final fetchedSubCategories = list
            .map((e) => SubcategoryLevelTwo.fromJson(e as Map<String, dynamic>))
            .toList();

        subCategoriesLevelTwo.value = fetchedSubCategories;
      } else {
        subCategoriesLevelTwo.clear();
      }
    } else {
      print('Error ${response.statusCode}');
    }
  } catch (e) {
    print('Exception fetchSubcategoriesLevelTwo: $e');
  } finally {
    isLoadingSubcategoryLevelTwo.value = false;
  }
}

  
  void selectSubcategoryLevelTwo(SubcategoryLevelTwo subcategory) {
    selectedSubcategoryLevelTwo.value = subcategory;
  }
  
  // جلب الخصائص
  Future<void> fetchAttributes(int categoryId, String language) async {
    attributes.clear();
    isLoadingAttributes.value = true;
    try {
      final uri = Uri.parse('$_baseUrl/categories/$categoryId/attributes?lang=$language');
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data is Map<String, dynamic> && data['success'] == true) {
          final List<dynamic> list = data['attributes'];
          final fetched = list
              .map((json) => Attribute.fromJson(json as Map<String, dynamic>))
              .toList();
          attributes.value = fetched;
        }
      }
    } catch (e) {
      print("Error fetching attributes: $e");
    } finally {
      isLoadingAttributes.value = false;
    }
  }
  
  // اختيار الصور
  Future<void> pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();
    if (pickedFiles != null) {
      for (var file in pickedFiles) {
        images.add(File(file.path));
      }
    }
  }
  
  void removeImage(int index) {
    images.removeAt(index);
  }
  
  // تحديث صورة محددة
  Future<void> updateImage(int index) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      images[index] = File(pickedFile.path);
    }
  }
  
  // رفع الصور للخادم
  Future<void> uploadImagesToServer() async {
    try {
      loadingImages.value = true;
      if (images.isEmpty) return;
      
      var request = http.MultipartRequest('POST', Uri.parse("$_baseUrl/upload"));
      
      for (var image in images) {
        if (await File(image.path).exists()) {
          request.files.add(
            await http.MultipartFile.fromPath('images[]', image.path)
          );
        }
      }
      
      var response = await request.send();
      if (response.statusCode == 201) {
        var responseData = await response.stream.bytesToString();
        var jsonData = json.decode(responseData);
        uploadedImageUrls.value = List<String>.from(jsonData['image_urls']).join(',');
      } else {
        throw Exception("Failed to upload images");
      }
    } catch (e) {
      throw Exception("Image upload error: $e");
    } finally {
      loadingImages.value = false;
    }
  }
  
//Hell every One Time Day Open Nice;

  ////
 

 
  ///
  // إدارة الموقع الجغرافي
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
      Get.snackbar("خطأ", "تعذر الحصول على الموقع الجغرافي: $e");
    } finally {
      isLoadingLocation.value = false;
    }
  }
  
  void clearLocation() {
    latitude.value = null;
    longitude.value = null;
  }
  
  // جلب المدن
Future<void> fetchCities(String countryCode, String language) async {
  isLoadingCities.value = true;
  try {
    final url = '$_baseUrl/cities/$countryCode/$language';
    final response = await http.get(Uri.parse(url));
    
    if (response.statusCode == 200) {
      final dynamic decodedData = json.decode(response.body);
      
      // الحالة 1: إذا كانت الاستجابة مباشرة قائمة من المدن
      if (decodedData is List) {
        final fetched = decodedData
          .map((jsonCity) {
            try {
              return TheCity.fromJson(jsonCity as Map<String, dynamic>);
            } catch (e) {
              print("Error parsing city: $e");
              return null;
            }
          })
          .where((city) => city != null)
          .cast<TheCity>()
          .toList();
          
        citiesList.value = fetched;
      }
      // الحالة 2: إذا كانت الاستجابة تحتوي على كائن به مفتاح "data"
      else if (decodedData is Map && decodedData.containsKey('data')) {
        final List<dynamic> listJson = decodedData['data'];
        
        final fetched = listJson
          .map((jsonCity) {
            try {
              return TheCity.fromJson(jsonCity as Map<String, dynamic>);
            } catch (e) {
              print("Error parsing city: $e");
              return null;
            }
          })
          .where((city) => city != null)
          .cast<TheCity>()
          .toList();
          
        citiesList.value = fetched;
      } else {
        print("Unknown response format: $decodedData");
      }
    } else {
      print("HTTP error ${response.statusCode}: ${response.body}");
    }
  } catch (e) {
    print("Error fetching cities: $e");
  } finally {
    isLoadingCities.value = false;
  }
}
  
  void selectCity(TheCity city) {
    selectedCity.value = city;
    selectedArea.value = null;
  }
  
  void selectArea(area.Area area) {
    selectedArea.value = area;
  }
  
  // التحقق مما إذا كان النص بالإنجليزية
  bool _isEnglish(String text) {
    if (text.isEmpty) return false;
    final englishRegex = RegExp(r'[a-zA-Z]');
    return englishRegex.hasMatch(text[0]);
  }
  
  // الترجمة التلقائية مع التخزين المؤقت وإعادة المحاولة
  Future<String> autoTranslate(String text, {int retries = 2}) async {
    try {
      // إذا كان النص فارغًا
      if (text.trim().isEmpty) return "";
      
      // التحقق من التخزين المؤقت
      if (translationCache.containsKey(text)) {
        return translationCache[text]!;
      }
      
      // إذا كان النص إنجليزيًا بالفعل
      if (_isEnglish(text)) {
        translationCache[text] = text;
        return text;
      }
      
      // إجراء الترجمة
      final translation = await translator.translate(text, from: 'ar', to: 'en');
      final translatedText = translation.text;
      
      // تخزين في ذاكرة التخزين المؤقت
      translationCache[text] = translatedText;
      
      return translatedText;
    } catch (e) {
      print("Translation error: $e");
      
      // إعادة المحاولة إذا كانت متاحة
      if (retries > 0) {
        await Future.delayed(Duration(seconds: 1));
        return autoTranslate(text, retries: retries - 1);
      }
      
      // في حالة فشل الترجمة، نرجع النص الأصلي
      return text;
    }
  }
  //////////الفيديو//////


  var selectedVideos = <PlatformFile>[].obs;
  var videoPlayers = <VideoPlayerController>[].obs;
  var uploadedVideoUrls = <String>[].obs;

  // 2) دالة اختيار الفيديو من الجهاز (متعدد)
  Future<void> pickVideos() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: true,
    );
    if (result != null && result.files.isNotEmpty) {
      selectedVideos.assignAll(result.files);
      // إنشاء VideoPlayerControllers للمعاينة
      videoPlayers.clear();
      for (final file in selectedVideos) {
        final controller =
            VideoPlayerController.file(File(file.path!));
        await controller.initialize();
        videoPlayers.add(controller);
      }
    }
  }

  // 3) دالة رفع الفيديوهات إلى السيرفر
  Future<void> uploadVideosToServer() async {
    if (selectedVideos.isEmpty) return;
    uploadedVideoUrls.clear();

    final uri = Uri.parse('$_baseUrl/videos/upload');
    final request = http.MultipartRequest('POST', uri);

    // أضف كل ملف إلى الطلب
    for (final file in selectedVideos) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'videos[]',
          File(file.path!).readAsBytesSync(),
          filename: file.name,
        ),
      );
    }

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode == 201) {
      final data = json.decode(body) as Map<String, dynamic>;
      final urls = List<String>.from(data['video_urls'] ?? []);
      uploadedVideoUrls.assignAll(urls);
    } else {
      throw Exception('فشل في رفع الفيديوهات: $body');
    }
  }

///
  var hasError = false.obs;
Future<int?> submitAd({bool? isPay, dynamic premiumDays}) async {
  try {
    print("🚀 بدء عملية إرسال الإعلان...");

    // 1) تهيئة الحالات
    isSubmitting.value = true;
    isTranslating.value = true;
    translationProgress.value = 0.0;

    // --- دالة مساعدة محلية لتحويل الأرقام العربية إلى لاتينية
    String _normalizeArabicNumbers(String s) {
      if (s.isEmpty) return s;
      const arabicNums1 = ['٠','١','٢','٣','٤','٥','٦','٧','٨','٩'];
      const arabicNums2 = ['۰','۱','۲','۳','۴','۵','۶','۷','۸','۹'];
      const western = ['0','1','2','3','4','5','6','7','8','9'];
      var out = s;
      for (int i = 0; i < arabicNums1.length; i++) {
        out = out.replaceAll(arabicNums1[i], western[i]);
      }
      for (int i = 0; i < arabicNums2.length; i++) {
        out = out.replaceAll(arabicNums2[i], western[i]);
      }
      return out.trim();
    }

    // 2) التحقق من البيانات الأساسية
    print("🔍 التحقق من البيانات الأساسية...");

    if (titleArController.text.trim().isEmpty) {
      print("❌ خطأ: حقل العنوان فارغ");
      Get.snackbar(
        "خطأ",
        "⚠️ حقل العنوان مطلوب ولا يمكن تركه فارغًا",
        colorText: Colors.white,
        backgroundColor: Colors.red,
      );
      return null;
    }

    if (descriptionArController.text.trim().isEmpty) {
      print("❌ خطأ: حقل الوصف فارغ");
      Get.snackbar(
        "خطأ",
        "⚠️ حقل الوصف مطلوب ولا يمكن تركه فارغًا",
        colorText: Colors.white,
        backgroundColor: Colors.red,
      );
      return null;
    }

    if (selectedMainCategory.value == null) {
      print("❌ خطأ: لم يتم اختيار تصنيف رئيسي");
      Get.snackbar(
        "خطأ",
        "📂 يجب اختيار تصنيف رئيسي للإعلان",
        colorText: Colors.white,
        backgroundColor: Colors.red,
      );
      return null;
    }

    if (images == null || images.isEmpty) {
      print("❌ خطأ: لم يتم رفع أي صور");
      Get.snackbar(
        "خطأ",
        "🖼️ يجب رفع صورة واحدة على الأقل للإعلان",
        colorText: Colors.white,
        backgroundColor: Colors.red,
      );
      return null;
    }

    if (latitude.value == null || longitude.value == null) {
      print("❌ خطأ: الموقع الجغرافي غير محدد");
      Get.snackbar(
        "خطأ",
        "📍 يجب تحديد الموقع الجغرافي للإعلان",
        colorText: Colors.white,
        backgroundColor: Colors.red,
      );
      return null;
    }

    if (selectedCity.value == null) {
      print("❌ خطأ: لم يتم اختيار المدينة");
      Get.snackbar(
        "خطأ",
        "🏙️ يجب اختيار المدينة للإعلان",
        colorText: Colors.white,
        backgroundColor: Colors.red,
      );
      return null;
    }

    print("✅ تم التحقق من جميع البيانات الأساسية بنجاح");

    // 3) حساب عدد العناصر المطلوب ترجمتها
    int translationCounter = 2; // العنوان والوصف
    for (var attribute in attributes) {
      if (attributeValues.containsKey(attribute.attributeId) && attribute.type == 'text') {
        translationCounter++;
      }
    }
    totalItemsToTranslate.value = translationCounter;
    int translatedItems = 0;

    // 4) ترجمة العنوان والوصف
    print("🌐 بدء ترجمة النص...");
    String titleEn = '';
    String descriptionEn = '';

    try {
      titleEn = await autoTranslate(titleArController.text.trim());
      translatedItems++;
      translationProgress.value = translatedItems / translationCounter;
      print("✅ تمت ترجمة العنوان: $titleEn");
    } catch (e) {
      print("⚠️ فشل ترجمة العنوان، سنستعمل النص العربي كنسخة إنجليزية احتياطية: $e");
      titleEn = titleArController.text.trim();
    }

    try {
      descriptionEn = await autoTranslate(descriptionArController.text.trim());
      translatedItems++;
      translationProgress.value = translatedItems / translationCounter;
      print("✅ تمت ترجمة الوصف");
    } catch (e) {
      print("⚠️ فشل ترجمة الوصف، سنستعمل النص العربي كنسخة إنجليزية احتياطية: $e");
      descriptionEn = descriptionArController.text.trim();
    }

    // 5) رفع الصور
    print("📤 بدء رفع الصور إلى السيرفر...");
    await uploadImagesToServer();

    final imagesList = uploadedImageUrls.value
        .split(',')
        .where((url) => url != null && url.trim().isNotEmpty)
        .toList();

    if (imagesList.isEmpty) {
      print("❌ فشل في رفع الصور إلى السيرفر");
      Get.snackbar(
        "خطأ",
        "❌ فشل في رفع الصور إلى السيرفر",
        colorText: Colors.white,
        backgroundColor: Colors.red,
      );
      return null;
    }
    print("✅ تم رفع ${imagesList.length} صورة بنجاح");

    // 6) رفع الفيديوهات (اختياري)
    if (uploadedVideoUrls == null || uploadedVideoUrls.isEmpty) {
      try {
        await uploadVideosToServer();
      } catch (e) {
        print("⚠️ فشل رفع الفيديوهات أو لا يوجد فيديوهات: $e");
      }
    }

    // 7) تحضير بيانات الخصائص مع الترجمة
    print("🔧 تحضير بيانات الخصائص...");
    List<Map<String, dynamic>> attributesData = [];
    for (var attribute in attributes) {
      if (!attributeValues.containsKey(attribute.attributeId)) continue;
      var value = attributeValues[attribute.attributeId];

      if (attribute.type == 'options') {
        attributesData.add({
          "attribute_id": attribute.attributeId,
          "attribute_type": attribute.type,
          "attribute_option_id": value,
          "value_ar": null,
          "value_en": null,
        });
      } else if (attribute.type == 'boolean') {
        final boolValue = value as bool;
        attributesData.add({
          "attribute_id": attribute.attributeId,
          "attribute_type": attribute.type,
          "value_ar": boolValue ? "نعم" : "لا",
          "value_en": boolValue ? "Yes" : "No",
          "attribute_option_id": null,
        });
      } else if (attribute.type == 'text') {
        final valueAr = value.toString();
        String valueEn = valueAr;
        try {
          valueEn = await autoTranslate(valueAr);
        } catch (e) {
          print("⚠️ فشل ترجمة خاصية ${attribute.attributeId}، استخدام النص الأصلي: $e");
        }
        attributesData.add({
          "attribute_id": attribute.attributeId,
          "attribute_type": attribute.type,
          "value_ar": valueAr,
          "value_en": valueEn,
          "attribute_option_id": null,
        });
        translatedItems++;
        translationProgress.value = translatedItems / translationCounter;
      } else {
        attributesData.add({
          "attribute_id": attribute.attributeId,
          "attribute_type": attribute.type,
          "value_ar": value.toString(),
          "value_en": value.toString(),
          "attribute_option_id": null,
        });
      }
    }
    print("✅ تم تحضير ${attributesData.length} خاصية بنجاح");

    // 8) بناء جسم الإعلان
    print("📦 بناء جسم الإعلان...");

    print("selectedMainCategory.value: ${selectedMainCategory.value?.id}");
    print("selectedSubcategoryLevelOne.value: ${selectedSubcategoryLevelOne.value?.id}");
    print("selectedSubcategoryLevelTwo.value: ${selectedSubcategoryLevelTwo.value?.id}");
    print("selectedCity.value: ${selectedCity.value?.id}");
    print("selectedArea.value: ${selectedArea.value?.id}");
    print("loadingC.currentUser: ${loadingC.currentUser?.id}");
    print("idOfadvertiserProfiles.value: ${idOfadvertiserProfiles.value}");

    if (selectedMainCategory.value == null || selectedCity.value == null) {
      print("❌ خطأ: بعض البيانات الأساسية مفقودة بعد التحقق الأولي (mainCategory أو city)");
      Get.snackbar(
        "خطأ",
        "🔧 حدث خطأ في البيانات، يرجى المحاولة مرة أخرى",
        colorText: Colors.white,
        backgroundColor: Colors.red,
      );
      return null;
    }

    final mainCategory = selectedMainCategory.value!;
    final subCategoryOne = selectedSubcategoryLevelOne.value;
    final subCategoryTwo = selectedSubcategoryLevelTwo.value;
    final city = selectedCity.value!;

    // === معالجة متغيرات الدفع / الباقة ===
    final bool isp = isPay == true;
    int? parsedPremiumDays;

    if (isp) {
      // التحقق من وجود premiumDays
      if (premiumDays == null) {
        print("❌ خطأ: يجب تحديد عدد أيام الباقة عند اختيار الدفع");
        Get.snackbar(
          "خطأ",
          "⚠️ حدد عدد أيام الباقة (مثلاً 30 أو 60 أو 90) عند اختيار الدفع",
          colorText: Colors.white,
          backgroundColor: Colors.red,
        );
        return null;
      }

      // معالجة premiumDays
      if (premiumDays is int) {
        parsedPremiumDays = premiumDays;
      } else if (premiumDays is String) {
        final normalized = _normalizeArabicNumbers(premiumDays);
        parsedPremiumDays = int.tryParse(normalized);
      } else {
        print("❌ خطأ: نوع غير صحيح لعدد أيام الباقة");
        Get.snackbar(
          "خطأ",
          "⚠️ نوع غير صحيح لعدد أيام الباقة",
          colorText: Colors.white,
          backgroundColor: Colors.red,
        );
        return null;
      }

      if (parsedPremiumDays == null || parsedPremiumDays <= 0) {
        print("❌ خطأ: يجب تحديد عدد أيام الباقة صحيح عند اختيار الدفع");
        Get.snackbar(
          "خطأ",
          "⚠️ حدد عدد أيام الباقة صحيح (مثلاً 30 أو 60 أو 90) عند اختيار الدفع",
          colorText: Colors.white,
          backgroundColor: Colors.red,
        );
        return null;
      }
    }

    final adData = <String, dynamic>{
      "user_id": loadingC.currentUser?.id ?? 0,
      "advertiser_profile_id": idOfadvertiserProfiles.value,
      "category_id": mainCategory.id,
      "sub_category_level_one_id": subCategoryOne?.id,
      "sub_category_level_two_id": subCategoryTwo?.id,
      "city_id": city.id,
      "area_id": selectedArea.value?.id,
      "title_ar": titleArController.text.trim(),
      "title_en": titleEn,
      "description_ar": descriptionArController.text.trim(),
      "description_en": descriptionEn,
      "price": priceController.text.isNotEmpty ? priceController.text.trim() : null,
      "latitude": latitude.value,
      "longitude": longitude.value,
      "images": imagesList,
      "attributes": attributesData,
      if (uploadedVideoUrls != null && uploadedVideoUrls.isNotEmpty) "videos": uploadedVideoUrls.toList(),
    };

    // إضافة حقول الدفع والباقة
    adData['ispay'] = isp ? 1 : 0;
    if (isp && parsedPremiumDays != null) {
      adData['premium_days'] = parsedPremiumDays;
    }

    print("📊 بيانات الإعلان المُعدّة: ${json.encode(adData)}");

    // 9) إرسال الإعلان إلى السيرفر
    print("🌐 إرسال الإعلان إلى السيرفر...");
    final response = await http.post(
      Uri.parse('$_baseUrl/ads'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(adData),
    );

    final rawBody = response.body;
    print("📨 رد الخادم: ${response.statusCode} - ${response.body}");

    if (response.statusCode == 201) {
      hasError.value = false;

      final responseData = json.decode(rawBody) as Map<String, dynamic>;

      // normalize is_premium to boolean (supports int 0/1, string "0"/"1", true/false, null)
      final dynamic isPremiumRaw = responseData['is_premium'];
      final bool isPremium = (isPremiumRaw == 1 || isPremiumRaw == '1' || isPremiumRaw == true);

      // premium_expires_at قد يكون null أو سلسلة
      final String? premiumExpiresAt = responseData['premium_expires_at'] != null
          ? responseData['premium_expires_at'].toString()
          : null;

      print("✅ تم إنشاء الإعلان بنجاح!");

      String successMessage = "✅ تم نشر الإعلان بنجاح";
      if (isPremium && premiumExpiresAt != null && premiumExpiresAt.isNotEmpty) {
        successMessage += " كإعلان مميز حتى ${premiumExpiresAt}";
      }

      try {
        NotificationController _notificationController = Get.put(NotificationController());
        _notificationController.sendCategoryNotification(
          "إعلان جديد",
          "تم إضافة إعلان جديد في التصنيف الذي تابعته",
          "category_${mainCategory.id}",
        );
      } catch (e) {
        print("⚠️ تعذر إرسال الإشعار: $e");
      }

      // إعادة تهيئة الفورم وجلب بيانات المستخدم المحدثة
      resetForm();
      try {
        Get.put(AuthController());
        Get.find<AuthController>().fetchUserDataApi(loadingC.currentUser?.id ?? 0);
      } catch (e) {
        print("⚠️ لم أتمكن من تحديث بيانات المستخدم تلقائيًا: $e");
      }

      // === هنا نأخذ معرف الإعلان الذي أعاده السيرفر ونرده للمستدعي ===
      final int? createdId = (responseData['id'] is num) ? (responseData['id'] as num).toInt() : null;
      if (createdId != null) {
        print("🔎 createdAdId = $createdId");
      } else {
        print("⚠️ لم يتم إيجاد معرف الإعلان في استجابة السيرفر.");
      }

      return createdId;
    }

    // 10) معالجة الأخطاء
    print("❌ فشل في إنشاء الإعلان، رمز الاستجابة: ${response.statusCode}");
    hasError.value = true;

    Map<String, dynamic> errorMap = {};
    try {
      errorMap = json.decode(rawBody) as Map<String, dynamic>;
    } catch (_) {
      hasError.value = true;
      print("❌ فشل في تحليل استجابة الخطأ من السيرفر");
      Get.snackbar(
        "خطأ",
        "🔧 حدث خطأ تقني غير متوقع",
        colorText: Colors.white,
        backgroundColor: Colors.red,
      );
      return null;
    }

    final apiMessage = errorMap['message'] as String? ?? 'فشل في إضافة الإعلان';
    print("📋 رسالة الخطأ: $apiMessage");

    String validationMessages = '';
    if (errorMap.containsKey('errors')) {
      final errs = errorMap['errors'] as Map<String, dynamic>;
      validationMessages = errs.entries
          .map((e) => e.value is List ? '• ${(e.value as List).join(', ')}' : '• ${e.value}')
          .join('\n');

      print("📋 أخطاء التحقق: $validationMessages");
    }

    final fullMessage = [
      "❌ $apiMessage",
      if (validationMessages.isNotEmpty) "📋 التفاصيل:\n$validationMessages",
    ].join('\n');

    Get.snackbar(
      "خطأ",
      fullMessage,
      colorText: Colors.white,
      backgroundColor: Colors.orange,
    );

    return null;
  } catch (e, stack) {
    print("💥 حدث استثناء غير متوقع: $e");
    print("📜 Stack trace: $stack");
    Get.snackbar(
      "خطأ غير متوقع",
      "⚡ حدث خطأ غير متوقع أثناء محاولة نشر الإعلان: ${e.toString()}",
      colorText: Colors.white,
      backgroundColor: Colors.red,
    );
    return null;
  } finally {
    isSubmitting.value = false;
    isTranslating.value = false;
    print("🏁 انتهت عملية إرسال الإعلان");
  }
}


var TimeOverTime;

  
  ////////////////////
  // إعادة تعيين النموذج
  void resetForm() {
    titleArController.clear();
    titleEnController.clear();
    descriptionArController.clear();
    descriptionEnController.clear();
    priceController.clear();
    selectedMainCategory.value = null;
    selectedSubcategoryLevelOne.value = null;
    selectedSubcategoryLevelTwo.value = null;
    selectedCity.value = null;
    selectedArea.value = null;
    latitude.value = null;
    longitude.value = null;
    images.clear();
    uploadedImageUrls.value = "";
    attributeValues.clear();
    attributes.clear();
    subCategories.clear();
    subCategoriesLevelTwo.clear();
    translationCache.clear();
  }

  ////////....بيانات المعلن........../////
  var isProfilesLoading = false.obs;
  var advertiserProfiles = <AdvertiserProfile>[].obs;
  var selectedProfile = Rxn<AdvertiserProfile>();
RxInt idOfadvertiserProfiles = 0.obs;
  Future<void> fetchAdvertiserProfiles(int userId) async {
    isProfilesLoading(true);
    try {
      final res = await http.get(Uri.parse('https://stayinme.arabiagroup.net/lar_stayInMe/public/api/advertiser-profiles/$userId'));
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        advertiserProfiles.value = data.map((e) => AdvertiserProfile.fromJson(e)).toList();
      } else {
        Get.snackbar('خطأ', 'فشل جلب بيانات المعلن');
      }
    } catch (e) {
      Get.snackbar('خطأ', 'تأكد من اتصال الانترنت');
    } finally {
      isProfilesLoading(false);
    }
  }

///////
  final LoadingController loadingC = Get.find<LoadingController>();

/// تحديث إعلان موجود
String? _extractTitleFromAdMap(Map<String, dynamic>? ad) {
  if (ad == null) return null;
  if (ad.containsKey('title_ar') && ad['title_ar'] != null) {
    return ad['title_ar'].toString();
  }
  if (ad.containsKey('title_en') && ad['title_en'] != null) {
    return ad['title_en'].toString();
  }
  return null;
}

// --- مساعدات لجلب الإعلان واستخراج السعر ---
Future<Map<String, dynamic>?> _fetchAdRaw(int adId) async {
  try {
    final uri = Uri.parse('$_baseUrl/ads/$adId');
    final resp = await http.get(uri, headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    });
    if (resp.statusCode != 200) return null;
    final body = json.decode(resp.body);
    if (body is Map<String, dynamic>) {
      if (body.containsKey('ad') && body['ad'] is Map) return Map<String, dynamic>.from(body['ad']);
      return Map<String, dynamic>.from(body);
    }
    return null;
  } catch (e, st) {
    debugPrint('Error fetching ad: $e\n$st');
    return null;
  }
}

double? _extractPriceFromAdMap(Map<String, dynamic>? ad) {
  if (ad == null) return null;
  final keys = ['price', 'price_value', 'price_amount'];
  for (var k in keys) {
    if (ad.containsKey(k) && ad[k] != null) {
      var v = ad[k].toString().trim();
      // تحويل أرقام عربية إلى لاتينية إن وجدت
      final arabic = ['٠','١','٢','٣','٤','٥','٦','٧','٨','٩'];
      final latin  = ['0','1','2','3','4','5','6','7','8','9'];
      for (int i=0;i<arabic.length;i++) v = v.replaceAll(arabic[i], latin[i]);
      v = v.replaceAll(',', ''); // إزالة فواصل الآلاف
      final parsed = double.tryParse(v);
      if (parsed != null) return parsed;
    }
  }
  if (ad.containsKey('data') && ad['data'] is Map) {
    return _extractPriceFromAdMap(Map<String, dynamic>.from(ad['data']));
  }
  return null;
}

// --- الدالة المطلوبة: updateAd مع طباعة عند تغيير السعر ---
Future<void> updateAd(int adId) async {
  try {
    isSubmitting.value = true;

    // (أ) خذ السعر القديم من السيرفر قبل التحديث
    final beforeAd = await _fetchAdRaw(adId);
    final oldPrice = _extractPriceFromAdMap(beforeAd);
    debugPrint('🔎 oldPrice for ad $adId = $oldPrice');

    // 1) رفع الصور إذا تم تعديلها
    if (images.isNotEmpty) {
      await uploadImagesToServer();
      if (uploadedImageUrls.value.isEmpty) {
        throw Exception("فشل في رفع الصور");
      }
    }

    // 2) تجميع بيانات الخصائص كما في submitAd()
    List<Map<String, dynamic>> attributesData = [];
    for (var attribute in attributes) {
      if (attributeValues.containsKey(attribute.attributeId)) {
        final value = attributeValues[attribute.attributeId];
        if (attribute.type == 'options') {
          attributesData.add({
            "attribute_id": attribute.attributeId,
            "attribute_type": attribute.type,
            "attribute_option_id": value,
          });
        } else if (attribute.type == 'boolean') {
          final bool b = value as bool;
          attributesData.add({
            "attribute_id": attribute.attributeId,
            "attribute_type": attribute.type,
            "value_ar": b ? "نعم" : "لا",
            "value_en": b ? "Yes" : "No",
          });
        } else {
          attributesData.add({
            "attribute_id": attribute.attributeId,
            "attribute_type": attribute.type,
            "value_ar": value.toString(),
            "value_en": value.toString(),
          });
        }
      }
    }

    // 3) بناء جسم الطلب مع إرسال price كنص
    final adData = <String, dynamic>{
      "advertiser_profile_id": selectedProfile.value?.id,
      "category_id": selectedMainCategory.value?.id,
      "sub_category_level_one_id": selectedSubcategoryLevelOne.value?.id,
      "sub_category_level_two_id": selectedSubcategoryLevelTwo.value?.id,
      "city_id": selectedCity.value?.id,
      "area_id": selectedArea.value?.id,
      "title_ar": titleArController.text,
      "title_en": titleEnController.text,
      "description_ar": descriptionArController.text,
      "description_en": descriptionEnController.text,
      // ← هنا السعر كنص وليس رقم
      "price": priceController.text.trim().isNotEmpty
          ? priceController.text.trim()
          : null,
      "latitude": latitude.value,
      "longitude": longitude.value,
      if (uploadedImageUrls.value.isNotEmpty)
        "images": uploadedImageUrls.value.split(','),
      if (attributesData.isNotEmpty) "attributes": attributesData,
    };

    // 4) طباعة payload للـ debug
    debugPrint("➡️ updateAd payload (adId=$adId): ${json.encode(adData)}");

    // 5) الإرسال
    final uri = Uri.parse('$_baseUrl/ads/$adId');
    final response = await http.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode(adData),
    );

    // 6) طباعة الاستجابة للـ debug
    debugPrint("⬅️ updateAd status: ${response.statusCode}");
    debugPrint("⬅️ updateAd body: ${response.body}");

    if (response.statusCode == 200) {
      // 7) بعد نجاح التحديث: جِب الإعلان المحدث للتأكد من السعر الجديد
      final afterAd = await _fetchAdRaw(adId);
      final newPrice = _extractPriceFromAdMap(afterAd);
      final adTitle = _extractTitleFromAdMap(afterAd);

      debugPrint('🔎 newPrice for ad $adId = $newPrice');

      // 8) قارن الأسعار — لو تغيّر اطبع الرسالة في الترمنال
      final priceChanged = (oldPrice != null || newPrice != null) && (oldPrice != newPrice);
      if (priceChanged) {
      NotificationController _notificationController =  Get.put(NotificationController());
      _notificationController.sendUpdatePriceNotification("اشعار تحدي  سعر اعلان ما","تم تحديث سعر اعلان: $adTitleالسعر الجديد هو:$oldPrice",adId.toString());
      }

      Get.snackbar("نجاح", "تم تحديث الإعلان بنجاح");
    } else {
      final err = json.decode(response.body) as Map<String, dynamic>;
      String msg = err['message'] ?? "فشل في تحديث الإعلان";
      if (err['errors'] != null && err['errors'] is Map) {
        (err['errors'] as Map).forEach((k, v) {
          if (v is List) msg += "\n• ${v.join(', ')}";
        });
      }
      throw Exception(msg);
    }
  } catch (e, st) {
    debugPrint('‼️ updateAd error: $e\n$st');
    Get.snackbar("خطأ", e.toString());
  } finally {
    isSubmitting.value = false;
  }}

  ///


  ///
  // قائمة إعلانات المستخدم
var userAdsList = <Ad>[].obs;
RxBool isLoadingUserAds = false.obs;

/// جلب إعلانات المستخدم الخاصة به
Future<void> fetchUserAds({
  required int userId,
  String lang =    'ar',
  String status = 'published',
  int page = 1,
  int perPage = 15,
}) async {
  isLoadingUserAds.value = true;
  try {
    final queryParameters = {
      'user_id': userId.toString(),
      'lang':Get.find<ChangeLanguageController>().currentLocale.value.languageCode,
      'status': status,
      'page': page.toString(),
      'per_page': perPage.toString(),
    };

    final uri = Uri.parse('$_baseUrl/ads/user')
        .replace(queryParameters: queryParameters);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body) as Map<String, dynamic>;

      // نفترض أن AdResponse.fromJson يتعامل مع حقل "data" ويحوله لقائمة Ad
      final adResponse = AdResponse.fromJson(jsonData);

      userAdsList.value = adResponse.data;
    } else {
      print('Error fetching user ads: ${response.statusCode}');
    }
  } catch (e) {
    print('Exception fetching user ads: $e');
  } finally {
    isLoadingUserAds.value = false;
  }
}
//////

RxBool isDeletingAd = false.obs;
/// حذف إعلان حسب معرّف
Future<void> deleteAd(int adId) async {
  isDeletingAd.value = true;
  try {
    final uri = Uri.parse('$_baseUrl/ads/$adId');
    final response = await http.delete(uri);

    if (response.statusCode == 200) {
      Get.snackbar("نجاح", "تم حذف الإعلان بنجاح");
      // تحديث القائمة محليًا بإزالة الإعلان المحذوف
      userAdsList.removeWhere((ad) => ad.id == adId);
      userAdsList.removeWhere((ad) => ad.id == adId);
    } else {
      final err = json.decode(response.body);
      String msg = err['message'] ?? "فشل في حذف الإعلان";
      throw Exception(msg);
    }
  } catch (e) {
    Get.snackbar("خطأ", e.toString());
  } finally {
    isDeletingAd.value = false;
  }
}
// داخل ManageAdController
 Rx<Ad?> currentAd = Rx<Ad?>(null);
  RxBool isLoadingAd = false.obs;

  Future<void> fetchAdDetails(int adId) async {
  isLoadingAd.value = true;
  try {
    final response = await http.get(Uri.parse('$_baseUrl/ads/$adId'));
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      if (jsonData['data'] != null) {
        currentAd.value = Ad.fromJson(jsonData['data']);
        await _populateFormFields();
      }
    }
  } finally {
    isLoadingAd.value = false;
  }
}
// في ManageAdController
Future<void> _populateFormFields() async {
  final ad = currentAd.value;
  if (ad == null) return;

  titleArController.text    = ad.title;
  descriptionArController.text = ad.description;
  priceController.text      = ad.price?.toString() ?? '';

  // تعبئة التصنيفات باستخدام الـ ID
  selectedMainCategory.value = 
      categoriesList.firstWhereOrNull((cat) => cat.id == ad.category.id);

  if (selectedMainCategory.value != null) {
    await fetchSubcategories(selectedMainCategory.value!.id, Get.find<ChangeLanguageController>().currentLocale.value.languageCode);

    selectedSubcategoryLevelOne.value = subCategories
        .firstWhereOrNull((sub) => sub.id == ad.subCategoryLevelOne.id);

    if (selectedSubcategoryLevelOne.value != null) {
      await fetchSubcategoriesLevelTwo(
        selectedSubcategoryLevelOne.value!.id,
        Get.find<ChangeLanguageController>().currentLocale.value.languageCode,
      );

      if (ad.subCategoryLevelTwo != null) {
        selectedSubcategoryLevelTwo.value = subCategoriesLevelTwo
            .firstWhereOrNull((sub) => sub.id == ad.subCategoryLevelTwo!.id);
      }
    }
  }

  // تعبئة المدن والمناطق
  selectedCity.value = 
      citiesList.firstWhereOrNull((city) => city.id == ad.city?.id);

  if (selectedCity.value != null) {
    await areaController.fetchAreas(selectedCity.value!.id);
    selectedArea.value = areaController.areas
        .firstWhereOrNull((area) => area.id == ad.areaId);
  }

  // تعبئة الخصائص مع تحويل الأنواع
  for (var attr in ad.attributes) {
    final attribute = attributes
        .firstWhereOrNull((a) => a.label == attr.name);
    if (attribute == null) continue;

    dynamic value;
    switch (attribute.type) {
      case 'boolean':
        value = (attr.value == 'نعم' || attr.value == 'Yes');
        break;
      case 'number':
        value = double.tryParse(
          attr.value.replaceAll(RegExp(r'[^0-9.]'), ''),
        );
        break;
      default:
        value = attr.value;
    }

    attributeValues[attribute.attributeId] = value;
  }
}

  // تعبئة الموقع الجغرافي
 

///

}