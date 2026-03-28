import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// ignore: must_be_immutable
class PaddingCustom extends StatelessWidget {
  double theTop;
  double theBottom;
  double theLeft;
  double theRight;
  final Widget child;

  PaddingCustom({
    super.key,
    required this.child,
    this.theTop = 0,
    this.theBottom = 0,
    this.theLeft = 0,
    this.theRight = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          top: theTop.h,
          bottom: theBottom.h,
          left: theLeft.w,
          right: theRight.w),
      child: child,
    );
  }
}
