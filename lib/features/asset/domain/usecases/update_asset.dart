import '../repositories/asset_repository.dart';

class UpdateAsset {
  final AssetRepository repository;

  UpdateAsset(this.repository);

  Future<bool> call({
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
    return await repository.updateAsset(
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
}