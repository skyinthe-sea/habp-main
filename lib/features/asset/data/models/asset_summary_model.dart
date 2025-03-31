import '../../domain/entities/asset_summary.dart';

class AssetSummaryModel extends AssetSummary {
  AssetSummaryModel({
    required double totalAssetValue,
    required double totalLoanAmount,
    required double netWorth,
    required Map<String, double> categoryValues,
  }) : super(
    totalAssetValue: totalAssetValue,
    totalLoanAmount: totalLoanAmount,
    netWorth: netWorth,
    categoryValues: categoryValues,
  );

  factory AssetSummaryModel.empty() {
    return AssetSummaryModel(
      totalAssetValue: 0.0,
      totalLoanAmount: 0.0,
      netWorth: 0.0,
      categoryValues: {},
    );
  }
}