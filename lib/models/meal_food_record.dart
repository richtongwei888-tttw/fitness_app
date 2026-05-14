import 'food_unit_type.dart';

class MealFoodRecord {
  const MealFoodRecord({
    this.id,
    required this.dateKey,
    required this.mealIndex,
    required this.mealLabel,
    this.foodTemplateId,
    required this.foodName,
    required this.baseUnitType,
    required this.baseCarbs,
    required this.baseProtein,
    required this.baseFat,
    required this.consumedAmount,
    required this.consumedUnit,
    required this.actualCarbs,
    required this.actualProtein,
    required this.actualFat,
    required this.createdAt,
  });

  final int? id;
  final String dateKey;
  final int mealIndex;
  final String mealLabel;
  final int? foodTemplateId;
  final String foodName;
  final FoodUnitType baseUnitType;
  final double baseCarbs;
  final double baseProtein;
  final double baseFat;
  final double consumedAmount;
  final String consumedUnit;
  final double actualCarbs;
  final double actualProtein;
  final double actualFat;
  final String createdAt;

  double get calories => actualCarbs * 4 + actualProtein * 4 + actualFat * 9;

  MealFoodRecord copyWith({
    int? id,
    String? dateKey,
    int? mealIndex,
    String? mealLabel,
    int? foodTemplateId,
    String? foodName,
    FoodUnitType? baseUnitType,
    double? baseCarbs,
    double? baseProtein,
    double? baseFat,
    double? consumedAmount,
    String? consumedUnit,
    double? actualCarbs,
    double? actualProtein,
    double? actualFat,
    String? createdAt,
  }) {
    return MealFoodRecord(
      id: id ?? this.id,
      dateKey: dateKey ?? this.dateKey,
      mealIndex: mealIndex ?? this.mealIndex,
      mealLabel: mealLabel ?? this.mealLabel,
      foodTemplateId: foodTemplateId ?? this.foodTemplateId,
      foodName: foodName ?? this.foodName,
      baseUnitType: baseUnitType ?? this.baseUnitType,
      baseCarbs: baseCarbs ?? this.baseCarbs,
      baseProtein: baseProtein ?? this.baseProtein,
      baseFat: baseFat ?? this.baseFat,
      consumedAmount: consumedAmount ?? this.consumedAmount,
      consumedUnit: consumedUnit ?? this.consumedUnit,
      actualCarbs: actualCarbs ?? this.actualCarbs,
      actualProtein: actualProtein ?? this.actualProtein,
      actualFat: actualFat ?? this.actualFat,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory MealFoodRecord.fromMap(Map<String, dynamic> map) {
    final actualCarbs =
        (map['actualCarbs'] as num?)?.toDouble() ??
        (map['carbs'] as num?)?.toDouble() ??
        0;
    final actualProtein =
        (map['actualProtein'] as num?)?.toDouble() ??
        (map['protein'] as num?)?.toDouble() ??
        0;
    final actualFat =
        (map['actualFat'] as num?)?.toDouble() ??
        (map['fat'] as num?)?.toDouble() ??
        0;
    final unitType = foodUnitTypeFromStorage(map['baseUnitType'] as String?);
    final mealIndex = (map['mealIndex'] as num?)?.toInt() ?? 0;

    return MealFoodRecord(
      id: map['id'] as int?,
      dateKey: map['date'] as String? ?? '',
      mealIndex: mealIndex,
      mealLabel:
          map['mealLabel'] as String? ??
          map['mealType'] as String? ??
          _mealLabelForIndex(mealIndex),
      foodTemplateId: (map['foodTemplateId'] as num?)?.toInt(),
      foodName: map['foodName'] as String? ?? '',
      baseUnitType: unitType,
      baseCarbs:
          (map['baseCarbs'] as num?)?.toDouble() ??
          (map['carbs'] as num?)?.toDouble() ??
          0,
      baseProtein:
          (map['baseProtein'] as num?)?.toDouble() ??
          (map['protein'] as num?)?.toDouble() ??
          0,
      baseFat:
          (map['baseFat'] as num?)?.toDouble() ??
          (map['fat'] as num?)?.toDouble() ??
          0,
      consumedAmount: (map['consumedAmount'] as num?)?.toDouble() ?? 1,
      consumedUnit:
          map['consumedUnit'] as String? ?? unitType.consumedUnitLabel,
      actualCarbs: actualCarbs,
      actualProtein: actualProtein,
      actualFat: actualFat,
      createdAt: map['createdAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': dateKey,
      'mealIndex': mealIndex,
      'mealLabel': mealLabel,
      'mealType': mealLabel,
      'foodTemplateId': foodTemplateId,
      'foodName': foodName,
      'baseUnitType': baseUnitType.storageValue,
      'baseCarbs': baseCarbs,
      'baseProtein': baseProtein,
      'baseFat': baseFat,
      'consumedAmount': consumedAmount,
      'consumedUnit': consumedUnit,
      'actualCarbs': actualCarbs,
      'actualProtein': actualProtein,
      'actualFat': actualFat,
      'carbs': actualCarbs,
      'protein': actualProtein,
      'fat': actualFat,
      'calories': calories,
      'notes': '',
      'createdAt': createdAt,
    };
  }

  static String _mealLabelForIndex(int index) {
    const labels = <String>['第一餐', '第二餐', '第三餐', '第四餐', '第五餐', '第六餐'];

    if (index >= 1 && index <= labels.length) {
      return labels[index - 1];
    }

    return '第$index餐';
  }
}
