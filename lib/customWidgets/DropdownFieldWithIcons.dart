import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../controllers/ThemeController.dart';
import '../core/constant/app_text_styles.dart';
import '../core/constant/appcolors.dart';
import '../core/localization/changelanguage.dart';

class CarBrand {
  final String arabicName;
  final String englishName;
  final String turkishName;
  final String kurdishName;
  String customLogo = "";
  IconData iconData = Icons.question_answer;

  CarBrand({
    required this.arabicName,
    required this.englishName,
    required this.turkishName,
    required this.kurdishName,
    this.customLogo = "",
    this.iconData = Icons.question_answer,
  });

  String getName(String languageCode) {
    switch (languageCode) {
      case 'ar':
        return arabicName;
      case 'en':
        return englishName;
      case 'tr':
        return turkishName;
      case 'ku':
        return kurdishName;
      default:
        return arabicName;
    }
  }
}

class DropdownFieldWithIcons extends StatelessWidget {
  final String label;
  final List<CarBrand> items;
  final CarBrand? selectedItem;
  final Color fillColor;
  final Color? borderColor;
  final double borderRadius;
  final Widget? customIcon;
  final Color menuColor;
  final double menuElevation;
  final EdgeInsetsGeometry menuPadding;
  final void Function(CarBrand?) onChanged;

  const DropdownFieldWithIcons({
    Key? key,
    required this.label,
    required this.items,
    this.selectedItem,
    this.fillColor = Colors.black,
    this.borderColor,
    this.borderRadius = 12.0,
    this.customIcon,
    this.menuColor = Colors.white,
    this.menuElevation = 8.0,
    this.menuPadding = const EdgeInsets.symmetric(vertical: 5.0),
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find();
    final isRTL =
        Get.find<ChangeLanguageController>().currentLocale.value.languageCode ==
            "ar";

    final Color actualBorderColor = borderColor ?? AppColors.primary;

    double maxMenuHeight = MediaQuery.of(context).size.height * 0.85;

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 0.h),
        child: DropdownButtonFormField<CarBrand>(
          value: selectedItem,
          isExpanded: true,
          items: items.map((item) => _buildMenuItem(item, actualBorderColor)).toList(),
          onChanged: onChanged,
          iconSize: 30,
          dropdownColor: menuColor,
          elevation: menuElevation.toInt(),
          menuMaxHeight: maxMenuHeight,
          padding: menuPadding,
          decoration: _buildInputDecoration(isRTL, themeController, actualBorderColor),
          style: TextStyle(
            color: AppColors.textPrimary(themeController.isDarkMode.value),
            fontSize: AppTextStyles.xlarge,

            fontWeight: FontWeight.w500,
          ),
          selectedItemBuilder: (_) => items.map((item) {
            return _buildSelectedItem(item, themeController, isRTL, actualBorderColor);
          }).toList(),
        ),
      ),
    );
  }

  DropdownMenuItem<CarBrand> _buildMenuItem(CarBrand item, Color actualBorderColor) {
    return DropdownMenuItem<CarBrand>(
      value: item,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: actualBorderColor.withOpacity(0.2),
              width: 1.0,
            ),
          ),
        ),
        child: Row(
          children: [
            _buildBrandIcon(item, 28.sp, actualBorderColor),
            SizedBox(width: 15.w),
            Expanded(
              child: Text(
                item.arabicName.tr,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  color: AppColors.backgroundDark,
                  fontSize: AppTextStyles.xlarge,

                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandIcon(CarBrand brand, double size, Color actualBorderColor) {
    if (brand.customLogo.isNotEmpty) {
      return SvgPicture.asset(
        brand.customLogo,
        width: size,
        height: size,
        placeholderBuilder: (_) => Icon(Icons.car_repair, size: size),
      );
    } else if (brand.iconData != null) {
      return Icon(brand.iconData, size: size, color: actualBorderColor);
    }
    return Icon(Icons.directions_car, size: size, color: actualBorderColor);
  }

  Widget _buildSelectedItem(CarBrand item, ThemeController themeController, bool isRTL, Color actualBorderColor) {
    return Container(
      alignment: isRTL ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selectedItem != null) _buildBrandIcon(item, 24.sp, actualBorderColor),
          SizedBox(width: 8.w),
          Flexible(
            child: Text(
              item.arabicName.tr,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                color: AppColors.textPrimary(themeController.isDarkMode.value),
                fontSize: AppTextStyles.xlarge,

              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration(bool isRTL, ThemeController themeController, Color actualBorderColor) {
    return InputDecoration(
      filled: true,
      fillColor: AppColors.card(themeController.isDarkMode.value),
      labelText: label,
      labelStyle: TextStyle(
        fontFamily: 'AppTextStyles.appFontFamily,',
        color: AppColors.textPrimary(themeController.isDarkMode.value),
        fontSize: AppTextStyles.xxlarge,

      ),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      contentPadding: EdgeInsets.symmetric(vertical: 22.0, horizontal: 20.0),
      constraints: BoxConstraints(minHeight: 60.h),
      border: OutlineInputBorder(
        borderSide: BorderSide(color: actualBorderColor, width: 2),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: actualBorderColor, width: 2),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: actualBorderColor, width: 2),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
