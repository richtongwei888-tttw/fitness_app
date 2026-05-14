import '../models/user_profile.dart';

double _roundNutritionValue(double value) {
  return double.parse(value.toStringAsFixed(1));
}

class MacroTargets {
  const MacroTargets({
    required this.carbs,
    required this.protein,
    required this.fat,
  });

  final double carbs;
  final double protein;
  final double fat;

  double get totalCalories => carbs * 4 + protein * 4 + fat * 9;
}

enum NutritionMissingField { weight, gender, age, height }

extension NutritionMissingFieldLabel on NutritionMissingField {
  String get label {
    switch (this) {
      case NutritionMissingField.weight:
        return '用于饮食计算的体重';
      case NutritionMissingField.gender:
        return '性别';
      case NutritionMissingField.age:
        return '年龄';
      case NutritionMissingField.height:
        return '身高';
    }
  }
}

class NutritionTargetState {
  const NutritionTargetState._({
    required this.missingFields,
    this.weightKg,
    this.bmr,
    this.targetCalories,
    this.targets,
  });

  factory NutritionTargetState.notReady({
    required List<NutritionMissingField> missingFields,
  }) {
    return NutritionTargetState._(
      missingFields: List<NutritionMissingField>.unmodifiable(missingFields),
    );
  }

  factory NutritionTargetState.ready({
    required double weightKg,
    required double bmr,
    required double targetCalories,
    required MacroTargets targets,
  }) {
    return NutritionTargetState._(
      missingFields: const <NutritionMissingField>[],
      weightKg: weightKg,
      bmr: bmr,
      targetCalories: targetCalories,
      targets: targets,
    );
  }

  final List<NutritionMissingField> missingFields;
  final double? weightKg;
  final double? bmr;
  final double? targetCalories;
  final MacroTargets? targets;

  bool get isReady =>
      weightKg != null &&
      bmr != null &&
      targetCalories != null &&
      targets != null &&
      missingFields.isEmpty;

  String get missingFieldsSummary {
    if (missingFields.isEmpty) {
      return '';
    }
    return missingFields.map((field) => field.label).join('、');
  }

  String get incompleteMessage {
    if (missingFields.isEmpty) {
      return '请先完善基础信息';
    }
    return '请先完善基础信息：$missingFieldsSummary';
  }
}

double? calculateBmr({
  required UserGender gender,
  required double weightKg,
  required double heightCm,
  required int age,
}) {
  if (!weightKg.isFinite ||
      !heightCm.isFinite ||
      weightKg <= 0 ||
      heightCm <= 0 ||
      age <= 0) {
    return null;
  }

  final baseValue = 10 * weightKg + 6.25 * heightCm - 5 * age;
  final bmr = switch (gender) {
    UserGender.male => baseValue + 5,
    UserGender.female => baseValue - 161,
  };

  if (!bmr.isFinite || bmr <= 0) {
    return null;
  }

  return _roundNutritionValue(bmr);
}

double? calculateTargetCalories({required double bmr}) {
  if (!bmr.isFinite || bmr <= 0) {
    return null;
  }

  final targetCalories = bmr + 480;
  if (!targetCalories.isFinite || targetCalories <= 0) {
    return null;
  }

  return _roundNutritionValue(targetCalories);
}

MacroTargets? calculateMacroTargets({required double targetCalories}) {
  if (!targetCalories.isFinite || targetCalories <= 0) {
    return null;
  }

  final targetCarbs = targetCalories * 0.5 / 4;
  final targetProtein = targetCalories * 0.3 / 4;
  final targetFat = targetCalories * 0.2 / 9;

  if (!targetCarbs.isFinite ||
      !targetProtein.isFinite ||
      !targetFat.isFinite ||
      targetCarbs < 0 ||
      targetProtein < 0 ||
      targetFat < 0) {
    return null;
  }

  return MacroTargets(
    carbs: _roundNutritionValue(targetCarbs),
    protein: _roundNutritionValue(targetProtein),
    fat: _roundNutritionValue(targetFat),
  );
}

NutritionTargetState buildNutritionTargetState({
  required double? weightKg,
  required UserProfile profile,
}) {
  final missingFields = <NutritionMissingField>[];

  if (weightKg == null || !weightKg.isFinite || weightKg <= 0) {
    missingFields.add(NutritionMissingField.weight);
  }
  if (profile.gender == null) {
    missingFields.add(NutritionMissingField.gender);
  }
  if (profile.age == null || profile.age! <= 0) {
    missingFields.add(NutritionMissingField.age);
  }
  if (profile.heightCm == null ||
      !profile.heightCm!.isFinite ||
      profile.heightCm! <= 0) {
    missingFields.add(NutritionMissingField.height);
  }

  if (missingFields.isNotEmpty) {
    return NutritionTargetState.notReady(missingFields: missingFields);
  }

  final bmr = calculateBmr(
    gender: profile.gender!,
    weightKg: weightKg!,
    heightCm: profile.heightCm!,
    age: profile.age!,
  );
  if (bmr == null) {
    return NutritionTargetState.notReady(
      missingFields: const <NutritionMissingField>[
        NutritionMissingField.weight,
        NutritionMissingField.gender,
        NutritionMissingField.age,
        NutritionMissingField.height,
      ],
    );
  }

  final targetCalories = calculateTargetCalories(bmr: bmr);
  if (targetCalories == null) {
    return NutritionTargetState.notReady(
      missingFields: const <NutritionMissingField>[
        NutritionMissingField.weight,
        NutritionMissingField.gender,
        NutritionMissingField.age,
        NutritionMissingField.height,
      ],
    );
  }

  final targets = calculateMacroTargets(targetCalories: targetCalories);
  if (targets == null) {
    return NutritionTargetState.notReady(
      missingFields: const <NutritionMissingField>[
        NutritionMissingField.weight,
        NutritionMissingField.gender,
        NutritionMissingField.age,
        NutritionMissingField.height,
      ],
    );
  }

  return NutritionTargetState.ready(
    weightKg: _roundNutritionValue(weightKg),
    bmr: bmr,
    targetCalories: targetCalories,
    targets: targets,
  );
}
