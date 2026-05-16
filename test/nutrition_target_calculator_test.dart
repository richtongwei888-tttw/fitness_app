import 'dart:io';

import 'package:fitness_app/models/user_profile.dart';
import 'package:fitness_app/services/nutrition_target_calculator.dart';
import 'package:fitness_app/storage/avatar_file_store.dart';
import 'package:fitness_app/storage/user_profile_store.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  late Directory documentsDirectory;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    documentsDirectory = Directory.systemTemp.createTempSync(
      'fitness_profile_store_test_',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (call) async {
          if (call.method == 'getApplicationDocumentsDirectory') {
            return documentsDirectory.path;
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    if (documentsDirectory.existsSync()) {
      documentsDirectory.deleteSync(recursive: true);
    }
  });

  test('buildNutritionTargetState returns ready result for complete info', () {
    const profile = UserProfile(
      gender: UserGender.male,
      age: 30,
      heightCm: 180,
    );

    final result = buildNutritionTargetState(weightKg: 75, profile: profile);

    expect(result.isReady, isTrue);
    expect(result.bmr, 1730);
    expect(result.targetCalories, 2210);
    expect(result.targets?.carbs, 276.3);
    expect(result.targets?.protein, 165.8);
    expect(result.targets?.fat, 49.1);
  });

  test(
    'buildNutritionTargetState returns incomplete state when info is missing',
    () {
      const profile = UserProfile(gender: UserGender.female, age: 28);

      final result = buildNutritionTargetState(
        weightKg: null,
        profile: profile,
      );

      expect(result.isReady, isFalse);
      expect(result.targets, isNull);
      expect(result.missingFields, contains(NutritionMissingField.weight));
      expect(result.missingFields, contains(NutritionMissingField.height));
    },
  );

  test(
    'SharedPreferencesUserProfileStore persists personal info after reload',
    () async {
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
    },
  );

  test(
    'SharedPreferencesUserProfileStore stores managed avatar paths relatively',
    () async {
      final store = SharedPreferencesUserProfileStore.instance;
      final avatarDirectory = await AvatarFileStore.managedDirectory();
      if (!avatarDirectory.existsSync()) {
        avatarDirectory.createSync(recursive: true);
      }
      final avatarFile = File(
        '${avatarDirectory.path}${Platform.pathSeparator}avatar_test.jpg',
      )..writeAsBytesSync(<int>[1, 2, 3, 4]);
      addTearDown(() {
        if (avatarFile.existsSync()) {
          avatarFile.deleteSync();
        }
      });

      await store.saveAvatarPath(avatarFile.path);

      final preferences = await SharedPreferences.getInstance();
      expect(
        preferences.getString('profile_avatar_path'),
        'profile_assets${Platform.pathSeparator}avatar_test.jpg',
      );

      final reloaded = await store.loadProfile();
      expect(reloaded.avatarPath, avatarFile.path);
    },
  );
}
