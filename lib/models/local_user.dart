class LocalUser {
  const LocalUser({
    required this.userId,
    required this.username,
    required this.email,
    required this.password,
    this.avatarPath,
    required this.createdAt,
  });

  final String userId;
  final String username;
  final String email;
  final String password;
  final String? avatarPath;
  final String createdAt;

  LocalUser copyWith({
    String? userId,
    String? username,
    String? email,
    String? password,
    String? avatarPath,
    String? createdAt,
    bool clearAvatar = false,
  }) {
    return LocalUser(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      avatarPath: clearAvatar ? null : (avatarPath ?? this.avatarPath),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory LocalUser.fromMap(Map<String, dynamic> map) {
    return LocalUser(
      userId: map['userId'] as String? ?? '',
      username: map['username'] as String? ?? '',
      email: map['email'] as String? ?? '',
      password: map['password'] as String? ?? '',
      avatarPath: map['avatarPath'] as String?,
      createdAt: map['createdAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'username': username,
      'email': email,
      'password': password,
      'avatarPath': avatarPath,
      'createdAt': createdAt,
    };
  }
}
