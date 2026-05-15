import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';
import 'auth_session_store.dart';

abstract class UserProfileStore {
  Future<UserProfile> loadProfile();

  Future<UserProfile> saveNickname(String nickname);

  Future<UserProfile> saveAvatarPath(String? avatarPath);

  Future<UserProfile> savePersonalInfo({
    required UserGender gender,
    required int age,
    required double heightCm,
  });
}

class SharedPreferencesUserProfileStore implements UserProfileStore {
  SharedPreferencesUserProfileStore._();

  static final SharedPreferencesUserProfileStore instance =
      SharedPreferencesUserProfileStore._();

  static const String _nicknameKey = 'profile_nickname';
  static const String _avatarPathKey = 'profile_avatar_path';
  static const String _genderKey = 'profile_gender';
  static const String _ageKey = 'profile_age';
  static const String _heightCmKey = 'profile_height_cm';

  Future<String> _key(String key) async {
    final userId = await AuthSessionStore.effectiveUserId();
    return AuthSessionStore.scopedKey(userId, key);
  }

  @override
  Future<UserProfile> loadProfile() async {
    final preferences = await SharedPreferences.getInstance();
    final nicknameKey = await _key(_nicknameKey);
    final avatarPathKey = await _key(_avatarPathKey);
    final genderKey = await _key(_genderKey);
    final ageKey = await _key(_ageKey);
    final heightCmKey = await _key(_heightCmKey);
    return UserProfile(
      nickname: preferences.getString(nicknameKey) ?? '',
      avatarPath: preferences.getString(avatarPathKey),
      gender: userGenderFromStorage(preferences.getString(genderKey)),
      age: preferences.getInt(ageKey),
      heightCm: preferences.getDouble(heightCmKey),
    );
  }

  @override
  Future<UserProfile> saveNickname(String nickname) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(await _key(_nicknameKey), nickname);
    final current = await loadProfile();
    return current.copyWith(nickname: nickname);
  }

  @override
  Future<UserProfile> saveAvatarPath(String? avatarPath) async {
    final preferences = await SharedPreferences.getInstance();
    final avatarPathKey = await _key(_avatarPathKey);
    if (avatarPath == null || avatarPath.isEmpty) {
      await preferences.remove(avatarPathKey);
    } else {
      await preferences.setString(avatarPathKey, avatarPath);
    }
    final current = await loadProfile();
    return current.copyWith(
      avatarPath: avatarPath == null || avatarPath.isEmpty ? null : avatarPath,
      clearAvatar: avatarPath == null || avatarPath.isEmpty,
    );
  }

  @override
  Future<UserProfile> savePersonalInfo({
    required UserGender gender,
    required int age,
    required double heightCm,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(await _key(_genderKey), gender.storageValue);
    await preferences.setInt(await _key(_ageKey), age);
    await preferences.setDouble(await _key(_heightCmKey), heightCm);

    final current = await loadProfile();
    return current.copyWith(gender: gender, age: age, heightCm: heightCm);
  }
}
