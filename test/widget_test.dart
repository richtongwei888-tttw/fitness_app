import 'dart:io';

import 'package:fitness_app/database/food_template_repository.dart';
import 'package:fitness_app/database/meal_food_record_repository.dart';
import 'package:fitness_app/main.dart';
import 'package:fitness_app/models/food_template.dart';
import 'package:fitness_app/models/food_unit_type.dart';
import 'package:fitness_app/models/local_user.dart';
import 'package:fitness_app/models/meal_food_record.dart';
import 'package:fitness_app/models/user_profile.dart';
import 'package:fitness_app/services/nutrition_target_calculator.dart';
import 'package:fitness_app/storage/local_auth_store.dart';
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

class _FakeLocalAuthStore extends LocalAuthStore {
  _FakeLocalAuthStore({required this.isGuest, LocalUser? user}) : _user = user;

  final bool isGuest;
  LocalUser? _user;

  LocalUser? get user => _user;

  @override
  Future<bool> isGuestSession() async => isGuest;

  @override
  Future<LocalUser?> loadCurrentUser() async => isGuest ? null : _user;

  @override
  Future<LocalUser> updateCurrentUsername(String username) async {
    final current = _user;
    if (isGuest || current == null) {
      throw const LocalAuthException('游客模式不能修改用户名');
    }
    _user = current.copyWith(username: username.trim());
    return _user!;
  }

  @override
  Future<LocalUser?> updateCurrentAvatarPath(String? avatarPath) async {
    final current = _user;
    if (isGuest || current == null) {
      return null;
    }
    _user = current.copyWith(
      avatarPath: avatarPath,
      clearAvatar: avatarPath == null || avatarPath.isEmpty,
    );
    return _user;
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  Future<void> pumpAppAsGuest(WidgetTester tester) async {
    await tester.pumpWidget(const FitnessApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('游客体验'));
    await tester.pumpAndSettle();
  }

  testWidgets('FitnessApp boots into the current HomePage', (
    WidgetTester tester,
  ) async {
    await pumpAppAsGuest(tester);

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
    await pumpAppAsGuest(tester);

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

  testWidgets('ProfilePage updates registered username', (
    WidgetTester tester,
  ) async {
    final store = _FakeUserProfileStore();
    final authStore = _FakeLocalAuthStore(
      isGuest: false,
      user: const LocalUser(
        userId: 'user_test',
        username: 'user',
        email: 'user@example.com',
        password: '1234',
        createdAt: '2026-05-15 00:00:00',
      ),
    );

    Future<void> pumpProfilePage() {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfilePage(profileStore: store, authStore: authStore),
          ),
        ),
      );
    }

    await pumpProfilePage();
    await tester.pumpAndSettle();

    expect(find.text('user'), findsOneWidget);
    expect(find.byIcon(Icons.person_rounded), findsOneWidget);
    expect(find.text('个人信息'), findsOneWidget);

    await tester.tap(find.text('user'));
    await tester.pumpAndSettle();

    if (find.byType(AlertDialog).evaluate().isNotEmpty) {
      expect(find.text('编辑用户名'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '小明');
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      expect(find.text('小明'), findsOneWidget);
      expect(authStore.user?.username, '小明');

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();

      await pumpProfilePage();
      await tester.pumpAndSettle();

      expect(find.text('小明'), findsOneWidget);
      return;
    }

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

  testWidgets('ProfilePage keeps guest profile read-only', (
    WidgetTester tester,
  ) async {
    final authStore = _FakeLocalAuthStore(isGuest: true);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProfilePage(
            profileStore: _FakeUserProfileStore(),
            authStore: authStore,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(UserProfile.guestName), findsOneWidget);
    expect(find.byIcon(Icons.person_rounded), findsOneWidget);
    expect(find.byIcon(Icons.edit_outlined), findsNothing);

    await tester.tap(find.text(UserProfile.guestName));
    await tester.pumpAndSettle();

    expect(find.text('编辑用户名'), findsNothing);
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
    final authStore = _FakeLocalAuthStore(
      isGuest: false,
      user: const LocalUser(
        userId: 'user_avatar_missing',
        username: 'user',
        email: 'user@example.com',
        password: '1234',
        createdAt: '2026-05-15 00:00:00',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProfilePage(profileStore: store, authStore: authStore),
        ),
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
    final authStore = _FakeLocalAuthStore(
      isGuest: false,
      user: LocalUser(
        userId: 'user_avatar_saved',
        username: 'user',
        email: 'user@example.com',
        password: '1234',
        avatarPath: avatarFile.path,
        createdAt: '2026-05-15 00:00:00',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProfilePage(
            initialProfile: profile,
            profileStore: store,
            authStore: authStore,
          ),
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
