import '../../data/datasources/fixed_transaction_local_data_source.dart';

abstract class FixedTransactionRepository {
  Future<List<CategoryWithSettings>> getFixedCategories();
  Future<List<CategoryWithSettings>> getFixedCategoriesByType(String type);
  Future<List<FixedTransactionSetting>> getSettingsForCategory(int categoryId);
  Future<FixedTransactionSetting?> getLatestSettingForCategory(int categoryId);
  Future<FixedTransactionSetting?> getSettingForCategoryAndDate(int categoryId, DateTime date);
  Future<bool> addSetting(FixedTransactionSetting setting);

  // New methods
  Future<int> addCategory(Category category);
  Future<bool> deleteFixedTransaction(int categoryId);
  Future<bool> categoryExists(String name, String type);
  Future<bool> createFixedTransaction({
    required String name,
    required String type,
    required double amount,
    required DateTime effectiveFrom,
  });
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

  @override
  Future<int> addCategory(Category category) async {
    return await localDataSource.addCategory(category);
  }

  @override
  Future<bool> deleteFixedTransaction(int categoryId) async {
    return await localDataSource.deleteFixedTransaction(categoryId);
  }

  @override
  Future<bool> categoryExists(String name, String type) async {
    return await localDataSource.categoryExists(name, type);
  }

  @override
  Future<bool> createFixedTransaction({
    required String name,
    required String type,
    required double amount,
    required DateTime effectiveFrom,
  }) async {
    try {
      // 1. Check if category already exists
      final exists = await categoryExists(name, type);
      if (exists) {
        return false;
      }

      // 2. Create category
      final now = DateTime.now();
      final category = Category(
        name: name,
        type: type,
        isFixed: 1,
        createdAt: now,
        updatedAt: now,
      );

      final categoryId = await addCategory(category);
      if (categoryId <= 0) {
        return false;
      }

      // 3. Create fixed transaction setting
      final setting = FixedTransactionSetting(
        categoryId: categoryId,
        amount: amount,
        effectiveFrom: effectiveFrom,
        createdAt: now,
        updatedAt: now,
      );

      final settingResult = await addSetting(setting);

      return settingResult;
    } catch (e) {
      return false;
    }
  }
}