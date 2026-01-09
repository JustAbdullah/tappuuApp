import 'dart:math' show max;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:tappuu_app/core/constant/appcolors.dart';
import 'package:tappuu_app/core/constant/app_text_styles.dart';

import '../../controllers/AdsManageSearchController.dart'; // AdsController
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
  final int? categoryId; // لو جاي من صفحة تصنيف محدد (ثابت)
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

  bool _didApply = false; // ✅ حتى ما نرجّع القيم بعد تطبيق الفلتر

  String? _selectedTimePeriod;

  /// ✅ attributeId -> value
  /// - options: List<int> (حتى لو single)
  /// - boolean: bool
  /// - text: String
  /// - number: String
  final Map<int, dynamic> _attributeValues = {};

  // Snapshot للرجوع عند الإلغاء
  TheCity? _tempCity;
  Area? _tempArea;
  late int _tempCategoryId;
  late List<Map<String, dynamic>> _tempAttributesPayload;
  late List<CategoryAttribute> _tempAttributesList;
  int? _tempAttributesCategoryId;
  String? _tempTimeframe;

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

    // ✅ Snapshots
    _tempCity = _ads.selectedCity.value;
    _tempArea = _ads.selectedArea.value;

    _tempCategoryId = _ads.currentCategoryId.value;
    _tempAttributesPayload = _ads.currentAttributes
        .map((m) => Map<String, dynamic>.from(m))
        .toList();

    _tempAttributesList = _ads.attributesList.toList();
    _tempAttributesCategoryId = _ads.attributesCategoryId.value;

    _tempTimeframe = _ads.currentTimeframe.value;

    // timeframe initial
    _selectedTimePeriod = widget.currentTimeframe ?? _ads.currentTimeframe.value;

    // ✅ category initial:
    // 1) لو الشاشة مربوطة بتصنيف ثابت (widget.categoryId) خذه
    // 2) غير كذا خذ آخر تصنيف مستخدم من الكنترولر (عشان ما يختفي)
    final fixed = (widget.categoryId != null && (widget.categoryId ?? 0) > 0)
        ? widget.categoryId
        : null;
    if (fixed != null) {
      _chosenCategoryId = fixed;
    } else {
      final fromController = _ads.currentCategoryId.value;
      _chosenCategoryId = (fromController > 0) ? fromController : null;
    }

    // hydrate فقط إذا عندنا تصنيف فعلي
    if (_effectiveCategoryId != null) {
      _hydrateFromController();
    } else {
      _attributeValues.clear();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final lang = Get.find<ChangeLanguageController>()
          .currentLocale
          .value
          .languageCode;

      // ✅ لو التصنيف غير ثابت: نحتاج قائمة التصنيفات دائمًا
      if (widget.categoryId == null || (widget.categoryId ?? 0) <= 0) {
        await _ads.fetchCategories(lang);
      }

      // ✅ لو عندنا تصنيف فعلي: حمّل خصائصه
      final eff = _effectiveCategoryId;
      if (eff != null) {
        await _ads.fetchAttributes(categoryId: eff, lang: lang);
        _pruneAttributeValuesToLoadedAttributes();
      } else {
        // ✅ مهم: إذا ما في تصنيف، لا تخلّي خصائص قديمة ظاهرة
        _ads.resetAttributesState();
      }

      await _ads.fetchCities('SY', lang);

      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    // ✅ إذا المستخدم خرج بدون تطبيق: رجّع كل شيء كما كان
    if (!_didApply) {
      _ads.selectedCity.value = _tempCity;
      _ads.selectedArea.value = _tempArea;

      _ads.currentCategoryId.value = _tempCategoryId;
      _ads.currentAttributes.assignAll(
        _tempAttributesPayload.map((m) => Map<String, dynamic>.from(m)).toList(),
      );

      _ads.attributesList.assignAll(_tempAttributesList);
      _ads.attributesCategoryId.value = _tempAttributesCategoryId;

      _ads.currentTimeframe.value = _tempTimeframe;
    }

    _priceMinCtrl.dispose();
    _priceMaxCtrl.dispose();
    super.dispose();
  }

  // ==================== Helpers ====================

  int? get _effectiveCategoryId => (_chosenCategoryId ?? widget.categoryId);

  void _hydrateFromController() {
    try {
      final list = _ads.currentAttributes.toList();
      for (final item in list) {
        final id = item['attribute_id'];
        final type = '${item['attribute_type'] ?? ''}';
        final value = item['value'];

        final int? aid = (id is int) ? id : int.tryParse('$id');
        if (aid == null || aid <= 0) continue;

        if (type == 'options') {
          final ids = <int>[];
          if (value is List) {
            for (final v in value) {
              if (v is int && v > 0) ids.add(v);
              if (v is String) {
                final p = int.tryParse(v);
                if (p != null && p > 0) ids.add(p);
              }
            }
          } else if (value is int && value > 0) {
            ids.add(value);
          } else if (value is String) {
            final p = int.tryParse(value);
            if (p != null && p > 0) ids.add(p);
          }
          final cleaned = ids.toSet().toList()..sort();
          if (cleaned.isNotEmpty) _attributeValues[aid] = cleaned;
          continue;
        }

        if (type == 'boolean') {
          if (value is bool) {
            _attributeValues[aid] = value;
          } else {
            final s = '${value ?? ''}'.toLowerCase().trim();
            if (s.isNotEmpty) {
              _attributeValues[aid] = (s == 'true' || s == '1' || s == 'yes' || s == 'نعم');
            }
          }
          continue;
        }

        if (type == 'text') {
          final s = '${value ?? ''}'.trim();
          if (s.isNotEmpty) _attributeValues[aid] = s;
          continue;
        }

        if (type == 'number') {
          final s = '${value ?? ''}'.trim();
          if (s.isNotEmpty) _attributeValues[aid] = s;
          continue;
        }
      }
    } catch (_) {}
  }

  void _pruneAttributeValuesToLoadedAttributes() {
    final ids = _ads.attributesList.map((a) => a.attributeId).toSet();
    _attributeValues.removeWhere((k, v) => !ids.contains(k));

    // ✅ لو كان عندنا قيم قديمة لتصنيف ثاني: امسحها فعليًا من UI
    _remountKey = UniqueKey();
  }

  Future<void> _onMainCategoryChanged(int? val) async {
    final lang = Get.find<ChangeLanguageController>()
        .currentLocale
        .value
        .languageCode;

    setState(() {
      _chosenCategoryId = val;
      _attributeValues.clear();
      _remountKey = UniqueKey();
    });

    // ✅ نظّف حالة الكنترولر الخاصة بالخصائص + payload (عشان ما يبقى أثر لتصنيف قديم)
    _ads.currentCategoryId.value = val ?? 0;
    _ads.currentAttributes.clear();
    _ads.resetAttributesState();

    if (val != null && val > 0) {
      await _ads.fetchAttributes(categoryId: val, lang: lang);
      _pruneAttributeValuesToLoadedAttributes();
      if (mounted) setState(() {});
    }
  }

  // ==================== UI ====================

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
            onPressed: () => Get.back(), // ✅ dispose بيرجع القيم إذا ما تم تطبيق
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
                            child: const CircularProgressIndicator(
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
              padding: EdgeInsets.only(left: 16.w, right: 16.w, top: 8.h, bottom: 120.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.categoryId == null || (widget.categoryId ?? 0) <= 0)
                    _buildMainCategoryPicker(loadingCats),

                  _buildAttributesBlock(loadingAttrs),

                  SizedBox(height: 8.h),
                  _buildPriceSection(),

                  SizedBox(height: 8.h),
                  _buildCityAreaSection(),

                  SizedBox(height: 8.h),
                  _buildTimePeriodSection(),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildAttributesBlock(bool loadingAttrs) {
    final eff = _effectiveCategoryId;
    if (eff == null) {
      return _noteCard('اختر التصنيف الرئيسي أولًا لعرض الخصائص المتاحة للفلترة.'.tr);
    }

    // ✅ لا تعرض خصائص “قديمة” لو ما تطابق التصنيف الحالي
    final attrsFor = _ads.attributesCategoryId.value;
    if (attrsFor != eff) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('الخصائص'.tr),
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
            ),
          ),
        ],
      );
    }

    if (loadingAttrs) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('الخصائص'.tr),
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
            ),
          ),
        ],
      );
    }

    return _buildAttributesSection();
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

                    // ✅ مهم: value لازم يكون موجود داخل items وإلا Dropdown ينهار
                    final bool exists = _chosenCategoryId != null &&
                        cats.any((c) => c.id == _chosenCategoryId);
                    final safeValue = exists ? _chosenCategoryId : null;

                    return SizedBox(
                      height: 56,
                      child: DropdownButton<int>(
                        value: safeValue,
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
                        onChanged: (val) => _onMainCategoryChanged(val),
                      ),
                    );
                  }),
                ),
        ),
        SizedBox(height: 12.h),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h, top: 4.h),
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
    final eff = _effectiveCategoryId;
    if (eff == null) {
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
            padding: EdgeInsets.only(bottom: 4.h, top: 6.h),
            child: Row(
              children: [
                Expanded(
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
                if (attribute.type == 'options' && attribute.isMultiSelect)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppColors.surface(isDark),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(color: AppColors.border(isDark), width: 0.6),
                    ),
                    child: Text(
                      'متعدد'.tr,
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: AppTextStyles.small,
                        color: AppColors.textSecondary(isDark),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          _buildAttributeInput(attribute),
          SizedBox(height: 8.h),
        ],
      ],
    );
  }

  Widget _noteCard(String msg) {
    return Container(
      padding: EdgeInsets.all(12.r),
      margin: EdgeInsets.only(bottom: 8.h),
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

  // ===== السعر UI =====
  Widget _buildPriceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('السعر'.tr),
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
        SizedBox(height: 8.h),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _priceMinCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩,،]'))],
                onChanged: (_) => _formatControllerText(_priceMinCtrl),
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
                onChanged: (_) => _formatControllerText(_priceMaxCtrl),
                decoration: _inputDecoration(hint: 'السعر إلى'.tr).copyWith(
                  prefixIcon: const Icon(Icons.arrow_downward, size: 18),
                  suffixIcon: _priceMode == PriceMode.minOnly
                      ? const Icon(Icons.lock_outline, size: 18)
                      : (_priceMaxCtrl.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () => setState(() => _priceMaxCtrl.clear()),
                            )),
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: EdgeInsets.only(top: 4.h),
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

  // ===== Inputs حسب النوع =====
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

  // ✅ options: single / multi
  Widget _buildOptionsAttribute(CategoryAttribute attribute) {
    if (attribute.isMultiSelect) return _buildMultiOptionsAttribute(attribute);
    return _buildSingleOptionsAttribute(attribute);
  }

  /// ✅ Single: نخزن List<int> لكن Dropdown يحتاج int
  Widget _buildSingleOptionsAttribute(CategoryAttribute attribute) {
    final selectedIds = _getSelectedIds(attribute);
    final selectedOne = selectedIds.isEmpty ? null : selectedIds.first;

    return DropdownButtonFormField<int>(
      value: selectedOne,
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
      onChanged: (v) {
        setState(() {
          if (v == null) {
            _attributeValues.remove(attribute.attributeId);
          } else {
            _attributeValues[attribute.attributeId] = <int>[v];
          }
        });
      },
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

  Widget _buildMultiOptionsAttribute(CategoryAttribute attribute) {
    final selectedIds = _getSelectedIds(attribute);
    final selectedOptions = attribute.options.where((o) => selectedIds.contains(o.id)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => _openMultiSelectSheet(attribute),
          borderRadius: BorderRadius.circular(8.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: AppColors.surface(isDark),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: AppColors.border(isDark), width: 0.5),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedIds.isEmpty
                        ? ('${'اختر'.tr} ${attribute.label}')
                        : ('${'تم اختيار'.tr} ${selectedIds.length}'),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: AppTextStyles.medium,
                      color: selectedIds.isEmpty
                          ? AppColors.textSecondary(isDark)
                          : AppColors.textPrimary(isDark),
                      fontWeight: selectedIds.isEmpty ? FontWeight.w500 : FontWeight.w600,
                    ),
                  ),
                ),
                Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary(isDark)),
              ],
            ),
          ),
        ),

        Padding(
          padding: EdgeInsets.only(top: 6.h),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: AppColors.textSecondary(isDark)),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  'يمكنك اختيار أكثر من خيار.'.tr,
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

        if (selectedOptions.isNotEmpty) ...[
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: selectedOptions.map((o) {
              return _selectedChip(
                text: o.value,
                onRemove: () {
                  final newIds = List<int>.from(selectedIds)..remove(o.id);
                  setState(() {
                    if (newIds.isEmpty) {
                      _attributeValues.remove(attribute.attributeId);
                    } else {
                      _attributeValues[attribute.attributeId] = newIds;
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _selectedChip({required String text, required VoidCallback onRemove}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.card(isDark),
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: AppColors.border(isDark), width: 0.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppTextStyles.appFontFamily,
                fontSize: AppTextStyles.small,
                color: AppColors.textPrimary(isDark),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(width: 6.w),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close, size: 16, color: AppColors.textSecondary(isDark)),
          ),
        ],
      ),
    );
  }

  Future<void> _openMultiSelectSheet(CategoryAttribute attribute) async {
    final initial = Set<int>.from(_getSelectedIds(attribute));
    final all = attribute.options;

    final res = await showModalBottomSheet<Set<int>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String query = '';
        final temp = Set<int>.from(initial);

        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final filtered = query.trim().isEmpty
                ? all
                : all.where((o) => o.value.toLowerCase().contains(query.toLowerCase())).toList();

            return Container(
              decoration: BoxDecoration(
                color: AppColors.card(isDark),
                borderRadius: BorderRadius.vertical(top: Radius.circular(18.r)),
                border: Border.all(color: AppColors.divider(isDark)),
              ),
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              attribute.label,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: AppTextStyles.appFontFamily,
                                fontSize: AppTextStyles.large,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary(isDark),
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: AppColors.surface(isDark),
                              borderRadius: BorderRadius.circular(20.r),
                              border: Border.all(color: AppColors.border(isDark), width: 0.6),
                            ),
                            child: Text(
                              '${temp.length}',
                              style: TextStyle(
                                fontFamily: AppTextStyles.appFontFamily,
                                fontSize: AppTextStyles.small,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary(isDark),
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx, null),
                            icon: Icon(Icons.close, color: AppColors.textSecondary(isDark)),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14.w),
                      child: TextField(
                        onChanged: (v) => setSheetState(() => query = v),
                        decoration: InputDecoration(
                          hintText: 'ابحث...'.tr,
                          filled: true,
                          fillColor: AppColors.surface(isDark),
                          prefixIcon: const Icon(Icons.search, size: 18),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.r),
                            borderSide: BorderSide(color: AppColors.border(isDark), width: 0.6),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.r),
                            borderSide: BorderSide(color: AppColors.border(isDark), width: 0.6),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 10.h),

                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => Divider(color: AppColors.divider(isDark), height: 1),
                        itemBuilder: (_, i) {
                          final o = filtered[i];
                          final checked = temp.contains(o.id);

                          return InkWell(
                            onTap: () {
                              setSheetState(() {
                                if (checked) {
                                  temp.remove(o.id);
                                } else {
                                  temp.add(o.id);
                                }
                              });
                            },
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: checked,
                                    onChanged: (_) {
                                      setSheetState(() {
                                        if (checked) {
                                          temp.remove(o.id);
                                        } else {
                                          temp.add(o.id);
                                        }
                                      });
                                    },
                                    activeColor: AppColors.primary,
                                  ),
                                  SizedBox(width: 6.w),
                                  Expanded(
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
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => setSheetState(() => temp.clear()),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.r),
                                  side: BorderSide(color: AppColors.primary, width: 1),
                                ),
                              ),
                              child: Text(
                                'مسح'.tr,
                                style: TextStyle(
                                  fontFamily: AppTextStyles.appFontFamily,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, temp),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                              ),
                              child: Text(
                                'تم'.tr,
                                style: TextStyle(
                                  fontFamily: AppTextStyles.appFontFamily,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (res == null) return;

    setState(() {
      final ids = res.toList()..sort();
      if (ids.isEmpty) {
        _attributeValues.remove(attribute.attributeId);
      } else {
        _attributeValues[attribute.attributeId] = ids;
      }
    });
  }

  List<int> _getSelectedIds(CategoryAttribute attribute) {
    final v = _attributeValues[attribute.attributeId];
    if (v is List<int>) return v;

    if (v is List) {
      final out = <int>[];
      for (final x in v) {
        if (x is int && x > 0) out.add(x);
        if (x is String) {
          final p = int.tryParse(x);
          if (p != null && p > 0) out.add(p);
        }
      }
      return out;
    }

    if (v is int) return [v];
    if (v is String) {
      final p = int.tryParse(v);
      if (p != null) return [p];
    }

    return <int>[];
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
      onChanged: (v) {
        final t = v.trim();
        if (t.isEmpty) {
          _attributeValues.remove(attribute.attributeId);
        } else {
          _attributeValues[attribute.attributeId] = t;
        }
      },
      decoration: _inputDecoration(hint: '${'أدخل'.tr} ${attribute.label}'),
    );
  }

  Widget _buildNumberAttribute(CategoryAttribute attribute) {
    return TextFormField(
      initialValue: _attributeValues[attribute.attributeId]?.toString() ?? '',
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩\.\,،]'))],
      onChanged: (v) {
        final t = _normalizeDigits(v).trim();
        if (t.isEmpty) {
          _attributeValues.remove(attribute.attributeId);
          return;
        }
        _attributeValues[attribute.attributeId] = t;
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
          SizedBox(height: 8.h),
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
        onChanged: (city) => setState(() => _ads.selectCity(city)),
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

        if (loading) return _noteRow('جارٍ تحميل المناطق...'.tr);
        if (hasError) return _noteRow('حدث خطأ أثناء الجلب'.tr);
        if (list.isEmpty) return _noteRow('لا توجد مناطق'.tr);

        return ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: DropdownButtonFormField<Area>(
            key: ValueKey<int>(selectedCity.id),
            value: list.any((a) => a.id == _ads.selectedArea.value?.id) ? _ads.selectedArea.value : null,
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
                      a.name,
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
            onChanged: (a) => setState(() => _ads.selectArea(a)),
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
    final periods = [
      {'value': '24h', 'label': 'آخر 24 ساعة'.tr},
      {'value': '48h', 'label': 'آخر 48 ساعة'.tr},
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
          runSpacing: 6.h,
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

  List<Map<String, dynamic>> _buildAttributesPayload() {
    final out = <Map<String, dynamic>>[];

    for (final entry in _attributeValues.entries) {
      final id = entry.key;
      final val = entry.value;

      final attr = _ads.attributesList.firstWhere(
        (a) => a.attributeId == id,
        orElse: () => CategoryAttribute(
          attributeId: id,
          label: 'غير معروف',
          type: 'غير معروف',
          isRequired: false,
          isMultiSelect: false,
          options: const [],
        ),
      );

      if (val == null) continue;

      if (attr.type == 'options') {
        final ids = <int>[];

        if (val is List<int>) {
          ids.addAll(val.where((x) => x > 0));
        } else if (val is List) {
          for (final v in val) {
            if (v is int && v > 0) ids.add(v);
            if (v is String) {
              final p = int.tryParse(v);
              if (p != null && p > 0) ids.add(p);
            }
          }
        } else if (val is int && val > 0) {
          ids.add(val);
        } else if (val is String) {
          final p = int.tryParse(val);
          if (p != null && p > 0) ids.add(p);
        }

        final cleaned = ids.toSet().toList()..sort();
        if (cleaned.isEmpty) continue;

        out.add({
          'attribute_id': id,
          'attribute_type': 'options',
          'value': cleaned,
        });
        continue;
      }

      if (attr.type == 'boolean') {
        if (val is bool) {
          out.add({'attribute_id': id, 'attribute_type': 'boolean', 'value': val});
        } else {
          final s = '${val ?? ''}'.toLowerCase().trim();
          if (s.isEmpty) continue;
          final b = (s == 'true' || s == '1' || s == 'yes' || s == 'نعم');
          out.add({'attribute_id': id, 'attribute_type': 'boolean', 'value': b});
        }
        continue;
      }

      if (attr.type == 'text') {
        final s = '${val ?? ''}'.trim();
        if (s.isEmpty) continue;
        out.add({'attribute_id': id, 'attribute_type': 'text', 'value': s});
        continue;
      }

      if (attr.type == 'number') {
        final s = '${val ?? ''}'.trim();
        if (s.isEmpty) continue;
        out.add({'attribute_id': id, 'attribute_type': 'number', 'value': s});
        continue;
      }
    }

    return out;
  }

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
    final minP = _parsePrice(_priceMinCtrl.text);
    final maxP = _parsePrice(_priceMaxCtrl.text);

    if (_priceMode == PriceMode.minOnly) {
      if (minP == null) return 'اكتب الحد الأدنى لعرض إعلانات أعلى من هذه القيمة.'.tr;
      return 'سيتم عرض الإعلانات بسعر أعلى من ${_formatWithGrouping(minP)}.'.tr;
    }

    if (minP == null && maxP == null) return 'اترك السعر فارغًا لتجاهله.'.tr;
    if (minP != null && maxP == null) return 'سيتم عرض الإعلانات من ${_formatWithGrouping(minP)} وحتى أي سعر أعلى.'.tr;
    if (minP == null && maxP != null) return 'سيتم عرض الإعلانات حتى ${_formatWithGrouping(maxP)}.'.tr;
    if (minP != null && maxP != null) {
      if (minP > maxP) return 'تنبيه: "من" أكبر من "إلى" — صحّح القيم.'.tr;
      return 'سيتم عرض الإعلانات ضمن ${_formatWithGrouping(minP)} – ${_formatWithGrouping(maxP)}.'.tr;
    }
    return '';
  }

  void _formatControllerText(TextEditingController ctrl) {
    final parsed = _parsePrice(ctrl.text);
    final newText = parsed == null ? '' : _formatWithGrouping(parsed);
    ctrl
      ..text = newText
      ..selection = TextSelection.fromPosition(TextPosition(offset: newText.length));
    setState(() {});
  }

  void _onResetPressed() {
    if (_isResetting) return;
    setState(() => _isResetting = true);

    FocusScope.of(context).unfocus();
    _formKey.currentState?.reset();

    // موقع
    _ads.selectedCity.value = null;
    _ads.selectedArea.value = null;

    // فترة + خصائص
    _selectedTimePeriod = null;
    _attributeValues.clear();
    _ads.currentAttributes.clear();
    _ads.resetAttributesState();

    // السعر
    _priceMode = PriceMode.range;
    _priceMinCtrl.clear();
    _priceMaxCtrl.clear();

    // ✅ التصنيف
    if (widget.categoryId == null || (widget.categoryId ?? 0) <= 0) {
      _chosenCategoryId = null;
      _ads.currentCategoryId.value = 0;
    } else {
      _chosenCategoryId = widget.categoryId;
      _ads.currentCategoryId.value = widget.categoryId ?? 0;
    }

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
      Get.snackbar('تنبيه'.tr, 'الرجاء اختيار التصنيف الرئيسي أولًا'.tr, snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final priceMin = _parsePrice(_priceMinCtrl.text);
    final priceMax = _priceMode == PriceMode.minOnly ? null : _parsePrice(_priceMaxCtrl.text);

    if (_priceMode == PriceMode.range && priceMin != null && priceMax != null && priceMin > priceMax) {
      Get.snackbar('تنبيه'.tr, 'قيمة "من" يجب أن تكون أقل من أو تساوي "إلى"'.tr, snackPosition: SnackPosition.BOTTOM);
      return;
    }

    setState(() => _isApplying = true);

    final attrs = _buildAttributesPayload();
    final cityId = _ads.selectedCity.value?.id;
    final areaId = _ads.selectedArea.value?.id;

    // ✅ ثبت الحالة في الكنترولر
    _ads.currentCategoryId.value = _effectiveCategoryId!;
    _ads.currentAttributes.assignAll(attrs);

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

      _didApply = true; // ✅ لا ترجع قيم الـ snapshot
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
