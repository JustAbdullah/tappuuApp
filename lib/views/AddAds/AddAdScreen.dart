// AddAdScreen.dart (مُحسّن)
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:tappuu_app/core/data/model/PremiumPackage.dart';
import 'package:tappuu_app/views/HomeScreen/home_screen.dart';
import 'package:video_player/video_player.dart';

// خرائط
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../controllers/AdsManageController.dart';
import '../../controllers/CardPaymentController.dart';
import '../../controllers/LoadingController.dart';
import '../../controllers/PremiumPackageController.dart';
import '../../controllers/ThemeController.dart';
import '../../controllers/areaController.dart';
import '../../controllers/user_wallet_controller.dart';
import '../../core/constant/app_text_styles.dart';
import '../../core/constant/appcolors.dart';
import '../../core/data/model/AdvertiserProfile.dart';
import '../../core/data/model/Attribute.dart';
import '../../core/data/model/Area.dart';
import '../../core/data/model/City.dart';
import '../../core/data/model/UserWallet.dart';
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

  // =====================================
  // تحسين واجهة اختيار الباقات البريميوم
  // =====================================
 // استبدل الدالة القديمة بهذه الدالة (تعرض الشاشة كاملة وتتعامل مع جميع الأجهزة)



  // ====================================
  // دالة تقديم الإعلان بدون بريميوم
  // ====================================
 

  // بقية الكود كما هو (مع تحسينات طفيفة في التصميم)
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

  if (controller.advertiserProfiles.isEmpty) {
    return Center(
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: AppColors.card(Get.find<ThemeController>().isDarkMode.value),
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

                color: AppColors.textPrimary((Get.find<ThemeController>().isDarkMode.value)),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              'قم بإنشاء ملف معلن لإتمام عملية نشر الإعلانات بسهولة',
              style: TextStyle(
                fontFamily: AppTextStyles.appFontFamily,
                fontSize: AppTextStyles.medium,

                color: AppColors.textSecondary((Get.find<ThemeController>().isDarkMode.value)),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              onPressed: () {
                // الانتقال إلى شاشة إنشاء/إدارة ملف المعلن
                Get.to(() => AdvertiserDataScreen());
              },
              icon: Icon(Icons.add_business, color: Colors.white),
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

  // في حال وجود ملفات معلن
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('ملف المعلن *', style: _fieldLabelStyle),
      SizedBox(height: 8.h),
      _buildDropdown<AdvertiserProfile>(
        hint: 'اختر بيانات المعلن',
        value: controller.selectedProfile.value,
        items: controller.advertiserProfiles.map((profile) {
          return DropdownMenuItem(
            value: profile,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name.toString(),
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${profile.contactPhone}',
                  style: TextStyle(fontFamily: AppTextStyles.appFontFamily),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: (profile) {
          setState(() {
            controller.selectedProfile.value = profile;
            controller.idOfadvertiserProfiles.value = profile?.id ?? 0;
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
/// ============================
/// PremiumPackagesScreen
/// ============================
class PremiumPackagesScreen extends StatefulWidget {
  const PremiumPackagesScreen({Key? key}) : super(key: key);

  @override
  State<PremiumPackagesScreen> createState() => _PremiumPackagesScreenState();
}

class _PremiumPackagesScreenState extends State<PremiumPackagesScreen> {
  final PremiumPackageController controller = Get.put(PremiumPackageController());
  final ThemeController themeController = Get.find<ThemeController>();
  final ManageAdController adController = Get.find<ManageAdController>();
  final LoadingController loadingController = Get.find<LoadingController>();
  final CardPaymentController _cardPaymentController = Get.put(CardPaymentController()); // إضافة التحكم بالبطاقة
  final NumberFormat _fmt = NumberFormat('#,##0', 'en_US');

  /// خريطة تحدد الباقة المختارة لكل نوع: { 'نوع A' : packageId, 'نوع B' : packageId }
  Map<String, int> selectedPackagesByType = {};

  @override
  void initState() {
    super.initState();
    controller.fetchPackages();
    // التأكد من جلب إعدادات البطاقة
    _cardPaymentController.fetchSetting();
  }

  // ------------------ Helpers ------------------
  int _extractDaysFromName(String name) {
    final regExp = RegExp(r'(\d+)');
    final match = regExp.firstMatch(name);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '') ?? 0;
    }
    return 0;
  }

  Map<String, List<PremiumPackage>> _groupPackagesByType(List<PremiumPackage> packages) {
    Map<String, List<PremiumPackage>> groupedPackages = {};
    for (var package in packages) {
      if (package.isActive == true) {
        String typeName = package.type?.name ?? 'باقات أخرى';
        groupedPackages.putIfAbsent(typeName, () => []);
        groupedPackages[typeName]!.add(package);
      }
    }
    groupedPackages.forEach((key, value) {
      value.sort((a, b) {
        int aDays = _extractDaysFromName(a.name ?? '');
        int bDays = _extractDaysFromName(b.name ?? '');
        if (aDays != bDays) return aDays.compareTo(bDays);
        final da = (a.price ?? 0).compareTo((b.price ?? 0));
        if (da != 0) return da;
        return (a.name ?? '').compareTo((b.name ?? ''));
      });
    });
    return groupedPackages;
  }

  void _togglePackageSelection(String typeName, int packageId) {
    setState(() {
      if (selectedPackagesByType[typeName] == packageId) {
        selectedPackagesByType.remove(typeName);
      } else {
        selectedPackagesByType[typeName] = packageId;
      }
    });
  }

  Set<int> get selectedPackageIds => selectedPackagesByType.values.toSet();

  List<PremiumPackage> get _selectedPackages {
    return controller.packagesList.where((p) => selectedPackageIds.contains(p.id)).toList();
  }

  String _buildSelectedSummary() {
    final selected = _selectedPackages;
    if (selected.isEmpty) return 'لم يتم اختيار باقات بعد';
    final total = selected.fold<double>(0.0, (prev, el) => prev + (el.price ?? 0));
    final types = selected.map((e) => e.type?.name ?? '').toSet().join(' • ');
    final names = selected.map((e) => e.name ?? '').join(' • ');
    return '$names · $types · ${_fmt.format(total)} ل.س';
  }

  // عند الضغط على زر الدفع: جهّز قائمة الحزم المختارة واذهب إلى شاشة الدفع
  void _onProceedToPayment() {
    final selectedIds = selectedPackageIds;
    if (selectedIds.isEmpty) {
      Get.snackbar('خطأ', 'يرجى اختيار باقة واحدة على الأقل', backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    final selectedPackages = _selectedPackages;

    // مرّر قائمة الباقات (حتى لو عنصر واحد) للـ PaymentScreen
    Get.to(() => PaymentScreen(
          package: selectedPackages,
          adTitle: adController.titleArController.text,
          adPrice: '${adController.priceController.text} ل.س',
        ));
  }

  // إنشاء الإعلان دون باقة
  Future<void> _submitAdWithoutPremium() async {
    try {
      _showLoadingDialog();
      await Future.delayed(const Duration(milliseconds: 100));
      await adController.submitAd();
      while (adController.isSubmitting.value) {
        await Future.delayed(const Duration(milliseconds: 200));
      }
      Get.offAll(() => HomeScreen());
    } catch (e) {
      print('⚠️ _submitAdWithoutPremium exception: $e');
      Get.back();
    } finally {
      if (mounted && Navigator.canPop(context)) {
        try {
          Navigator.pop(context);
        } catch (_) {}
      }
    }
  }

  void _confirmCreateWithoutPackage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تأكيد'.tr, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, color: Colors.black, fontSize: AppTextStyles.large, fontWeight: FontWeight.w500)),
        content: Text('هل تريد إنشاء الإعلان دون أي باقة مميزة؟'.tr, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, color: Colors.black, fontSize: AppTextStyles.medium, fontWeight: FontWeight.w600)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('إلغاء'.tr, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, color: AppColors.primary))),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _submitAdWithoutPremium();
            },
            child: Text('تأكيد'.tr, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, color: AppColors.primary, fontSize: AppTextStyles.large, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // bottom sheet لعرض تفاصيل الباقة (مبسّط، مع ملخّص المتوقّع)
  void _showPackageDetailsSheet(PremiumPackage pkg, String typeName) {
    final currentlySelected = _selectedPackages;
    final currentTotal = currentlySelected.fold<double>(0.0, (p, e) => p + (e.price ?? 0));
    final willAdd = selectedPackagesByType[typeName] != pkg.id;
    final predictedTotal = currentTotal + (willAdd ? (pkg.price ?? 0) : 0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: themeController.isDarkMode.value ? Color(0xFF0b1220) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16.r))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 16.w),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 60.w, height: 6.h, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10.r))),
                  SizedBox(height: 12.h),
                  Text(pkg.name ?? '', style: TextStyle(fontSize: AppTextStyles.xlarge, fontWeight: FontWeight.w900, fontFamily: AppTextStyles.appFontFamily)),
                  SizedBox(height: 8.h),
                  Text('${_fmt.format(pkg.price ?? 0)} ل.س • ${pkg.durationDays ?? '-'} يوم', style: TextStyle(fontSize: AppTextStyles.medium, color: AppColors.textSecondary(themeController.isDarkMode.value))),
                  SizedBox(height: 10.h),
                  if ((pkg.description ?? '').isNotEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6.w),
                      child: Text(pkg.description!, style: TextStyle(fontSize: AppTextStyles.small, color: AppColors.textSecondary(themeController.isDarkMode.value)), textAlign: TextAlign.center),
                    ),
                  SizedBox(height: 16.h),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('المجموع بعد الاختيار', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('${_fmt.format(predictedTotal)} ل.س', style: TextStyle(fontWeight: FontWeight.bold, fontSize: AppTextStyles.large)),
                    ],
                  ),
                  SizedBox(height: 12.h),
              
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            _togglePackageSelection(typeName, pkg.id!);
                            Navigator.of(ctx).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: (selectedPackagesByType[typeName] == pkg.id) ? Colors.grey : AppColors.primary,
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                          ),
                          child: Text((selectedPackagesByType[typeName] == pkg.id) ? 'إلغاء الاختيار' : 'اختيار هذه الباقة', style: TextStyle(fontSize: AppTextStyles.medium, fontWeight: FontWeight.w800)),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            if (selectedPackagesByType[typeName] != pkg.id) _togglePackageSelection(typeName, pkg.id!);
                            Navigator.of(ctx).pop();
                            _onProceedToPayment();
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.primary, width: 2),
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                          ),
                          child: Text('الدفع الآن لهذه الباقة', style: TextStyle(fontSize: AppTextStyles.medium, fontWeight: FontWeight.w800, color: AppColors.primary)),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 18.h),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // نافذة التحميل
  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            content: Center(
              child: Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(color: AppColors.card(themeController.isDarkMode.value), borderRadius: BorderRadius.circular(16.r), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 12)]),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12.h),
                    Text('جاري إنشاء/معالجة الإعلان...', style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.medium, fontWeight: FontWeight.bold, color: AppColors.textPrimary(themeController.isDarkMode.value))),
                    SizedBox(height: 8.h),
                    Text('يرجى الانتظار قليلاً', style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.small, color: AppColors.textSecondary(themeController.isDarkMode.value))),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = themeController.isDarkMode.value;
      final activePackages = controller.packagesList.where((pkg) => pkg.isActive == true).toList();
      final groupedPackages = _groupPackagesByType(activePackages);

      return Scaffold(
        backgroundColor: AppColors.background(isDark),
        appBar: AppBar(
          backgroundColor: AppColors.appBar(isDark),
          centerTitle: true,
          elevation: 0,
          title: Text('الباقات المميزة'.tr, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, color: AppColors.onPrimary, fontSize: AppTextStyles.xxlarge, fontWeight: FontWeight.w700)),
          leading: IconButton(icon: Icon(Icons.arrow_back, color: AppColors.onPrimary), onPressed: () => Get.back()),
        ),
        body: SafeArea
        (
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                // Header مختصر (يمكنك إبقاؤه كما تريد)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(12.r)),
                  child: Row(
                    children: [
                      Icon(Icons.star, color: AppColors.primary),
                      SizedBox(width: 12.w),
                      Expanded(child: Text('اختر الباقات المناسبة لإبراز إعلانك', style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.large, fontWeight: FontWeight.w700, color: AppColors.primary))),
                    ],
                  ),
                ),
                SizedBox(height: 18.h),
          
                Expanded(
                  child: controller.isLoadingPackages.value
                      ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primary)))
                      : activePackages.isEmpty
                          ? Center(child: Text('لا توجد باقات متاحة حالياً'.tr))
                          : ListView(
                              padding: EdgeInsets.only(bottom: 120.h),
                              children: [
                                ...groupedPackages.entries.map((entry) {
                                  final typeName = entry.key;
                                  final typePackages = entry.value;
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.symmetric(vertical: 8.h),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(typeName, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.xlarge, fontWeight: FontWeight.w800, color: AppColors.primary)),
                                            if (typePackages.isNotEmpty && (typePackages.first.type?.description ?? '').isNotEmpty)
                                              IconButton(
                                                onPressed: () {
                                                  Get.defaultDialog(title: typeName, content: Text(typePackages.first.type!.description ?? ''));
                                                },
                                                icon: Icon(Icons.info_outline, color: AppColors.textSecondary(isDark)),
                                              ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                        height: 190.h,
                                        child: ListView.separated(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: typePackages.length,
                                          separatorBuilder: (_, __) => SizedBox(width: 14.w),
                                          padding: EdgeInsets.symmetric(horizontal: 4.w),
                                          itemBuilder: (context, idx) {
                                            final pkg = typePackages[idx];
                                            final isSelected = selectedPackagesByType[typeName] == pkg.id;
                                            return HorizontalPackageCard(
                                              pkg: pkg,
                                              isDark: isDark,
                                              priceText: '${_fmt.format(pkg.price ?? 0)} ل.س',
                                              isSelected: isSelected,
                                              onSelect: () => _showPackageDetailsSheet(pkg, typeName),
                                            );
                                          },
                                        ),
                                      ),
                                      SizedBox(height: 22.h),
                                    ],
                                  );
                                }).toList(),
                              ],
                            ),
                ),
                SizedBox(height: 30.h,)
              ],
            ),
          ),
        ),
      

        // FAB bottom: شريط ملخّص + زر إنشاء دون باقة
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selectedPackageIds.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(bottom: 8.h,top: 10.h),
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.90,
                    decoration: BoxDecoration(color: isDark ? Color(0xFF0b1220) : Colors.white, borderRadius: BorderRadius.circular(12.r), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 12, offset: Offset(0, 6))]),
                    child: Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${selectedPackageIds.length} ${'باقات مختارة'.tr}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: AppTextStyles.large,fontFamily:  AppTextStyles.appFontFamily,)),
                                SizedBox(height: 6.h),
                                Text(_buildSelectedSummary(), style: TextStyle(
                                  fontFamily:  AppTextStyles.appFontFamily,
                                  fontSize: AppTextStyles.small, color: AppColors.textSecondary(isDark)), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.only(right: 8.w),
                          child: ElevatedButton(
                            onPressed: _onProceedToPayment,
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 14.h), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.r))),
                            child: Text('الدفع الآن'.tr, style: TextStyle(fontFamily:  AppTextStyles.appFontFamily,fontWeight: FontWeight.bold, fontSize: AppTextStyles.medium)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
           SafeArea(
          child:
              // زر إنشاء دون باقة كبير وواضح
              FloatingActionButton.extended(
                heroTag: 'create_no_pkg',
                onPressed: _confirmCreateWithoutPackage,
                label: Padding(padding: EdgeInsets.symmetric(horizontal: 50.w), child: Text('إنشاء دون باقة'.tr, style: TextStyle(fontWeight: FontWeight.w700,fontFamily: AppTextStyles.appFontFamily,fontSize:  AppTextStyles.medium))),
                icon: Icon(Icons.post_add_outlined),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              )),
          
              SizedBox(height: 0.h,)
            ],
          ),
        ),
      );
    });
  }
}

/// ============================
/// HorizontalPackageCard (مبسّط: يظهر السعر والمدة + زر تفاصيل/info على الكرت)
/// ============================
class HorizontalPackageCard extends StatelessWidget {
  final PremiumPackage pkg;
  final bool isDark;
  final String priceText;
  final bool isSelected;
  final VoidCallback onSelect;

  const HorizontalPackageCard({
    Key? key,
    required this.pkg,
    required this.isDark,
    required this.priceText,
    required this.isSelected,
    required this.onSelect,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected ? AppColors.primary : Colors.grey.withOpacity(0.25);
    final bg = isSelected ? AppColors.primary.withOpacity(0.06) : (isDark ? Color(0xFF141722) : Colors.white);

    return GestureDetector(
      onTap: onSelect,
      child: Container(
        width: 170.w,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: Offset(0, 4))],
        ),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // اسم الباقة (مكثّف)
              Row(
                children: [
                  Expanded(
                    child: Text(pkg.name ?? '', style: TextStyle(fontSize: AppTextStyles.large, fontWeight: FontWeight.w800, fontFamily: AppTextStyles.appFontFamily, color: AppColors.textPrimary(isDark)), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ),
                  SizedBox(width: 6.w),
                  // أيقونة المعلومات: تفتح الـ sheet عند الضغط (نفس onSelect يستخدمها)
                  InkWell(
                    onTap: onSelect,
                    child: Icon(Icons.info_outline, size: 20.w, color: AppColors.textSecondary(isDark)),
                  )
                ],
              ),

              SizedBox(height: 10.h),

              // سعر ومدة فقط
              Text(priceText, style: TextStyle(fontSize: AppTextStyles.xlarge, fontWeight: FontWeight.w900, color: AppColors.primary)),
              SizedBox(height: 6.h),
              Text('${pkg.durationDays ?? '-'} يوم', style: TextStyle(fontSize: AppTextStyles.small, color: AppColors.textSecondary(isDark))),

              Spacer(),

              // زر مبسّط
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: onSelect,
                  style: TextButton.styleFrom(
                    backgroundColor: isSelected ? AppColors.primary : Colors.transparent,
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      side: BorderSide(color: isSelected ? AppColors.primary : Colors.grey.withOpacity(0.2)),
                    ),
                  ),
                  child: Text(isSelected ? 'محدد' : 'عرض التفاصيل', style: TextStyle(fontSize: AppTextStyles.small, fontWeight: FontWeight.w700, color: isSelected ? Colors.white : AppColors.buttonAndLinksColor)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ============================
/// PaymentScreen (يتعامل مع قائمة باقات أو باقة واحدة)
/// ============================
class PaymentScreen extends StatefulWidget {
  /// package can be List<PremiumPackage> or PremiumPackage
  final dynamic package;
  final String adTitle;
  final String adPrice;

  const PaymentScreen({
    Key? key,
    required this.package,
    required this.adTitle,
    required this.adPrice,
  }) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final ManageAdController adController = Get.find<ManageAdController>();
  final ThemeController themeController = Get.find<ThemeController>();
  final UserWalletController walletController = Get.put(UserWalletController());
  final LoadingController loadingController = Get.find<LoadingController>();
  final CardPaymentController _cardPaymentController = Get.find<CardPaymentController>(); // إضافة التحكم بالبطاقة
  final _formKey = GlobalKey<FormState>();

  final cardNumberCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final expiryCtrl = TextEditingController();
  final cvvCtrl = TextEditingController();

  // تحديد طريقة الدفع الافتراضية بناءً على حالة البطاقة
  String get initialPaymentMethod {
    return _cardPaymentController.isEnabled.value ? 'card' : 'wallet';
  }
  
  String selectedPaymentMethod = 'wallet'; // سيتم تحديثها في initState
  bool isProcessing = false;
  UserWallet? selectedWallet;

  final fmt = NumberFormat('#,##0', 'en_US');

  @override
  void initState() {
    super.initState();
    _fetchUserWallets();
    
    // تعيين طريقة الدفع الافتراضية بناءً على حالة البطاقة
    selectedPaymentMethod = initialPaymentMethod;
    
    // التأكد من جلب أحدث إعدادات البطاقة
    _cardPaymentController.fetchSetting();
  }

  Future<void> _fetchUserWallets() async {
    final userId = loadingController.currentUser?.id;
    if (userId != null) {
      await walletController.fetchUserWallets(userId);
    }
  }

  List<PremiumPackage> _packageListFromWidget() {
    final p = widget.package;
    final out = <PremiumPackage>[];
    try {
      if (p == null) return out;
      if (p is List) {
        for (var e in p) {
          if (e == null) continue;
          if (e is PremiumPackage) out.add(e);
        }
        return out;
      }
      if (p is PremiumPackage) {
        out.add(p);
        return out;
      }
    } catch (e) {
      print('⚠️ _packageListFromWidget parse error: $e');
    }
    return out;
  }

  List<int> _extractPackageIdsFromWidgetPackage() {
    return _packageListFromWidget().map((e) => e.id ?? 0).where((id) => id > 0).toList();
  }

  double _totalPriceOfSelected() {
    final list = _packageListFromWidget();
    return list.fold(0.0, (p, e) => p + (e.price ?? 0));
  }

  String _namesOfSelected() {
    final list = _packageListFromWidget();
    if (list.isEmpty) return '-';
    return list.map((e) => e.name ?? '-').join(' • ');
  }

  String _typesOfSelected() {
    final list = _packageListFromWidget();
    if (list.isEmpty) return '-';
    return list.map((e) => e.type?.name ?? '-').toSet().join(' • ');
  }

  String _durationText() {
    final list = _packageListFromWidget();
    if (list.isEmpty) return '-';
    if (list.length == 1) return '${list.first.durationDays ?? '-'} يوم';
    final durations = list.map((e) => e.durationDays ?? 0).toSet();
    if (durations.length == 1) return '${durations.first} يوم';
    return 'متعددة';
  }

  // ------------------ parse createdAdId helper ------------------
  Future<int?> _parseCreatedAdId(dynamic result) async {
    try {
      if (result == null) return null;

      if (result is int) return result;
      if (result is String) {
        final val = int.tryParse(result);
        if (val != null) return val;
      }
      if (result is Map) {
        // common keys
        final keys = ['id', 'ad_id', 'created_ad_id', 'createdId', 'createdId', 'data', 'result'];
        for (var k in keys) {
          if (result.containsKey(k)) {
            final v = result[k];
            if (v is int) return v;
            if (v is String) {
              final val = int.tryParse(v);
              if (val != null) return val;
            }
            if (v is Map) {
              // nested
              final nested = await _parseCreatedAdId(v);
              if (nested != null) return nested;
            }
          }
        }
        // try to find any numeric value
        for (var entry in result.entries) {
          final v = entry.value;
          if (v is int) return v;
          if (v is String) {
            final val = int.tryParse(v);
            if (val != null) return val;
          }
        }
      }
      // fallback: check controller properties if exist (best-effort)
      try {
        final dynamic c = adController;
        // try common field names
        if (c != null) {
          if ((c as dynamic).createdAdId != null) {
            final v = (c).createdAdId;
            if (v is int) return v;
            if (v is String) return int.tryParse(v);
          }
        }
      } catch (_) {}
    } catch (e) {
      print('⚠️ _parseCreatedAdId error: $e');
    }
    return null;
  }

  // ------------------ عملية الدفع (نفس منطقك مع تحسينات) ------------------
  Future<void> _processPayment() async {
    FocusScope.of(context).unfocus();
    if (selectedPaymentMethod == 'card' && !_formKey.currentState!.validate()) return;

    if (selectedPaymentMethod == 'wallet') {
      if (selectedWallet == null) {
        Get.snackbar('خطأ', 'يرجى اختيار محفظة للدفع', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }
      // تمنع الدفع إذا لم تكن المحفظة نشطة
      if ((selectedWallet!.status ?? '').toString().toLowerCase() != 'active') {
        Get.snackbar('خطأ', 'لا يمكن استخدام هذه المحفظة لأنها ليست نشطة', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }
    }

    setState(() => isProcessing = true);
    final packageIds = _extractPackageIdsFromWidgetPackage();
    if (packageIds.isEmpty) {
      Get.snackbar('خطأ', 'لا توجد باقات صالحة للاشتراك', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      setState(() => isProcessing = false);
      return;
    }

    try {
      if (selectedPaymentMethod == 'wallet') {
        final bool isSingle = _packageListFromWidget().length == 1;
        final PremiumPackage? firstPkg = isSingle ? _packageListFromWidget().first : null;

        // إنشاء الإعلان أولا (نمرّر premiumDays لو باقة مفردة)
        final int? createdAdId = await _submitAdAndGetId(forPackage: firstPkg, isSinglePackage: isSingle);
        if (createdAdId == null) {
          setState(() => isProcessing = false);
          return;
        }

        // purchase via wallet
        final result = await walletController.purchasePremium(walletUuid: selectedWallet!.uuid, adId: createdAdId, packageIds: packageIds);

        if (result != null && result['success'] == true) {
          Get.snackbar('نجاح', 'تم شراء/تجديد الباقات بنجاح', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
        } else {
          final body = result != null ? result['body'] : null;
          final message = body != null && body['message'] != null ? body['message'] : 'فشل شراء/تجديد الباقات';
          Get.snackbar('خطأ', message, snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
        }

        if (Navigator.canPop(context)) Navigator.pop(context);
        Get.offAll(HomeScreen());
      } else {
        // بطاقة (محاكاة)
        final bool isSingle = _packageListFromWidget().length == 1;
        await Future.delayed(Duration(seconds: 2));
        Get.snackbar('نجاح', 'تمت عملية الدفع بالبطاقة بنجاح', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);

        final PremiumPackage? firstPkg = isSingle ? _packageListFromWidget().first : null;
        final int? createdAdId = await _submitAdAndGetId(forPackage: firstPkg, isSinglePackage: isSingle);
        if (createdAdId == null) {
          setState(() => isProcessing = false);
          return;
        }

        if (!isSingle) {
          Get.snackbar('ملاحظة', 'لقد دفعت بالبطاقة وتم إنشاء الإعلان. لربط الباقات المتعددة يرجى استخدام المحفظة أو التواصل مع الدعم.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange, colorText: Colors.white, duration: Duration(seconds: 5));
        } else {
          Get.snackbar('نجاح', 'تم إنشاء الإعلان بنجاح وهو قيد المراجعة', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
        }

        if (Navigator.canPop(context)) Navigator.pop(context);
        Get.offAll(HomeScreen());
      }
    } catch (e, st) {
      print('⚠️ _processPayment exception: $e\n$st');
      Get.snackbar('خطأ', 'حدث خطأ أثناء عملية الدفع: ${e.toString()}', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      setState(() => isProcessing = false);
    }
  }

  /// ينشئ الإعلان ويرجع createdAdId عند النجاح.
  /// إذا كان isSinglePackage=true فسيتم تمرير premiumDays و isPay=true
  /// إذا كانت false فسيتم إنشاء الإعلان بدون isPay لضمان عدم فشل الـ validation في السيرفر.
  Future<int?> _submitAdAndGetId({required PremiumPackage? forPackage, required bool isSinglePackage}) async {
    _showLoadingDialog();
    try {
      dynamic rawResult;
      if (isSinglePackage && forPackage != null) {
        // تمرير premiumDays لو باقة مفردة (افتراضي: durationDays أو days)
       
        rawResult = await adController.submitAd();
      } else {
        // باقات متعددة أو لا باقة -> إنشاء الإعلان بدون isPay
        rawResult = await adController.submitAd(isPay: false);
      }

      // انتظر انتهاء حالة الإرسال إن كانت true
      while (adController.isSubmitting.value) {
        await Future.delayed(const Duration(milliseconds: 200));
      }

      final int? parsedId = await _parseCreatedAdId(rawResult);
      if (parsedId != null) return parsedId;

      // محاولة أخيرة: قراءة خاصية من الـ controller (best-effort)
      try {
        final dynamic c = adController;
        if (c != null) {
          try {
            final maybe = (c).createdAdId;
            if (maybe != null) {
              if (maybe is int) return maybe;
              if (maybe is String) return int.tryParse(maybe);
            }
          } catch (_) {}
          try {
            final maybe2 = (c).adId;
            if (maybe2 != null) {
              if (maybe2 is int) return maybe2;
              if (maybe2 is String) return int.tryParse(maybe2);
            }
          } catch (_) {}
        }
      } catch (_) {}

      // إذا لم نتمكن من الحصول على المعرف — أظهر رسالة واضحة
      if (adController.hasError.value) {
        Get.snackbar('خطأ', 'فشل إنشاء الإعلان', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      } else {
        Get.snackbar('خطأ', 'لم يتم استلام معرف الإعلان من الخادم', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange, colorText: Colors.white);
      }
      return null;
    } catch (e) {
      print('⚠️ _submitAdAndGetId exception: $e');
      Get.snackbar('خطأ', 'حدث خطأ أثناء إنشاء الإعلان: ${e.toString()}', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      return null;
    } finally {
      if (Navigator.canPop(context)) Navigator.pop(context);
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            content: Center(
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppColors.card(themeController.isDarkMode.value), borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 12)]),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('جاري إنشاء/معالجة الإعلان...', style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary(themeController.isDarkMode.value))),
                  SizedBox(height: 8),
                  Text('يرجى الانتظار قليلاً', style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: 13, color: AppColors.textSecondary(themeController.isDarkMode.value))),
                ]),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    cardNumberCtrl.dispose();
    nameCtrl.dispose();
    expiryCtrl.dispose();
    cvvCtrl.dispose();
    super.dispose();
  }

  void _onCardNumberChanged(String val) {
    final digits = val.replaceAll(RegExp(r'\D'), '');
    final groups = <String>[];
    for (int i = 0; i < digits.length; i += 4) {
      groups.add(digits.substring(i, i + 4 > digits.length ? digits.length : i + 4));
    }
    final formatted = groups.join(' ');
    if (formatted != cardNumberCtrl.text) {
      cardNumberCtrl.value = TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
    }
  }

  String _getWalletStatusText(String status) {
    switch (status) {
      case 'active':
        return 'نشطة'.tr;
      case 'frozen':
        return 'مجمدة'.tr;
      case 'closed':
        return 'مغلقة'.tr;
      default:
        return status;
    }
  }

  Color _getWalletStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'frozen':
        return Colors.orange;
      case 'closed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildCreditCardSection(bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.credit_card, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'الدفع الآمن بالبطاقة'.tr,
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: AppTextStyles.medium,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'مدفوعات آمنة ومشفرة. سيتم خصم المبلغ من بطاقتك الائتمانية فوراً.'.tr,
                  style: TextStyle(
                    fontFamily: AppTextStyles.appFontFamily,
                    fontSize: AppTextStyles.small,
                    color: AppColors.textSecondary(isDark),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),

          TextFormField(
            controller: cardNumberCtrl,
            keyboardType: TextInputType.number,
            onChanged: _onCardNumberChanged,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(19)],
            decoration: InputDecoration(
              labelText: 'رقم البطاقة'.tr, 
              hintText: 'xxxx xxxx xxxx xxxx', 
              filled: true, 
              fillColor: AppColors.card(isDark), 
              prefixIcon: Icon(Icons.credit_card, color: AppColors.primary), 
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
            ),
            validator: (v) {
              final digits = (v ?? '').replaceAll(RegExp(r'\s+'), '');
              if (digits.isEmpty) return 'الرجاء إدخال رقم البطاقة'.tr;
              if (digits.length < 12) return 'رقم البطاقة غير صحيح'.tr;
              return null;
            },
          ),
          SizedBox(height: 12),
          
          TextFormField(
            controller: nameCtrl, 
            keyboardType: TextInputType.name, 
            decoration: InputDecoration(
              labelText: 'اسم صاحب البطاقة'.tr, 
              filled: true, 
              fillColor: AppColors.card(isDark), 
              prefixIcon: Icon(Icons.person_outline, color: AppColors.primary), 
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
            ), 
            validator: (v) => (v ?? '').trim().isEmpty ? 'الرجاء إدخال الاسم'.tr : null
          ),
          SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: expiryCtrl, 
                  keyboardType: TextInputType.number, 
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)], 
                  decoration: InputDecoration(
                    labelText: 'انتهاء الصلاحية (MMYY)'.tr, 
                    filled: true, 
                    fillColor: AppColors.card(isDark), 
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
                  ), 
                  validator: (v) => (v ?? '').length < 4 ? 'تاريخ غير صحيح'.tr : null
                ),
              ),
              SizedBox(width: 12),
              SizedBox(
                width: 120, 
                child: TextFormField(
                  controller: cvvCtrl, 
                  keyboardType: TextInputType.number, 
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)], 
                  decoration: InputDecoration(
                    labelText: 'CVV'.tr, 
                    filled: true, 
                    fillColor: AppColors.card(isDark), 
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
                  ), 
                  obscureText: true, 
                  validator: (v) => (v ?? '').length < 3 ? 'CVV غير صحيح'.tr : null
                ),
              ),
            ]
          ),
          SizedBox(height: 18),
        ],
      ),
    );
  }

  Widget _buildWalletSection(bool isDark) {
    return Obx(() {
      if (walletController.isLoading.value) return Center(child: CircularProgressIndicator());
      if (walletController.userWallets.isEmpty) return Text('لا توجد محافظ متاحة'.tr, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, color: AppColors.textSecondary(isDark)));

      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('اختر المحفظة:'.tr, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: AppTextStyles.appFontFamily)),
        SizedBox(height: 8),
        DropdownButtonFormField<UserWallet>(
          value: walletController.userWallets.contains(selectedWallet) ? selectedWallet : null,
          items: walletController.userWallets.map((wallet) {
            // نعرض الحالة في كل بند
            final statusColor = _getWalletStatusColor(wallet.status ?? '');
            final statusText = _getWalletStatusText(wallet.status ?? '');
            return DropdownMenuItem<UserWallet>(
              value: wallet,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${wallet.uuid}', style: TextStyle(fontFamily: AppTextStyles.appFontFamily)),
                  Row(
                    children: [
                      Text(statusText, style: TextStyle(color: statusColor, fontFamily: AppTextStyles.appFontFamily)),
                      SizedBox(width: 8),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (wallet) {
            // منع اختيار المحفظة إذا لم تكن نشطة
            if (wallet == null) {
              setState(() => selectedWallet = null);
              return;
            }
            final st = (wallet.status ?? '').toString().toLowerCase();
            if (st != 'active') {
              Get.snackbar('غير مسموح', 'هذه المحفظة ليست نشطة ولا يمكن استخدامها للدفع', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.orange, colorText: Colors.white);
              return;
            }
            setState(() => selectedWallet = wallet);
          },
          decoration: InputDecoration(border: OutlineInputBorder(), labelText: 'اختر المحفظة'.tr, prefixIcon: Icon(Icons.account_balance_wallet)),
        ),
        SizedBox(height: 12),
        if (selectedWallet != null)
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.card(isDark), borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('تفاصيل المحفظة:'.tr, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('${'معرف المحفظة:'.tr} ${selectedWallet!.uuid}', style: TextStyle(fontFamily: AppTextStyles.appFontFamily)),
              SizedBox(height: 6),
              Text('${'الرصيد:'.tr} ${selectedWallet!.balance} ${selectedWallet!.currency}', style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontWeight: FontWeight.bold)),
              SizedBox(height: 6),
              Row(
                children: [
                  Text('${'الحالة:'.tr} ', style: TextStyle(fontFamily: AppTextStyles.appFontFamily)),
                  Text('${_getWalletStatusText(selectedWallet!.status)}', style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontWeight: FontWeight.bold, color: _getWalletStatusColor(selectedWallet!.status ?? ''))),
                ],
              ),
            ]),
          ),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = themeController.isDarkMode.value;
    final selectedPackages = _packageListFromWidget();
    final totalPrice = _totalPriceOfSelected();
    final priceText = '${fmt.format(totalPrice)} ل.س';
    final namesText = _namesOfSelected();
    final typesText = _typesOfSelected();
    final durationText = _durationText();

    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      appBar: AppBar(
        backgroundColor: AppColors.appBar(isDark),
        elevation: 0,
        centerTitle: true,
        title: Text('إتمام الشراء'.tr, style: TextStyle(fontFamily: AppTextStyles.appFontFamily)),
        leading: IconButton(onPressed: () => Get.back(), icon: Icon(Icons.arrow_back)),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.card(isDark), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)]),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Center(child: Text('ملخص طلبك'.tr, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: 18, fontWeight: FontWeight.w800))),
                SizedBox(height: 12),
                Divider(),
                SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('الباقات المختارة:'.tr, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, color: AppColors.textSecondary(isDark))),
                  Expanded(child: Text(namesText, textAlign: TextAlign.end, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontWeight: FontWeight.w700))),
                ]),
                SizedBox(height: 8),
                // تعديل العرض ليأخذ أكثر من سطر بوضوح
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('النوع:'.tr, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, color: AppColors.textSecondary(isDark))),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        typesText,
                        textAlign: TextAlign.end,
                        style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontWeight: FontWeight.w700),
                        softWrap: true,
                        maxLines: 5, // يسمح حتى 5 أسطر بالظهور
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('المدة:'.tr, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, color: AppColors.textSecondary(isDark))),
                  Text(durationText, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontWeight: FontWeight.w700)),
                ]),
                SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('عنوان الإعلان:'.tr, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, color: AppColors.textSecondary(isDark))),
                  SizedBox(width: 200, child: Text(widget.adTitle, textAlign: TextAlign.end, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontWeight: FontWeight.w700))),
                ]),
                SizedBox(height: 12),
                Divider(),
                SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('الإجمالي:'.tr, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: 16, fontWeight: FontWeight.w800)),
                  Text(priceText, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.primary)),
                ]),
              ]),
            ),

            SizedBox(height: 22),
            Text('اختر طريقة الدفع'.tr, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontFamily: AppTextStyles.appFontFamily)),
            SizedBox(height: 12),

            // استخدام Obx لتحديث واجهة طرق الدفع بناءً على حالة البطاقة
            Obx(() {
              final isCardEnabled = _cardPaymentController.isEnabled.value;
              
              return Container(
                decoration: BoxDecoration(color: AppColors.card(isDark), borderRadius: BorderRadius.circular(12)),
                child: Column(children: [
                  // عرض خيار البطاقة فقط إذا كان مفعلاً
                  if (isCardEnabled)
                  ListTile(
                    leading: Icon(Icons.credit_card, color: AppColors.primary),
                    title: Text('بطاقة ائتمان'.tr, style: TextStyle(fontFamily: AppTextStyles.appFontFamily)),
                    trailing: Radio(value: 'card', groupValue: selectedPaymentMethod, onChanged: (value) => setState(() => selectedPaymentMethod = value.toString()), activeColor: AppColors.primary),
                    onTap: () => setState(() => selectedPaymentMethod = 'card'),
                  ),
                  
                  // خيار المحفظة (متاح دائماً)
                  ListTile(
                    leading: Icon(Icons.account_balance_wallet, color: AppColors.primary),
                    title: Text('المحفظة الإلكترونية'.tr, style: TextStyle(fontFamily: AppTextStyles.appFontFamily)),
                    trailing: Radio(value: 'wallet', groupValue: selectedPaymentMethod, onChanged: (value) => setState(() => selectedPaymentMethod = value.toString()), activeColor: AppColors.primary),
                    onTap: () => setState(() => selectedPaymentMethod = 'wallet'),
                  ),

                  // رسالة إذا كانت البطاقة معطلة
                  if (!isCardEnabled)
                  ListTile(
                    leading: Icon(Icons.credit_card_off, color: Colors.grey),
                    title: Text(
                      'الدفع بالبطاقة غير متاح حالياً'.tr, 
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily, 
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      )
                    ),
                    subtitle: Text(
                      'يرجى استخدام المحفظة الإلكترونية للدفع'.tr,
                      style: TextStyle(
                        fontFamily: AppTextStyles.appFontFamily,
                        fontSize: AppTextStyles.small,
                        color: Colors.grey,
                      )
                    ),
                  ),
                ]),
              );
            }),

            SizedBox(height: 18),

            // عرض القسم المناسب بناءً على طريقة الدفع المختارة
            if (selectedPaymentMethod == 'card') 
              _buildCreditCardSection(isDark),

            if (selectedPaymentMethod == 'wallet') 
              _buildWalletSection(isDark),

            // زر الدفع النهائي
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isProcessing ? null : _processPayment,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: isProcessing 
                    ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : Text('إتمام الدفع'.tr, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontFamily: AppTextStyles.appFontFamily)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}