class TrainingRecord {
  final int? id;
  final String date; // YYYY-MM-DD 格式
  final String muscleGroups; // 用逗号分隔，如 "胸,背,肩"
  final bool isAerobic;
  final int aerobicDuration; // 分钟数
  final String notes;
  final String createdAt; // 时间戳

  TrainingRecord({
    this.id,
    required this.date,
    required this.muscleGroups,
    required this.isAerobic,
    required this.aerobicDuration,
    required this.notes,
    required this.createdAt,
  });

  TrainingRecord copyWith({
    int? id,
    String? date,
    String? muscleGroups,
    bool? isAerobic,
    int? aerobicDuration,
    String? notes,
    String? createdAt,
  }) {
    return TrainingRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      muscleGroups: muscleGroups ?? this.muscleGroups,
      isAerobic: isAerobic ?? this.isAerobic,
      aerobicDuration: aerobicDuration ?? this.aerobicDuration,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // 从数据库 Map 转换为对象
  factory TrainingRecord.fromMap(Map<String, dynamic> map) {
    return TrainingRecord(
      id: map['id'] as int?,
      date: map['date'] as String,
      muscleGroups: map['muscleGroups'] as String,
      isAerobic: (map['isAerobic'] as int) == 1,
      aerobicDuration: map['aerobicDuration'] as int,
      notes: map['notes'] as String,
      createdAt: map['createdAt'] as String,
    );
  }

  // 转换为数据库 Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'muscleGroups': muscleGroups,
      'isAerobic': isAerobic ? 1 : 0,
      'aerobicDuration': aerobicDuration,
      'notes': notes,
      'createdAt': createdAt,
    };
  }

  // 便于调试的字符串表示
  @override
  String toString() {
    return 'TrainingRecord(id: $id, date: $date, muscleGroups: $muscleGroups, isAerobic: $isAerobic, aerobicDuration: $aerobicDuration, notes: $notes)';
  }
}
