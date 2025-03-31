// lib/features/asset/domain/usecases/get_assets.dart
import '../entities/asset.dart';
import '../repositories/asset_repository.dart';

class GetAssets {
  final AssetRepository repository;

  GetAssets(this.repository);

  Future<List<Asset>> call(int userId) async {
    return await repository.getAssets(userId);
  }
}