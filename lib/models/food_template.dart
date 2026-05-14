import 'food_unit_type.dart';

class FoodTemplate {
  const FoodTemplate({
    this.id,
    required this.name,
    required this.unitType,
    required this.carbs,
    required this.protein,
    required this.fat,
    required this.createdAt,
  });

  final int? id;
  final String name;
  final FoodUnitType unitType;
  final double carbs;
  final double protein;
  final double fat;
  final String createdAt;

  factory FoodTemplate.fromMap(Map<String, dynamic> map) {
    return FoodTemplate(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      unitType: foodUnitTypeFromStorage(map['unitType'] as String?),
      carbs: (map['carbs'] as num?)?.toDouble() ?? 0,
      protein: (map['protein'] as num?)?.toDouble() ?? 0,
      fat: (map['fat'] as num?)?.toDouble() ?? 0,
      createdAt: map['createdAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'unitType': unitType.storageValue,
      'carbs': carbs,
      'protein': protein,
      'fat': fat,
      'createdAt': createdAt,
    };
  }
}
