import 'package:fitness_app/models/user_profile.dart';
import 'package:fitness_app/services/nutrition_target_calculator.dart';
import 'package:fitness_app/storage/user_profile_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('buildNutritionTargetState returns ready result for complete info', () {
    const profile = UserProfile(
      gender: UserGender.male,
      age: 30,
      heightCm: 180,
    );

    final result = buildNutritionTargetState(
      weightKg: 75,
      profile: profile,
    );

    expect(result.isReady, isTrue);
    expect(result.bmr, 1730);
    expect(result.targetCalories, 2210);
    expect(result.targets?.carbs, 276.3);
    expect(result.targets?.protein, 165.8);
    expect(result.targets?.fat, 49.1);
  });

  test('buildNutritionTargetState returns incomplete state when info is missing', () {
    const profile = UserProfile(gender: UserGender.female, age: 28);

    final result = buildNutritionTargetState(
      weightKg: null,
      profile: profile,
    );

    expect(result.isReady, isFalse);
    expect(result.targets, isNull);
    expect(result.missingFields, contains(NutritionMissingField.weight));
    expect(result.missingFields, contains(NutritionMissingField.height));
  });

  test('SharedPreferencesUserProfileStore persists personal info after reload', () async {
    final store = SharedPreferencesUserProfileStore.instance;

    await store.savePersonalInfo(
      gender: UserGender.female,
      age: 26,
      heightCm: 168,
    );

    final reloaded = await store.loadProfile();

    expect(reloaded.gender, UserGender.female);
    expect(reloaded.age, 26);
    expect(reloaded.heightCm, 168);
  });
}
