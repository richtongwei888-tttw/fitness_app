import 'package:shared_preferences/shared_preferences.dart';

class AuthSessionStore {
  const AuthSessionStore._();

  static const String guestUserId = 'guest';
  static const String _currentUserIdKey = 'auth_current_user_id';
  static const String _guestModeStartedKey = 'auth_guest_mode_started';
  static const String _guestMigrationPrefix = 'auth_guest_migrated_';

  static Future<String?> loadCurrentUserId() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_currentUserIdKey);
  }

  static Future<String> effectiveUserId() async {
    return await loadCurrentUserId() ?? guestUserId;
  }

  static Future<void> saveCurrentUserId(String userId) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_currentUserIdKey, userId);
  }

  static Future<void> startGuestSession() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_currentUserIdKey, guestUserId);
    await preferences.setBool(_guestModeStartedKey, true);
  }

  static Future<void> clearSession() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_currentUserIdKey);
  }

  static String scopedKey(String userId, String key) {
    return userId == guestUserId ? key : '$key.$userId';
  }

  static Future<bool> isGuestDataMigratedTo(String userId) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool('$_guestMigrationPrefix$userId') ?? false;
  }

  static Future<void> markGuestDataMigratedTo(String userId) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('$_guestMigrationPrefix$userId', true);
  }

  static Future<bool> hasLegacyGuestPreferences() async {
    final preferences = await SharedPreferences.getInstance();
    const legacyKeys = <String>[
      'profile_nickname',
      'profile_avatar_path',
      'profile_gender',
      'profile_age',
      'profile_height_cm',
      'home_target_weight_kg',
      'home_weight_entries',
    ];

    return legacyKeys.any(preferences.containsKey);
  }

  static Future<void> copyLegacyGuestPreferencesToUser(String userId) async {
    final preferences = await SharedPreferences.getInstance();
    const legacyKeys = <String>[
      'profile_nickname',
      'profile_avatar_path',
      'profile_gender',
      'profile_age',
      'profile_height_cm',
      'home_target_weight_kg',
      'home_weight_entries',
    ];

    for (final key in legacyKeys) {
      if (!preferences.containsKey(key)) {
        continue;
      }
      final targetKey = scopedKey(userId, key);
      final value = preferences.get(key);
      if (value is String) {
        await preferences.setString(targetKey, value);
      } else if (value is int) {
        await preferences.setInt(targetKey, value);
      } else if (value is double) {
        await preferences.setDouble(targetKey, value);
      } else if (value is bool) {
        await preferences.setBool(targetKey, value);
      } else if (value is List<String>) {
        await preferences.setStringList(targetKey, value);
      }
    }
  }

  static Future<String?> loadScopedString(String userId, String key) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(scopedKey(userId, key));
  }
}
