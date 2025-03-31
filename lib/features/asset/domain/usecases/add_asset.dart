import '../repositories/asset_repository.dart';

class AddAsset {
  final AssetRepository repository;

  AddAsset(this.repository);

  Future<int?> call({
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
    return await repository.addAsset(
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
}