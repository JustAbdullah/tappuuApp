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
      success: json['success'] as bool,
      attributes: (json['attributes'] as List)
          .map((e) => CategoryAttribute.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CategoryAttribute {
  final int attributeId;
  final String label;
  final String type;
  final bool isRequired;
  final List<AttributeOption> options;

  CategoryAttribute({
    required this.attributeId,
    required this.label,
    required this.type,
    required this.isRequired,
    required this.options,
  });

  factory CategoryAttribute.fromJson(Map<String, dynamic> json) {
    return CategoryAttribute(
      attributeId: json['attribute_id'] as int,
      label: json['label'] as String,
      type: json['type'] as String,
      isRequired: json['is_required'] as bool,
      options: (json['options'] as List)
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
      id: json['id'] as int,
      value: json['value'] as String,
    );
  }
}
