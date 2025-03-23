import '../entities/category.dart';

class CategoryModel extends Category {
  CategoryModel({
    required int id,
    required String name,
    required String type,
    required int isFixed,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super(
    id: id,
    name: name,
    type: type,
    isFixed: isFixed,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      isFixed: json['is_fixed'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}