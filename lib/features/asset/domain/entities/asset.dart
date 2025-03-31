// lib/features/asset/domain/entities/asset.dart
class Asset {
  final int id;
  final int userId;
  final int categoryId;
  final String categoryName;
  final String categoryType;
  final String name;
  final double currentValue;
  final double? purchaseValue;
  final String? purchaseDate;
  final double? interestRate;
  final double? loanAmount;
  final String? description;
  final String? location;
  final String? details;
  final String? iconType;
  final bool isActive;

  Asset({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.categoryName,
    required this.categoryType,
    required this.name,
    required this.currentValue,
    this.purchaseValue,
    this.purchaseDate,
    this.interestRate,
    this.loanAmount,
    this.description,
    this.location,
    this.details,
    this.iconType,
    this.isActive = true,
  });
}