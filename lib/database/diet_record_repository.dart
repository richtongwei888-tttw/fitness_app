import '../models/diet_record.dart';
import 'database_service.dart';

abstract class DietRecordRepository {
  Future<List<DietRecord>> getByDate(String date);

  Future<int> addRecord(DietRecord record);

  Future<int> deleteRecord(int id);

  Future<void> resequenceForDate(String date);
}

class DatabaseDietRecordRepository implements DietRecordRepository {
  DatabaseDietRecordRepository._();

  static final DatabaseDietRecordRepository instance =
      DatabaseDietRecordRepository._();

  @override
  Future<List<DietRecord>> getByDate(String date) {
    return DatabaseService.getDietRecordsByDate(date);
  }

  @override
  Future<int> addRecord(DietRecord record) {
    return DatabaseService.addDietRecord(record);
  }

  @override
  Future<int> deleteRecord(int id) {
    return DatabaseService.deleteDietRecord(id);
  }

  @override
  Future<void> resequenceForDate(String date) {
    return DatabaseService.resequenceDietRecordsByDate(date);
  }
}
