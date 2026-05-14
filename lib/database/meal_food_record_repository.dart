import '../models/meal_food_record.dart';
import 'database_service.dart';

abstract class MealFoodRecordRepository {
  Future<List<MealFoodRecord>> getByDate(String dateKey);

  Future<int> addRecord(MealFoodRecord record);

  Future<int> updateRecord(MealFoodRecord record);

  Future<int> deleteRecord(int id);
}

class DatabaseMealFoodRecordRepository implements MealFoodRecordRepository {
  DatabaseMealFoodRecordRepository._();

  static final DatabaseMealFoodRecordRepository instance =
      DatabaseMealFoodRecordRepository._();

  @override
  Future<List<MealFoodRecord>> getByDate(String dateKey) {
    return DatabaseService.getMealFoodRecordsByDate(dateKey);
  }

  @override
  Future<int> addRecord(MealFoodRecord record) {
    return DatabaseService.addMealFoodRecord(record);
  }

  @override
  Future<int> updateRecord(MealFoodRecord record) {
    return DatabaseService.updateMealFoodRecord(record);
  }

  @override
  Future<int> deleteRecord(int id) {
    return DatabaseService.deleteMealFoodRecord(id);
  }
}
