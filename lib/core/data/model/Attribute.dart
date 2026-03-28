
class Attribute {
  final int attributeId;
  final String label;
  final String type;
  final bool required;
  final List<AttributeOption> options;

  Attribute({
    required this.attributeId,
    required this.label,
    required this.type,
    required this.required,
    required this.options,
  });

  factory Attribute.fromJson(Map<String, dynamic> json) {
    return Attribute(
      attributeId: json['attribute_id'] as int,
      label: json['label'] as String,
      type: json['type'] as String,
      required: json['required'] as bool,
      options: (json['options'] as List<dynamic>)
          .map((opt) => AttributeOption.fromJson(opt))
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
