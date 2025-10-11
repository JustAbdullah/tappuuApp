import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../core/constant/appcolors.dart';

// ignore: must_be_immutable
class ContainerCustom extends StatelessWidget {
  final double heigthContainer;
  final double widthContainer;
  Color colorContainer;
  double theBorderRadius;
  final Widget child;
  BoxShape boxShape;

  ContainerCustom(
      {super.key,
      required this.heigthContainer,
      required this.widthContainer,
      this.colorContainer = AppColors.backgroundLight,
      this.theBorderRadius = 0,
      required this.child,
      this.boxShape = BoxShape.rectangle});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      height: heigthContainer.h,
      width: widthContainer.w,
      decoration: BoxDecoration(
          color: colorContainer,
          shape: boxShape,
          borderRadius: BorderRadius.circular(theBorderRadius)),
      child: child,
    );
  }
}
