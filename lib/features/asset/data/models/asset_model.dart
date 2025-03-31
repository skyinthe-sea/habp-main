// lib/features/asset/data/models/asset_model.dart
import '../../domain/entities/asset.dart';

class AssetModel extends Asset {
  AssetModel({
    required int id,
    required int userId,
    required int categoryId,
    required String categoryName,
    required String categoryType,
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
    bool isActive = true,
  }) : super(
    id: id,
    userId: userId,
    categoryId: categoryId,
    categoryName: categoryName,
    categoryType: categoryType,
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
    isActive: isActive,
  );

  factory AssetModel.fromMap(Map<String, dynamic> map, {required String categoryName, required String categoryType}) {
    return AssetModel(
      id: map['id'] as int,
      userId: map['user_id'] as int,
      categoryId: map['category_id'] as int,
      categoryName: categoryName,
      categoryType: categoryType,
      name: map['name'] as String,
      currentValue: (map['current_value'] as num).toDouble(),
      purchaseValue: map['purchase_value'] != null ? (map['purchase_value'] as num).toDouble() : null,
      purchaseDate: map['purchase_date'] as String?,
      interestRate: map['interest_rate'] != null ? (map['interest_rate'] as num).toDouble() : null,
      loanAmount: map['loan_amount'] != null ? (map['loan_amount'] as num).toDouble() : null,
      description: map['description'] as String?,
      location: map['location'] as String?,
      details: map['details'] as String?,
      iconType: map['icon_type'] as String?,
      isActive: (map['is_active'] as int) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'category_id': categoryId,
      'name': name,
      'current_value': currentValue,
      'purchase_value': purchaseValue,
      'purchase_date': purchaseDate,
      'interest_rate': interestRate,
      'loan_amount': loanAmount,
      'description': description,
      'location': location,
      'details': details,
      'icon_type': iconType,
      'is_active': isActive ? 1 : 0,
    };
  }
}