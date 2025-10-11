import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:tappuu_app/core/constant/appcolors.dart';
import 'package:tappuu_app/core/constant/app_text_styles.dart';
import '../../controllers/AdsManageSearchController.dart';
import '../../controllers/ThemeController.dart';
import '../../controllers/areaController.dart';
import '../../core/data/model/Area.dart';
import '../../core/data/model/CategoryAttributesResponse.dart';
import '../../core/data/model/City.dart';
import '../../core/localization/changelanguage.dart';

class FilterScreen extends StatefulWidget {
  final int categoryId;
    final String ?currentTimeframe;
      final  bool onlyFeatured ;


  const FilterScreen({super.key, required this.categoryId, this.currentTimeframe,    this.onlyFeatured= false,
});

  @override
  _FilterScreenState createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  bool _isApplyingFilters = false;
  final AdsController _adsController = Get.find<AdsController>();
  final themeController = Get.find<ThemeController>();
  bool get isDarkMode => themeController.isDarkMode.value;
  
  final _formKey = GlobalKey<FormState>();
  final AreaController _areaController = Get.put(AreaController());
  
  final List<Map<String, dynamic>> timePeriods = [
    {'value': 'last_2_days', 'label': 'آخر يومين'.tr},
    {'value': 'last_week', 'label': 'آخر أسبوع'.tr},
    {'value': 'last_month', 'label': 'آخر شهر'.tr},
    {'value': 'last_year', 'label': 'آخر سنة'.tr},
    {'value': 'all', 'label': 'كل الاوقات'.tr},
  ];
  
  String? _selectedTimePeriod;
  final Map<int, dynamic> _attributeValues = {};
  TheCity? _tempSelectedCity;
  Area? _tempSelectedArea;

  @override
  void initState() {
    super.initState();
    _tempSelectedCity = _adsController.selectedCity.value;
    _tempSelectedArea = _adsController.selectedArea.value;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _adsController.fetchAttributes(categoryId: widget.categoryId,lang: Get.find<ChangeLanguageController>().currentLocale.value.languageCode);
      _adsController.fetchCities('SY',Get.find<ChangeLanguageController>().currentLocale.value.languageCode);
    });
  }

  @override
  void dispose() {
    _adsController.selectedCity.value = _tempSelectedCity;
    _adsController.selectedArea.value = _tempSelectedArea;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(isDarkMode),
      appBar: AppBar(
        title: Text(
          'فلترة الإعلانات'.tr,
          style: TextStyle(
            color: AppColors.onPrimary,
            fontFamily: AppTextStyles.appFontFamily,
            fontSize: AppTextStyles.xxlarge,

            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.appBar(isDarkMode),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.close, color: AppColors.onPrimary),
            onPressed: () {
              _adsController.selectedCity.value = _tempSelectedCity;
              _adsController.selectedArea.value = _tempSelectedArea;
              Get.back();
            },
          ),
        ],
      ),
      body: Obx(() {
        if (_adsController.isLoadingAttributes.value) {
          return Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2.0,
            ),
          );
        }
        
        return Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.only(bottom: 100.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAttributesSection(),
                _buildCityAreaSection(),
                _buildTimePeriodSection(),
              ],
            ),
          ),
        );
      }),
      bottomSheet: _buildActionButtons(),
    );
  }

  Widget _buildAttributesSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: Text(
              'الخصائص'.tr,
              style: TextStyle(
                fontFamily: AppTextStyles.appFontFamily,
                fontSize: AppTextStyles.xlarge,

                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          
          ..._adsController.attributesList.map((attribute) {
            return Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: Text(
                      attribute.label,
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: AppTextStyles.medium,

                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary(isDarkMode),
                      ),
                    ),
                  ),
                  _buildAttributeInput(attribute),
                  Divider(
                    height: 24.h,
                    color: AppColors.divider(isDarkMode),
                    thickness: 0.5,
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildAttributeInput(CategoryAttribute attribute) {
    switch (attribute.type) {
      case 'options':
        return _buildOptionsAttribute(attribute);
      case 'boolean':
        return _buildBooleanAttribute(attribute);
      case 'text':
        return _buildTextAttribute(attribute);
      case 'number':
        return _buildNumberAttribute(attribute);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildOptionsAttribute(CategoryAttribute attribute) {
    return DropdownButtonFormField<int>(
      value: _attributeValues[attribute.attributeId] as int?,
      decoration: InputDecoration(
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        filled: true,
        fillColor: AppColors.surface(isDarkMode),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(
            color: AppColors.border(isDarkMode),
            width: 0.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(
            color: AppColors.border(isDarkMode),
            width: 0.5,
          ),
        ),
      ),
      items: attribute.options.map((option) {
        return DropdownMenuItem<int>(
          value: option.id,
          child: Text(
            option.value,
            style: TextStyle(
              fontFamily: AppTextStyles.appFontFamily,
              fontSize: AppTextStyles.medium,

              color: AppColors.textPrimary(isDarkMode),
            ),
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _attributeValues[attribute.attributeId] = value;
        });
      },
      hint: Text(
        '${'اختر'.tr} ${attribute.label}',
        style: TextStyle(
          fontFamily: AppTextStyles.appFontFamily,
          fontSize: AppTextStyles.medium,

          color: AppColors.textSecondary(isDarkMode),
        ),
      ),
      style: TextStyle(
        fontFamily: AppTextStyles.appFontFamily,
        fontSize: AppTextStyles.medium,

        color: AppColors.textPrimary(isDarkMode),
      ),
      dropdownColor: AppColors.card(isDarkMode),
    );
  }

  Widget _buildBooleanAttribute(CategoryAttribute attribute) {
    final currentValue = _attributeValues[attribute.attributeId] as bool?;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _buildBooleanOption('نعم'.tr, currentValue == true, () {
          setState(() {
            _attributeValues[attribute.attributeId] = true;
          });
        }),
        SizedBox(width: 16.w),
        _buildBooleanOption('لا'.tr, currentValue == false, () {
          setState(() {
            _attributeValues[attribute.attributeId] = false;
          });
        }),
      ],
    );
  }

  Widget _buildBooleanOption(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface(isDarkMode),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: AppColors.border(isDarkMode),
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppTextStyles.appFontFamily,
            fontSize: AppTextStyles.medium,

            color: isSelected ? Colors.white : AppColors.textPrimary(isDarkMode),
          ),
        ),
      ),
    );
  }

  Widget _buildTextAttribute(CategoryAttribute attribute) {
    return TextFormField(
      controller: TextEditingController(
        text: _attributeValues[attribute.attributeId]?.toString() ?? '',
      ),
      onChanged: (value) {
        _attributeValues[attribute.attributeId] = value;
      },
      decoration: InputDecoration(
        hintText: '${'أدخل'.tr} ${attribute.label}',
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        filled: true,
        fillColor: AppColors.surface(isDarkMode),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(
            color: AppColors.border(isDarkMode),
            width: 0.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(
            color: AppColors.border(isDarkMode),
            width: 0.5,
          ),
        ),
      ),
      style: TextStyle(
        fontFamily: AppTextStyles.appFontFamily,
        fontSize: AppTextStyles.medium,

        color: AppColors.textPrimary(isDarkMode),
      ),
    );
  }

  Widget _buildNumberAttribute(CategoryAttribute attribute) {
    return TextFormField(
      controller: TextEditingController(
        text: _attributeValues[attribute.attributeId]?.toString() ?? '',
      ),
      keyboardType: TextInputType.number,
      onChanged: (value) {
        if (value.isNotEmpty) {
          final arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
          final latin = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
          final normalizedValue = value
            .split('')
            .map((char) {
              final index = arabic.indexOf(char);
              return index != -1 ? latin[index] : char;
            })
            .join('');
          
          _attributeValues[attribute.attributeId] = double.tryParse(normalizedValue);
        } else {
          _attributeValues[attribute.attributeId] = null;
        }
      },
      decoration: InputDecoration(
        hintText: '${'أدخل'.tr} ${attribute.label}',
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        filled: true,
        fillColor: AppColors.surface(isDarkMode),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(
            color: AppColors.border(isDarkMode),
            width: 0.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(
            color: AppColors.border(isDarkMode),
            width: 0.5,
          ),
        ),
      ),
      style: TextStyle(
        fontFamily: AppTextStyles.appFontFamily,
        fontSize: AppTextStyles.medium,

        color: AppColors.textPrimary(isDarkMode),
      ),
    );
  }

  Widget _buildCityAreaSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: Text(
              'الموقع'.tr,
              style: TextStyle(
                fontFamily: AppTextStyles.appFontFamily,
                fontSize: AppTextStyles.xlarge,

                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          
          _buildCityDropdown(),
          
          if (_adsController.selectedCity.value != null)
            Padding(
              padding: EdgeInsets.only(top: 12.h),
              child: _buildAreaDropdown(),
            ),
        ],
      ),
    );
  }

  Widget _buildCityDropdown() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: AppColors.border(isDarkMode),
          width: 0.5,
        ),
      ),
      child: DropdownButtonFormField<TheCity>(
        value: _adsController.selectedCity.value,
        decoration: InputDecoration(
          labelText: 'المدينة'.tr,
          contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
          filled: true,
          fillColor: AppColors.surface(isDarkMode),
          border: InputBorder.none,
        ),
        items: _adsController.citiesList.map((city) {
          return DropdownMenuItem<TheCity>(
            value: city,
            child: Text(
              city.translations.first.name,
              style: TextStyle(
                fontFamily: AppTextStyles.appFontFamily,
                fontSize: AppTextStyles.medium,

                color: AppColors.textPrimary(isDarkMode),
              ),
            ),
          );
        }).toList(),
        onChanged: (city) {
          setState(() {
            _adsController.selectCity(city!);
          });
        },
        style: TextStyle(
          fontFamily: AppTextStyles.appFontFamily,
          fontSize: AppTextStyles.medium,

          color: AppColors.textPrimary(isDarkMode),
        ),
        dropdownColor: AppColors.card(isDarkMode),
      ),
    );
  }
Widget _buildAreaDropdown() {
  final isDarkMode =  Get.find<ThemeController>().isDarkMode.value;


  return Obx(() {
    final selectedCity = _adsController.selectedCity.value;

    // لو المدينة غير محددة لسه
    if (selectedCity == null) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: AppColors.border(isDarkMode),
            width: 0.5,
          ),
        ),
        child: DropdownButtonFormField<Area>(
          value: null,
          decoration: InputDecoration(
            labelText: 'المنطقة'.tr,
            contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            filled: true,
            fillColor: AppColors.surface(isDarkMode),
            border: InputBorder.none,
          ),
          items: const [],
          onChanged: null, // معطّل
          hint: Text(
            'اختر المدينة أولاً',
            style: TextStyle(
              fontFamily: AppTextStyles.appFontFamily,
              fontSize: AppTextStyles.medium,

              color: AppColors.textSecondary(isDarkMode),
            ),
          ),
          dropdownColor: AppColors.card(isDarkMode),
          style: TextStyle(
            fontFamily: AppTextStyles.appFontFamily,
            fontSize: AppTextStyles.medium,

            color: AppColors.textPrimary(isDarkMode),
          ),
        ),
      );
    }

    // جلب المناطق من الكنترولر
    return FutureBuilder<List<Area>>(
      future: _areaController.getAreasOrFetch(selectedCity.id),
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final hasError = snapshot.hasError;
        final list = snapshot.data ?? const <Area>[];

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: AppColors.border(isDarkMode),
              width: 0.5,
            ),
          ),
          child: DropdownButtonFormField<Area>(
            key: ValueKey<int>(selectedCity.id), // لإعادة بناء صحيحة عند تغيير المدينة
            value: list.any((a) => a.id == _adsController.selectedArea.value?.id)
                ? _adsController.selectedArea.value
                : null,
            decoration: InputDecoration(
              labelText: 'المنطقة'.tr,
              contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
              filled: true,
              fillColor: AppColors.surface(isDarkMode),
              border: InputBorder.none,
            ),
            items: list.map((area) {
              return DropdownMenuItem<Area>(
                value: area,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        area.name,
                        style: TextStyle(
                          fontFamily: AppTextStyles.appFontFamily,
                          fontSize: AppTextStyles.medium,

                          color: AppColors.textPrimary(isDarkMode),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      '(${area.id})', // إظهار المعرف
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: AppTextStyles.small,

                        color: AppColors.textSecondary(isDarkMode),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (area) {
              setState(() {
                if (area != null) {
                  _adsController.selectArea(area);
                }
              });
            },
            hint: Text(
              isLoading
                  ? 'جارٍ تحميل المناطق...'
                  : (hasError
                      ? 'حدث خطأ أثناء الجلب'
                      : (list.isEmpty ? 'لا توجد مناطق' : 'اختر المنطقة')),
              style: TextStyle(
                fontFamily: AppTextStyles.appFontFamily,
                fontSize: AppTextStyles.medium,

                color: AppColors.textSecondary(isDarkMode),
              ),
            ),
            dropdownColor: AppColors.card(isDarkMode),
            style: TextStyle(
              fontFamily: AppTextStyles.appFontFamily,
              fontSize: AppTextStyles.medium,

              color: AppColors.textPrimary(isDarkMode),
            ),
          ),
        );
      },
    );
  });
}



  Widget _buildTimePeriodSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: Text(
              'الفترة الزمنية'.tr,
              style: TextStyle(
                fontFamily: AppTextStyles.appFontFamily,
                fontSize: AppTextStyles.xlarge,

                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: timePeriods.map((period) {
              final isSelected = _selectedTimePeriod == period['value'];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTimePeriod = period['value'];
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.surface(isDarkMode),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: AppColors.border(isDarkMode),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    period['label'],
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: AppTextStyles.medium,

                      color: isSelected ? Colors.white : AppColors.textPrimary(isDarkMode),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.background(isDarkMode),
        border: Border(top: BorderSide(
          color: AppColors.divider(isDarkMode),
          width: 0.5,
        )),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: _resetFilters,
              style: TextButton.styleFrom(
                backgroundColor: Colors.transparent,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  side: BorderSide(
                    color: AppColors.primary,
                    width: 1,
                  ),
                ),
              ),
              child: Text(
                'إعادة تعيين'.tr,
                style: TextStyle(
                  fontFamily: AppTextStyles.appFontFamily,
                  fontSize: AppTextStyles.large,

                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: ElevatedButton(
              onPressed: _isApplyingFilters ? null : _applyFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: _isApplyingFilters
                  ? SizedBox(
                      width: 20.w,
                      height: 20.h,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'تطبيق الفلترة'.tr,
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: AppTextStyles.large,

                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
void _applyFilters() async {
  if (!_formKey.currentState!.validate()) return;
  setState(() => _isApplyingFilters = true);

  final attrsPayload = _buildAttributesPayload();
  final selectedCityId = _adsController.selectedCity.value?.id;
  final selectedAreaId = _adsController.selectedArea.value?.id;

  // تحديث حالة الفلترة في الكنترولر
  _adsController.currentAttributes.value = attrsPayload;

  // طباعة مفصلة للفلاتر
  _printFiltersDetails({
    'category_id': _adsController.currentCategoryId.value,
    'city_id': selectedCityId,
    'area_id': selectedAreaId,
    'attributes': attrsPayload,
    'lang': Get.find<ChangeLanguageController>().currentLocale.value.languageCode,
    'timeframe':widget.currentTimeframe,
     'onlyFeatured':widget. onlyFeatured,


  });

  try {
    // استدعاء الدالة الموحدة مع جميع الفلاتر
    await _adsController.fetchAds(
      categoryId: _adsController.currentCategoryId.value,
      subCategoryLevelOneId: _adsController.currentSubCategoryLevelOneId.value,
      subCategoryLevelTwoId: _adsController.currentSubCategoryLevelTwoId.value,
      search: _adsController.currentSearch.value.isNotEmpty
          ? _adsController.currentSearch.value
          : null,
       sortBy: _adsController.currentSortBy.value,
      cityId: selectedCityId,
      areaId: selectedAreaId,
      attributes: attrsPayload.isNotEmpty ? attrsPayload : null,
      lang: Get.find<ChangeLanguageController>().currentLocale.value.languageCode,
      page: 1,
    );

    Get.back(); // إغلاق شاشة الفلترة

    // إظهار النتيجة
    final count = _adsController.adsList.length;
    Future.delayed(Duration(milliseconds: 300), () {
      final msg = count == 0
          ? 'لا توجد إعلانات مطابقة'
          : 'تم العثور على $count إعلان';
      Get.snackbar('نتيجة الفلترة'.tr, msg,
          snackPosition: SnackPosition.BOTTOM);
    });
  } catch (e) {
    Get.snackbar('خطأ', 'فشل الاتصال: $e',
        snackPosition: SnackPosition.BOTTOM);
  } finally {
    setState(() => _isApplyingFilters = false);
  }
}

// طباعة مفصلة للفلاتر مع معلومات النوع
void _printFiltersDetails(Map<String, dynamic> filters) {
  print('══════════════ فلاتر التطبيق ══════════════');
  print('معرف التصنيف: ${filters['category_id']}');
  print('معرف المدينة: ${filters['city_id']}');
  print('معرف المنطقة: ${filters['area_id']}');
  print('اللغة: ${filters['lang']}');
  
  if (filters.containsKey('attributes') && filters['attributes'] is List) {
    final attributes = filters['attributes'] as List;
    print('\n══════════ تفاصيل الخصائص (${attributes.length}) ══════════');
    
    for (var i = 0; i < attributes.length; i++) {
      final attr = attributes[i];
      if (attr is Map<String, dynamic>) {
        final attributeId = attr['attribute_id'];
        final attributeType = attr['attribute_type'];
        final value = attr['value'];
        
        print('  ➤ الخاصية #${i + 1}');
        print('    ➤ معرف الخاصية: $attributeId');
        print('    ➤ نوع الخاصية: $attributeType');
        print('    ➤ القيمة: $value');
        print('    ➤ نوع القيمة: ${value?.runtimeType}');
        print('    ➤ الاستعلام المتوقع: ${_getExpectedQuery(attributeType, value)}');
        print('  ──────────────────────────────────────');
      }
    }
  } else {
    print('\n══════════ لا توجد خصائص محددة ══════════');
  }
  print('═════════════════════════════════════════════');
}

// الحصول على الاستعلام المتوقع بناءً على نوع الخاصية
String _getExpectedQuery(String attributeType, dynamic value) {
  if (value == null) return 'لا يوجد قيمة';
  
  switch (attributeType) {
    case 'options':
      return 'attribute_option_id = $value';
    
    case 'boolean':
      final boolValue = value == true ? 'نعم' : 'لا';
      return 'value_ar = "$boolValue" OR value_en = "${value ? "Yes" : "No"}"';
    
    case 'number':
      final numValue = value.toString();
      return 'value_ar = "$numValue" OR value_en = "$numValue"';
    
    case 'text':
      return 'value_ar LIKE "%$value%" OR value_en LIKE "%$value%"';
    
    default:
      return 'نوع خاصية غير معروف: $attributeType';
  }
}

List<Map<String, dynamic>> _buildAttributesPayload() {
  return _attributeValues.entries.map((entry) {
    final attributeId = entry.key;
    final value = entry.value;
    
    // البحث عن تعريف الخاصية
    final attribute = _adsController.attributesList.firstWhere(
      (attr) => attr.attributeId == attributeId,
      orElse: () => CategoryAttribute(
        attributeId: attributeId,
        label: 'غير معروف',
        type: 'غير معروف',
        isRequired: false,
        options: [],
      ),
    );
    
    // إرجاع الهيكل مع إضافة نوع الخاصية
    return {
      'attribute_id': attributeId,
      'attribute_type': attribute.type,
      'value': value,
    };
  }).toList();
}

void _resetFilters() {
  _formKey.currentState?.reset();
  setState(() {
    _adsController.selectedCity.value = null;
    _adsController.selectedArea.value = null;
    _selectedTimePeriod = null;
    _attributeValues.clear();
    // إعادة ضبط السمات في الكنترولر
    _adsController.currentAttributes.clear();
  });
}}