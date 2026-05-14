import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/diet_record.dart';
import '../models/food_template.dart';
import '../models/meal_food_record.dart';
import '../models/training_record.dart';

class DatabaseService {
  static Database? _database;
  static Future<Database>? _dbInitFuture;

  static const String _trainingTable = 'training_records';
  static const String _dietTable = 'diet_records';
  static const String _foodTemplateTable = 'food_templates';

  static Future<Database> get database async {
    if (_database != null) {
      await _ensureAppSchema(_database!);
      return _database!;
    }

    final initFuture = _dbInitFuture ??= _initDatabase();

    try {
      _database = await initFuture;
      await _ensureAppSchema(_database!);
      return _database!;
    } catch (_) {
      _dbInitFuture = null;
      rethrow;
    }
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'fitness_app.db');

    return openDatabase(
      path,
      version: 3,
      onCreate: _createTables,
      onUpgrade: _upgradeDatabase,
    );
  }

  static Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_trainingTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        muscleGroups TEXT NOT NULL,
        isAerobic INTEGER NOT NULL,
        aerobicDuration INTEGER NOT NULL,
        notes TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $_dietTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        mealType TEXT NOT NULL,
        mealIndex INTEGER NOT NULL,
        mealLabel TEXT NOT NULL,
        foodTemplateId INTEGER,
        foodName TEXT NOT NULL,
        baseUnitType TEXT NOT NULL DEFAULT '',
        baseCarbs REAL NOT NULL DEFAULT 0,
        baseProtein REAL NOT NULL DEFAULT 0,
        baseFat REAL NOT NULL DEFAULT 0,
        consumedAmount REAL NOT NULL DEFAULT 0,
        consumedUnit TEXT NOT NULL DEFAULT '',
        actualCarbs REAL NOT NULL DEFAULT 0,
        actualProtein REAL NOT NULL DEFAULT 0,
        actualFat REAL NOT NULL DEFAULT 0,
        carbs REAL NOT NULL DEFAULT 0,
        protein REAL NOT NULL DEFAULT 0,
        fat REAL NOT NULL DEFAULT 0,
        calories REAL NOT NULL,
        notes TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $_foodTemplateTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        unitType TEXT NOT NULL,
        carbs REAL NOT NULL,
        protein REAL NOT NULL,
        fat REAL NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  static Future<void> _upgradeDatabase(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await _migrateDietTableToMealSchema(db);
    }

    await _ensureAppSchema(db);
  }

  static Future<void> _ensureAppSchema(Database db) async {
    await _ensureDietSchema(db);
    await _ensureFoodTemplateSchema(db);
  }

  static Future<void> _ensureDietSchema(Database db) async {
    final tableInfo = await db.rawQuery('PRAGMA table_info($_dietTable)');
    final columns = tableInfo
        .map((column) => column['name'] as String? ?? '')
        .where((name) => name.isNotEmpty)
        .toSet();

    if (!columns.contains('foodTemplateId')) {
      await db.execute(
        'ALTER TABLE $_dietTable ADD COLUMN foodTemplateId INTEGER',
      );
    }
    if (!columns.contains('baseUnitType')) {
      await db.execute(
        "ALTER TABLE $_dietTable ADD COLUMN baseUnitType TEXT NOT NULL DEFAULT ''",
      );
    }
    if (!columns.contains('baseCarbs')) {
      await db.execute(
        'ALTER TABLE $_dietTable ADD COLUMN baseCarbs REAL NOT NULL DEFAULT 0',
      );
    }
    if (!columns.contains('baseProtein')) {
      await db.execute(
        'ALTER TABLE $_dietTable ADD COLUMN baseProtein REAL NOT NULL DEFAULT 0',
      );
    }
    if (!columns.contains('baseFat')) {
      await db.execute(
        'ALTER TABLE $_dietTable ADD COLUMN baseFat REAL NOT NULL DEFAULT 0',
      );
    }
    if (!columns.contains('consumedAmount')) {
      await db.execute(
        'ALTER TABLE $_dietTable ADD COLUMN consumedAmount REAL NOT NULL DEFAULT 0',
      );
    }
    if (!columns.contains('consumedUnit')) {
      await db.execute(
        "ALTER TABLE $_dietTable ADD COLUMN consumedUnit TEXT NOT NULL DEFAULT ''",
      );
    }
    if (!columns.contains('actualCarbs')) {
      await db.execute(
        'ALTER TABLE $_dietTable ADD COLUMN actualCarbs REAL NOT NULL DEFAULT 0',
      );
    }
    if (!columns.contains('actualProtein')) {
      await db.execute(
        'ALTER TABLE $_dietTable ADD COLUMN actualProtein REAL NOT NULL DEFAULT 0',
      );
    }
    if (!columns.contains('actualFat')) {
      await db.execute(
        'ALTER TABLE $_dietTable ADD COLUMN actualFat REAL NOT NULL DEFAULT 0',
      );
    }

    if (!columns.contains('mealIndex')) {
      await db.execute(
        'ALTER TABLE $_dietTable ADD COLUMN mealIndex INTEGER NOT NULL DEFAULT 0',
      );
    }
    if (!columns.contains('mealLabel')) {
      await db.execute(
        "ALTER TABLE $_dietTable ADD COLUMN mealLabel TEXT NOT NULL DEFAULT ''",
      );
    }
    if (!columns.contains('carbs')) {
      await db.execute(
        'ALTER TABLE $_dietTable ADD COLUMN carbs REAL NOT NULL DEFAULT 0',
      );
    }
    if (!columns.contains('protein')) {
      await db.execute(
        'ALTER TABLE $_dietTable ADD COLUMN protein REAL NOT NULL DEFAULT 0',
      );
    }
    if (!columns.contains('fat')) {
      await db.execute(
        'ALTER TABLE $_dietTable ADD COLUMN fat REAL NOT NULL DEFAULT 0',
      );
    }

    await _backfillDietMealColumns(db);
    await _backfillDietConsumptionColumns(db);
  }

  static Future<void> _migrateDietTableToMealSchema(Database db) async {
    await _ensureDietSchema(db);
  }

  static Future<void> _ensureFoodTemplateSchema(Database db) async {
    final existingTable = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
      [_foodTemplateTable],
    );

    if (existingTable.isEmpty) {
      await db.execute('''
        CREATE TABLE $_foodTemplateTable (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          unitType TEXT NOT NULL,
          carbs REAL NOT NULL,
          protein REAL NOT NULL,
          fat REAL NOT NULL,
          createdAt TEXT NOT NULL
        )
      ''');
    }
  }

  static Future<void> _backfillDietMealColumns(Database db) async {
    final records = await db.query(
      _dietTable,
      columns: ['id', 'date', 'mealIndex', 'mealLabel', 'mealType'],
      orderBy: 'date ASC, createdAt ASC, id ASC',
    );

    final batch = db.batch();
    var needsCommit = false;

    for (final record in records) {
      final storedMealIndex = (record['mealIndex'] as num?)?.toInt() ?? 0;
      final storedMealLabel = record['mealLabel'] as String? ?? '';
      final storedMealType = record['mealType'] as String? ?? '';
      final resolvedMealIndex = _resolveMealIndex(
        storedMealIndex: storedMealIndex,
        storedMealLabel: storedMealLabel,
        storedMealType: storedMealType,
      );
      final resolvedMealLabel = _resolveMealLabel(
        mealIndex: resolvedMealIndex,
        storedMealLabel: storedMealLabel,
        storedMealType: storedMealType,
      );
      final resolvedMealType = storedMealType.isNotEmpty
          ? storedMealType
          : resolvedMealLabel;

      if (storedMealIndex == resolvedMealIndex &&
          storedMealLabel == resolvedMealLabel &&
          storedMealType == resolvedMealType) {
        continue;
      }

      needsCommit = true;
      batch.update(
        _dietTable,
        {
          'mealIndex': resolvedMealIndex,
          'mealLabel': resolvedMealLabel,
          'mealType': resolvedMealType,
        },
        where: 'id = ?',
        whereArgs: [record['id']],
      );
    }

    if (needsCommit) {
      await batch.commit(noResult: true);
    }
  }

  static Future<void> _backfillDietConsumptionColumns(Database db) async {
    final records = await db.query(
      _dietTable,
      columns: [
        'id',
        'carbs',
        'protein',
        'fat',
        'baseUnitType',
        'baseCarbs',
        'baseProtein',
        'baseFat',
        'consumedAmount',
        'consumedUnit',
        'actualCarbs',
        'actualProtein',
        'actualFat',
      ],
    );

    final batch = db.batch();
    var needsCommit = false;

    for (final record in records) {
      final baseUnitType = record['baseUnitType'] as String? ?? '';
      final consumedUnit = record['consumedUnit'] as String? ?? '';
      final consumedAmount =
          (record['consumedAmount'] as num?)?.toDouble() ?? 0;

      if (baseUnitType.isNotEmpty &&
          consumedUnit.isNotEmpty &&
          consumedAmount > 0) {
        continue;
      }

      final carbs = (record['carbs'] as num?)?.toDouble() ?? 0;
      final protein = (record['protein'] as num?)?.toDouble() ?? 0;
      final fat = (record['fat'] as num?)?.toDouble() ?? 0;

      needsCommit = true;
      batch.update(
        _dietTable,
        {
          'baseUnitType': 'perServing',
          'baseCarbs': carbs,
          'baseProtein': protein,
          'baseFat': fat,
          'consumedAmount': 1,
          'consumedUnit': '份',
          'actualCarbs': carbs,
          'actualProtein': protein,
          'actualFat': fat,
        },
        where: 'id = ?',
        whereArgs: [record['id']],
      );
    }

    if (needsCommit) {
      await batch.commit(noResult: true);
    }
  }

  static String _mealLabelForIndex(int index) {
    const labels = <String>[
      '\u7b2c\u4e00\u9910',
      '\u7b2c\u4e8c\u9910',
      '\u7b2c\u4e09\u9910',
      '\u7b2c\u56db\u9910',
      '\u7b2c\u4e94\u9910',
      '\u7b2c\u516d\u9910',
    ];

    if (index >= 1 && index <= labels.length) {
      return labels[index - 1];
    }

    return '\u7b2c$index\u9910';
  }

  static int _resolveMealIndex({
    required int storedMealIndex,
    required String storedMealLabel,
    required String storedMealType,
  }) {
    if (storedMealIndex > 0) {
      return storedMealIndex;
    }

    return _inferMealIndexFromText(storedMealLabel) ??
        _inferMealIndexFromText(storedMealType) ??
        1;
  }

  static String _resolveMealLabel({
    required int mealIndex,
    required String storedMealLabel,
    required String storedMealType,
  }) {
    if (storedMealLabel.isNotEmpty) {
      return storedMealLabel;
    }
    if (storedMealType.isNotEmpty) {
      return storedMealType;
    }

    return _mealLabelForIndex(mealIndex);
  }

  static int? _inferMealIndexFromText(String value) {
    if (value.isEmpty) {
      return null;
    }

    const aliases = <String, int>{
      '\u7b2c\u4e00\u9910': 1,
      '\u7b2c\u4e8c\u9910': 2,
      '\u7b2c\u4e09\u9910': 3,
      '\u7b2c\u56db\u9910': 4,
      '\u7b2c\u4e94\u9910': 5,
      '\u7b2c\u516d\u9910': 6,
      '\u65e9\u9910': 1,
      '\u5348\u9910': 2,
      '\u665a\u9910': 3,
      '\u52a0\u9910': 4,
    };

    final directMatch = aliases[value];
    if (directMatch != null) {
      return directMatch;
    }

    final match = RegExp(r'^第(\d+)餐$').firstMatch(value);
    if (match == null) {
      return null;
    }

    return int.tryParse(match.group(1) ?? '');
  }

  static Future<int> addTrainingRecord(TrainingRecord record) async {
    final db = await database;
    return db.insert(_trainingTable, record.toMap());
  }

  static Future<List<TrainingRecord>> getTrainingRecordsByDate(
    String date,
  ) async {
    final db = await database;
    final maps = await db.query(
      _trainingTable,
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'createdAt DESC',
    );
    return List.generate(maps.length, (i) => TrainingRecord.fromMap(maps[i]));
  }

  static Future<TrainingRecord?> getLatestTrainingRecordByDate(
    String date,
  ) async {
    final db = await database;
    final maps = await db.query(
      _trainingTable,
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'createdAt DESC, id DESC',
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return TrainingRecord.fromMap(maps.first);
  }

  static Future<List<TrainingRecord>> getTrainingRecordsDateRange(
    String startDate,
    String endDate,
  ) async {
    final db = await database;
    final maps = await db.query(
      _trainingTable,
      where: 'date BETWEEN ? AND ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date DESC, createdAt DESC',
    );
    return List.generate(maps.length, (i) => TrainingRecord.fromMap(maps[i]));
  }

  static Future<List<TrainingRecord>> getAllTrainingRecords() async {
    final db = await database;
    final maps = await db.query(
      _trainingTable,
      orderBy: 'date DESC, createdAt DESC',
    );
    return List.generate(maps.length, (i) => TrainingRecord.fromMap(maps[i]));
  }

  static Future<int> updateTrainingRecord(TrainingRecord record) async {
    final db = await database;
    return db.update(
      _trainingTable,
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  static Future<TrainingRecord> upsertTrainingRecordByDate(
    TrainingRecord record,
  ) async {
    final existing = record.id != null
        ? record
        : await getLatestTrainingRecordByDate(record.date);

    if (existing?.id != null) {
      final updatedRecord = record.copyWith(
        id: existing!.id,
        createdAt: existing.createdAt,
      );
      await updateTrainingRecord(updatedRecord);
      return updatedRecord;
    }

    final newId = await addTrainingRecord(record);
    return record.copyWith(id: newId);
  }

  static Future<int> deleteTrainingRecord(int id) async {
    final db = await database;
    return db.delete(_trainingTable, where: 'id = ?', whereArgs: [id]);
  }

  static Future<int> addDietRecord(DietRecord record) async {
    final db = await database;
    return db.insert(_dietTable, record.toMap());
  }

  static Future<int> addFoodTemplate(FoodTemplate template) async {
    final db = await database;
    return db.insert(_foodTemplateTable, template.toMap());
  }

  static Future<int> deleteFoodTemplate(int id) async {
    final db = await database;
    return db.delete(_foodTemplateTable, where: 'id = ?', whereArgs: [id]);
  }

  static Future<List<FoodTemplate>> getAllFoodTemplates() async {
    final db = await database;
    final maps = await db.query(
      _foodTemplateTable,
      orderBy: 'createdAt DESC, id DESC',
    );
    return List.generate(maps.length, (i) => FoodTemplate.fromMap(maps[i]));
  }

  static Future<int> addMealFoodRecord(MealFoodRecord record) async {
    final db = await database;
    return db.insert(_dietTable, record.toMap());
  }

  static Future<int> updateMealFoodRecord(MealFoodRecord record) async {
    final db = await database;
    return db.update(
      _dietTable,
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  static Future<int> deleteMealFoodRecord(int id) async {
    final db = await database;
    return db.delete(_dietTable, where: 'id = ?', whereArgs: [id]);
  }

  static Future<List<MealFoodRecord>> getMealFoodRecordsByDate(
    String dateKey,
  ) async {
    final db = await database;
    final maps = await db.query(
      _dietTable,
      where: 'date = ?',
      whereArgs: [dateKey],
      orderBy: 'mealIndex ASC, createdAt ASC, id ASC',
    );
    return List.generate(maps.length, (i) => MealFoodRecord.fromMap(maps[i]));
  }

  static Future<List<DietRecord>> getDietRecordsByDate(String date) async {
    final db = await database;
    final maps = await db.query(
      _dietTable,
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'mealIndex ASC, createdAt ASC, id ASC',
    );
    return List.generate(maps.length, (i) => DietRecord.fromMap(maps[i]));
  }

  static Future<List<DietRecord>> getDietRecordsDateRange(
    String startDate,
    String endDate,
  ) async {
    final db = await database;
    final maps = await db.query(
      _dietTable,
      where: 'date BETWEEN ? AND ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date DESC, mealIndex ASC, createdAt ASC, id ASC',
    );
    return List.generate(maps.length, (i) => DietRecord.fromMap(maps[i]));
  }

  static Future<List<DietRecord>> getAllDietRecords() async {
    final db = await database;
    final maps = await db.query(
      _dietTable,
      orderBy: 'date DESC, mealIndex ASC, createdAt ASC, id ASC',
    );
    return List.generate(maps.length, (i) => DietRecord.fromMap(maps[i]));
  }

  static Future<double> getTotalCaloriesByDate(String date) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(calories) as total FROM $_dietTable WHERE date = ?',
      [date],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  static Future<int> updateDietRecord(DietRecord record) async {
    final db = await database;
    return db.update(
      _dietTable,
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  static Future<int> deleteDietRecord(int id) async {
    final db = await database;
    return db.delete(_dietTable, where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> resequenceDietRecordsByDate(String date) async {
    final db = await database;
    await db.transaction((txn) async {
      final records = await txn.query(
        _dietTable,
        columns: ['id', 'mealIndex', 'mealLabel', 'mealType'],
        where: 'date = ?',
        whereArgs: [date],
        orderBy: 'mealIndex ASC, createdAt ASC, id ASC',
      );

      final batch = txn.batch();
      var needsCommit = false;
      for (final record in records) {
        final storedMealIndex = (record['mealIndex'] as num?)?.toInt() ?? 0;
        final storedMealLabel = record['mealLabel'] as String? ?? '';
        final storedMealType = record['mealType'] as String? ?? '';
        final resolvedMealIndex = _resolveMealIndex(
          storedMealIndex: storedMealIndex,
          storedMealLabel: storedMealLabel,
          storedMealType: storedMealType,
        );
        final resolvedMealLabel = _resolveMealLabel(
          mealIndex: resolvedMealIndex,
          storedMealLabel: storedMealLabel,
          storedMealType: storedMealType,
        );
        final resolvedMealType = storedMealType.isNotEmpty
            ? storedMealType
            : resolvedMealLabel;

        if (storedMealIndex == resolvedMealIndex &&
            storedMealLabel == resolvedMealLabel &&
            storedMealType == resolvedMealType) {
          continue;
        }

        needsCommit = true;
        batch.update(
          _dietTable,
          {
            'mealIndex': resolvedMealIndex,
            'mealLabel': resolvedMealLabel,
            'mealType': resolvedMealType,
          },
          where: 'id = ?',
          whereArgs: [record['id']],
        );
      }
      if (needsCommit) {
        await batch.commit(noResult: true);
      }
    });
  }

  static String getTodayDateString() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  static String getCurrentTimestamp() {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
  }
}
