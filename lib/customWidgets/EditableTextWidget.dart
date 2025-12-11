// lib/core/widgets/editable_text_widget.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/editable_text_controller.dart';

class EditableTextWidget extends StatefulWidget {
  final String keyName;
  final TextAlign textAlign;
  final FontWeight fontWeight;
  final double? height;
  final double? overrideFontSize; // لو حبيت تزود حجم مؤقت

  const EditableTextWidget({
    Key? key,
    required this.keyName,
    this.textAlign = TextAlign.center,
    this.fontWeight = FontWeight.normal,
    this.height,
    this.overrideFontSize,
  }) : super(key: key);

  @override
  State<EditableTextWidget> createState() => _EditableTextWidgetState();
}

class _EditableTextWidgetState extends State<EditableTextWidget> {
  final EditableTextController ctrl = Get.find<EditableTextController>();

  @override
  void initState() {
    super.initState();
    // إذا البيانات موجودة مسبقًا فحمل الخط (إن وجد)
    final item = ctrl.findByKey(widget.keyName);
    if (item != null) {
      // نطلق التحميل في الخلفية، بدون انتظار
      ctrl.ensureFontLoaded(item);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // ربط تفاعلي مباشر بقائمة العناصر (حتى لو تم تعديل عنصر داخلها)
      final _ = ctrl.items.length;

      final item = ctrl.findByKey(widget.keyName);
      if (item == null) {
        // فارغ لحين جلب البيانات — يمكن عرض placeholder لو تحب
        return const SizedBox.shrink();
      }

      final family = ctrl.fontFamilyForKey(item.keyName);
      final fontSize = widget.overrideFontSize ?? item.fontSize.toDouble();

      return Text(
        item.textContent,
        textAlign: widget.textAlign,
        style: TextStyle(
          fontFamily: family,
          fontSize: fontSize,
          fontWeight: widget.fontWeight,
          color: ctrl.hexToColor(item.color),
          height: widget.height,
        ),
      );
    });
  }
}
