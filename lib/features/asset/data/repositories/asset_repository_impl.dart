// lib/features/asset/data/repositories/asset_repository_impl.dart
import '../../domain/entities/asset.dart';
import '../../domain/entities/asset_summary.dart';
import '../../domain/repositories/asset_repository.dart';
import '../datasources/asset_local_data_source.dart';
import '../models/asset_category_model.dart';

class AssetRepositoryImpl implements AssetRepository {
  final AssetLocalDataSource localDataSource;

  AssetRepositoryImpl({required this.localDataSource});

  @override
  Future<List<Asset>> getAssets(int userId) async {
    final result = await localDataSource.getAssets(userId);
    return result;
  }

  @override
  Future<AssetSummary> getAssetSummary(int userId) async {
    return await localDataSource.getAssetSummary(userId);
  }

  @override
  Future<List<AssetCategoryModel>> getAssetCategories() async {
    return await localDataSource.getAssetCategories();
  }

  @override
  Future<Asset?> getAssetById(int assetId) async {
    return await localDataSource.getAssetById(assetId);
  }

  @override
  Future<int?> addAsset({
    required int userId,
    required int categoryId,
    required String name,
    required double currentValue,
    double? purchaseValue,
    String? purchaseDate,
    double? interestRate,
    double? loanAmount,
    String? description,
    String? location,
    String? details,
    String? iconType,
  }) async {
    return await localDataSource.addAsset(
      userId: userId,
      categoryId: categoryId,
      name: name,
      currentValue: currentValue,
      purchaseValue: purchaseValue,
      purchaseDate: purchaseDate,
      interestRate: interestRate,
      loanAmount: loanAmount,
      description: description,
      location: location,
      details: details,
      iconType: iconType,
    );
  }

  @override
  Future<bool> updateAsset({
    required int assetId,
    int? categoryId,
    String? name,
    double? currentValue,
    double? purchaseValue,
    String? purchaseDate,
    double? interestRate,
    double? loanAmount,
    String? description,
    String? location,
    String? details,
    String? iconType,
  }) async {
    return await localDataSource.updateAsset(
      assetId: assetId,
      categoryId: categoryId,
      name: name,
      currentValue: currentValue,
      purchaseValue: purchaseValue,
      purchaseDate: purchaseDate,
      interestRate: interestRate,
      loanAmount: loanAmount,
      description: description,
      location: location,
      details: details,
      iconType: iconType,
    );
  }

  @override
  Future<bool> deleteAsset(int assetId) async {
    return await localDataSource.deleteAsset(assetId);
  }
}