// lib/features/asset/domain/entities/asset_summary.dart
class AssetSummary {
  final double totalAssetValue;
  final double totalLoanAmount;
  final double netWorth;
  final Map<String, double> categoryValues;

  AssetSummary({
    required this.totalAssetValue,
    required this.totalLoanAmount,
    required this.netWorth,
    required this.categoryValues,
  });
}