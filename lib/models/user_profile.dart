enum UserGender { male, female }

extension UserGenderLabel on UserGender {
  String get label {
    switch (this) {
      case UserGender.male:
        return '男';
      case UserGender.female:
        return '女';
    }
  }

  String get storageValue {
    switch (this) {
      case UserGender.male:
        return 'male';
      case UserGender.female:
        return 'female';
    }
  }
}

UserGender? userGenderFromStorage(String? value) {
  switch (value) {
    case 'male':
      return UserGender.male;
    case 'female':
      return UserGender.female;
    default:
      return null;
  }
}

class UserProfile {
  const UserProfile({
    this.nickname = '',
    this.avatarPath,
    this.gender,
    this.age,
    this.heightCm,
  });

  static const String guestName = '游客';

  final String nickname;
  final String? avatarPath;
  final UserGender? gender;
  final int? age;
  final double? heightCm;

  String get displayName {
    final trimmed = nickname.trim();
    return trimmed.isEmpty ? guestName : trimmed;
  }

  String get personalInfoSummary {
    final items = <String>[];
    if (gender != null) {
      items.add(gender!.label);
    }
    if (age != null) {
      items.add('$age 岁');
    }
    if (heightCm != null) {
      final roundedHeight = heightCm!.roundToDouble();
      final text = (heightCm! - roundedHeight).abs() < 0.0001
          ? roundedHeight.toStringAsFixed(0)
          : heightCm!.toStringAsFixed(1);
      items.add('$text cm');
    }
    return items.isEmpty ? '未填写' : items.join(' · ');
  }

  UserProfile copyWith({
    String? nickname,
    String? avatarPath,
    UserGender? gender,
    int? age,
    double? heightCm,
    bool clearAvatar = false,
    bool clearGender = false,
    bool clearAge = false,
    bool clearHeightCm = false,
  }) {
    return UserProfile(
      nickname: nickname ?? this.nickname,
      avatarPath: clearAvatar ? null : (avatarPath ?? this.avatarPath),
      gender: clearGender ? null : (gender ?? this.gender),
      age: clearAge ? null : (age ?? this.age),
      heightCm: clearHeightCm ? null : (heightCm ?? this.heightCm),
    );
  }
}
