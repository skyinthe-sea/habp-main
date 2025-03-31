import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/asset.dart';

class AssetIconVisualizer extends StatelessWidget {
  final Asset asset;

  const AssetIconVisualizer({
    Key? key,
    required this.asset,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 자산 유형에 따라 다른 시각화 위젯 반환
    switch (asset.categoryName) {
      case '부동산':
        return _buildRealEstateVisualizer();
      case '자동차':
        return _buildCarVisualizer();
      case '주식':
        return _buildStockVisualizer();
      case '가상화폐':
        return _buildCryptoVisualizer();
      case '현금':
        return _buildCashVisualizer();
      case '귀금속':
        return _buildGoldVisualizer();
      case '적금':
      case '예금':
        return _buildSavingsVisualizer();
      default:
        return _buildDefaultVisualizer();
    }
  }

  Widget _buildRealEstateVisualizer() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: AppColors.cate1.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          // 집 그림
          Center(
            child: Icon(
              Icons.home,
              size: 100,
              color: AppColors.cate1.withOpacity(0.5),
            ),
          ),

          // 부동산 정보
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    asset.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (asset.location != null && asset.location!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            asset.location!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarVisualizer() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: AppColors.cate2.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          // 차 애니메이션 효과
          AnimatedPositioned(
            duration: const Duration(seconds: 6),
            left: 0,
            right: 0,
            top: 50,
            curve: Curves.easeInOut,
            child: Icon(
              Icons.directions_car,
              size: 80,
              color: AppColors.cate2.withOpacity(0.7),
            ),
          ),

          // 도로 효과
          Positioned(
            bottom: 40,
            left: 16,
            right: 16,
            height: 5,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // 차량 정보
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                asset.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockVisualizer() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: AppColors.cate3.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: CustomPaint(
        size: const Size(double.infinity, 180),
        painter: StockChartPainter(color: AppColors.cate3),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              asset.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppColors.cate3,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCryptoVisualizer() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: AppColors.cate4.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          // 비트코인 심볼 배경
          Center(
            child: Icon(
              Icons.currency_bitcoin,
              size: 120,
              color: AppColors.cate4.withOpacity(0.2),
            ),
          ),

          // 가상화폐 정보
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.cate4.withOpacity(0.8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                asset.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashVisualizer() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: AppColors.cate5.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          // 돈 심볼 애니메이션
          Center(
            child: Icon(
              Icons.account_balance_wallet,
              size: 100,
              color: AppColors.cate5.withOpacity(0.5),
            ),
          ),

          // 현금 정보
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                asset.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoldVisualizer() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.amber.shade200,
            Colors.amber.shade300,
            Colors.amber.shade400,
            Colors.amber.shade500,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          // 보석 심볼
          Center(
            child: Icon(
              Icons.diamond,
              size: 100,
              color: Colors.white.withOpacity(0.7),
            ),
          ),

          // 귀금속 정보
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                asset.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.amber.shade800,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsVisualizer() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: AppColors.cate7.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          // 저축 심볼
          Center(
            child: Icon(
              Icons.savings,
              size: 100,
              color: AppColors.cate7.withOpacity(0.5),
            ),
          ),

          // 저축 정보
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    asset.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (asset.interestRate != null && asset.interestRate! > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      '이자율: ${asset.interestRate!.toStringAsFixed(2)}%',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultVisualizer() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.category,
              size: 80,
              color: AppColors.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              asset.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 주식 차트 CustomPainter
class StockChartPainter extends CustomPainter {
  final Color color;

  StockChartPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final path = Path();

    // 랜덤같은 주식 차트 그리기
    path.moveTo(0, height * 0.5);
    path.lineTo(width * 0.1, height * 0.45);
    path.lineTo(width * 0.2, height * 0.6);
    path.lineTo(width * 0.3, height * 0.4);
    path.lineTo(width * 0.4, height * 0.55);
    path.lineTo(width * 0.5, height * 0.35);
    path.lineTo(width * 0.6, height * 0.45);
    path.lineTo(width * 0.7, height * 0.3);
    path.lineTo(width * 0.8, height * 0.5);
    path.lineTo(width * 0.9, height * 0.35);
    path.lineTo(width, height * 0.4);

    canvas.drawPath(path, paint);

    // 아래쪽 영역 채우기
    final fillPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final fillPath = Path.from(path);
    fillPath.lineTo(width, height);
    fillPath.lineTo(0, height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}