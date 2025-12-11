import 'dart:math' show max;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:tappuu_app/core/constant/appcolors.dart';
import 'package:tappuu_app/core/constant/app_text_styles.dart';

import '../../controllers/AdsManageSearchController.dart';
import '../../controllers/ThemeController.dart';
import '../../controllers/areaController.dart';
import '../../core/data/model/Area.dart';
import '../../core/data/model/category.dart' as cat;
import '../../core/data/model/CategoryAttributesResponse.dart';
import '../../core/data/model/City.dart';
import '../../core/localization/changelanguage.dart';

// لازم يكون Top-level
enum PriceMode { range, minOnly }

class FilterScreen extends StatefulWidget {
  final int? categoryId;
  final String? currentTimeframe;
  final bool onlyFeatured;

  const FilterScreen({
    super.key,
    required this.categoryId,
    this.currentTimeframe,
    this.onlyFeatured = false,
  });

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  final AdsController _ads = Get.find<AdsController>();
  final theme = Get.find<ThemeController>();
  bool get isDark => theme.isDarkMode.value;

  final _formKey = GlobalKey<FormState>();
  final AreaController _areaCtrl = Get.put(AreaController());

  bool _isApplying = false;
  bool _isResetting = false;
  String? _selectedTimePeriod;
  final Map<int, dynamic> _attributeValues = {};

  TheCity? _tempCity;
  Area? _tempArea;

  int? _chosenCategoryId;

  // السعر
  PriceMode _priceMode = PriceMode.range;
  final TextEditingController _priceMinCtrl = TextEditingController();
  final TextEditingController _priceMaxCtrl = TextEditingController();

  // لإجبار إعادة بناء حقول الخصائص ومسح initialValue فعليًا
  Key _remountKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _tempCity = _ads.selectedCity.value;
    _tempArea = _ads.selectedArea.value;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final lang = Get.find<ChangeLanguageController>().currentLocale.value.languageCode;

      if (widget.categoryId == null || (widget.categoryId ?? 0) <= 0) {
        _chosenCategoryId = null;
        await _ads.fetchCategories(lang);
      } else {
        _chosenCategoryId = widget.categoryId;
        await _ads.fetchAttributes(categoryId: _chosenCategoryId!, lang: lang);
      }

      await _ads.fetchCities('SY', lang);
    });
  }

  @override
  void dispose() {
    _ads.selectedCity.value = _tempCity;
    _ads.selectedArea.value = _tempArea;
    _priceMinCtrl.dispose();
    _priceMaxCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(isDark),
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
        backgroundColor: AppColors.appBar(isDark),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.close, color: AppColors.onPrimary),
            onPressed: () {
              _ads.selectedCity.value = _tempCity;
              _ads.selectedArea.value = _tempArea;
              Get.back();
            },
          ),
        ],
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SafeArea(
        minimum: EdgeInsets.only(left: 16.w, right: 16.w, bottom: 8.h),
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(12.r),
          color: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: AppColors.card(isDark),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.divider(isDark)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isResetting ? null : _onResetPressed,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                        side: BorderSide(color: AppColors.primary, width: 1),
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
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isApplying ? null : _applyFilters,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                    child: _isApplying
                        ? SizedBox(
                            width: 20.w,
                            height: 20.h,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
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
          ),
        ),
      ),

      body: Obx(() {
        final loadingAttrs = _ads.isLoadingAttributes.value;
        final loadingCats = _ads.isLoadingCategories.value;

        return Form(
          key: _formKey,
          child: KeyedSubtree(
            key: _remountKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.only(left: 16.w, right: 16.w, top: 8.h, bottom: 120.h), // تم تقليل المسافات
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.categoryId == null || (widget.categoryId ?? 0) <= 0)
                    _buildMainCategoryPicker(loadingCats),

                  if (loadingAttrs) _buildSectionTitle('الخصائص'.tr),
                  if (loadingAttrs)
                    Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.h), // تم تقليل المسافة
                        child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                      ),
                    )
                  else
                    _buildAttributesSection(),

                  SizedBox(height: 8.h), // تم تقليل المسافة
                  _buildPriceSection(),

                  SizedBox(height: 8.h), // تم تقليل المسافة
                  _buildCityAreaSection(),
                  SizedBox(height: 8.h), // تم تقليل المسافة
                  _buildTimePeriodSection(),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  // ================= UI Blocks =================

  Widget _buildMainCategoryPicker(bool loading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('التصنيف الرئيسي'.tr),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface(isDark),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: AppColors.border(isDark), width: 0.6),
          ),
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: loading
              ? Padding(
                  padding: EdgeInsets.all(12.r),
                  child: Row(
                    children: [
                      SizedBox(
                        height: 18.r,
                        width: 18.r,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                      ),
                      SizedBox(width: 10.w),
                      Text(
                        'جارٍ تحميل التصنيفات...'.tr,
                        style: TextStyle(
                          fontFamily: AppTextStyles.appFontFamily,
                          fontSize: AppTextStyles.medium,
                          color: AppColors.textSecondary(isDark),
                        ),
                      ),
                    ],
                  ),
                )
              : DropdownButtonHideUnderline(
                  child: Obx(() {
                    final List<cat.Category> cats = _ads.categoriesList.toList();
                    return SizedBox(
                      height: 56,
                      child: DropdownButton<int>(
                        value: _chosenCategoryId,
                        isExpanded: true,
                        hint: Text(
                          'اختر تصنيفًا لعرض خصائصه'.tr,
                          style: TextStyle(
                            fontFamily: AppTextStyles.appFontFamily,
                            fontSize: AppTextStyles.medium,
                            color: AppColors.textSecondary(isDark),
                          ),
                        ),
                        items: cats
                            .map<DropdownMenuItem<int>>(
                              (cat.Category c) => DropdownMenuItem<int>(
                                value: c.id,
                                child: Text(
                                  c.translations.first.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: AppTextStyles.appFontFamily,
                                    fontSize: AppTextStyles.medium,
                                    color: AppColors.textPrimary(isDark),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) async {
                          setState(() {
                            _chosenCategoryId = val;
                            _attributeValues.clear();
                          });
                          if (val != null) {
                            _ads.currentCategoryId.value = val;
                            final lang = Get.find<ChangeLanguageController>().currentLocale.value.languageCode;
                            await _ads.fetchAttributes(categoryId: val, lang: lang);
                          }
                        },
                      ),
                    );
                  }),
                ),
        ),
        SizedBox(height: 12.h), // تم تقليل المسافة
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h, top: 4.h), // تم تقليل المسافة
      child: Text(
        title,
        style: TextStyle(
          fontFamily: AppTextStyles.appFontFamily,
          fontSize: AppTextStyles.xlarge,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildAttributesSection() {
    if (_effectiveCategoryId == null) {
      return _noteCard('اختر التصنيف الرئيسي أولًا لعرض الخصائص المتاحة للفلترة.'.tr);
    }

    final attrs = _ads.attributesList;

    if (attrs.isEmpty) {
      return _noteCard('لا توجد خصائص قابلة للفلترة لهذا التصنيف.'.tr);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final attribute in attrs) ...[
          Padding(
            padding: EdgeInsets.only(bottom: 4.h, top: 6.h), // تم تقليل المسافة
            child: Text(
              attribute.label,
              style: TextStyle(
                fontFamily: AppTextStyles.appFontFamily,
                fontSize: AppTextStyles.medium,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary(isDark),
              ),
            ),
          ),
          _buildAttributeInput(attribute),
          SizedBox(height: 8.h), // تم تقليل المسافة بدلاً من الديفايدر الكبير
        ],
      ],
    );
  }

  Widget _noteCard(String msg) {
    return Container(
      padding: EdgeInsets.all(12.r),
      margin: EdgeInsets.only(bottom: 8.h), // تم تقليل المسافة
      decoration: BoxDecoration(
        color: AppColors.card(isDark),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.divider(isDark)),
      ),
      child: Text(
        msg,
        style: TextStyle(
          fontFamily: AppTextStyles.appFontFamily,
          fontSize: AppTextStyles.medium,
          color: AppColors.textSecondary(isDark),
        ),
      ),
    );
  }

  // ===== السعر UI (مبسّط) =====
  Widget _buildPriceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('السعر'.tr),

        // اختيار النمط: نطاق / أعلى من
        Wrap(
          spacing: 8.w,
          children: [
            _selectChip(
              label: 'نطاق (من–إلى)'.tr,
              selected: _priceMode == PriceMode.range,
              onTap: () => setState(() => _priceMode = PriceMode.range),
            ),
            _selectChip(
              label: 'أعلى من'.tr,
              selected: _priceMode == PriceMode.minOnly,
              onTap: () {
                setState(() {
                  _priceMode = PriceMode.minOnly;
                  _priceMaxCtrl.clear();
                });
              },
            ),
          ],
        ),

        SizedBox(height: 8.h), // تم تقليل المسافة

        // حقول الإدخال
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _priceMinCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩,،]'))],
                onChanged: (v) => _formatControllerText(_priceMinCtrl),
                decoration: _inputDecoration(hint: 'السعر من'.tr).copyWith(
                  prefixIcon: const Icon(Icons.arrow_upward, size: 18),
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: TextFormField(
                controller: _priceMaxCtrl,
                enabled: _priceMode == PriceMode.range,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩,،]'))],
                onChanged: (v) => _formatControllerText(_priceMaxCtrl),
                decoration: _inputDecoration(hint: 'السعر إلى'.tr).copyWith(
                  prefixIcon: const Icon(Icons.arrow_downward, size: 18),
                  suffixIcon: _priceMode == PriceMode.minOnly
                      ? const Icon(Icons.lock_outline, size: 18)
                      : (_priceMaxCtrl.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                setState(() {
                                  _priceMaxCtrl.clear();
                                });
                              },
                            )),
                ),
              ),
            ),
          ],
        ),

        // ملخص بسيط
        Padding(
          padding: EdgeInsets.only(top: 4.h), // تم تقليل المسافة
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: AppColors.textSecondary(isDark)),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  _priceSummary(),
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    fontSize: AppTextStyles.small,
                    color: AppColors.textSecondary(isDark),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _selectChip({required String label, required bool selected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface(isDark),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: AppColors.border(isDark), width: 0.6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(Icons.check, size: 16, color: Colors.white),
              SizedBox(width: 6.w),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTextStyles.appFontFamily,
                fontSize: AppTextStyles.medium,
                color: selected ? Colors.white : AppColors.textPrimary(isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== المدخلات حسب نوع الخاصية =====
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
      isExpanded: true,
      menuMaxHeight: MediaQuery.of(context).size.height * 0.5,
      decoration: _inputDecoration(),
      items: attribute.options
          .map<DropdownMenuItem<int>>(
            (o) => DropdownMenuItem<int>(
              value: o.id,
              child: Text(
                o.value,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppTextStyles.appFontFamily,
                  fontSize: AppTextStyles.medium,
                  color: AppColors.textPrimary(isDark),
                ),
              ),
            ),
          )
          .toList(),
      onChanged: (v) => setState(() => _attributeValues[attribute.attributeId] = v),
      hint: Text(
        '${'اختر'.tr} ${attribute.label}',
        style: TextStyle(
          fontFamily: AppTextStyles.appFontFamily,
          fontSize: AppTextStyles.medium,
          color: AppColors.textSecondary(isDark),
        ),
      ),
      dropdownColor: AppColors.card(isDark),
    );
  }

  Widget _buildBooleanAttribute(CategoryAttribute attribute) {
    final current = _attributeValues[attribute.attributeId] as bool?;
    return Row(
      children: [
        _boolChip('نعم'.tr, current == true, () => setState(() => _attributeValues[attribute.attributeId] = true)),
        SizedBox(width: 12.w),
        _boolChip('لا'.tr, current == false, () => setState(() => _attributeValues[attribute.attributeId] = false)),
      ],
    );
  }

  Widget _boolChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface(isDark),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: AppColors.border(isDark), width: 0.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppTextStyles.appFontFamily,
            fontSize: AppTextStyles.medium,
            color: selected ? Colors.white : AppColors.textPrimary(isDark),
          ),
        ),
      ),
    );
  }

  Widget _buildTextAttribute(CategoryAttribute attribute) {
    return TextFormField(
      initialValue: _attributeValues[attribute.attributeId]?.toString() ?? '',
      onChanged: (v) => _attributeValues[attribute.attributeId] = v,
      decoration: _inputDecoration(hint: '${'أدخل'.tr} ${attribute.label}'),
    );
  }

  Widget _buildNumberAttribute(CategoryAttribute attribute) {
    return TextFormField(
      initialValue: _attributeValues[attribute.attributeId]?.toString() ?? '',
      keyboardType: TextInputType.number,
      onChanged: (v) {
        if (v.isEmpty) {
          _attributeValues[attribute.attributeId] = null;
          return;
        }
        const arabic = ['٠','١','٢','٣','٤','٥','٦','٧','٨','٩'];
        const latin  = ['0','1','2','3','4','5','6','7','8','9'];
        final normalized = v.split('').map((c) {
          final i = arabic.indexOf(c);
          return i == -1 ? c : latin[i];
        }).join();
        _attributeValues[attribute.attributeId] = double.tryParse(normalized);
      },
      decoration: _inputDecoration(hint: '${'أدخل'.tr} ${attribute.label}'),
    );
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      filled: true,
      fillColor: AppColors.surface(isDark),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
        borderSide: BorderSide(color: AppColors.border(isDark), width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
        borderSide: BorderSide(color: AppColors.border(isDark), width: 0.5),
      ),
    );
  }

  Widget _buildCityAreaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('الموقع'.tr),
        _buildCityDropdown(),
        if (_ads.selectedCity.value != null) ...[
          SizedBox(height: 8.h), // تم تقليل المسافة
          _buildAreaDropdown(),
        ],
      ],
    );
  }

  Widget _buildCityDropdown() {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: DropdownButtonFormField<TheCity>(
        value: _ads.selectedCity.value,
        isExpanded: true,
        menuMaxHeight: MediaQuery.of(context).size.height * 0.5,
        decoration: InputDecoration(
          labelText: 'المدينة'.tr,
          contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
          filled: true,
          fillColor: AppColors.surface(isDark),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: BorderSide(color: AppColors.border(isDark), width: 0.5),
          ),
        ),
        items: _ads.citiesList
            .map<DropdownMenuItem<TheCity>>(
              (city) => DropdownMenuItem<TheCity>(
                value: city,
                child: Text(
                  city.translations.first.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    fontSize: AppTextStyles.medium,
                    color: AppColors.textPrimary(isDark),
                  ),
                ),
              ),
            )
            .toList(),
        onChanged: (city) => setState(() => _ads.selectCity(city!)),
        dropdownColor: AppColors.card(isDark),
      ),
    );
  }

  Widget _buildAreaDropdown() {
    final selectedCity = _ads.selectedCity.value;
    if (selectedCity == null) {
      return ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: DropdownButtonFormField<Area>(
          value: null,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'المنطقة'.tr,
            contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            filled: true,
            fillColor: AppColors.surface(isDark),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: AppColors.border(isDark), width: 0.5),
            ),
          ),
          items: const <DropdownMenuItem<Area>>[],
          onChanged: null,
          hint: Text(
            'اختر المدينة أولًا'.tr,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppTextStyles.appFontFamily,
              fontSize: AppTextStyles.medium,
              color: AppColors.textSecondary(isDark),
            ),
          ),
          dropdownColor: AppColors.card(isDark),
        ),
      );
    }

    return FutureBuilder<List<Area>>(
      future: _areaCtrl.getAreasOrFetch(selectedCity.id),
      builder: (context, snap) {
        final list = snap.data ?? const <Area>[];
        final loading = snap.connectionState == ConnectionState.waiting;
        final hasError = snap.hasError;

        if (loading) {
          return _noteRow('جارٍ تحميل المناطق...'.tr);
        }

        if (hasError) {
          return _noteRow('حدث خطأ أثناء الجلب'.tr);
        }

        if (list.isEmpty) {
          return _noteRow('لا توجد مناطق'.tr);
        }

        return ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: DropdownButtonFormField<Area>(
            key: ValueKey<int>(selectedCity.id),
            value: list.any((a) => a.id == _ads.selectedArea.value?.id)
                ? _ads.selectedArea.value
                : null,
            isExpanded: true,
            menuMaxHeight: MediaQuery.of(context).size.height * 0.5,
            decoration: InputDecoration(
              labelText: 'المنطقة'.tr,
              contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
              filled: true,
              fillColor: AppColors.surface(isDark),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(color: AppColors.border(isDark), width: 0.5),
              ),
            ),
            items: list
                .map<DropdownMenuItem<Area>>(
                  (a) => DropdownMenuItem<Area>(
                    value: a,
                    child: Text(
                      a.name, // تم إصلاح الخطأ هنا - إزالة عرض الـ ID
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: AppTextStyles.medium,
                        color: AppColors.textPrimary(isDark),
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: (a) => setState(() {
              if (a != null) _ads.selectArea(a);
            }),
            dropdownColor: AppColors.card(isDark),
          ),
        );
      },
    );
  }

  Widget _noteRow(String msg) {
    return Container(
      height: 56,
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: AppColors.surface(isDark),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.border(isDark), width: 0.5),
      ),
      child: Text(
        msg,
        style: TextStyle(
          fontFamily: AppTextStyles.appFontFamily,
          fontSize: AppTextStyles.medium,
          color: AppColors.textSecondary(isDark),
        ),
      ),
    );
  }

  Widget _buildTimePeriodSection() {
    // القيم المتوقعة من الباك-إند
    final periods = [
      {'value': '2_days', 'label': 'آخر يومين'.tr},
      {'value': 'week', 'label': 'آخر أسبوع'.tr},
      {'value': 'month', 'label': 'آخر شهر'.tr},
      {'value': 'year', 'label': 'آخر سنة'.tr},
      {'value': 'all', 'label': 'كل الأوقات'.tr},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('الفترة الزمنية'.tr),
        Wrap(
          spacing: 8.w,
          runSpacing: 6.h, // تم تقليل المسافة
          children: periods.map((p) {
            final sel = _selectedTimePeriod == p['value'];
            return GestureDetector(
              onTap: () => setState(() => _selectedTimePeriod = p['value']),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: sel ? AppColors.primary : AppColors.surface(isDark),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: AppColors.border(isDark), width: 0.5),
                ),
                child: Text(
                  p['label']!,
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    fontSize: AppTextStyles.medium,
                    color: sel ? Colors.white : AppColors.textPrimary(isDark),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ================ Actions ================

  int? get _effectiveCategoryId => (_chosenCategoryId ?? widget.categoryId);

  List<Map<String, dynamic>> _buildAttributesPayload() {
    return _attributeValues.entries.map((e) {
      final id = e.key;
      final val = e.value;
      final attr = _ads.attributesList.firstWhere(
        (a) => a.attributeId == id,
        orElse: () => CategoryAttribute(
          attributeId: id,
          label: 'غير معروف',
          type: 'غير معروف',
          isRequired: false,
          options: const [],
        ),
      );
      return {
        'attribute_id': id,
        'attribute_type': attr.type,
        'value': val,
      };
    }).toList();
  }

  // === تحويل + تنسيق
  String _normalizeDigits(String input) {
    const arabic = ['٠','١','٢','٣','٤','٥','٦','٧','٨','٩', '٬', '،', ','];
    const latin  = ['0','1','2','3','4','5','6','7','8','9', '',   '',   ''];
    final buf = StringBuffer();
    for (final ch in input.trim().split('')) {
      final i = arabic.indexOf(ch);
      buf.write(i == -1 ? ch : latin[i]);
    }
    return buf.toString();
  }

  double? _parsePrice(String s) {
    final t = _normalizeDigits(s).replaceAll(',', '').trim();
    if (t.isEmpty) return null;
    final v = double.tryParse(t);
    return v == null ? null : max(0, v);
  }

  String _formatWithGrouping(num value) {
    final s = value.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final idxFromEnd = s.length - i;
      buf.write(s[i]);
      if (idxFromEnd > 1 && idxFromEnd % 3 == 1) buf.write(',');
    }
    return buf.toString();
  }

  String _priceSummary() {
    final min = _parsePrice(_priceMinCtrl.text);
    final max = _parsePrice(_priceMaxCtrl.text);

    if (_priceMode == PriceMode.minOnly) {
      if (min == null) return 'اكتب الحد الأدنى لعرض إعلانات أعلى من هذه القيمة.'.tr;
      return 'سيتم عرض الإعلانات بسعر أعلى من ${_formatWithGrouping(min)}.'.tr;
    }

    // نطاق
    if (min == null && max == null) {
      return 'اترك السعر فارغًا لتجاهله.'.tr;
    }
    if (min != null && max == null) {
      return 'سيتم عرض الإعلانات من ${_formatWithGrouping(min)} وحتى أي سعر أعلى.'.tr;
    }
    if (min == null && max != null) {
      return 'سيتم عرض الإعلانات حتى ${_formatWithGrouping(max)}.'.tr;
    }
    if (min != null && max != null) {
      if (min > max) {
        return 'تنبيه: "من" أكبر من "إلى" — صحّح القيم.'.tr;
      }
      return 'سيتم عرض الإعلانات ضمن ${_formatWithGrouping(min)} – ${_formatWithGrouping(max)}.'.tr;
    }
    return '';
  }

  void _formatControllerText(TextEditingController ctrl) {
    final parsed = _parsePrice(ctrl.text);
    final newText = parsed == null ? '' : _formatWithGrouping(parsed);
    ctrl
      ..text = newText
      ..selection = TextSelection.fromPosition(TextPosition(offset: newText.length));
    setState(() {}); // تحديث الملخص/الأيقونات
  }

  // ✅ إصلاح تفريغ الحقول
  void _onResetPressed() {
    if (_isResetting) return;
    setState(() => _isResetting = true);

    FocusScope.of(context).unfocus();
    _formKey.currentState?.reset();

    // مسح القيم فورًا
    _ads.selectedCity.value = null;
    _ads.selectedArea.value = null;
    _selectedTimePeriod = null;
    _attributeValues.clear();
    _ads.currentAttributes.clear();
    _priceMode = PriceMode.range;
    _priceMinCtrl.clear();
    _priceMaxCtrl.clear();
    _chosenCategoryId = null; // إضافة هذا السطر لتفريغ التصنيف

    // إعادة تعيين المفاتيح لإجبار إعادة البناء
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _remountKey = UniqueKey();
        _isResetting = false;
      });
    });
  }

  Future<void> _applyFilters() async {
    if (_effectiveCategoryId == null) {
      Get.snackbar('تنبيه'.tr, 'الرجاء اختيار التصنيف الرئيسي أولًا'.tr,
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final priceMin = _parsePrice(_priceMinCtrl.text);
    final priceMax = _priceMode == PriceMode.minOnly ? null : _parsePrice(_priceMaxCtrl.text);

    if (_priceMode == PriceMode.range && priceMin != null && priceMax != null && priceMin > priceMax) {
      Get.snackbar('تنبيه'.tr, 'قيمة "من" يجب أن تكون أقل من أو تساوي "إلى"'.tr,
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    setState(() => _isApplying = true);

    final attrs = _buildAttributesPayload();
    final cityId = _ads.selectedCity.value?.id;
    final areaId = _ads.selectedArea.value?.id;

    _ads.currentAttributes.value = attrs;

    try {
      await _ads.fetchAds(
        categoryId: _effectiveCategoryId!,
        subCategoryLevelOneId: _ads.currentSubCategoryLevelOneId.value,
        subCategoryLevelTwoId: _ads.currentSubCategoryLevelTwoId.value,
        search: _ads.currentSearch.value.isNotEmpty ? _ads.currentSearch.value : null,
        sortBy: _ads.currentSortBy.value,
        cityId: cityId,
        areaId: areaId,
        attributes: attrs.isNotEmpty ? attrs : null,
        timeframe: _selectedTimePeriod ?? widget.currentTimeframe,
        onlyFeatured: widget.onlyFeatured,
        lang: Get.find<ChangeLanguageController>().currentLocale.value.languageCode,
        priceMin: priceMin,
        priceMax: priceMax,
        page: 1,
      );

      Get.back();
      final count = _ads.adsList.length;
      Future.delayed(const Duration(milliseconds: 250), () {
        final msg = count == 0 ? 'لا توجد إعلانات مطابقة'.tr : 'تم العثور على $count إعلان'.tr;
        Get.snackbar('نتيجة الفلترة'.tr, msg, snackPosition: SnackPosition.BOTTOM);
      });
    } catch (e) {
      Get.snackbar('خطأ'.tr, 'فشل الاتصال: $e', snackPosition: SnackPosition.BOTTOM);
    } finally {
      if (mounted) setState(() => _isApplying = false);
    }
  }
}
