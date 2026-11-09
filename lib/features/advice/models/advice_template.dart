import '../../../core/utils/json_readers.dart';

class AdviceTemplate {
  const AdviceTemplate({
    required this.id,
    required this.title,
    required this.body,
    required this.sortOrder,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String body;
  final int sortOrder;
  final DateTime updatedAt;

  AdviceTemplate copyWith({
    String? id,
    String? title,
    String? body,
    int? sortOrder,
    DateTime? updatedAt,
  }) {
    return AdviceTemplate(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      sortOrder: sortOrder ?? this.sortOrder,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'sortOrder': sortOrder,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory AdviceTemplate.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! String || id.isEmpty) {
      throw const FormatException('Advice template id is missing');
    }
    return AdviceTemplate(
      id: id,
      title: textField(json, 'title'),
      body: textField(json, 'body'),
      sortOrder: optionalInt(json['sortOrder']) ?? 0,
      updatedAt: requiredDate(json, 'updatedAt'),
    );
  }
}
