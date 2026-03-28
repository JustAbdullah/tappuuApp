import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../core/constant/appcolors.dart';

// ignore: must_be_immutable
class ContainerCustomApi extends StatelessWidget {
  final double heigthContainer;

  Color colorContainer;
  double theBorderRadius;
  final Widget? child;
  BoxShape boxShape;

  ContainerCustomApi(
      {super.key,
      required this.heigthContainer,
      this.colorContainer = AppColors.backgroundLight,
      this.theBorderRadius = 0,
      required this.child,
      this.boxShape = BoxShape.rectangle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 5.w),
      child: Container(
        alignment: Alignment.center,
        height: heigthContainer.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(theBorderRadius),
          color: colorContainer,
          shape: boxShape,
        ),
        child: child,
      ),
    );
  }
}
