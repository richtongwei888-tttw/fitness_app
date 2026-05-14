class DietRecord {
  final int? id;
  final String date;
  final int mealIndex;
  final String mealLabel;
  final String mealType;
  final String foodName;
  final double carbs;
  final double protein;
  final double fat;
  final double calories;
  final String notes;
  final String createdAt;

  DietRecord({
    this.id,
    required this.date,
    int? mealIndex,
    String? mealLabel,
    String? mealType,
    required this.foodName,
    double? carbs,
    double? protein,
    double? fat,
    double? calories,
    this.notes = '',
    required this.createdAt,
  }) : mealIndex = mealIndex ?? 0,
       mealLabel = mealLabel ?? mealType ?? '',
       mealType = mealType ?? mealLabel ?? '',
       carbs = carbs ?? 0,
       protein = protein ?? 0,
       fat = fat ?? 0,
       calories =
           calories ??
           ((carbs ?? 0) * 4 + (protein ?? 0) * 4 + (fat ?? 0) * 9);

  double get calculatedCalories => carbs * 4 + protein * 4 + fat * 9;

  DietRecord copyWith({
    int? id,
    String? date,
    int? mealIndex,
    String? mealLabel,
    String? mealType,
    String? foodName,
    double? carbs,
    double? protein,
    double? fat,
    double? calories,
    String? notes,
    String? createdAt,
  }) {
    return DietRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      mealIndex: mealIndex ?? this.mealIndex,
      mealLabel: mealLabel ?? this.mealLabel,
      mealType: mealType ?? this.mealType,
      foodName: foodName ?? this.foodName,
      carbs: carbs ?? this.carbs,
      protein: protein ?? this.protein,
      fat: fat ?? this.fat,
      calories: calories ?? this.calories,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory DietRecord.fromMap(Map<String, dynamic> map) {
    final carbs = (map['carbs'] as num?)?.toDouble() ?? 0;
    final protein = (map['protein'] as num?)?.toDouble() ?? 0;
    final fat = (map['fat'] as num?)?.toDouble() ?? 0;
    final mealType = map['mealType'] as String? ?? '';
    final mealLabel = map['mealLabel'] as String? ?? mealType;

    return DietRecord(
      id: map['id'] as int?,
      date: map['date'] as String,
      mealIndex: (map['mealIndex'] as num?)?.toInt() ?? 0,
      mealLabel: mealLabel,
      mealType: mealType,
      foodName: map['foodName'] as String,
      carbs: carbs,
      protein: protein,
      fat: fat,
      calories:
          (map['calories'] as num?)?.toDouble() ?? (carbs * 4 + protein * 4 + fat * 9),
      notes: map['notes'] as String? ?? '',
      createdAt: map['createdAt'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'mealType': mealLabel.isNotEmpty ? mealLabel : mealType,
      'mealIndex': mealIndex,
      'mealLabel': mealLabel.isNotEmpty ? mealLabel : mealType,
      'foodName': foodName,
      'carbs': carbs,
      'protein': protein,
      'fat': fat,
      'calories': calories,
      'notes': notes,
      'createdAt': createdAt,
    };
  }

  @override
  String toString() {
    return 'DietRecord(id: $id, date: $date, mealIndex: $mealIndex, mealLabel: $mealLabel, foodName: $foodName, carbs: $carbs, protein: $protein, fat: $fat, calories: $calories)';
  }
}
