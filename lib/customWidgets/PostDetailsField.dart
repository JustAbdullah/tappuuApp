import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/constant/appcolors.dart';

class PostDetailsField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController? controller;
  final Color fillColor;
  final Color hintColor;
  final Color? borderColor; // nullable
  final Color fontColor;
  final double borderRadius;
  final int maxLines;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final Widget? prefixIcon;
  final Widget? prefix; // أضف هذا الباراميتر
  final double? width;
  final Widget? suffixIcon;

  const PostDetailsField({
    super.key,
    required this.label,
    required this.hint,
    this.controller,
    this.fillColor = Colors.white,
    this.hintColor = Colors.grey,
    this.borderColor,
    this.fontColor = Colors.black,
    this.borderRadius = 5.0,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.prefixIcon,
    this.prefix,
    this.width,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final Color actualBorderColor = borderColor ?? AppColors.primary;

    return SizedBox(
      width: width,
      child: TextFormField(
        scrollPadding: EdgeInsets.only(bottom: 250.h),
        onChanged: (value) {
          SystemChrome.setEnabledSystemUIMode(
            SystemUiMode.manual,
            overlays: [],
          );
        },
        textDirection: TextDirection.rtl,
        keyboardType: keyboardType,
        controller: controller,
        validator: validator,
        maxLines: maxLines,
        decoration: InputDecoration(
          prefix: prefix,
          prefixIcon: prefixIcon != null
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: prefixIcon,
                )
              : null,
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: fillColor,
          hintText: hint.tr,
          hintStyle: TextStyle(color: hintColor, fontSize: screenWidth * 0.035),
          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          labelText: label,
          labelStyle: TextStyle(
            fontFamily: 'AppTextStyles.appFontFamily,',
            color: fontColor,
            fontSize: screenWidth * 0.043,
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: actualBorderColor, width: 2),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: actualBorderColor, width: 2),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          errorBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.red, width: 2),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        style: TextStyle(color: fontColor),
      ),
    );
  }        
}
