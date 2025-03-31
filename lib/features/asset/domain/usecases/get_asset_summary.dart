import '../entities/asset_summary.dart';
import '../repositories/asset_repository.dart';

class GetAssetSummary {
  final AssetRepository repository;

  GetAssetSummary(this.repository);

  Future<AssetSummary> call(int userId) async {
    return await repository.getAssetSummary(userId);
  }
}