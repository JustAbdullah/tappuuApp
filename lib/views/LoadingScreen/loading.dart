// lib/views/LoadingScreen/loading.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../controllers/LoadingController.dart';
import '../../controllers/WaitingScreenController.dart';
import '../../core/constant/app_text_styles.dart';
import '../../core/constant/appcolors.dart';
import '../../core/constant/images_path.dart';
import '../../core/services/appservices.dart';

class Loading extends StatefulWidget {
  const Loading({super.key});

  @override
  State<Loading> createState() => _LoadingState();
}

class _LoadingState extends State<Loading> {
  // LoadingController الموجود عندك
  final LoadingController loading = Get.put(LoadingController());

  // نتأكد وجود WaitingScreenController (إذا موجود يسترجع، وإلا ينشئ)
  final WaitingScreenController waiting =
      Get.put(WaitingScreenController(), permanent: true);

  @override
  void initState() {
    super.initState();
    loading.loadUserData();
    // لا حاجة لاستدعاء waiting.loadWaitingScreen() هنا لأن onInit في الكنترولر يتكفل
  }

  @override
  Widget build(BuildContext context) {
    final appServices = Get.find<AppServices>();

    return Obx(() {
      // اختر لون الخلفية: إن وُجد في الكنترولر استخدمه، وإلا الافتراضي
      final bgColor = waiting.backgroundColor.value ?? AppColors.wait;

      // اختر صورة شاشة الانتظار من الكنترولر، وإلا استخدم شعار التطبيق المخزن
      final waitingImage = waiting.imageUrl.value;
      final logoUrl = appServices.getStoredAppLogoUrl();

      return Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // مسافة مرنة لأعلى إن احتجنا
                SizedBox(height: 8.h),

                // صورة شاشة الانتظار (لو موجودة) — عرض واضح، مع فالك باك للشعار
              if (waitingImage.isNotEmpty)
  Expanded(
    child: Image.network(
      waitingImage,
      width: double.infinity,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) {
        if (logoUrl != null && logoUrl.isNotEmpty) {
          return Image.network(
            logoUrl,
            width: double.infinity,
            height: 150.h,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                Image.asset(ImagesPath.wait, width: double.infinity, height: 150.h),
          );
        } else {
          return Image.asset(ImagesPath.wait, width: double.infinity, height: 150.h);
        }
      },
    ),
  )
else
  Column(
    children: [
      if (logoUrl != null && logoUrl.isNotEmpty)
        Image.network(
          logoUrl,
          width: double.infinity,
          height: 150.h,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) =>
              Image.asset(ImagesPath.wait, width: double.infinity, height: 150.h),
        )
      else
        Image.asset(
          ImagesPath.wait,
          width: double.infinity,
          height: 150.h,
          fit: BoxFit.contain,
        ),
    ],
  ),
                  


             

                SizedBox(height: 20.h),

                // للمساعدة في التصحيح: عرض hex اللون إن أردت (خفي عادة)
                // Text(waiting.colorHex.value, style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ),
      );
    });
  }
}
