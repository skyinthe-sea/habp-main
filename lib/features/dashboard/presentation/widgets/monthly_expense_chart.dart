import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/entities/monthly_expense.dart';
import '../presentation/dashboard_controller.dart';

class MonthlyExpenseChart extends StatelessWidget {
  final DashboardController controller;

  const MonthlyExpenseChart({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isExpenseTrendLoading.value) {
        return Container(
          height: 200, // 300에서 200으로 감소
          alignment: Alignment.center,
          child: const CircularProgressIndicator(),
        );
      }

      if (controller.monthlyExpenses.isEmpty) {
        return Container(
          height: 200, // 300에서 200으로 감소
          alignment: Alignment.center,
          child: const Text('데이터가 없습니다'),
        );
      }

      // 원본 데이터 직접 사용 (정규화된 데이터 대신)
      final expenses = controller.monthlyExpenses;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // 16,8에서 12,6으로 감소
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '월별 지출 추이',
                  style: TextStyle(
                    fontSize: 14, // 16에서 14로 감소
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '최근 ${expenses.length}개월',
                  style: const TextStyle(
                    fontSize: 10, // 12에서 10으로 감소
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          // 그래프 영역
          Container(
            height: 200, // 240에서 200으로 감소
            padding: const EdgeInsets.all(12), // 16에서 12로 감소
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _calculateMaxY(expenses),
                minY: 0,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final expense = expenses[groupIndex];
                      return BarTooltipItem(
                        '${_formatAmount(expense.amount)}원',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10, // 추가: 툴팁 폰트 사이즈 지정
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < expenses.length) {
                          final month = expenses[index].date.month;
                          return Padding(
                            padding: const EdgeInsets.only(top: 6.0), // 8에서 6으로 감소
                            child: Text(
                              '${month}월',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 10, // 12에서 10으로 감소
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                      reservedSize: 22, // 28에서 22로 감소
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox();

                        String text;
                        if (value >= 10000000) {
                          text = '${(value / 10000000).toStringAsFixed(0)}천만';
                        } else if (value >= 1000000) {
                          text = '${(value / 1000000).toStringAsFixed(0)}백만';
                        } else if (value >= 10000) {
                          text = '${(value / 10000).toStringAsFixed(0)}만';
                        } else {
                          text = value.toInt().toString();
                        }

                        return Padding(
                          padding: const EdgeInsets.only(right: 4), // 8에서 4로 감소
                          child: Text(
                            text,
                            style: const TextStyle(
                              fontSize: 8, // 10에서 8로 감소
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                      reservedSize: 30, // 40에서 30으로 감소
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: false,
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  drawHorizontalLine: true,
                  horizontalInterval: _calculateInterval(expenses),
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.shade200,
                    strokeWidth: 0.8, // 1에서 0.8로 감소
                    dashArray: [5, 5],
                  ),
                  getDrawingVerticalLine: (value) => FlLine(
                    color: Colors.grey.shade200,
                    strokeWidth: 0,
                    dashArray: [5, 5],
                  ),
                ),
                barGroups: expenses.asMap().entries.map((entry) {
                  final index = entry.key;
                  final expense = entry.value;

                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: expense.amount,
                        color: AppColors.primary,
                        width: 30, // 40에서 30으로 감소
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      );
    });
  }

  // 최대 Y값 계산 - 그대로유지
  double _calculateMaxY(List<MonthlyExpense> expenses) {
    if (expenses.isEmpty) return 100000;

    double max = expenses.map((e) => e.amount).reduce((a, b) => a > b ? a : b);

    // 여백을 위해 20% 증가
    max *= 1.2;

    // 깔끔한 눈금을 위해 반올림
    if (max < 10000) {
      return ((max / 1000).ceil()) * 1000;
    } else if (max < 100000) {
      return ((max / 10000).ceil()) * 10000;
    } else if (max < 1000000) {
      return ((max / 100000).ceil()) * 100000;
    } else {
      return ((max / 1000000).ceil()) * 1000000;
    }
  }

  // 그리드 간격 계산 - 그대로유지
  double _calculateInterval(List<MonthlyExpense> expenses) {
    final maxY = _calculateMaxY(expenses);

    // 그리드 라인 4-6개 정도 표시되도록 간격 계산
    if (maxY <= 10000) return 2000;
    if (maxY <= 100000) return 20000;
    if (maxY <= 500000) return 100000;
    if (maxY <= 1000000) return 200000;
    if (maxY <= 5000000) return 1000000;
    return 2000000;
  }

  // 금액 포맷팅 - 그대로유지
  String _formatAmount(double amount) {
    if (amount >= 10000000) {
      return '${(amount / 10000000).toStringAsFixed(1)}천만';
    } else if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}백만';
    } else if (amount >= 10000) {
      return '${(amount / 10000).toStringAsFixed(1)}만';
    } else {
      return amount.toInt().toString();
    }
  }
}