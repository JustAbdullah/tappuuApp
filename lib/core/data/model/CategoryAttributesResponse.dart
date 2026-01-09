// lib/models/category_attributes_response.dart

class CategoryAttributesResponse {
  final bool success;
  final List<CategoryAttribute> attributes;

  CategoryAttributesResponse({
    required this.success,
    required this.attributes,
  });

  factory CategoryAttributesResponse.fromJson(Map<String, dynamic> json) {
    return CategoryAttributesResponse(
      success: json['success'] == true,
      attributes: (json['attributes'] as List<dynamic>? ?? [])
          .map((e) => CategoryAttribute.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CategoryAttribute {
  final int attributeId;
  final String label;
  final String type;

  /// ✅ من الـ pivot (category_attributes)
  final bool isRequired;

  /// ✅ الجديد: من attributes.is_multi_select
  final bool isMultiSelect;

  final List<AttributeOption> options;

  CategoryAttribute({
    required this.attributeId,
    required this.label,
    required this.type,
    required this.isRequired,
    required this.isMultiSelect,
    required this.options,
  });

  factory CategoryAttribute.fromJson(Map<String, dynamic> json) {
    return CategoryAttribute(
      attributeId: (json['attribute_id'] ?? 0) as int,
      label: (json['label'] ?? '') as String,
      type: (json['type'] ?? '') as String,

      // بعض السيرفرات ترجع 0/1 بدل true/false
      isRequired: json['is_required'] == true || json['is_required'] == 1,

      // ✅ الجديد
      isMultiSelect:
          json['is_multi_select'] == true || json['is_multi_select'] == 1,

      options: (json['options'] as List<dynamic>? ?? [])
          .map((e) => AttributeOption.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class AttributeOption {
  final int id;
  final String value;

  AttributeOption({
    required this.id,
    required this.value,
  });

  factory AttributeOption.fromJson(Map<String, dynamic> json) {
    return AttributeOption(
      id: (json['id'] ?? 0) as int,
      value: (json['value'] ?? '') as String,
    );
  }
}
