import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TextFormFieldCustom extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final Widget? suffixIcon;
  final TextEditingController? controller;
  final Color fillColor;
  final Color hintColor;
  final Color iconColor;
  final Color borderColor;
  final Color fontColor;
  final double borderRadius;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final int? maxLines;
  final int? minLines;
  final bool enableInteractiveSelection;
  final List<BoxShadow>? boxShadow;
  final Gradient? gradient;
  final EdgeInsetsGeometry? contentPadding;

  const TextFormFieldCustom({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    this.suffixIcon,
    this.controller,
    this.fillColor = Colors.white,
    this.hintColor = Colors.grey,
    this.iconColor = Colors.blue,
    this.borderColor = Colors.blue,
    this.fontColor = Colors.black,
    this.borderRadius = 16.0,
    this.obscureText = false,
    this.keyboardType,
    this.autofillHints,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
    this.minLines,
    this.enableInteractiveSelection = true,
    this.boxShadow,
    this.gradient,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      decoration: BoxDecoration(
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: TextFormField(
        maxLines: maxLines,
        minLines: minLines,
        textDirection: TextDirection.rtl,
        autofillHints: autofillHints,
        keyboardType: keyboardType,
        obscureText: obscureText,
        controller: controller,
        enableInteractiveSelection: enableInteractiveSelection,
        onChanged: onChanged,
        validator: validator,
        style: TextStyle(
          color: fontColor,
          fontSize: screenWidth * 0.04,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: fillColor,
          hintText: hint.tr,
          hintStyle: TextStyle(
            color: hintColor,
            fontSize: screenWidth * 0.035,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.only(left: 12, right: 12),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(borderRadius * 0.5),
            ),
            child: Icon(icon, color: iconColor, size: screenWidth * 0.06),
          ),
          suffixIcon: suffixIcon,
          contentPadding: contentPadding ??
              const EdgeInsets.symmetric(
                vertical: 18,
                horizontal: 16,
              ),
          labelText: label,
          labelStyle: TextStyle(
            fontFamily: 'AppTextStyles.appFontFamily,',
            color: fontColor.withOpacity(0.8),
            fontSize: screenWidth * 0.045,
            fontWeight: FontWeight.w600,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          enabledBorder: _buildBorder(borderColor),
          focusedBorder: _buildBorder(theme.primaryColor),
          errorBorder: _buildBorder(Colors.red),
          focusedErrorBorder: _buildBorder(Colors.red),
          errorStyle: TextStyle(
            color: Colors.red[700],
            fontSize: screenWidth * 0.03,
          ),
        ),
      ),
    );
  }

  OutlineInputBorder _buildBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: BorderSide(
        color: color,
        width: 1.5,
        strokeAlign: BorderSide.strokeAlignOutside,
      ),
    );
  }
}
