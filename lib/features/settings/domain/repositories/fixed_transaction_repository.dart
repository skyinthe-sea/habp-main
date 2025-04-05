import '../../data/datasources/fixed_transaction_local_data_source.dart';

abstract class FixedTransactionRepository {
  Future<List<CategoryWithSettings>> getFixedCategories();
  Future<List<CategoryWithSettings>> getFixedCategoriesByType(String type);
  Future<List<FixedTransactionSetting>> getSettingsForCategory(int categoryId);
  Future<FixedTransactionSetting?> getLatestSettingForCategory(int categoryId);
  Future<FixedTransactionSetting?> getSettingForCategoryAndDate(int categoryId, DateTime date);
  Future<bool> addSetting(FixedTransactionSetting setting);
}

class FixedTransactionRepositoryImpl implements FixedTransactionRepository {
  final FixedTransactionLocalDataSource localDataSource;

  FixedTransactionRepositoryImpl({required this.localDataSource});

  @override
  Future<List<CategoryWithSettings>> getFixedCategories() async {
    return await localDataSource.getFixedCategories();
  }

  @override
  Future<List<CategoryWithSettings>> getFixedCategoriesByType(String type) async {
    return await localDataSource.getFixedCategoriesByType(type);
  }

  @override
  Future<List<FixedTransactionSetting>> getSettingsForCategory(int categoryId) async {
    return await localDataSource.getSettingsForCategory(categoryId);
  }

  @override
  Future<FixedTransactionSetting?> getLatestSettingForCategory(int categoryId) async {
    return await localDataSource.getLatestSettingForCategory(categoryId);
  }

  @override
  Future<FixedTransactionSetting?> getSettingForCategoryAndDate(int categoryId, DateTime date) async {
    return await localDataSource.getSettingForCategoryAndDate(categoryId, date);
  }

  @override
  Future<bool> addSetting(FixedTransactionSetting setting) async {
    final result = await localDataSource.addSetting(setting);
    return result > 0;
  }
}