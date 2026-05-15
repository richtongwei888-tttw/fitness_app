import '../database/database_service.dart';
import '../models/local_user.dart';
import 'auth_session_store.dart';

class LocalAuthException implements Exception {
  const LocalAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class LocalAuthStore {
  const LocalAuthStore();

  Future<String?> loadCurrentUserId() {
    return AuthSessionStore.loadCurrentUserId();
  }

  Future<void> continueAsGuest() {
    return AuthSessionStore.startGuestSession();
  }

  Future<void> logout() {
    // Only clear the active local session. User-owned business data stays in
    // SQLite/SharedPreferences and can be loaded again after the next login.
    return AuthSessionStore.clearSession();
  }

  Future<bool> isGuestSession() async {
    return await AuthSessionStore.effectiveUserId() ==
        AuthSessionStore.guestUserId;
  }

  Future<LocalUser?> loadCurrentUser() async {
    final userId = await AuthSessionStore.loadCurrentUserId();
    if (userId == null || userId == AuthSessionStore.guestUserId) {
      return null;
    }
    return DatabaseService.getUserById(userId);
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    final normalizedUsername = username.trim();
    if (normalizedUsername.isEmpty || password.isEmpty) {
      throw const LocalAuthException('请输入账号和密码');
    }

    final user = await DatabaseService.getUserByUsername(normalizedUsername);
    if (user == null || user.password != password) {
      throw const LocalAuthException('账号或密码不正确');
    }

    await AuthSessionStore.saveCurrentUserId(user.userId);
  }

  Future<LocalUser> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final normalizedUsername = username.trim();
    final normalizedEmail = email.trim();
    if (normalizedUsername.isEmpty ||
        normalizedEmail.isEmpty ||
        password.isEmpty) {
      throw const LocalAuthException('请填写账号、邮箱和密码');
    }
    if (password.length < 4) {
      throw const LocalAuthException('密码至少 4 位');
    }

    final existing = await DatabaseService.getUserByUsername(
      normalizedUsername,
    );
    if (existing != null) {
      throw const LocalAuthException('账号已存在，请换一个账号');
    }

    final now = DatabaseService.getCurrentTimestamp();
    final user = LocalUser(
      userId: 'user_${DateTime.now().microsecondsSinceEpoch}',
      username: normalizedUsername,
      email: normalizedEmail,
      password: password,
      createdAt: now,
    );

    await DatabaseService.addUser(user);
    await AuthSessionStore.saveCurrentUserId(user.userId);
    return user;
  }

  Future<bool> hasMigratableGuestData() {
    return DatabaseService.hasGuestBusinessData();
  }

  Future<void> migrateGuestDataToUser(String userId) {
    return DatabaseService.copyGuestDataToUser(userId);
  }

  Future<LocalUser> updateCurrentUsername(String username) async {
    final user = await loadCurrentUser();
    if (user == null) {
      throw const LocalAuthException('游客模式不能修改用户名');
    }

    final normalizedUsername = username.trim();
    if (normalizedUsername.isEmpty) {
      throw const LocalAuthException('用户名不能为空');
    }

    final existing = await DatabaseService.getUserByUsername(
      normalizedUsername,
    );
    if (existing != null && existing.userId != user.userId) {
      throw const LocalAuthException('账号已存在，请换一个用户名');
    }

    final updatedUser = user.copyWith(username: normalizedUsername);
    await DatabaseService.updateUser(updatedUser);
    return updatedUser;
  }

  Future<LocalUser?> updateCurrentAvatarPath(String? avatarPath) async {
    final user = await loadCurrentUser();
    if (user == null) {
      return null;
    }
    final updatedUser = user.copyWith(
      avatarPath: avatarPath,
      clearAvatar: avatarPath == null || avatarPath.isEmpty,
    );
    await DatabaseService.updateUser(updatedUser);
    return updatedUser;
  }
}
