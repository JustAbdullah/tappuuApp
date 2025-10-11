
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../../controllers/AdsManageSearchController.dart';
import '../../controllers/ThemeController.dart';
import '../../core/constant/app_text_styles.dart';
import '../../core/constant/appcolors.dart';
import '../../core/localization/changelanguage.dart';

class FullScreenMap extends StatefulWidget {
  final String mainCat;
  final int ?idMaincate ;
  
  final String subCat;
  final String secondaryCat;  final String ?currentTimeframe;
  final  bool onlyFeatured ;

  const FullScreenMap({
    super.key,
    required this.mainCat,
    required this.idMaincate,
    required this.subCat,
    required this.secondaryCat,
 this .currentTimeframe,
    this.onlyFeatured= false,
  });

  @override
  _FullScreenMapState createState() => _FullScreenMapState();
}
class _FullScreenMapState extends State<FullScreenMap> {
  final AdsController _adsController = Get.find<AdsController>();
  final themeController = Get.find<ThemeController>();
  bool get isDarkMode => themeController.isDarkMode.value;
  
  final LatLng defaultLocation = LatLng(33.5138, 36.2765);
  
  final List<Map<String, dynamic>> radiusOptions = [
    {'value': 1.0, 'label': '1 كم'.tr},
    {'value': 5.0, 'label': '5 كم'.tr},
    {'value': 10.0, 'label': '10 كم'.tr},
    {'value': 20.0, 'label': '20 كم'.tr},
    {'value': 50.0, 'label': '50 كم'.tr},
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    await _adsController.fetchCurrentLocation();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final hasLocation = _adsController.latitude.value != null && 
                          _adsController.longitude.value != null;
      
      return Scaffold(
        backgroundColor: AppColors.background(isDarkMode),
        appBar: AppBar(
          title: Text(
            'الخريطة'.tr,
            style: TextStyle(
              color: AppColors.onPrimary,
              fontFamily: AppTextStyles.appFontFamily,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: AppColors.appBar(isDarkMode),
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.onPrimary),
            onPressed: () => Get.back(),
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // مسار البحث
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Row(
                children: [
                  Text(
                    widget.mainCat,
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: AppTextStyles.medium,

                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary(isDarkMode),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Icon(Icons.chevron_left, size: 16.sp, color: AppColors.grey),
                  SizedBox(width: 8.w),
                  Text(
                    widget.subCat,
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: AppTextStyles.medium,

                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary(isDarkMode),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Icon(Icons.chevron_left, size: 16.sp, color: AppColors.grey),
                  SizedBox(width: 8.w),
                  Text(
                    widget.secondaryCat,
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: AppTextStyles.medium,

                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),

            // إحداثيات المستخدم وأزرار التحكم
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_pin, size: 18.sp, color: AppColors.primary),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          hasLocation
                              ? '${'خط العرض:'.tr} ${_adsController.latitude.value!.toStringAsFixed(4)}\nخط الطول: ${_adsController.longitude.value!.toStringAsFixed(4)}'
                              : 'الموقع الجغرافي: غير مدخل'.tr,
                          style: TextStyle(
                            fontFamily: AppTextStyles.appFontFamily,
                            fontSize: AppTextStyles.medium,

                            color: AppColors.textSecondary(isDarkMode),
                          ),
                        ),
                      ),
                      SizedBox(width: 16.w),
                      // زر أخذ الموقع
                      ElevatedButton.icon(
                        icon: Icon(Icons.location_searching, size: 18.sp),
                        label: Text('أخذ الموقع'.tr),
                        onPressed: _getCurrentLocation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                ],
              ),
            ),

            // خيارات الحصر
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'حدد نطاق البحث:'.tr,
                    style: TextStyle(
                      fontFamily: AppTextStyles.appFontFamily,
                      fontSize: AppTextStyles.large,

                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary(isDarkMode),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: radiusOptions.map((option) {
                      final isSelected = _adsController.selectedRadius.value == option['value'];
                      return ChoiceChip(
                        label: Text(
                          option['label'],
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textPrimary(isDarkMode),
                            fontFamily: AppTextStyles.appFontFamily,
                            fontSize: AppTextStyles.medium,

                          ),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            _adsController.selectedRadius.value = option['value'];
                            setState(() {}); // تحديث الخريطة فوراً
                          }
                        },
                        backgroundColor: AppColors.card(isDarkMode),
                        selectedColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            // زر تطبيق البحث
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.search, size: 20.sp),
                  label: Text('تطبيق البحث'.tr),
                  onPressed: hasLocation
                      ? () {
                          _performSearch( widget.idMaincate, widget.currentTimeframe,widget.onlyFeatured);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasLocation ? AppColors.primary : Colors.grey,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(0.r),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 5.h),

            // الخريطة
            Expanded(
              child: Stack(
                children: [
                Obx(() {  return _buildInteractiveMap(
                    hasLocation ? _adsController.latitude.value! : defaultLocation.latitude,
                    hasLocation ? _adsController.longitude.value! : defaultLocation.longitude,
                    hasLocation,
               ); }),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  // بناء الخريطة التفاعلية
  Widget _buildInteractiveMap(double latitude, double longitude, bool hasLocation, ) {

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.r),
          topRight: Radius.circular(24.r),
        ),
      ),
      child: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(latitude, longitude),
          initialZoom: hasLocation ? 14.0 : 10.0,
          interactionOptions: const InteractionOptions(
            flags: ~InteractiveFlag.rotate,
          ),
        ),
        children: [
          // طبقة الخريطة
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.stayinme.app',
            tileDisplay: TileDisplay.fadeIn(),
          ),
          
          if (hasLocation) ...[
            // طبقة العلامات
            MarkerLayer(
              markers: [
                Marker(
                  point: LatLng(latitude, longitude),
                  width: 50.w,
                  height: 50.h,
                  child: Icon(
                    Icons.location_pin,
                    color: AppColors.primary,
                    size: 40.w,
                  ),
                ),
              ],
            ),
            
            // طبقة دائرة البحث
            CircleLayer(
              circles: [
                CircleMarker(
                  point: LatLng(latitude, longitude),
                  color: AppColors.primary.withOpacity(0.2),
                  borderColor: AppColors.primary,
                  borderStrokeWidth: 2,
                  radius: _adsController.selectedRadius.value * 1000, // تحويل الكيلومترات إلى أمتار
                ),
              ],
            ),
          ]
        ],
      ),
    );
  }

  // تنفيذ البحث
  void _performSearch(int ?idcate,  final String ?currentTimeframe,
  final  bool onlyFeatured ) {

            final AdsController adsController = Get.find<AdsController>();

    if (_adsController.latitude.value == null || 
        _adsController.longitude.value == null) {
      Get.snackbar("خطأ".tr, "يرجى تحديد الموقع الجغرافي أولاً".tr);
      return;
    }

    // تنفيذ البحث باستخدام AdsController
    _adsController.fetchAds(
   categoryId: idcate,
    subCategoryLevelOneId: adsController.currentSubCategoryLevelOneId.value,
    subCategoryLevelTwoId: adsController.currentSubCategoryLevelTwoId.value,
    search: adsController.searchController.text.toString(),
    cityId: adsController.selectedCity.value?.id,
    areaId: adsController.selectedArea.value?.id,
    attributes: adsController.currentAttributes.isNotEmpty 
        ? adsController.currentAttributes 
        : null,
    sortBy: adsController.currentSortBy.value,
    order: adsController.currentOrder.value,
              timeframe: currentTimeframe,
              onlyFeatured: onlyFeatured,
      // إضافة معايير الموقع الجغرافي
      latitude: _adsController.latitude.value,
      longitude: _adsController.longitude.value,
      distanceKm: _adsController.selectedRadius.value, lang:Get.find<ChangeLanguageController>().currentLocale.value.languageCode,
    );
    
    Get.back();
        Get.back(); // العودة لشاشة الإعلانات

     // العودة لشاشة الإعلانات
    Get.snackbar("نجاح".tr, "${'تم البحث في نطاق'.tr} ${_adsController.selectedRadius.value} ${'كم'.tr}");
  }}