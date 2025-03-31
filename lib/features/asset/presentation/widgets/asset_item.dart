// lib/features/asset/presentation/widgets/asset_item.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/asset.dart';

class AssetItem extends StatelessWidget {
  final Asset asset;
  final VoidCallback onTap;

  const AssetItem({
    Key? key,
    required this.asset,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,###', 'ko_KR');

    // 애셋 타입별 아이콘과 색상 결정
    final (IconData assetIcon, Color assetColor) = _getAssetIconAndColor();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // 왼쪽: 자산 아이콘
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: assetColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  assetIcon,
                  color: assetColor,
                  size: 28,
                ),
              ),
            ),

            const SizedBox(width: 16),

            // 중앙: 자산 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: assetColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          asset.categoryName,
                          style: TextStyle(
                            color: assetColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (asset.loanAmount != null && asset.loanAmount! > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '대출잔액 ${currencyFormat.format(asset.loanAmount!.toInt())}원',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    asset.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (asset.location != null && asset.location!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      asset.location!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // 오른쪽: 가격 정보
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${currencyFormat.format(asset.currentValue.toInt())}원',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                // 구매가가 있는 경우, 현재가와의 차이 표시
                if (asset.purchaseValue != null && asset.purchaseValue! > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        asset.currentValue >= asset.purchaseValue!
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        color: asset.currentValue >= asset.purchaseValue!
                            ? Colors.green
                            : Colors.red,
                        size: 12,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        _calculateChangePercentage(),
                        style: TextStyle(
                          fontSize: 12,
                          color: asset.currentValue >= asset.purchaseValue!
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _calculateChangePercentage() {
    if (asset.purchaseValue == null || asset.purchaseValue! <= 0) {
      return '0%';
    }

    final change = asset.currentValue - asset.purchaseValue!;
    final percentage = (change / asset.purchaseValue!) * 100;

    return '${percentage >= 0 ? '+' : ''}${percentage.toStringAsFixed(1)}%';
  }

  (IconData, Color) _getAssetIconAndColor() {
    switch (asset.categoryName) {
      case '부동산':
        return (Icons.home, AppColors.cate1);
      case '자동차':
        return (Icons.directions_car, AppColors.cate2);
      case '주식':
        return (Icons.show_chart, AppColors.cate3);
      case '가상화폐':
        return (Icons.currency_bitcoin, AppColors.cate4);
      case '현금':
        return (Icons.account_balance_wallet, AppColors.cate5);
      case '귀금속':
        return (Icons.diamond, AppColors.cate6);
      case '적금':
        return (Icons.savings, AppColors.cate7);
      case '예금':
        return (Icons.attach_money, AppColors.cate8);
      default:
        return (Icons.category, AppColors.primary);
    }
  }
}