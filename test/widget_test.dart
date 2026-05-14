import 'dart:io';

import 'package:fitness_app/database/food_template_repository.dart';
import 'package:fitness_app/database/meal_food_record_repository.dart';
import 'package:fitness_app/main.dart';
import 'package:fitness_app/models/food_template.dart';
import 'package:fitness_app/models/food_unit_type.dart';
import 'package:fitness_app/models/meal_food_record.dart';
import 'package:fitness_app/models/user_profile.dart';
import 'package:fitness_app/services/nutrition_target_calculator.dart';
import 'package:fitness_app/storage/user_profile_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeMealFoodRecordRepository implements MealFoodRecordRepository {
  @override
  Future<int> addRecord(MealFoodRecord record) async => 1;

  @override
  Future<int> deleteRecord(int id) async => 1;

  @override
  Future<List<MealFoodRecord>> getByDate(String dateKey) async =>
      <MealFoodRecord>[];

  @override
  Future<int> updateRecord(MealFoodRecord record) async => 1;
}

class _FakeFoodTemplateRepository implements FoodTemplateRepository {
  _FakeFoodTemplateRepository(this.templates);

  final List<FoodTemplate> templates;

  @override
  Future<int> addTemplate(FoodTemplate template) async {
    templates.add(template);
    return templates.length;
  }

  @override
  Future<int> deleteTemplate(int id) async {
    templates.removeWhere((template) => template.id == id);
    return 1;
  }

  @override
  Future<List<FoodTemplate>> getAll() async => List<FoodTemplate>.of(templates);
}

class _FakeUserProfileStore implements UserProfileStore {
  _FakeUserProfileStore({UserProfile initialProfile = const UserProfile()})
    : _profile = initialProfile;

  UserProfile _profile;

  UserProfile get profile => _profile;

  @override
  Future<UserProfile> loadProfile() async => _profile;

  @override
  Future<UserProfile> saveAvatarPath(String? avatarPath) async {
    _profile = _profile.copyWith(
      avatarPath: avatarPath,
      clearAvatar: avatarPath == null || avatarPath.isEmpty,
    );
    return _profile;
  }

  @override
  Future<UserProfile> saveNickname(String nickname) async {
    _profile = _profile.copyWith(nickname: nickname);
    return _profile;
  }

  @override
  Future<UserProfile> savePersonalInfo({
    required UserGender gender,
    required int age,
    required double heightCm,
  }) async {
    _profile = _profile.copyWith(gender: gender, age: age, heightCm: heightCm);
    return _profile;
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('FitnessApp boots into the current HomePage', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const FitnessApp());
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('My Fitness'), findsOneWidget);
    expect(find.text('饮食'), findsOneWidget);
    expect(find.text('训练'), findsOneWidget);
    expect(find.text('我的'), findsOneWidget);
  });

  testWidgets('HomePage navigates to the current diet page', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const FitnessApp());
    await tester.pump();

    await tester.tap(find.text('饮食'));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(AutoMealDietPage), findsOneWidget);
    expect(find.text('营养目标'), findsOneWidget);
    expect(find.text('第一餐'), findsOneWidget);
    expect(find.text('第二餐'), findsOneWidget);
  });

  testWidgets('AutoMealDietPage renders the current six-meal structure', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AutoMealDietPage(
            repository: _FakeMealFoodRecordRepository(),
            nutritionTargetState: NutritionTargetState.notReady(
              missingFields: const <NutritionMissingField>[
                NutritionMissingField.weight,
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('饮食'), findsOneWidget);
    expect(find.text('营养目标'), findsOneWidget);
    expect(find.text('第一餐'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('第六餐'),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('第六餐'), findsOneWidget);
  });

  testWidgets('FoodSelectionPage filters saved foods by search keyword', (
    WidgetTester tester,
  ) async {
    final templates = <FoodTemplate>[
      const FoodTemplate(
        id: 1,
        name: '鸡胸肉',
        unitType: FoodUnitType.per100g,
        carbs: 0,
        protein: 24,
        fat: 2,
        createdAt: '2026-05-14T00:00:00',
      ),
      const FoodTemplate(
        id: 2,
        name: 'Egg',
        unitType: FoodUnitType.perServing,
        carbs: 1,
        protein: 6,
        fat: 5,
        createdAt: '2026-05-14T00:00:00',
      ),
      const FoodTemplate(
        id: 3,
        name: '牛奶',
        unitType: FoodUnitType.per100g,
        carbs: 5,
        protein: 3,
        fat: 3,
        createdAt: '2026-05-14T00:00:00',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: FoodSelectionPage(
          mealIndex: 1,
          mealLabel: '早餐',
          selectedDate: DateTime(2026, 5, 14),
          templateRepository: _FakeFoodTemplateRepository(templates),
          recordRepository: _FakeMealFoodRecordRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('鸡胸肉'), findsOneWidget);
    expect(find.text('Egg'), findsOneWidget);
    expect(find.text('牛奶'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '鸡');
    await tester.pumpAndSettle();

    expect(find.text('鸡胸肉'), findsOneWidget);
    expect(find.text('Egg'), findsNothing);
    expect(find.text('牛奶'), findsNothing);

    await tester.enterText(find.byType(TextField).first, 'egg');
    await tester.pumpAndSettle();

    expect(find.text('Egg'), findsOneWidget);
    expect(find.text('鸡胸肉'), findsNothing);

    await tester.enterText(find.byType(TextField).first, '不存在');
    await tester.pumpAndSettle();

    expect(find.text('没有找到相关食物'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '');
    await tester.pumpAndSettle();

    expect(find.text('鸡胸肉'), findsOneWidget);
    expect(find.text('Egg'), findsOneWidget);
    expect(find.text('牛奶'), findsOneWidget);
  });

  testWidgets('ProfilePage defaults to guest and updates nickname', (
    WidgetTester tester,
  ) async {
    final store = _FakeUserProfileStore();

    Future<void> pumpProfilePage() {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ProfilePage(profileStore: store)),
        ),
      );
    }

    await pumpProfilePage();
    await tester.pumpAndSettle();

    expect(find.text(UserProfile.guestName), findsOneWidget);
    expect(find.byIcon(Icons.person_rounded), findsOneWidget);
    expect(find.text('个人信息'), findsOneWidget);

    await tester.tap(find.text(UserProfile.guestName));
    await tester.pumpAndSettle();

    expect(find.text('编辑昵称'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '小明');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(find.text('小明'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    await pumpProfilePage();
    await tester.pumpAndSettle();

    expect(find.text('小明'), findsOneWidget);
  });

  testWidgets('ProfilePage clears missing persisted avatar path', (
    WidgetTester tester,
  ) async {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'missing_profile_avatar_test_',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });

    final missingAvatarPath =
        '${tempDirectory.path}${Platform.pathSeparator}missing_profile_avatar.jpg';
    final store = _FakeUserProfileStore(
      initialProfile: UserProfile(avatarPath: missingAvatarPath),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ProfilePage(profileStore: store)),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.person_rounded), findsOneWidget);
    expect(store.profile.avatarPath, isNull);
  });

  testWidgets('ProfilePage shows initial persisted avatar during rebuild', (
    WidgetTester tester,
  ) async {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'profile_avatar_rebuild_test_',
    );
    addTearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });

    final avatarFile = File(
      '${tempDirectory.path}${Platform.pathSeparator}profile_avatar.jpg',
    )..writeAsBytesSync(<int>[1, 2, 3, 4]);
    final profile = UserProfile(avatarPath: avatarFile.path);
    final store = _FakeUserProfileStore(initialProfile: profile);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProfilePage(initialProfile: profile, profileStore: store),
        ),
      ),
    );

    expect(find.byType(Image), findsOneWidget);
    expect(find.byIcon(Icons.person_rounded), findsNothing);

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(Image), findsOneWidget);
  });
}
