// lib/features/asset/domain/repositories/asset_repository.dart
import '../entities/asset.dart';
import '../entities/asset_summary.dart';
import '../../data/models/asset_category_model.dart';

abstract class AssetRepository {
  Future<List<Asset>> getAssets(int userId);
  Future<AssetSummary> getAssetSummary(int userId);
  Future<List<AssetCategoryModel>> getAssetCategories();
  Future<Asset?> getAssetById(int assetId);

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
  });

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
  });

  Future<bool> deleteAsset(int assetId);
}