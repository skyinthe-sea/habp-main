import '../repositories/asset_repository.dart';

class DeleteAsset {
  final AssetRepository repository;

  DeleteAsset(this.repository);

  Future<bool> call(int assetId) async {
    return await repository.deleteAsset(assetId);
  }
}