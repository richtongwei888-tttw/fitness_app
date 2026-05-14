import '../models/food_template.dart';
import 'database_service.dart';

abstract class FoodTemplateRepository {
  Future<List<FoodTemplate>> getAll();

  Future<int> addTemplate(FoodTemplate template);

  Future<int> deleteTemplate(int id);
}

class DatabaseFoodTemplateRepository implements FoodTemplateRepository {
  DatabaseFoodTemplateRepository._();

  static final DatabaseFoodTemplateRepository instance =
      DatabaseFoodTemplateRepository._();

  @override
  Future<List<FoodTemplate>> getAll() {
    return DatabaseService.getAllFoodTemplates();
  }

  @override
  Future<int> addTemplate(FoodTemplate template) {
    return DatabaseService.addFoodTemplate(template);
  }

  @override
  Future<int> deleteTemplate(int id) {
    return DatabaseService.deleteFoodTemplate(id);
  }
}
