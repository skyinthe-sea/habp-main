import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../controllers/expense_controller.dart';

class BudgetPieChart extends StatelessWidget {
  final ExpenseController controller;

  const BudgetPieChart({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.budgetStatusList.isEmpty) {
        return _buildEmptyState();
      }

      // 예산이 0인 항목 필터링
      final budgetItems = controller.budgetStatusList
          .where((item) => item.budgetAmount > 0)
          .toList();

      if (budgetItems.isEmpty) {
        return _buildEmptyState();
      }

      return Container(
        height: 280,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '예산 배분',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Row(
                children: [
                  // 파이 차트
                  Expanded(
                    flex: 6,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: _generatePieSections(budgetItems),
                        pieTouchData: PieTouchData(
                          touchCallback: (FlTouchEvent event, pieTouchResponse) {
                            // 터치 이벤트 처리 (원하는 경우)
                          },
                        ),
                      ),
                    ),
                  ),

                  // 범례
                  Expanded(
                    flex: 5,
                    child: _buildLegend(budgetItems),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  // 파이 차트 섹션 생성
  List<PieChartSectionData> _generatePieSections(final budgetItems) {
    // 카테고리 색상 매핑 함수
    Color getCategoryColor(int index) {
      final colors = [
        AppColors.primary,
        Color(0xFF9177E0),
        Color(0xFF49E292),
        Color(0xFF4990E2),
        Color(0xFFE2A949),
        Color(0xFFE07777),
        Color(0xFF49C5E2),
        Color(0xFF7CC576),
        Color(0xFFE5A5A5),
        Color(0xFFE2CF49),
      ];
      return colors[index % colors.length];
    }

    // 총 예산 계산
    final totalBudget = budgetItems.fold<double>(
        0.0, (double sum, item) => sum + item.budgetAmount.toDouble());

    // 각 카테고리의 파이 차트 섹션 생성
    return List.generate(budgetItems.length, (i) {
      final item = budgetItems[i];
      final percentage = (item.budgetAmount / totalBudget) * 100;

      return PieChartSectionData(
        color: getCategoryColor(i),
        value: item.budgetAmount.toDouble(), // 명시적으로 double로 변환
        title: '',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 0,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        badgeWidget: percentage >= 5 ? _Badge(
          '${percentage.toStringAsFixed(0)}%',
          size: 30,
          borderColor: getCategoryColor(i),
        ) : null,
        badgePositionPercentageOffset: .98,
      );
    });
  }

  // 범례 위젯
  Widget _buildLegend(final budgetItems) {
    // 카테고리 색상 매핑 함수
    Color getCategoryColor(int index) {
      final colors = [
        AppColors.primary,
        Color(0xFF9177E0),
        Color(0xFF49E292),
        Color(0xFF4990E2),
        Color(0xFFE2A949),
        Color(0xFFE07777),
        Color(0xFF49C5E2),
        Color(0xFF7CC576),
        Color(0xFFE5A5A5),
        Color(0xFFE2CF49),
      ];
      return colors[index % colors.length];
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: budgetItems.length > 5 ? 5 : budgetItems.length,
      itemBuilder: (context, index) {
        final item = budgetItems[index];
        // 천 단위 콤마 포맷팅
        final budget = '${item.budgetAmount.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원';

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: getCategoryColor(index),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.categoryName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                budget,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 데이터가 없을 때 표시할 위젯
  Widget _buildEmptyState() {
    return Container(
      height: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              '예산 데이터가 없습니다',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '카테고리별 예산을 설정하면 차트가 표시됩니다',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 차트 위에 표시되는 배지 위젯
class _Badge extends StatelessWidget {
  final String text;
  final double size;
  final Color borderColor;

  const _Badge(
      this.text, {
        required this.size,
        required this.borderColor,
      });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: PieChart.defaultDuration,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.5),
            offset: const Offset(3, 3),
            blurRadius: 3,
          ),
        ],
      ),
      padding: EdgeInsets.all(size * .15),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: size * .35,
            fontWeight: FontWeight.bold,
            color: borderColor,
          ),
        ),
      ),
    );
  }
}