import 'dart:convert';
import 'package:get/get.dart';
import '../core/data/model/Attribute.dart';
import '../core/data/model/category.dart';
import 'package:http/http.dart' as http;
import '../core/data/model/subcategory_level_one.dart';
import '../core/data/model/subcategory_level_two.dart';
import '../core/localization/changelanguage.dart';

class HomeController extends GetxController
    with GetSingleTickerProviderStateMixin {
  // ==================== [المتغيرات القابلة للمراقبة] ====================
  RxBool isGetFirstTime = false.obs;

  // ------ التصنيفات الرئيسية ------
  RxList<Category> categoriesList = <Category>[].obs;
  RxBool isLoadingCategories = false.obs;

  // ------ التصنيفات الفرعية (المستوى الأول) ------
  RxList<SubcategoryLevelOne> subCategories = <SubcategoryLevelOne>[].obs;
  RxBool isLoadingSubcategoryLevelOne = false.obs;

  // ------ التصنيفات الفرعية (المستوى الثاني) ------
  RxList<SubcategoryLevelTwo> subCategoriesLevelTwo = <SubcategoryLevelTwo>[].obs;
  RxBool isLoadingSubcategoryLevelTwo = false.obs;

  // ------ الخصائص (Attributes) ------
  RxList<Attribute> attributes = <Attribute>[].obs;
  RxBool isLoadingAttributes = false.obs;

  // ------ تعريفات التصنيفات المحددة ------
  Rx<String?> nameOfMainCate = Rx<String?>(null);
  Rx<int?> idOfMainCate = Rx<int?>(null);
  Rx<String?> nameOfSubCate = Rx<String?>(null);
  Rx<int?> idOfSubCate = Rx<int?>(null);
  Rx<String?> nameOfSubTwo = Rx<String?>(null);
  Rx<int?> idOFSubTwo = Rx<int?>(null);

  // ------ تتبع الحالة الحالية ------
  Rx<int?> currentCategoryId = Rx<int?>(null);
  Rx<int?> currentSubCategoryId = Rx<int?>(null);
  var currentAdsPeriod = ''.obs;

  // Maps لتتبع آخر فترة تم جلبها
  final Map<int, String> _lastAdsPeriodForCategory = {};
  final Map<int, String> _lastAdsPeriodForSubOne = {};

  @override
  void onInit() {
    super.onInit();
    if (!isGetFirstTime.value) {
      fetchCategories(Get.find<ChangeLanguageController>().currentLocale.value.languageCode);
      isGetFirstTime.value = true;
    }
  }

  // ------ مسح جميع البيانات المؤقتة ------
  void clearAllTempData() {
    // لا نمسح التصنيفات الرئيسية
    subCategories.clear();
    subCategoriesLevelTwo.clear();
    attributes.clear();
    
    nameOfMainCate.value = null;
    idOfMainCate.value = null;
    nameOfSubCate.value = null;
    idOfSubCate.value = null;
    nameOfSubTwo.value = null;
    idOFSubTwo.value = null;
    
    currentCategoryId.value = null;
    currentSubCategoryId.value = null;
    currentAdsPeriod.value = '';
  }

  // ------ مسح بيانات التصنيفات الفرعية فقط ------
  void clearSubCategories() {
    subCategories.clear();
    subCategoriesLevelTwo.clear();
    currentSubCategoryId.value = null;
  }

  // ------ مسح بيانات المستوى الثاني فقط ------
  void clearSubCategoriesLevelTwo() {
    subCategoriesLevelTwo.clear();
  }

  // ------ جلب التصنيفات الرئيسية ------
  Future<void> fetchCategories(String language, {String? adsPeriod}) async {
    isLoadingCategories.value = true;
    currentAdsPeriod.value = adsPeriod ?? '';

    try {
      Uri uri = Uri.parse(
        '$_baseUrl/categories/${Get.find<ChangeLanguageController>().currentLocale.value.languageCode}'
      );
      
      if (adsPeriod != null && adsPeriod.isNotEmpty) {
        uri = uri.replace(queryParameters: {'ads_period': adsPeriod});
      }

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        
        if (jsonResponse['status'] == 'success') {
          final List<dynamic> data = jsonResponse['data'] as List<dynamic>;
          categoriesList.value = data
              .map((category) => Category.fromJson(category as Map<String, dynamic>))
              .toList();
        } else {
          print("Success false: ${jsonResponse['message']}");
        }
      } else {
        print("Error ${response.statusCode}: ${response.body}");
      }
    } catch (e) {
      print("Error fetching categories: $e");
    } finally {
      isLoadingCategories.value = false;
    }
  }

  // ------ جلب التصنيفات الفرعية (المستوى الأول) ------
  Future<void> fetchSubcategories(int categoryId, String language, {String? adsPeriod, bool forceRefresh = false}) async {
    final String period = adsPeriod ?? '';

    // التحقق مما إذا كنا نحتاج إلى جلب بيانات جديدة
    final bool needsRefresh = forceRefresh ||
        currentCategoryId.value != categoryId ||
        _lastAdsPeriodForCategory[categoryId] != period ||
        subCategories.isEmpty;

    if (!needsRefresh) {
      return;
    }

    // تحديث الحالة الحالية
    currentCategoryId.value = categoryId;
    _lastAdsPeriodForCategory[categoryId] = period;
    currentAdsPeriod.value = period;

    // مسح البيانات القديمة إذا كان التصنيف مختلف
    if (currentCategoryId.value != categoryId) {
      subCategories.clear();
    }

    isLoadingSubcategoryLevelOne.value = true;

    try {
      Map<String, String> queryParams = {
        'category_id': categoryId.toString(),
        'language': language,
      };

      if (period.isNotEmpty) {
        queryParams['ads_period'] = period;
      }

      final uri = Uri.parse('$_baseUrl/subcategories').replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonMap = json.decode(response.body);

        if (jsonMap['success'] == true) {
          final List<dynamic> list = jsonMap['data'] as List<dynamic>;
          subCategories.value = list
              .map((e) => SubcategoryLevelOne.fromJson(e as Map<String, dynamic>))
              .toList();
        } else {
          subCategories.clear();
        }
      } else {
        print('Error ${response.statusCode} when fetching subcategories for category $categoryId');
        subCategories.clear();
      }
    } catch (e, st) {
      print('Exception fetchSubcategories($categoryId): $e\n$st');
      subCategories.clear();
    } finally {
      isLoadingSubcategoryLevelOne.value = false;
    }
  }

  // ------ جلب التصنيفات الفرعية (المستوى الثاني) ------
  Future<void> fetchSubcategoriesLevelTwo(int subCategoryId, String language, {String? adsPeriod, bool forceRefresh = false}) async {
    final String period = adsPeriod ?? '';

    // التحقق مما إذا كنا نحتاج إلى جلب بيانات جديدة
    final bool needsRefresh = forceRefresh ||
        currentSubCategoryId.value != subCategoryId ||
        _lastAdsPeriodForSubOne[subCategoryId] != period ||
        subCategoriesLevelTwo.isEmpty;

    if (!needsRefresh) {
      return;
    }

    // تحديث الحالة الحالية
    currentSubCategoryId.value = subCategoryId;
    _lastAdsPeriodForSubOne[subCategoryId] = period;
    currentAdsPeriod.value = period;

    // مسح البيانات القديمة إذا كان التصنيف الفرعي مختلف
    if (currentSubCategoryId.value != subCategoryId) {
      subCategoriesLevelTwo.clear();
    }

    isLoadingSubcategoryLevelTwo.value = true;

    try {
      Map<String, String> queryParams = {
        'sub_category_level_one_id': subCategoryId.toString(),
        'language': language,
      };

      if (period.isNotEmpty) {
        queryParams['ads_period'] = period;
      }

      final uri = Uri.parse('$_baseUrl/subcategories-level-two').replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonMap = json.decode(response.body);

        if (jsonMap['success'] == true) {
          final List<dynamic> list = jsonMap['data'] as List<dynamic>;
          subCategoriesLevelTwo.value = list
              .map((e) => SubcategoryLevelTwo.fromJson(e as Map<String, dynamic>))
              .toList();
        } else {
          subCategoriesLevelTwo.clear();
        }
      } else {
        print('Error ${response.statusCode} when fetching subcategories level two for subOne $subCategoryId');
        subCategoriesLevelTwo.clear();
      }
    } catch (e, st) {
      print('Exception fetchSubcategoriesLevelTwo($subCategoryId): $e\n$st');
      subCategoriesLevelTwo.clear();
    } finally {
      isLoadingSubcategoryLevelTwo.value = false;
    }
  }

  // ------ جلب الخصائص (Attributes) ------
  Future<void> fetchAttributes(int categoryId, String language) async {
    isLoadingAttributes.value = true;
    
    try {
      final uri = Uri.parse(
          '$_baseUrl/categories/$categoryId/attributes?lang=${Get.find<ChangeLanguageController>().currentLocale.value.languageCode}');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data != null && data is Map<String, dynamic> && data['success'] == true) {
          final List<dynamic> list = data['attributes'];
          attributes.value = list
              .map((json) => Attribute.fromJson(json as Map<String, dynamic>))
              .toList();
        } else {
          attributes.clear();
        }
      } else {
        print('HTTP ${response.statusCode}');
        attributes.clear();
      }
    } catch (e) {
      print(e);
      attributes.clear();
    } finally {
      isLoadingAttributes.value = false;
    }
  }

  // ------ دالة للمساعدة في الحصول على العدد الكلي للإعلانات في التصنيفات الفرعية ------
  int get totalSubCategoriesAdsCount {
    return subCategories.fold(0, (sum, subCategory) => sum + subCategory.adsCount);
  }

  // ------ إعادة تعيين فترة الإعلانات ------
  void resetAdsPeriod() {
    currentAdsPeriod.value = '';
  }

  // ------ تعيين فترة الإعلانات ------
  void setAdsPeriod(String period) {
    currentAdsPeriod.value = period;
  }

  final String _baseUrl = "https://stayinme.arabiagroup.net/lar_stayInMe/public/api";
}