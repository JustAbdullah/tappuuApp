// lib/core/data/model/AppColor.dart
import 'package:flutter/material.dart';

class AppColor {
  final int id;
  final String name;
  final String hexCode;

  AppColor({
    required this.id,
    required this.name,
    required this.hexCode,
  });

  factory AppColor.fromJson(Map<String, dynamic> json) {
    return AppColor(
      id: json['id'] as int,
      name: json['name'] as String,
      hexCode: json['hex_code'] as String,
    );
  }

  Color toColor() {
    String hex = hexCode.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }
}