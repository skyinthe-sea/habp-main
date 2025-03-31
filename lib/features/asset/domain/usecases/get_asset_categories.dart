import '../../data/models/asset_category_model.dart';
import '../repositories/asset_repository.dart';

class GetAssetCategories {
  final AssetRepository repository;

  GetAssetCategories(this.repository);

  Future<List<AssetCategoryModel>> call() async {
    return await repository.getAssetCategories();
  }
}