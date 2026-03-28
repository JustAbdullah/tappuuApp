// AddAdScreen.dart (مُحسّن)
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:tappuu_app/views/AddAds/PremiumPackagesScreen.dart';
import 'package:video_player/video_player.dart';

// خرائط
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../controllers/AdsManageController.dart';
import '../../controllers/LoadingController.dart';
import '../../controllers/ThemeController.dart';
import '../../controllers/areaController.dart';
import '../../core/constant/app_text_styles.dart';
import '../../core/constant/appcolors.dart';
import '../../core/data/model/AdvertiserProfile.dart';
import '../../core/data/model/Attribute.dart';
import '../../core/data/model/Area.dart';
import '../../core/data/model/City.dart';
import '../../core/data/model/category.dart';
import '../../core/data/model/subcategory_level_one.dart';
import '../../core/data/model/subcategory_level_two.dart';
import '../AdvertiserScreen/AdvertiserDataScreen.dart';

class AddAdScreen extends StatefulWidget {
  @override
  _AddAdScreenState createState() => _AddAdScreenState();
}

class _AddAdScreenState extends State<AddAdScreen> {
  final ManageAdController controller = Get.put(ManageAdController());
  final ThemeController themeC = Get.find<ThemeController>();
  final LoadingController loadingC = Get.find<LoadingController>();
  final AreaController areaC = Get.find<AreaController>();
  
  final isDark = Get.find<ThemeController>().isDarkMode.value;
  int _currentStep = 0;
  PageController _pageController = PageController();
  final _formKey = GlobalKey<FormState>();
  final Map<int, GlobalKey<FormState>> _attributeFormKeys = {};
  int _reviewTabIndex = 0;
  final List<String> _stepTitles = ['بيانات المعلن', 'التصنيفات', 'الخصائص', 'التفاصيل', 'الموقع', 'الوسائط', 'المراجعة'];
  final List<bool> _stepValid = List.filled(7, false);

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    controller.fetchCategories('ar');
    controller.fetchCities('SY', 'ar');
    final userId = loadingC.currentUser?.id;
    if (userId != null) controller.fetchAdvertiserProfiles(userId);
    _stepValid[0] = false;
  }

  List<Widget> get _steps => [
    _buildAdvertiserProfileStep(),
    _buildCategoryStep(),
    _buildAttributesStep(),
    _buildBasicInfoStep(),
    _buildLocationStep(),
    _buildMediaStep(),
    Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.card(isDark) : AppColors.surface(isDark),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.divider(isDark)),
      ),
      child: _buildReviewStep(),
    )
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            _buildStepHeader(),
            Expanded(child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: _steps,
            )),
            _buildStepControls(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() => AppBar(
    leading: IconButton(icon: Icon(Icons.arrow_back, color: AppColors.onPrimary), onPressed: () => Get.back()),
    title: Text('إضافة إعلان جديد', style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontWeight: FontWeight.bold, fontSize: AppTextStyles.xlarge,
 color: Colors.white)),
    centerTitle: true,
    backgroundColor: AppColors.buttonAndLinksColor,
    elevation: 0,
    iconTheme: IconThemeData(color: Colors.white),
  );

  Widget _buildStepHeader() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
      decoration: BoxDecoration(color: AppColors.card(isDark), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))]),
      child: Column(
        children: [
          LinearProgressIndicator(value: (_currentStep + 1) / _steps.length, backgroundColor: AppColors.divider(isDark), color: AppColors.primary, minHeight: 6.h),
          SizedBox(height: 16.h),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('الخطوة ${_currentStep + 1} من ${_steps.length}', style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.large,
 fontWeight: FontWeight.bold, color: AppColors.textPrimary(isDark))),
            Text(_stepTitles[_currentStep], style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.large,
 fontWeight: FontWeight.bold, color: AppColors.primary)),
          ]),
        ],
      ),
    );
  }

  Widget _buildStepControls() {
    final bool isLastStep = _currentStep == _steps.length - 1;
    final bool isFirstStep = _currentStep == 0;
    final bool isNextDisabled = !_stepValid[_currentStep] && !isLastStep;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(color: AppColors.background(isDark), border: Border(top: BorderSide(color: AppColors.divider(isDark), width: 1))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(onPressed: _showExitDialog, child: Text('إلغاء', style: TextStyle(fontFamily: AppTextStyles.appFontFamily, color: Colors.red, fontSize: 16.sp))),
          Row(children: [
            if (!isFirstStep) ElevatedButton(
              onPressed: _previousStep,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.surface(isDark), padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r))),
              child: Text('السابق', style: TextStyle(fontFamily: AppTextStyles.appFontFamily, color: AppColors.textPrimary(isDark), fontSize: 16.sp)),
            ),
            SizedBox(width: 10.w),
            ElevatedButton(
              onPressed: isNextDisabled ? null : _nextStep,
              style: ElevatedButton.styleFrom(backgroundColor: isNextDisabled ? AppColors.primary.withOpacity(0.5) : AppColors.primary, padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r))),
              child: Text(isLastStep ? 'إنهاء' : 'التالي', style: TextStyle(fontFamily: AppTextStyles.appFontFamily, color: Colors.white, fontSize: 16.sp)),
            ),
          ]),
        ],
      ),
    );
  }

  void _nextStep() {
    if (_currentStep == 2 && !_validateAttributesStep()) return;
    if (_currentStep < _steps.length - 1) {
      setState(() {
        _currentStep++;
        _pageController.nextPage(duration: Duration(milliseconds: 300), curve: Curves.ease);
      });
    }    else {
      Get.to(() => PremiumPackagesScreen());
    }
  }

  void _previousStep() {
    if (_currentStep > 0) setState(() {
      _currentStep--;
      _pageController.previousPage(duration: Duration(milliseconds: 300), curve: Curves.ease);
    });
  }

 

  bool _validateAttributesStep() {
    bool allValid = true;
    for (var attribute in controller.attributes) {
      if (attribute.required == true) {
        final key = _attributeFormKeys[attribute.attributeId];
        if (key != null && key.currentState != null && !key.currentState!.validate()) allValid = false;
        else if (controller.attributeValues[attribute.attributeId] == null || controller.attributeValues[attribute.attributeId].toString().isEmpty) allValid = false;
      }
    }
    setState(() => _stepValid[2] = allValid);
    return allValid;
  }

  void _showExitDialog() {
    showDialog(context: context, builder: (context) => AlertDialog(
      title: Text('هل أنت متأكد؟', textAlign: TextAlign.center, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontWeight: FontWeight.bold)),
      content: Text('سيتم فقدان جميع البيانات التي أدخلتها', textAlign: TextAlign.center, style: TextStyle(fontFamily: AppTextStyles.appFontFamily)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('تراجع', style: TextStyle(fontFamily: AppTextStyles.appFontFamily))),
        TextButton(onPressed: () { Navigator.pop(context); Get.back(); }, child: Text('تأكيد الخروج', style: TextStyle(fontFamily: AppTextStyles.appFontFamily, color: Colors.red))),
      ],
    ));
  }

  // ===================== خطوات الإضافة ===================== //
  Widget _buildAdvertiserProfileStep() => _buildStepScaffold('الخطوة 1: بيانات المعلن', 'سيتم عرض هذه البيانات للتواصل معك', _buildProfileDropdown());
  Widget _buildCategoryStep() => _buildStepScaffold('الخطوة 2: التصنيفات', 'اختر التصنيف المناسب لإعلانك', Column(children: [
    _buildMainCategoryDropdown(),
    SizedBox(height: 16.h),
    Obx(() => controller.subCategories.isNotEmpty ? _buildSubcategoryDropdown() : SizedBox()),
    SizedBox(height: 16.h),
    Obx(() => controller.subCategoriesLevelTwo.isNotEmpty ? _buildSubcategoryLevelTwoDropdown() : SizedBox()),
  ]));

  Widget _buildAttributesStep() {
    return SingleChildScrollView(padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('الخطوة 3: الخصائص', style: _stepTitleStyle),
        SizedBox(height: 8.h),
        RichText(
          text: TextSpan(text: 'الخصائص المطلوبة ', style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.medium,
 color: AppColors.textSecondary(isDark)), 
          children: [TextSpan(text: 'علامة (*)', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))])),  
        SizedBox(height: 24.h),
        Obx(() => controller.attributes.isEmpty ? _buildNoAttributesMessage() : Container(
          decoration: _stepContainerDecoration(),
          padding: EdgeInsets.all(16.w),
          child: ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: controller.attributes.length,
            separatorBuilder: (context, index) => Divider(height: 32.h),
            itemBuilder: (context, index) {
              final attribute = controller.attributes[index];
              _attributeFormKeys.putIfAbsent(attribute.attributeId, () => GlobalKey<FormState>());
              return _buildAttributeField(attribute);
            },
          ),
        )),
      ],
    ));
  }

  Widget _buildBasicInfoStep() {
    return Form(key: _formKey, child: _buildStepScaffold('الخطوة 4: التفاصيل', 'الحقول المطلوبة علامة (*)', Column(children: [
      _buildInputField(controller: controller.titleArController, label: 'عنوان الإعلان *', icon: Icons.title, validator: (value) => value == null || value.isEmpty ? 'يرجى إدخال عنوان الإعلان' : null),
      SizedBox(height: 16.h),
      _buildInputField(controller: controller.priceController, label: 'السعر *', icon: Icons.attach_money, keyboardType: TextInputType.number, validator: (value) {
        if (value == null || value.isEmpty) return 'يرجى إدخال السعر';
        if (double.tryParse(value) == null) return 'يرجى إدخال سعر صحيح';
        return null;
      }),
      SizedBox(height: 16.h),
      _buildLargeDescriptionField(),
    ])));
  }

  Widget _buildLargeDescriptionField() {
    final errorText = ''.obs;
    controller.descriptionArController.addListener(() {
      if (_formKey.currentState != null) errorText.value = controller.descriptionArController.text.isEmpty ? 'يرجى إدخال وصف الإعلان' : '';
    });

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('وصف الإعلان *', style: _fieldLabelStyle),
      SizedBox(height: 8.h),
      Container(
        height: 200.h,
        decoration: BoxDecoration(color: AppColors.surface(isDark), borderRadius: BorderRadius.circular(12.r), border: Border.all(color: AppColors.border(isDark))),
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: TextFormField(
          controller: controller.descriptionArController,
          maxLines: null,
          expands: true,
          textAlignVertical: TextAlignVertical.top,
          decoration: InputDecoration(border: InputBorder.none, hintText: 'ادخل وصف الإعلان هنا...', hintStyle: TextStyle(fontFamily: AppTextStyles.appFontFamily)),
          style: TextStyle(fontFamily: AppTextStyles.appFontFamily, color: AppColors.textPrimary(isDark)),
          validator: (value) => value == null || value.isEmpty ? 'يرجى إدخال وصف الإعلان' : null,
          onChanged: (value) => setState(() => _stepValid[3] = _formKey.currentState?.validate() ?? false),
        ),
      ),
      Obx(() => errorText.value.isNotEmpty ? Padding(padding: EdgeInsets.only(left: 8.w, top: 4.h), child: Text(errorText.value, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, color: Colors.red, fontSize: AppTextStyles.small,
))) : SizedBox()),
    ]);
  }

  Widget _buildLocationStep() => _buildStepScaffold('الخطوة 5: الموقع', 'الحقول المطلوبة علامة (*)', Column(children: [
    _buildCityDropdown(),
    SizedBox(height: 16.h),
    Obx(() => controller.selectedCity.value != null ? _buildAreaDropdown() : SizedBox()),
    SizedBox(height: 16.h),
    ElevatedButton.icon(
      onPressed: () async {
        final LatLng? picked = await Navigator.push(context, MaterialPageRoute(builder: (_) => MapPickerScreen(initialLat: controller.latitude.value, initialLng: controller.longitude.value)));
        if (picked != null) setState(() {
          controller.latitude.value = picked.latitude;
          controller.longitude.value = picked.longitude;
          _stepValid[4] = controller.selectedCity.value != null && controller.selectedArea.value != null;
        });
      },
      icon: Icon(Icons.map, size: 20.w),
      label: Text('تحديد الموقع يدوياً على الخريطة'),
      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, minimumSize: Size(double.infinity, 50.h), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r))),
    ),
    SizedBox(height: 8.h),
    OutlinedButton.icon(
      onPressed: () async {
        await controller.fetchCurrentLocation();
        if (controller.latitude.value != null && controller.longitude.value != null) setState(() => _stepValid[4] = controller.selectedCity.value != null && controller.selectedArea.value != null);
      },
      icon: Icon(Icons.my_location, size: 20.w),
      label: Text('تحديد الموقع الحالي'),
      style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, minimumSize: Size(double.infinity, 50.h), side: BorderSide(color: AppColors.primary), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r))),
    ),
    Obx(() => controller.latitude.value != null && controller.longitude.value != null ? _buildLocationPreview() : _buildNoLocationMessage()),
  ]));

  Widget _buildLocationPreview() => Padding(padding: EdgeInsets.only(top: 16.h), child: Container(
    height: 220.h,
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(12.r), color: AppColors.surface(isDark)),
    child: ClipRRect(borderRadius: BorderRadius.circular(12.r), child: FlutterMap(
      options: MapOptions(initialCenter: LatLng(controller.latitude.value!, controller.longitude.value!), initialZoom: 15.0, interactionOptions: const InteractionOptions(flags: ~InteractiveFlag.rotate)),
      children: [
        TileLayer(urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png", userAgentPackageName: 'com.stayinme.app', tileDisplay: const TileDisplay.fadeIn()),
        MarkerLayer(markers: [Marker(point: LatLng(controller.latitude.value!, controller.longitude.value!), width: 50.w, height: 50.h, child: Icon(Icons.location_on, color: AppColors.primary, size: 40.w))]),
      ],
    )),
  ));

  Widget _buildNoLocationMessage() => Padding(padding: EdgeInsets.only(top: 16.h), child: Text('لم يتم تحديد الموقع بعد', style: TextStyle(fontFamily: AppTextStyles.appFontFamily, color: AppColors.textSecondary(isDark))));

  Widget _buildMediaStep() {
    return Stack(children: [
      _buildMediaContent(),
      Obx(() {
        final hasImages = controller.images.isNotEmpty;
        if (hasImages != _stepValid[5]) WidgetsBinding.instance.addPostFrameCallback((_) => setState(() => _stepValid[5] = hasImages));
        return SizedBox.shrink();
      }),
    ]);
  }

  Widget _buildMediaContent() => _buildStepScaffold('الخطوة 6: الوسائط', 'إضافة الصور والفيديو (اختياري)', Column(children: [
    _buildImagesSection(),
    SizedBox(height: 24.h),
    _buildVideosSection(),
  ]));

  Widget _buildReviewStep() => SingleChildScrollView(padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Center(child: Text(controller.titleArController.text.isNotEmpty ? controller.titleArController.text : 'عنوان الإعلان', style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.xlarge,
 fontWeight: FontWeight.bold, color: AppColors.textPrimary(isDark)), textAlign: TextAlign.center)),
    SizedBox(height: 16.h),
    _buildImageGalleryWithIndicator(),
    SizedBox(height: 16.h),
    Center(child: Text(controller.selectedProfile.value?.name ?? 'اسم المعلن', style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.large,
 fontWeight: FontWeight.bold, color: AppColors.buttonAndLinksColor))),
    SizedBox(height: 16.h),
    _buildCategoryPath(),
    SizedBox(height: 16.h),
    _buildLocationInfo(),
    SizedBox(height: 24.h),
    _buildReviewTabs(),
    Divider(height: 1, thickness: 1.8, color: AppColors.yellow),
    SizedBox(height: 16.h),
    _buildActiveTabContent(),
  ]));

  Widget _buildImageGalleryWithIndicator() {
    return Stack(alignment: Alignment.bottomCenter, children: [
      Container(height: 250.h, width: double.infinity, decoration: BoxDecoration(color: AppColors.surface(isDark), borderRadius: BorderRadius.circular(12.r)), child: 
        controller.images.isNotEmpty ? _buildImageGallery() : Center(child: Icon(Icons.image, size: 50.w, color: AppColors.textSecondary(isDark)))
      ),
      if (controller.images.isNotEmpty) Positioned(bottom: 10.h, child: _buildImageCounter()),
    ]);
  }

  Widget _buildImageGallery() => PageView.builder(itemCount: controller.images.length, itemBuilder: (context, index) => 
    Padding(padding: EdgeInsets.symmetric(horizontal: 8.w), child: ClipRRect(borderRadius: BorderRadius.circular(12.r), child: Image.file(controller.images[index], fit: BoxFit.cover, width: double.infinity)))
  );

  Widget _buildImageCounter() => Container(
    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20.r)),
    child: Obx(() => Text('${controller.currentImageIndex.value + 1}/${controller.images.length}', style: TextStyle(fontFamily: AppTextStyles.appFontFamily, color: Colors.white, fontSize: 14.sp))),
  );

  Widget _buildCategoryPath() => Row(mainAxisAlignment: MainAxisAlignment.center, children: [
    Text(controller.selectedMainCategory.value?.translations.first.name ?? 'التصنيف الرئيسي', style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.small,
 fontWeight: FontWeight.w600, color: AppColors.buttonAndLinksColor)),
    SizedBox(width: 4.w), Icon(Icons.chevron_right, size: 12.sp, color: AppColors.primary), SizedBox(width: 4.w),
    Text(controller.selectedSubcategoryLevelOne.value?.translations.first.name ?? 'التصنيف الفرعي', style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.small,
 fontWeight: FontWeight.w600, color: AppColors.buttonAndLinksColor)),
    if (controller.selectedSubcategoryLevelTwo.value != null) ...[SizedBox(width: 4.w), Icon(Icons.chevron_right, size: 12.sp, color: AppColors.primary), SizedBox(width: 4.w), Text(controller.selectedSubcategoryLevelTwo.value!.translations.first.name, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.small,
 fontWeight: FontWeight.w600, color: AppColors.buttonAndLinksColor))],
  ]);

  Widget _buildLocationInfo() => Row(mainAxisAlignment: MainAxisAlignment.center, children: [
    Text(controller.selectedCity.value?.translations.first.name ?? 'المدينة', style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.small,
 fontWeight: FontWeight.w600, color: AppColors.buttonAndLinksColor)),
    SizedBox(width: 4.w), Text("/", style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.small,
 fontWeight: FontWeight.w600, color: AppColors.buttonAndLinksColor)), SizedBox(width: 4.w),
    Text(controller.selectedArea.value?.name ?? 'المنطقة', style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.small,
 fontWeight: FontWeight.w600, color: AppColors.buttonAndLinksColor)),
  ]);

  Widget _buildReviewTabs() => Container(decoration: BoxDecoration(color: AppColors.background(isDark), borderRadius: BorderRadius.circular(12.r)), child: Row(children: [
    _buildReviewTabButton(0, 'معلومات الإعلان'),
    _buildReviewTabButton(1, 'توضيح'),
    _buildReviewTabButton(2, 'موقع'),
  ]));

  Widget _buildReviewTabButton(int index, String title) {
    final selected = _reviewTabIndex == index;
    return Expanded(child: GestureDetector(
      onTap: () => setState(() => _reviewTabIndex = index),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(color: selected ? AppColors.yellow : AppColors.surface(isDark), border: Border(bottom: BorderSide(color: selected ? AppColors.yellow : Colors.transparent, width: 2))),
        child: Center(child: Text(title, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.small,
 fontWeight: FontWeight.bold, color: selected ? Colors.black : AppColors.textSecondary(isDark)))),
      ),
    ));
  }

  Widget _buildActiveTabContent() {
    switch (_reviewTabIndex) {
      case 0: return _buildAttributesReview();
      case 1: return _buildDescriptionReview();
      case 2: return _buildLocationReview();
      default: return SizedBox();
    }
  }

  Widget _buildAttributesReview() => Container(padding: EdgeInsets.symmetric(horizontal: 16.w), child: Column(children: [
    _buildPriceReview(),
    Divider(height: 24.h, color: AppColors.divider(isDark)),
    _buildPublishDateReview(),
    Divider(height: 24.h, color: AppColors.divider(isDark)),
    ...controller.attributes.map((attribute) => Column(children: [_buildAttributeReviewItem(attribute), Divider(height: 24.h, color: AppColors.divider(isDark))])).toList(),
  ]));

  Widget _buildPriceReview() {
    final price = double.tryParse(controller.priceController.text) ?? 0;
    final syrianPrice = (price ).toInt();

    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text('السعر', style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.medium,
 color: AppColors.textPrimary(isDark))),
      Text('${NumberFormat.decimalPattern().format(syrianPrice)} ليرة سورية', style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.medium,
 fontWeight: FontWeight.bold, color: AppColors.buttonAndLinksColor)),
    ]);
  }

  Widget _buildPublishDateReview() => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Text('تاريخ النشر', style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.medium,
 color: AppColors.textPrimary(isDark))),
    Text(DateFormat('yyyy-MM-dd').format(DateTime.now()), style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.medium,
 fontWeight: FontWeight.bold, color: AppColors.textPrimary(isDark))),
  ]);

  Widget _buildAttributeReviewItem(Attribute attribute) {
    final value = _formatAttributeValue(attribute);
    Color valueColor = AppColors.textSecondary(isDark);
    if (value.toLowerCase() == 'نعم') valueColor = Colors.green;
    else if (value.toLowerCase() == 'لا') valueColor = Colors.red;

    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(attribute.label, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.medium,
 color: AppColors.textPrimary(isDark))),
      Text(value, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.medium,
 fontWeight: FontWeight.bold, color: valueColor)),
    ]);
  }

  String _formatAttributeValue(Attribute attribute) {
    final raw = controller.attributeValues[attribute.attributeId];
    if (raw == null) return '-';
    if (attribute.type == 'options') {
      try {
        final selectedId = raw is String ? int.tryParse(raw) : (raw as int?);
        if (selectedId != null) {
          final found = attribute.options.where((o) => o.id == selectedId).toList();
          if (found.isNotEmpty) return found.first.value;
        }
        return raw.toString();
      } catch (e) { return raw.toString(); }
    }
    if (attribute.type == 'boolean') {
      if (raw is bool) return raw ? 'نعم' : 'لا';
      final s = raw.toString().toLowerCase();
      if (s == 'true' || s == '1' || s == 'نعم') return 'نعم';
      return 'لا';
    }
    return raw.toString();
  }

  Widget _buildDescriptionReview() => Padding(padding: EdgeInsets.symmetric(horizontal: 16.w), child: Text(controller.descriptionArController.text.isNotEmpty ? controller.descriptionArController.text : 'لا يوجد توضيح', style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.medium,
 color: AppColors.textPrimary(isDark))));
  
  Widget _buildLocationReview() {
    if (controller.latitude.value != null && controller.longitude.value != null) {
      return Container(height: 260.h, margin: EdgeInsets.symmetric(horizontal: 16.w), decoration: BoxDecoration(color: AppColors.card(isDark), borderRadius: BorderRadius.circular(12.r)), child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: FlutterMap(
          options: MapOptions(initialCenter: LatLng(controller.latitude.value!, controller.longitude.value!), initialZoom: 15.0),
          children: [
            TileLayer(urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png", userAgentPackageName: 'com.stayinme.app'),
            MarkerLayer(markers: [Marker(point: LatLng(controller.latitude.value!, controller.longitude.value!), width: 50.w, height: 50.h, child: Icon(Icons.location_on, color: AppColors.primary, size: 40.w))]),
          ],
        ),
      ));
    } else {
      return Center(child: Text('لا يتوفر موقع جغرافي', style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.medium,
 color: AppColors.textSecondary(isDark))));
    }
  }

  // ================ مكونات مساعدة ================ //
  Widget _buildStepScaffold(String title, String? description, Widget child) {
    return SingleChildScrollView(padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: _stepTitleStyle),
        if (description != null) ...[SizedBox(height: 8.h), Text(description, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.medium,
 color: AppColors.textSecondary(isDark)))],
        SizedBox(height: 24.h),
        Container(decoration: _stepContainerDecoration(), padding: EdgeInsets.all(16.w), child: child),
      ],
    ));
  }

  TextStyle get _stepTitleStyle => TextStyle(fontFamily: AppTextStyles.appFontFamily, fontWeight: FontWeight.bold, fontSize: AppTextStyles.xlarge,
 color: AppColors.primary);
  BoxDecoration _stepContainerDecoration() => BoxDecoration(color: AppColors.card(isDark), borderRadius: BorderRadius.circular(16.r), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: Offset(0, 4))]);

Widget _buildProfileDropdown() => Obx(() {
  if (controller.isProfilesLoading.value) return _buildLoadingIndicator();

  // لا يوجد ملفات معلنين
  if (controller.advertiserProfiles.isEmpty) {
    final isDark = Get.find<ThemeController>().isDarkMode.value;
    return Center(
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: AppColors.card(isDark),
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.business, size: 80.w, color: AppColors.primary),
            SizedBox(height: 16.h),
            Text(
              'لا يوجد لديك ملف معلن حتى الآن',
              style: TextStyle(
                fontFamily: AppTextStyles.appFontFamily,
                fontWeight: FontWeight.bold,
                fontSize: AppTextStyles.large,
                color: AppColors.textPrimary(isDark),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              'قم بإنشاء ملف معلن لإتمام عملية نشر الإعلانات بسهولة',
              style: TextStyle(
                fontFamily: AppTextStyles.appFontFamily,
                fontSize: AppTextStyles.medium,
                color: AppColors.textSecondary(isDark),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
              onPressed: () => Get.to(() => AdvertiserDataScreen()),
              icon: const Icon(Icons.add_business, color: Colors.white),
              label: Text(
                'إنشاء ملف معلن',
                style: TextStyle(
                  fontFamily: AppTextStyles.appFontFamily,
                  fontSize: AppTextStyles.medium,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // في حال وجود ملفات معلنين
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('ملف المعلن *', style: _fieldLabelStyle),
      SizedBox(height: 8.h),

      // ===== Dropdown يظهر نوع الملف، وإن كان "شركة" يظهر فقط اسم العضو + نوعه =====
      _buildDropdown<AdvertiserProfile>(
        hint: 'اختر بيانات المعلن',
        value: controller.selectedProfile.value,
        items: controller.advertiserProfiles.map((profile) {
          final isCompany = profile.accountType.toLowerCase() == 'company';
          final member = profile.companyMember; // قد يكون null

          return DropdownMenuItem<AdvertiserProfile>(
            value: profile,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // اسم الملف + شارة النوع (شركة/فردي)
                Row(
                  children: [
                    Icon(isCompany ? Icons.apartment : Icons.person, size: 18.sp, color: AppColors.primary),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text(
                        (profile.name ?? 'بدون اسم'),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppTextStyles.appFontFamily,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: isCompany ? Colors.orange.withOpacity(0.15) : Colors.green.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        isCompany ? 'شركة' : 'فردي',
                        style: TextStyle(
                          fontFamily: AppTextStyles.appFontFamily,
                          fontSize: 11.sp,
                          color: isCompany ? Colors.orange : Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),

                // لو شركة: سطر مختصر لاسم العضو + نوع/دور العضو فقط
                if (isCompany && member != null) ...[
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      Icon(Icons.badge, size: 16.sp, color: AppColors.primary),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          '${member.displayName ?? "-"} — ${member.role}',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppTextStyles.appFontFamily,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        }).toList(),
        onChanged: (profile) {
          setState(() {
            controller.selectedProfile.value = profile;
            controller.idOfadvertiserProfiles.value = profile?.id ?? 0;

            // إسناد النوع + المعرّف (لو شركة)
            final isCompany = (profile?.accountType.toLowerCase() == 'company');
            controller.selectedAdvertiserAccountType.value = isCompany ? 'company' : 'individual';
            controller.selectedCompanyMemberId.value = isCompany ? profile?.companyMember?.id : null;

            _stepValid[0] = profile != null;
          });
        },
        icon: Icons.person,
      ),
    ],
  );
});



  Widget _buildMainCategoryDropdown() => Obx(() {
    if (controller.isLoadingCategories.value) return _buildLoadingIndicator();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('التصنيف الرئيسي *', style: _fieldLabelStyle),
      SizedBox(height: 8.h),
      _buildDropdown<Category>(
        hint: 'اختر التصنيف الرئيسي',
        value: controller.selectedMainCategory.value,
        items: controller.categoriesList.map((category) => DropdownMenuItem(
          value: category,
          child: Text(category.translations.first.name, style: TextStyle(fontFamily: AppTextStyles.appFontFamily)),
        )).toList(),
        onChanged: (category) => setState(() {
          if (category != null) {
            controller.selectMainCategory(category);
            _stepValid[1] = true;
          } else {
            _stepValid[1] = false;
          }
        }),
        icon: Icons.category,
      ),
    ]);
  });

  Widget _buildSubcategoryDropdown() => Obx(() {
    if (controller.isLoadingSubcategoryLevelOne.value) return _buildLoadingIndicator();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('التصنيف الفرعي (اختياري)', style: _fieldLabelStyle),
      SizedBox(height: 8.h),
      _buildDropdown<SubcategoryLevelOne>(
        hint: 'اختر التصنيف الفرعي',
        value: controller.selectedSubcategoryLevelOne.value,
        items: controller.subCategories.map((subcategory) => DropdownMenuItem(
          value: subcategory,
          child: Text(subcategory.translations.first.name, style: TextStyle(fontFamily: AppTextStyles.appFontFamily)),
        )).toList(),
        onChanged: (subcategory) => setState(() => subcategory != null ? controller.selectSubcategoryLevelOne(subcategory) : null),
        icon: Icons.list,
      ),
    ]);
  });

  Widget _buildSubcategoryLevelTwoDropdown() => Obx(() {
    if (controller.isLoadingSubcategoryLevelTwo.value) return _buildLoadingIndicator();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('التصنيف الثانوي (اختياري)', style: _fieldLabelStyle),
      SizedBox(height: 8.h),
      _buildDropdown<SubcategoryLevelTwo>(
        hint: 'اختر التصنيف الثانوي',
        value: controller.selectedSubcategoryLevelTwo.value,
        items: controller.subCategoriesLevelTwo.map((subcategory) => DropdownMenuItem(
          value: subcategory,
          child: Text(subcategory.translations.first.name, style: TextStyle(fontFamily: AppTextStyles.appFontFamily)),
        )).toList(),
        onChanged: (subcategory) => setState(() => subcategory != null ? controller.selectSubcategoryLevelTwo(subcategory) : null),
        icon: Icons.list_alt,
      ),
    ]);
  });

  Widget _buildCityDropdown() => Obx(() {
    if (controller.isLoadingCities.value) return _buildLoadingIndicator();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('المدينة *', style: _fieldLabelStyle),
      SizedBox(height: 8.h),
      _buildDropdown<TheCity>(
        hint: 'اختر المدينة',
        value: controller.selectedCity.value,
        items: controller.citiesList.map((city) => DropdownMenuItem(
          value: city,
          child: Text(city.translations.first.name, style: TextStyle(fontFamily: AppTextStyles.appFontFamily)),
        )).toList(),
        onChanged: (city) => setState(() {
          if (city != null) {
            controller.selectCity(city);
            _stepValid[4] = controller.selectedCity.value != null && controller.selectedArea.value != null;
          } else {
            _stepValid[4] = false;
          }
        }),
        icon: Icons.location_city,
      ),
    ]);
  });

  Widget _buildAreaDropdown() {
    if (controller.selectedCity.value == null) return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('المنطقة *', style: _fieldLabelStyle),
      SizedBox(height: 8.h),
      AbsorbPointer(child: Opacity(opacity: 0.6, child: _buildDropdown<Area>(hint: 'اختر المدينة أولاً', value: null, items: <DropdownMenuItem<Area>>[], onChanged: (_) {}, icon: Icons.map))),
    ]);

    return FutureBuilder<List<Area>>(future: areaC.getAreasOrFetch(controller.selectedCity.value!.id), builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('المنطقة *', style: _fieldLabelStyle),
        SizedBox(height: 8.h),
        _buildDropdown<Area>(hint: 'جارٍ تحميل المناطق...', value: controller.selectedArea.value, items: [], onChanged: (_) {}, icon: Icons.map),
      ]);

      if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('المنطقة *', style: _fieldLabelStyle),
        SizedBox(height: 8.h),
        _buildDropdown<Area>(hint: snapshot.hasError ? 'خطأ في جلب البيانات' : 'لا توجد مناطق', value: controller.selectedArea.value, items: [], onChanged: (_) {}, icon: Icons.map),
      ]);

      final areas = snapshot.data!;
      final items = areas.map((area) => DropdownMenuItem<Area>(value: area, child: Text(area.name, style: TextStyle(fontFamily: AppTextStyles.appFontFamily)))).toList();

      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('المنطقة *', style: _fieldLabelStyle),
        SizedBox(height: 8.h),
        _buildDropdown<Area>(
          hint: 'اختر المنطقة',
          value: controller.selectedArea.value,
          items: items,
          onChanged: (area) => setState(() {
            if (area != null) {
              controller.selectArea(area);
              _stepValid[4] = controller.selectedCity.value != null && controller.selectedArea.value != null;
            } else {
              _stepValid[4] = false;
            }
          }),
          icon: Icons.map,
        ),
      ]);
    });
  }

  Widget _buildDropdown<T>({required String hint, required T? value, required List<DropdownMenuItem<T>> items, required ValueChanged<T?> onChanged, required IconData icon}) {
    return Container(
      decoration: BoxDecoration(color: AppColors.surface(isDark), borderRadius: BorderRadius.circular(12.r), border: Border.all(color: value != null ? AppColors.primary : AppColors.border(isDark), width: 1.5)),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      child: Row(children: [
        Icon(icon, color: AppColors.icon(isDark), size: 20.w),
        SizedBox(width: 12.w),
        Expanded(child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            isExpanded: true,
            hint: Text(hint, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, color: AppColors.textSecondary(isDark))),
            value: value,
            items: items,
            onChanged: onChanged,
            icon: Icon(Icons.arrow_drop_down, color: AppColors.primary, size: 28.w),
            style: TextStyle(fontFamily: AppTextStyles.appFontFamily, color: AppColors.textPrimary(isDark)),
            dropdownColor: AppColors.card(isDark),
          ),
        )),
      ]),
    );
  }

  Widget _buildAttributeField(Attribute attribute) {
    final textColor = AppColors.textPrimary(isDark);
    switch (attribute.type) {
      case 'number': return _buildNumberField(attribute, textColor);
      case 'text': return _buildTextField(attribute, textColor);
      case 'boolean': return _buildBooleanField(attribute, textColor);
      case 'options': return _buildOptionsField(attribute, textColor);
      default: return _buildTextField(attribute, textColor);
    }
  }

  Widget _buildNumberField(Attribute attribute, Color textColor) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    RichText(text: TextSpan(text: attribute.label, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontWeight: FontWeight.w600, color: textColor), children: attribute.required == true ? [TextSpan(text: ' *', style: TextStyle(color: Colors.red))] : [])),
    SizedBox(height: 8.h),
    Form(key: _attributeFormKeys[attribute.attributeId], child: Container(
      decoration: BoxDecoration(color: AppColors.surface(isDark), borderRadius: BorderRadius.circular(12.r), border: Border.all(color: AppColors.border(isDark))),
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: TextFormField(
        keyboardType: TextInputType.number,
        decoration: InputDecoration(border: InputBorder.none, hintText: 'أدخل ${attribute.label}', hintStyle: TextStyle(fontFamily: AppTextStyles.appFontFamily), suffixIcon: Icon(Icons.numbers, color: AppColors.primary, size: 20.w)),
        style: TextStyle(fontFamily: AppTextStyles.appFontFamily, color: textColor),
        validator: attribute.required == true ? (value) => value == null || value.isEmpty ? 'هذا الحقل مطلوب' : null : null,
        onChanged: (value) {
          controller.attributeValues[attribute.attributeId] = value;
          if (attribute.required == true) _attributeFormKeys[attribute.attributeId]?.currentState?.validate();
        },
      ),
    )),
  ]);

  Widget _buildTextField(Attribute attribute, Color textColor) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    RichText(text: TextSpan(text: attribute.label, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontWeight: FontWeight.w600, color: textColor), children: attribute.required == true ? [TextSpan(text: ' *', style: TextStyle(color: Colors.red))] : [])),
    SizedBox(height: 8.h),
    Form(key: _attributeFormKeys[attribute.attributeId], child: Container(
      decoration: BoxDecoration(color: AppColors.surface(isDark), borderRadius: BorderRadius.circular(12.r), border: Border.all(color: AppColors.border(isDark))),
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: TextFormField(
        decoration: InputDecoration(border: InputBorder.none, hintText: 'ادخل ${attribute.label}', hintStyle: TextStyle(fontFamily: AppTextStyles.appFontFamily), suffixIcon: Icon(Icons.text_fields, color: AppColors.primary, size: 20.w)),
        style: TextStyle(fontFamily: AppTextStyles.appFontFamily, color: textColor),
        validator: attribute.required == true ? (value) => value == null || value.isEmpty ? 'هذا الحقل مطلوب' : null : null,
        onChanged: (value) {
          controller.attributeValues[attribute.attributeId] = value;
          if (attribute.required == true) _attributeFormKeys[attribute.attributeId]?.currentState?.validate();
        },
      ),
    )),
  ]);

  Widget _buildBooleanField(Attribute attribute, Color textColor) {
    bool? value = controller.attributeValues[attribute.attributeId] as bool?;
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      RichText(text: TextSpan(text: attribute.label, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontWeight: FontWeight.w600, color: textColor), children: attribute.required == true ? [TextSpan(text: ' *', style: TextStyle(color: Colors.red))] : [])),
      Row(children: [
        _buildBooleanOption('نعم', true, value == true, attribute),
        SizedBox(width: 12.w),
        _buildBooleanOption('لا', false, value == false, attribute),
      ]),
    ]);
  }

  Widget _buildBooleanOption(String label, bool optionValue, bool isSelected, Attribute attribute) => GestureDetector(
    onTap: () => setState(() {
      controller.attributeValues[attribute.attributeId] = optionValue;
      if (attribute.required == true) _validateAttributesStep();
    }),
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(color: isSelected ? AppColors.primary : AppColors.surface(isDark), borderRadius: BorderRadius.circular(8.r), border: Border.all(color: isSelected ? AppColors.primary : AppColors.border(isDark), width: 1.5)),
      child: Text(label, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, color: isSelected ? Colors.white : AppColors.textPrimary(isDark))),
    ),
  );

  Widget _buildOptionsField(Attribute attribute, Color textColor) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    RichText(text: TextSpan(text: attribute.label, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontWeight: FontWeight.w600, color: textColor), children: attribute.required == true ? [TextSpan(text: ' *', style: TextStyle(color: Colors.red))] : [])),
    SizedBox(height: 12.h),
    Wrap(spacing: 8.w, runSpacing: 12.h, children: attribute.options.map((option) {
      final isSelected = controller.attributeValues[attribute.attributeId] == option.id;
      return _buildOptionChip(option.value, option.id, isSelected, attribute);
    }).toList()),
  ]);

  Widget _buildOptionChip(String label, int value, bool isSelected, Attribute attribute) => ChoiceChip(
    label: Text(label, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, color: isSelected ? Colors.white : AppColors.textPrimary(isDark))),
    selected: isSelected,
    onSelected: (selected) => setState(() {
      controller.attributeValues[attribute.attributeId] = selected ? value : null;
      if (attribute.required == true) _validateAttributesStep();
    }),
    backgroundColor: AppColors.surface(isDark),
    selectedColor: AppColors.primary,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r), side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border(isDark), width: 1.5)),
    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
  );

  Widget _buildImagesSection() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('صور الإعلان (إلزامي)', style: _fieldLabelStyle),
    SizedBox(height: 12.h),
    Obx(() => controller.images.isEmpty ? _buildEmptyImagesPlaceholder() : _buildImagesGrid()),
    SizedBox(height: 16.h),
    ElevatedButton.icon(
      onPressed: controller.pickImages,
      icon: Icon(Icons.add_photo_alternate, size: 20.w),
      label: Text('إضافة صور'),
      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, minimumSize: Size(double.infinity, 50.h), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r))),
    ),
  ]);

  Widget _buildEmptyImagesPlaceholder() => DottedBorder(
    borderType: BorderType.RRect,
    radius: Radius.circular(12.r),
    color: AppColors.border(isDark),
    dashPattern: [6, 3],
    child: Container(
      height: 120.h,
      width: double.infinity,
      decoration: BoxDecoration(color: AppColors.surface(isDark), borderRadius: BorderRadius.circular(12.r)),
      child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.photo_library, size: 36.w, color: AppColors.textSecondary(isDark)),
        SizedBox(height: 8.h),
        Text('لم يتم إضافة أي صور', style: TextStyle(fontFamily: AppTextStyles.appFontFamily, color: AppColors.textSecondary(isDark))),
      ])),
    ),
  );

  Widget _buildImagesGrid() => Obx(() => GridView.builder(
    shrinkWrap: true,
    physics: NeverScrollableScrollPhysics(),
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8.w, mainAxisSpacing: 8.h, childAspectRatio: 0.8),
    itemCount: controller.images.length,
    itemBuilder: (context, index) => Stack(children: [
      ClipRRect(borderRadius: BorderRadius.circular(8.r), child: Image.file(controller.images[index], fit: BoxFit.cover, width: double.infinity, height: double.infinity)),
      Positioned(top: 4, right: 4, child: GestureDetector(
        onTap: () => controller.removeImage(index),
        child: Container(decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle), padding: EdgeInsets.all(4.w), child: Icon(Icons.close, size: 16.w, color: Colors.white)),
      )),
    ]),
  ));

  Widget _buildVideosSection() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('فيديو الإعلان (اختياري)', style: _fieldLabelStyle),
    SizedBox(height: 12.h),
    Obx(() => controller.selectedVideos.isEmpty ? _buildEmptyVideosPlaceholder() : SizedBox(
      height: 120.h,
      child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: controller.videoPlayers.length, separatorBuilder: (_, __) => SizedBox(width: 8.w), itemBuilder: (context, i) => ClipRRect(
        borderRadius: BorderRadius.circular(8.r),
        child: AspectRatio(aspectRatio: controller.videoPlayers[i].value.aspectRatio, child: VideoPlayer(controller.videoPlayers[i])),
      )),
    )),
    SizedBox(height: 16.h),
    ElevatedButton.icon(
      onPressed: controller.pickVideos,
      icon: Icon(Icons.video_library, size: 20.w),
      label: Text('إضافة فيديو'),
      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, minimumSize: Size(double.infinity, 50.h), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r))),
    ),
  ]);

  Widget _buildEmptyVideosPlaceholder() => DottedBorder(
    borderType: BorderType.RRect,
    radius: Radius.circular(12.r),
    color: AppColors.border(isDark),
    dashPattern: [6, 3],
    child: Container(
      height: 120.h,
      width: double.infinity,
      decoration: BoxDecoration(color: AppColors.surface(isDark), borderRadius: BorderRadius.circular(12.r)),
      child: Center(child: Text('لم يتم إضافة فيديو', style: TextStyle(fontFamily: AppTextStyles.appFontFamily, color: AppColors.textSecondary(isDark)))),
    ),
  );

  Widget _buildInputField({required TextEditingController controller, required String label, required IconData icon, int maxLines = 1, TextInputType keyboardType = TextInputType.text, String? Function(String?)? validator}) {
    final errorText = ''.obs;
    controller.addListener(() => errorText.value = validator?.call(controller.text) ?? '');

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: _fieldLabelStyle),
      SizedBox(height: 8.h),
      Container(
        decoration: BoxDecoration(color: AppColors.surface(isDark), borderRadius: BorderRadius.circular(12.r), border: Border.all(color: AppColors.border(isDark))),
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(border: InputBorder.none, suffixIcon: Icon(icon, color: AppColors.primary, size: 20.w)),
          style: TextStyle(fontFamily: AppTextStyles.appFontFamily, color: AppColors.textPrimary(isDark)),
          validator: validator,
          onChanged: (value) => setState(() => _stepValid[3] = _formKey.currentState?.validate() ?? false),
        ),
      ),
      Obx(() => errorText.value.isNotEmpty ? Padding(padding: EdgeInsets.only(left: 8.w, top: 4.h), child: Text(errorText.value, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, color: Colors.red, fontSize: AppTextStyles.small,
))) : SizedBox()),
    ]);
  }

  Widget _buildNoAttributesMessage() => Center(child: Padding(padding: EdgeInsets.all(24.h), child: Text('لا توجد خصائص لهذا التصنيف', style: TextStyle(fontFamily: AppTextStyles.appFontFamily, color: AppColors.textSecondary(isDark)))));
  Widget _buildNoDataMessage(String message) => Text(message, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, color: AppColors.textSecondary(isDark)));
  Widget _buildLoadingIndicator() => Center(child: Padding(padding: EdgeInsets.all(24.w), child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5)));
  TextStyle get _fieldLabelStyle => TextStyle(fontFamily: AppTextStyles.appFontFamily, fontWeight: FontWeight.w600);
}

class MapPickerScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;
  MapPickerScreen({this.initialLat, this.initialLng});

  @override
  _MapPickerScreenState createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  LatLng? _picked;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) _picked = LatLng(widget.initialLat!, widget.initialLng!);
  }

  @override
  Widget build(BuildContext context) {
final start = _picked ?? LatLng(33.5138, 36.2765);
    return Scaffold(
      appBar: AppBar(
        title: Text('اختيار الموقع', style: TextStyle(fontFamily: AppTextStyles.appFontFamily)),
        backgroundColor: AppColors.buttonAndLinksColor,
        actions: [
          TextButton(onPressed: () => _picked != null ? Navigator.pop(context, _picked) : ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('الرجاء تحديد النقطة على الخريطة'))), child: Text('تأكيد', style: TextStyle(color: Colors.white, fontFamily: AppTextStyles.appFontFamily))),
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(initialCenter: start, initialZoom: 13, onTap: (tapPos, latlng) => setState(() => _picked = latlng), interactionOptions: const InteractionOptions(flags: ~InteractiveFlag.rotate)),
        children: [
          TileLayer(urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png", userAgentPackageName: 'com.stayinme.app', tileDisplay: const TileDisplay.fadeIn()),
          MarkerLayer(markers: _picked != null ? [Marker(point: _picked!, width: 50.w, height: 50.h, child: Icon(Icons.location_on, color: AppColors.primary, size: 40.w))] : []),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _picked != null ? Navigator.pop(context, _picked) : Get.snackbar('حدد الموقع', 'الرجاء تحديد موقع على الخريطة'),
        label: Text('تأكيد الموقع', style: TextStyle(fontFamily: AppTextStyles.appFontFamily)),
        icon: Icon(Icons.check),
        backgroundColor: AppColors.primary,
      ),
    );
  }

}

