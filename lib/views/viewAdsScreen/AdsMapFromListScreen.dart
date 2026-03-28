// lib/views/ads_map_from_list_screen.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../controllers/areaController.dart';
import '../../core/constant/appcolors.dart';
import '../../core/constant/app_text_styles.dart';
import '../../core/data/model/AdResponse.dart';
import 'AdDetailsScreen.dart';
import 'package:tappuu_app/controllers/CurrencyController.dart';

// إذا FullScreenMap في مسار آخر غيّر المسار التالي:
import 'FullScreenMap.dart';

class AdsMapFromListScreen extends StatefulWidget {
  final List<Ad> ads;
  final double clusterRadiusKm;
  final double clusterZoomThreshold;
  final bool embedded;

  const AdsMapFromListScreen({
    Key? key,
    required this.ads,
    this.clusterRadiusKm = 200,
    this.clusterZoomThreshold = 8.5,
    this.embedded = false,
  }) : super(key: key);

  @override
  State<AdsMapFromListScreen> createState() => _AdsMapFromListScreenState();
}

class Cluster {
  LatLng center;
  final List<Ad> items;
  double maxDistanceKm;
  Cluster({required this.center, required this.items, this.maxDistanceKm = 0});
}

class _AdsMapFromListScreenState extends State<AdsMapFromListScreen> {
  final MapController _mapController = MapController();
  List<Cluster> _clusters = [];
  double _currentZoom = 6.0;
  Timer? _debounce;

  Ad? _activeAd;
  Position? _userPosition;
  bool _gettingLocation = false;

  // مركز دمشق الافتراضي وزوم خفيف لعرض المدينة كاملة (عدل الرقم لو تبي أوسع/أقرب)
  final LatLng _defaultDamascusCenter = const LatLng(33.5138, 36.2765);
  final double _defaultDamascusZoom = 8.5; // زووم أخف لعرض المدينة بالكامل

  @override
  void initState() {
    super.initState();
    _computeClusters();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        _fitBoundsToClusters();
        _focusBiggestCluster();
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  // ===== haversine =====
  static const _earthRadiusKm = 6371.0;
  double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
    final toRad = (double deg) => deg * pi / 180.0;
    final dLat = toRad(lat2 - lat1);
    final dLon = toRad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(toRad(lat1)) * cos(toRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return _earthRadiusKm * c;
  }

  // ===== clustering (greedy) =====
  void _computeClusters() {
    final radius = widget.clusterRadiusKm;
    final adsWithCoords =
        widget.ads.where((a) => a.latitude != null && a.longitude != null).toList();

    final List<bool> used = List<bool>.filled(adsWithCoords.length, false);
    final List<Cluster> clusters = [];

    for (int i = 0; i < adsWithCoords.length; i++) {
      if (used[i]) continue;
      final Ad seed = adsWithCoords[i];
      final List<Ad> members = [seed];
      used[i] = true;

      for (int j = i + 1; j < adsWithCoords.length; j++) {
        if (used[j]) continue;
        final Ad other = adsWithCoords[j];
        final d = _haversineKm(seed.latitude!, seed.longitude!, other.latitude!, other.longitude!);
        if (d <= radius) {
          members.add(other);
          used[j] = true;
        }
      }

      final latAvg = members.map((m) => m.latitude!).reduce((a, b) => a + b) / members.length;
      final lngAvg = members.map((m) => m.longitude!).reduce((a, b) => a + b) / members.length;

      double maxD = 0;
      for (final m in members) {
        final dd = _haversineKm(latAvg, lngAvg, m.latitude!, m.longitude!);
        if (dd > maxD) maxD = dd;
      }

      clusters.add(Cluster(center: LatLng(latAvg, lngAvg), items: members, maxDistanceKm: maxD));
    }

    setState(() {
      _clusters = clusters;
    });
  }

  // ===== zoom approximator =====
  double _zoomForRadius(double radiusKm) {
    if (radiusKm <= 1) return 15.5;
    if (radiusKm <= 5) return 13.5;
    if (radiusKm <= 20) return 11.5;
    if (radiusKm <= 50) return 9.5;
    if (radiusKm <= 200) return 6.5;
    return 4.5;
  }

  void _focusBiggestCluster() {
    if (_clusters.isEmpty) {
      // لو ما فيه بيانات، ضع الخريطة على دمشق بزوم افتراضي أخف
      _mapController.move(_defaultDamascusCenter, _defaultDamascusZoom);
      setState(() => _currentZoom = _defaultDamascusZoom);
      return;
    }
    final Cluster biggest = _clusters.reduce((a, b) => a.items.length >= b.items.length ? a : b);
    final zoomTarget = _zoomForRadius(biggest.maxDistanceKm);
    _mapController.move(biggest.center, zoomTarget);
    setState(() {
      _currentZoom = zoomTarget;
    });
  }

  void _fitBoundsToClusters() {
    if (_clusters.isEmpty) {
      _mapController.move(_defaultDamascusCenter, _defaultDamascusZoom);
      setState(() => _currentZoom = _defaultDamascusZoom);
      return;
    }

    final points = <LatLng>[];
    for (final c in _clusters) {
      points.add(c.center);
      for (final a in c.items) {
        if (a.latitude != null && a.longitude != null) points.add(LatLng(a.latitude!, a.longitude!));
      }
    }
    if (points.isEmpty) return;

    final bounds = LatLngBounds.fromPoints(points);
    final center = bounds.center;

    double maxD = 0;
    for (final p in points) {
      final d = _haversineKm(center.latitude, center.longitude, p.latitude, p.longitude);
      if (d > maxD) maxD = d;
    }

    final z = _zoomForRadius(maxD);
    _mapController.move(center, z);
    setState(() {
      _currentZoom = z;
    });
  }

  // ===== cluster marker widget =====
  Widget _buildClusterMarker(Cluster c) {
    final count = c.items.length;
    final premiumCount = c.items.where((a) => a.is_premium == true).length;
    final hasPremium = premiumCount > 0;
    final size = (40.0 + min(count / 5, 5) * 8).clamp(40.0, 80.0);

    return GestureDetector(
      onTap: () {
        final zoomTo = max(widget.clusterZoomThreshold + 1.5, _zoomForRadius(c.maxDistanceKm));
        _mapController.move(c.center, zoomTo);
        setState(() {
          _currentZoom = zoomTo;
          _activeAd = null;
        });
      },
      child: SizedBox(
        width: size,
        height: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: hasPremium ? [Colors.amber.shade700, Colors.amber.shade900] : [AppColors.primary, AppColors.primary],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 6, offset: const Offset(0, 3))],
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (hasPremium) const Icon(Icons.star, size: 14, color: Colors.white),
                Text(count.toString(), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: size > 56 ? 16 : 14)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===== ad marker widget (use child) =====
  Widget _buildAdMarker(Ad ad) {
    final isPremium = ad.is_premium == true;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeAd = ad;
          _mapController.move(LatLng(ad.latitude ?? 0, ad.longitude ?? 0), max(_currentZoom, 12));
        });
      },
      child: SizedBox(
        width: 54,
        height: 70,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isPremium)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle),
                child: const Icon(Icons.star, size: 12, color: Colors.white),
              ),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.22), blurRadius: 6, offset: const Offset(0, 3))],
              ),
              child: ClipOval(
                child: ad.images.isNotEmpty
                    ? Image.network(ad.images[0], fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: AppColors.grey.withOpacity(0.2)))
                    : Container(color: AppColors.primary.withOpacity(0.9)),
              ),
            ),
            Container(width: 10, height: 6, decoration: BoxDecoration(color: isPremium ? Colors.amber : AppColors.primary, borderRadius: BorderRadius.circular(2))),
          ],
        ),
      ),
    );
  }

  // ===== small bottom card for active ad =====
  Widget _buildActiveAdCard() {
    if (_activeAd == null) return const SizedBox.shrink();
    final ad = _activeAd!;
    final currencyController = Get.put(CurrencyController());
    final areaController = Get.put(AreaController());
    final areaName = areaController.getAreaNameById(ad.areaId);

    return SafeArea(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 12.w),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 12, offset: const Offset(0, 6))],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: Container(
                width: 88.w,
                height: 68.h,
                color: AppColors.grey.withOpacity(0.08),
                child: ad.images.isNotEmpty
                    ? Image.network(ad.images[0], fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.broken_image, color: AppColors.grey))
                    : Icon(Icons.image, color: AppColors.grey),
              ),
            ),

            SizedBox(width: 12.w),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ad.title,
                    style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.small,
 fontWeight: FontWeight.w700, color: AppColors.textPrimary(Theme.of(context).brightness == Brightness.dark)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14.sp, color: AppColors.grey),
                      SizedBox(width: 6.w),
                      Flexible(
                        child: Text(
                          '${ad.city?.name ?? ''}${areaName != null && areaName!.isNotEmpty ? ', ${areaName}' : ''}',
                          style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.small,
 color: AppColors.textSecondary(Theme.of(context).brightness == Brightness.dark)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(width: 10.w),

            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (ad.price != null)
                  Text(
                    currencyController.formatPrice(ad.price!),
                    style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.small,
 fontWeight: FontWeight.bold, color: AppColors.buttonAndLinksColor),
                  ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => setState(() => _activeAd = null),
                      child: Text('إلغاء'.tr, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.small,
)),
                    ),
                    SizedBox(width: 6.w),
                    ElevatedButton(
                      onPressed: () {
                        Get.to(() => AdDetailsScreen(ad: ad));
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h)),
                      child: Text('عرض'.tr, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===== markers & circles (use child param) =====
  List<Marker> _buildMarkers(double zoom) {
    final markers = <Marker>[];
    final showClusters = zoom < widget.clusterZoomThreshold;

    if (showClusters) {
      for (final c in _clusters) {
        markers.add(Marker(point: c.center, width: 70, height: 70, child: _buildClusterMarker(c)));
      }
    } else {
      for (final c in _clusters) {
        for (final ad in c.items) {
          if (ad.latitude == null || ad.longitude == null) continue;
          markers.add(Marker(point: LatLng(ad.latitude!, ad.longitude!), width: 60, height: 70, child: _buildAdMarker(ad)));
        }
      }
    }

    if (_userPosition != null) {
      markers.add(Marker(
        point: LatLng(_userPosition!.latitude, _userPosition!.longitude),
        width: 44,
        height: 44,
        child: Container(
          decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary, border: Border.all(color: Colors.white, width: 2), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 6)]),
          child: Icon(Icons.my_location, color: Colors.white, size: 20.w),
        ),
      ));
    }

    return markers;
  }

  List<CircleMarker> _buildClusterCircles(double zoom) {
    final circles = <CircleMarker>[];
    if (zoom < widget.clusterZoomThreshold) {
      for (final c in _clusters) {
        final radiusMeters = (c.maxDistanceKm * 1000.0) * 1.15;
        circles.add(CircleMarker(point: c.center, color: AppColors.primary.withOpacity(0.06), borderStrokeWidth: 1.0, borderColor: AppColors.primary.withOpacity(0.18), useRadiusInMeter: true, radius: max(radiusMeters, 3000)));
      }
    }
    return circles;
  }

  Ad? _findNearestAd(LatLng pos, {double maxKm = 9999.0}) {
    Ad? nearest;
    double minD = double.infinity;

    for (final ad in widget.ads) {
      if (ad.latitude == null || ad.longitude == null) continue;
      final d = _haversineKm(pos.latitude, pos.longitude, ad.latitude!, ad.longitude!);
      if (d < minD) {
        minD = d;
        nearest = ad;
      }
    }

    if (nearest == null) return null;
    if (minD <= maxKm) return nearest;
    return null;
  }

  Future<Position?> _getDevicePosition() async {
    try {
      setState(() => _gettingLocation = true);
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Get.snackbar('خطأ'.tr, 'خدمة الموقع معطلة'.tr);
        return null;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Get.snackbar('مطلوب صلاحية'.tr, 'الرجاء السماح بالوصول للموقع'.tr);
          return null;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        Get.snackbar('مطلوب صلاحية'.tr, 'الرجاء تفعيل صلاحيات الموقع من إعدادات الجهاز'.tr);
        return null;
      }

      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
      return pos;
    } catch (e) {
      Get.snackbar('خطأ'.tr, 'تعذر الحصول على الموقع: $e');
      return null;
    } finally {
      if (mounted) setState(() => _gettingLocation = false);
    }
  }

  Future<void> _showUserLocation() async {
    final pos = await _getDevicePosition();
    if (pos == null) return;
    setState(() {
      _userPosition = pos;
      _activeAd = null;
    });
    final latlng = LatLng(pos.latitude, pos.longitude);
    final double userZoom = 13.0; // زووم مناسب حول المستخدم
    _mapController.move(latlng, userZoom);
    setState(() => _currentZoom = userZoom);
    Get.snackbar('موقعي'.tr, 'تم تحديد موقعك على الخريطة'.tr);
  }

  void _resetToDefault() {
    _mapController.move(_defaultDamascusCenter, _defaultDamascusZoom);
    setState(() {
      _activeAd = null;
      _currentZoom = _defaultDamascusZoom;
    });
    Get.snackbar('تم'.tr, 'تمت إعادة الخريطة للوضع الافتراضي'.tr);
  }

  void _openScaleSelector() {
    // انتقل إلى واجهة FullScreenMap — عدّل المعطيات حسب حاجتك
    Get.to(() => FullScreenMap(
          mainCat: '',
          idMaincate: null,
          subCat: '',
          secondaryCat: '',
          currentTimeframe: null,
          onlyFeatured: false,
        ));
  }

  Future<void> _searchNearestToUser() async {
    Position? pos = await _getDevicePosition();
    LatLng center;

    if (pos != null) {
      center = LatLng(pos.latitude, pos.longitude);
    } else {
      // fallback to default center
      center = _defaultDamascusCenter;
    }

    final nearest = _findNearestAd(center, maxKm: 9999.0);
    if (nearest == null) {
      Get.snackbar('نتيجة'.tr, 'لم يتم العثور على إعلان قريب'.tr);
      return;
    }

    final lat = nearest.latitude ?? 0.0;
    final lng = nearest.longitude ?? 0.0;
    _mapController.move(LatLng(lat, lng), max(_currentZoom, 13));
    setState(() {
      _activeAd = nearest;
    });
  }

  void _onMapTapClear(TapPosition tapPosition, LatLng latlng) {
    setState(() {
      _activeAd = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final initialCenter = _clusters.isNotEmpty ? _clusters[0].center : _defaultDamascusCenter;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final mapWidget = FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        // استخدم initialCenter/initialZoom للتوافق مع إصدارات شائعة من flutter_map
        initialCenter: initialCenter,
        initialZoom: _clusters.isNotEmpty ? _currentZoom : _defaultDamascusZoom,
        minZoom: 12,
        maxZoom: 18,
        onPositionChanged: (pos, hasGesture) {
          _debounce?.cancel();
          _debounce = Timer(const Duration(milliseconds: 220), () {
            try {
              final z = (pos as dynamic).zoom ?? _currentZoom;
              if (z != _currentZoom) setState(() => _currentZoom = z);
            } catch (_) {}
          });
        },
        onTap: (tapPosition, latlng) {
          _onMapTapClear(tapPosition, latlng);
        },
      ),
      children: [
        // ===== Tile layer: Carto Voyager (أجمل من OSM الافتراضية) =====
       TileLayer(
  
  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  userAgentPackageName: 'com.example.stayinme',
)
,
        // Layer الدوائر (clusters)
        CircleLayer(circles: _buildClusterCircles(_currentZoom)),

        // Layer العلامات
        MarkerLayer(markers: _buildMarkers(_currentZoom)),
      ],
    );

    if (widget.embedded) {
      return SizedBox.expand(child: mapWidget);
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Get.back()),
        title: Text('الخريطة'.tr, style: TextStyle(fontFamily: AppTextStyles.appFontFamily, fontSize: AppTextStyles.large,
 fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'مركز/عرض جميع النقاط',
            icon: const Icon(Icons.center_focus_strong),
            onPressed: _fitBoundsToClusters,
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // يملأ الشاشة بالكامل
            Positioned.fill(child: mapWidget),

            // بطاقة الإعلان الفعّالة
            Positioned(
              left: 12,
              right: 12,
              bottom: 16,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _activeAd != null ? _buildActiveAdCard() : const SizedBox.shrink(),
              ),
            ),

            // Buttons column (يمين)
            Positioned(
              right: 12,
              top: 120,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton(
                    heroTag: 'nearest',
                    mini: false,
                    backgroundColor: AppColors.primary,
                    onPressed: _showUserLocation,
                    child: Icon(Icons.my_location, color: Colors.white),
                    tooltip: 'موقعي'.tr,
                  ),
                  SizedBox(height: 10.h),
                  FloatingActionButton(
                    heroTag: 'reset_default',
                    mini: false,
                    backgroundColor: AppColors.primary,
                    onPressed: _resetToDefault,
                    child: Icon(Icons.public, color: Colors.white),
                    tooltip: 'إعادة الضبط'.tr,
                  ),
                  SizedBox(height: 10.h),
                  FloatingActionButton(
                    heroTag: 'scale_selector',
                    mini: false,
                    backgroundColor: AppColors.primary,
                    onPressed: _openScaleSelector,
                    child: Icon(Icons.tune, color: Colors.white),
                    tooltip: 'تحديد مقياس البحث'.tr,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
