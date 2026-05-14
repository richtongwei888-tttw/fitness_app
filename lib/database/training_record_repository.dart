import '../models/training_record.dart';
import 'database_service.dart';

abstract class TrainingRecordRepository {
  Future<TrainingRecord?> getByDate(String date);

  Future<TrainingRecord> saveForDate(TrainingRecord record);
}

class DatabaseTrainingRecordRepository implements TrainingRecordRepository {
  DatabaseTrainingRecordRepository._();

  static final DatabaseTrainingRecordRepository instance =
      DatabaseTrainingRecordRepository._();

  @override
  Future<TrainingRecord?> getByDate(String date) {
    return DatabaseService.getLatestTrainingRecordByDate(date);
  }

  @override
  Future<TrainingRecord> saveForDate(TrainingRecord record) {
    return DatabaseService.upsertTrainingRecordByDate(record);
  }
}
