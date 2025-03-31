// lib/features/asset/data/models/asset_category_model.dart
class AssetCategoryModel {
  final int id;
  final String name;
  final String type;
  final int isFixed;

  AssetCategoryModel({
    required this.id,
    required this.name,
    required this.type,
    required this.isFixed,
  });

  factory AssetCategoryModel.fromMap(Map<String, dynamic> map) {
    return AssetCategoryModel(
      id: map['id'] as int,
      name: map['name'] as String,
      type: map['type'] as String,
      isFixed: map['is_fixed'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'is_fixed': isFixed,
    };
  }
}