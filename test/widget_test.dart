import 'dart:io';

import 'package:fitness_app/database/meal_food_record_repository.dart';
import 'package:fitness_app/main.dart';
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
}
