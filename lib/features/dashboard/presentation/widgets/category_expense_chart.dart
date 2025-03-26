import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/entities/category_expense.dart';
import '../presentation/dashboard_controller.dart';

class CategoryExpenseChart extends StatelessWidget {
  final DashboardController controller;

  const CategoryExpenseChart({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isCategoryExpenseLoading.value) {
        return Container(
          height: 300,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(),
        );
      }

      if (controller.categoryExpenses.isEmpty) {
        return Container(
          height: 300,
          alignment: Alignment.center,
          child: const Text('카테고리별 지출 데이터가 없습니다'),
        );
      }

      final categoryExpenses = controller.categoryExpenses;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '카테고리별 지출',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '이번 달',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          // 도넛 차트
          SizedBox(
            height: 300,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 도넛 차트
                PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 70,
                    sections: _createSections(categoryExpenses),
                    startDegreeOffset: 180,
                  ),
                ),

                // 중앙 텍스트 (선택적)
                const Text(
                  '지출 비율',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  List<PieChartSectionData> _createSections(List<CategoryExpense> expenses) {
    return expenses.map((expense) {
      final color = AppColors.getCategoryColor(expense.categoryId);
      final percentage = expense.percentage.roundToDouble();

      return PieChartSectionData(
        color: color,
        value: expense.amount,
        title: '',
        radius: 60,
        titlePositionPercentageOffset: 0.6,
        badgeWidget: _getBadgeWidget(expense.categoryName, percentage, color),
        badgePositionPercentageOffset: 1.2,
      );
    }).toList();
  }

  Widget _getBadgeWidget(String categoryName, double percentage, Color color) {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$categoryName ',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            TextSpan(
              text: '${percentage.toInt()}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
                shadows: const [
                  Shadow(
                    offset: Offset(1.0, 1.0),
                    blurRadius: 2.0,
                    color: Colors.black,
                  ),
                  Shadow(
                    offset: Offset(-1.0, -1.0),
                    blurRadius: 2.0,
                    color: Colors.black,
                  ),
                  Shadow(
                    offset: Offset(1.0, -1.0),
                    blurRadius: 2.0,
                    color: Colors.black,
                  ),
                  Shadow(
                    offset: Offset(-1.0, 1.0),
                    blurRadius: 2.0,
                    color: Colors.black,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}