// lib/features/dashboard/presentation/widgets/monthly_expense_chart.dart
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
          height: 200,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(),
        );
      }

      if (controller.monthlyExpenses.isEmpty) {
        return Container(
          height: 200,
          alignment: Alignment.center,
          child: const Text('데이터가 없습니다'),
        );
      }

      // 원본 데이터 사용
      final expenses = controller.monthlyExpenses;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '월별 지출 추이',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '최근 ${expenses.length}개월',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          // 슬라이더 컨트롤 추가
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text('3', style: TextStyle(fontSize: 10, color: Colors.grey)),
                Expanded(
                  child: Slider(
                    value: controller.monthRange.value.toDouble(),
                    min: 3,
                    max: 12,
                    divisions: 9,
                    label: '${controller.monthRange.value}개월',
                    activeColor: AppColors.primary,
                    inactiveColor: AppColors.primary.withOpacity(0.2),
                    onChanged: (value) {
                      controller.setMonthRange(value.toInt());
                    },
                  ),
                ),
                const Text('12', style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),

          // 그래프 영역
          Container(
            height: 200,
            padding: const EdgeInsets.all(12),
            child: _buildAnimatedChart(expenses),
          ),
        ],
      );
    });
  }

  Widget _buildAnimatedChart(List<MonthlyExpense> expenses) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              getDrawingHorizontalLine: (value) => FlLine(
                color: Colors.grey.shade200,
                strokeWidth: 0.8,
                dashArray: [5, 5],
              ),
              getDrawingVerticalLine: (value) => FlLine(
                color: Colors.grey.shade200,
                strokeWidth: 0.8,
                dashArray: [5, 5],
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (double value, TitleMeta meta) {
                    final int index = value.toInt();
                    if (index >= 0 && index < expenses.length) {
                      final month = expenses[index].date.month;
                      return Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text(
                          '$month월',
                          style: TextStyle(
                            color: index == expenses.length - 1
                                ? Colors.black
                                : Colors.grey,
                            fontWeight: index == expenses.length - 1
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 10,
                          ),
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                  reservedSize: 22,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (double value, TitleMeta meta) {
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
                      padding: const EdgeInsets.only(right: 4),
                      child: Text(
                        text,
                        style: const TextStyle(
                          fontSize: 8,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  },
                  reservedSize: 30,
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
              show: true,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                left: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
            ),
            minX: 0,
            maxX: expenses.length - 1.0,
            minY: 0,
            maxY: _calculateMaxY(expenses),
            lineBarsData: [
              // 주요 라인 차트
              LineChartBarData(
                spots: _createSpots(expenses, value),
                isCurved: true,
                color: AppColors.primary,
                barWidth: 3 * value,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    Color dotColor = AppColors.primary;
                    return FlDotCirclePainter(
                      radius: 4 * value,
                      color: dotColor,
                      strokeWidth: 1,
                      strokeColor: Colors.white,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.3 * value),
                      AppColors.primary.withOpacity(0.05 * value),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              // 강조된 선택된 달 (맨 오른쪽 데이터)
              LineChartBarData(
                spots: expenses.isNotEmpty ? [
                  FlSpot(expenses.length - 1.0, expenses.last.amount * value),
                ] : [],
                color: Colors.transparent,
                barWidth: 0,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 6 * value,
                      color: AppColors.primary,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    );
                  },
                ),
              ),
            ],
            lineTouchData: LineTouchData(
              enabled: true,
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (List<LineBarSpot> touchedSpots) {
                  return touchedSpots.map((LineBarSpot touchedSpot) {
                    final expense = expenses[touchedSpot.x.toInt()];
                    return LineTooltipItem(
                      '${expense.date.month}월\n₩${_formatAmount(expense.amount)}',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    );
                  }).toList();
                },
              ),
            ),
          ),
        );
      },
    );
  }

  // 애니메이션에 따라 변화하는 데이터 포인트 생성
  List<FlSpot> _createSpots(List<MonthlyExpense> expenses, double animationValue) {
    return expenses.asMap().entries.map((entry) {
      return FlSpot(
        entry.key.toDouble(),
        entry.value.amount * animationValue,
      );
    }).toList();
  }

  // 최대 Y값 계산
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

  // 금액 포맷팅
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