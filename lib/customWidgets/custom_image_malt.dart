import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:tappuu_app/controllers/ThemeController.dart';
import 'package:tappuu_app/core/constant/appcolors.dart';
import 'package:tappuu_app/core/constant/app_text_styles.dart';

enum ImageQuality {
  low,    // للتحميل السريع
  medium, // توازن بين الجودة والأداء
  high,   // أعلى جودة
}

class ImagesViewer extends StatefulWidget {
  final List<String> images;
  final double? width;
  final double? height;
  final bool isCompactMode;
  final bool enableZoom;
  final bool showPageIndicator;
  final ImageQuality imageQuality;
  final BoxFit fit;

  const ImagesViewer({
    required this.images,
    this.width,
    this.height,
    this.isCompactMode = false,
    this.enableZoom = true,
    this.showPageIndicator = true,
    this.imageQuality = ImageQuality.medium,
    this.fit = BoxFit.cover,
    Key? key,
  }) : super(key: key);

  @override
  _ImagesViewerState createState() => _ImagesViewerState();
}

class _ImagesViewerState extends State<ImagesViewer> {
  late final PageController _pageController;
  int _currentPageIndex = 0;
  final ValueNotifier<double> _scaleNotifier = ValueNotifier(1.0);

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(_updateCurrentPage);
    
    // Precache الصور مع جودة عالية
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (int i = 0; i < widget.images.length && i < 3; i++) {
        _precacheImage(widget.images[i]);
      }
    });
  }

  void _precacheImage(String url) {
    final maxSize = _getMaxSizeForQuality();
    precacheImage(
      CachedNetworkImageProvider(
        url,
        maxWidth: maxSize?.width.toInt(),
        maxHeight: maxSize?.height.toInt(),
        cacheKey: '${url}_${maxSize?.width}x${maxSize?.height}',
      ),
      Get.context!,
    );
  }

  Size? _getMaxSizeForQuality() {
    switch (widget.imageQuality) {
      case ImageQuality.low:
        return Size(400, 400);
      case ImageQuality.medium:
        return Size(800, 800);
      case ImageQuality.high:
        return Size(1200, 1200);
      default:
        return Size(800, 800);
    }
  }

  void _updateCurrentPage() {
    final newPage = _pageController.page?.round() ?? 0;
    if (newPage != _currentPageIndex) {
      setState(() {
        _currentPageIndex = newPage;
      });
      
      // معاينة مسبقة للصور المجاورة
      for (var idx in [newPage - 1, newPage + 1]) {
        if (idx >= 0 && idx < widget.images.length) {
          _precacheImage(widget.images[idx]);
        }
      }
    }
  }

  void _zoomIn() {
    if (!widget.enableZoom) return;
    _scaleNotifier.value = (_scaleNotifier.value * 1.2).clamp(1.0, 4.0);
  }

  void _zoomOut() {
    if (!widget.enableZoom) return;
    _scaleNotifier.value = (_scaleNotifier.value / 1.2).clamp(1.0, 4.0);
  }

  void _resetZoom() {
    _scaleNotifier.value = 1.0;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scaleNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return _buildPlaceholder();
    }

    final themeController = Get.find<ThemeController>();
    final size = MediaQuery.of(context).size;
    final effectiveWidth = widget.width ?? size.width;
    final effectiveHeight = widget.height ?? size.height * 0.4;

    return GestureDetector(
      onDoubleTap: _resetZoom,
      child: ValueListenableBuilder<double>(
        valueListenable: _scaleNotifier,
        builder: (context, scale, child) {
          return Stack(
            children: [
              // عارض الصور الأساسي
              PageView.builder(
                controller: _pageController,
                itemCount: widget.images.length,
                physics: widget.enableZoom && scale > 1.0
                    ? NeverScrollableScrollPhysics()
                    : const PageScrollPhysics(),
                itemBuilder: (context, index) {
                  return Transform.scale(
                    scale: scale,
                    child: _buildImageItem(widget.images[index]),
                  );
                },
              ),

              // عناصر التحكم
              ..._buildControlOverlays(themeController, effectiveWidth, effectiveHeight),
            ],
          );
        },
      ),
    );
  }

  Widget _buildImageItem(String imageUrl) {
    final maxSize = _getMaxSizeForQuality();

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      memCacheWidth: maxSize?.width.toInt(),
      memCacheHeight: maxSize?.height.toInt(),
      fadeInDuration: const Duration(milliseconds: 300),
      placeholder: (context, url) => _buildShimmerPlaceholder(),
      errorWidget: (context, url, error) => _buildErrorPlaceholder(),
      imageBuilder: (context, imageProvider) {
        return Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: imageProvider,
              fit: widget.fit,
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildControlOverlays(ThemeController themeController, double width, double height) {
    final controls = <Widget>[];

    // مؤشر الصفحات
    if (widget.showPageIndicator && widget.images.length > 1) {
      controls.add(Positioned(
        bottom: 12.h,
        left: 0,
        right: 0,
        child: Center(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: SmoothPageIndicator(
              controller: _pageController,
              count: widget.images.length,
              effect: ScrollingDotsEffect(
                activeDotColor: AppColors.primary,
                dotColor: Colors.white.withOpacity(0.6),
                dotHeight: 6.h,
                dotWidth: 6.w,
                spacing: 4.w,
              ),
              onDotClicked: (idx) {
                _resetZoom();
                _pageController.animateToPage(
                  idx,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                );
              },
            ),
          ),
        ),
      ));
    }

    // أزرار التكبير/التصغير
    if (widget.enableZoom && !widget.isCompactMode) {
      controls.addAll([
        Positioned(
          right: 16.w,
          bottom: 16.h,
          child: Column(
            children: [
              _buildControlButton(
                icon: Icons.add,
                onPressed: _zoomIn,
                themeController: themeController,
              ),
              SizedBox(height: 8.h),
              _buildControlButton(
                icon: Icons.remove,
                onPressed: _zoomOut,
                themeController: themeController,
              ),
              SizedBox(height: 8.h),
              _buildControlButton(
                icon: Icons.fullscreen,
                onPressed: () => _openFullScreen(),
                themeController: themeController,
              ),
            ],
          ),
        ),
      ]);
    }

    // عداد الصور
    if (widget.images.length > 1) {
      controls.add(Positioned(
        top: 16.h,
        right: 16.w,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Text(
            '${_currentPageIndex + 1}/${widget.images.length}',
            style: TextStyle(
              fontFamily: AppTextStyles.appFontFamily,
              fontSize: AppTextStyles.small,

              color: Colors.white,
            ),
          ),
        ),
      ));
    }

    return controls;
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required ThemeController themeController,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(themeController.isDarkMode.value).withOpacity(0.8),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, size: 18.sp),
        color: AppColors.icon(themeController.isDarkMode.value),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildShimmerPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Icon(Icons.image, size: 40.sp, color: Colors.grey[400]),
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image, size: 40.sp, color: Colors.grey[400]),
            SizedBox(height: 8.h),
            Text(
              'فشل تحميل الصورة',
              style: TextStyle(
                fontFamily: AppTextStyles.appFontFamily,
                fontSize: AppTextStyles.small,

                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported, size: 40.sp, color: Colors.grey[400]),
            SizedBox(height: 8.h),
            Text(
              'لا توجد صور متاحة',
              style: TextStyle(
                fontFamily: AppTextStyles.appFontFamily,
                fontSize: AppTextStyles.medium,

                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openFullScreen() {
    // يمكنك فتح شاشة كاملة هنا
  }
}