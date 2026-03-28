import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// ignore: must_be_immutable
class TextCustom extends StatelessWidget {
  final String theText;
  final double fontSizeWidth;
  final String fontFamily;
  final Color fontColor;
  int maxLines;
  FontWeight fontWeight;

  TextCustom(
      {super.key,
      required this.theText,
      required this.fontSizeWidth,
      required this.fontFamily,
      required this.fontColor,
      this.fontWeight = FontWeight.normal,
      this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return Text(
      maxLines: maxLines,
      theText,
      style: TextStyle(
          height: 0.002.h,
          fontFamily: fontFamily,
          color: fontColor,
          fontSize: fontSizeWidth.sp,
          fontWeight: fontWeight),
      textAlign: TextAlign.center,
    );
  }
}
