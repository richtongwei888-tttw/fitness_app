enum FoodUnitType { per100g, perServing }

FoodUnitType foodUnitTypeFromStorage(String? value) {
  switch (value) {
    case 'per100g':
      return FoodUnitType.per100g;
    case 'perServing':
    default:
      return FoodUnitType.perServing;
  }
}

extension FoodUnitTypeX on FoodUnitType {
  String get storageValue {
    switch (this) {
      case FoodUnitType.per100g:
        return 'per100g';
      case FoodUnitType.perServing:
        return 'perServing';
    }
  }

  String get label {
    switch (this) {
      case FoodUnitType.per100g:
        return '每100g';
      case FoodUnitType.perServing:
        return '每1份';
    }
  }

  String get consumedUnitLabel {
    switch (this) {
      case FoodUnitType.per100g:
        return 'g';
      case FoodUnitType.perServing:
        return '份';
    }
  }
}
