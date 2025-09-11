import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import '../../../../core/controllers/theme_controller.dart';

class CategoryAnalyticsCharts extends StatelessWidget {
  final String title;
  final String chartType; // 'dayOfWeek' or 'daily'
  final Map<int, double> dayOfWeekExpenses;
  final Map<int, double> dailyExpenses;
  final String selectedPeriod;

  const CategoryAnalyticsCharts({
    Key? key,
    required this.title,
    required this.chartType,
    required this.dayOfWeekExpenses,
    required this.dailyExpenses,
    required this.selectedPeriod,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeController.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: themeController.isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: themeController.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: chartType == 'dayOfWeek'
                ? _buildDayOfWeekChart(themeController)
                : _buildDailyExpensesChart(themeController),
          ),
        ],
      ),
    );
  }

  // 요일별 지출 차트
  Widget _buildDayOfWeekChart(ThemeController themeController) {
    final dayLabels = ['월', '화', '수', '목', '금', '토', '일'];

    // 데이터가 비어있는지 확인
    bool hasData = dayOfWeekExpenses.values.any((value) => value > 0);

    if (!hasData) {
      return _buildNoDataMessage(themeController);
    }

    final maxExpense = dayOfWeekExpenses.values.fold<double>(
        0, (max, value) => value > max ? value : max);

    // 최댓값이 0이면 데이터가 없는 것
    if (maxExpense <= 0) {
      return _buildNoDataMessage(themeController);
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxExpense * 1.2,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipPadding: const EdgeInsets.all(8),
            tooltipMargin: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final currencyFormat = NumberFormat('#,###', 'ko_KR');
              return BarTooltipItem(
                '${currencyFormat.format(rod.toY.toInt())}원',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
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
                if (index >= 0 && index < dayLabels.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      dayLabels[index],
                      style: TextStyle(
                        color: themeController.textPrimaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final currencyFormat = NumberFormat('#,###', 'ko_KR');
                if (value == 0) return const SizedBox();

                // 최대 3개의 레이블만 표시
                final interval = maxExpense / 3;
                if (value % interval > interval * 0.3 && value != maxExpense) {
                  return const SizedBox();
                }

                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    '${currencyFormat.format(value.toInt())}',
                    style: TextStyle(
                      color: themeController.textSecondaryColor,
                      fontSize: 10,
                    ),
                  ),
                );
              },
              reservedSize: 40,
            ),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: false,
        ),
        barGroups: List.generate(7, (index) {
          final day = index + 1; // 1(월) ~ 7(일)
          final expense = dayOfWeekExpenses[day] ?? 0;

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: expense,
                color: _getDayColor(day, themeController),
                width: 16,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  // 일별 지출 추이 차트 (라인 차트)
  Widget _buildDailyExpensesChart(ThemeController themeController) {
    // 월의 총 일수 계산
    final year = int.parse(selectedPeriod.split('-')[0]);
    final month = int.parse(selectedPeriod.split('-')[1]);
    final daysInMonth = DateTime(year, month + 1, 0).day;

    // 데이터가 비어있는지 확인
    bool hasData = dailyExpenses.values.any((value) => value > 0);

    if (!hasData) {
      return _buildNoDataMessage(themeController);
    }

    // 일별 데이터 포인트 생성
    List<FlSpot> spots = [];
    for (int day = 1; day <= daysInMonth; day++) {
      final amount = dailyExpenses[day] ?? 0;
      if (amount > 0) {
        spots.add(FlSpot(day.toDouble(), amount));
      }
    }

    // 빈 데이터 처리
    if (spots.isEmpty) {
      return _buildNoDataMessage(themeController);
    }

    // 최대값 계산
    final maxY = spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b) * 1.2;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: themeController.isDarkMode 
                  ? Colors.grey.shade700.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.2),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: daysInMonth > 15 ? 5 : 2,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox();

                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${value.toInt()}일',
                    style: TextStyle(
                      color: themeController.textSecondaryColor,
                      fontSize: 11,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: maxY / 4,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox();

                final currencyFormat = NumberFormat('#,###', 'ko_KR');
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    '${currencyFormat.format(value.toInt())}',
                    style: TextStyle(
                      color: themeController.textSecondaryColor,
                      fontSize: 10,
                    ),
                  ),
                );
              },
              reservedSize: 40,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(
              color: themeController.isDarkMode 
                  ? Colors.grey.shade700.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.2),
            ),
            left: BorderSide(
              color: themeController.isDarkMode 
                  ? Colors.grey.shade700.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.2),
            ),
            right: BorderSide(
              color: Colors.transparent,
            ),
            top: BorderSide(
              color: Colors.transparent,
            ),
          ),
        ),
        minX: 1,
        maxX: daysInMonth.toDouble(),
        minY: 0,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: themeController.primaryColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                radius: 4,
                color: themeController.primaryColor,
                strokeWidth: 2,
                strokeColor: themeController.cardColor,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: themeController.primaryColor.withOpacity(0.1),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((touchedSpot) {
                final currencyFormat = NumberFormat('#,###', 'ko_KR');
                final day = touchedSpot.x.toInt();
                final amount = touchedSpot.y;

                return LineTooltipItem(
                  '${day}일: ${currencyFormat.format(amount.toInt())}원',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  // 데이터가 없을 때 표시할 위젯
  Widget _buildNoDataMessage(ThemeController themeController) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart,
            size: 48,
            color: themeController.isDarkMode 
                ? Colors.grey.shade600.withOpacity(0.4)
                : Colors.grey.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            '데이터가 충분하지 않습니다',
            style: TextStyle(
              color: themeController.textSecondaryColor,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // 요일별 색상 지정
  Color _getDayColor(int day, ThemeController themeController) {
    switch (day) {
      case 1: // 월요일
        return themeController.primaryColor.withOpacity(0.7);
      case 2: // 화요일
        return themeController.primaryColor.withOpacity(0.8);
      case 3: // 수요일
        return themeController.primaryColor.withOpacity(0.9);
      case 4: // 목요일
        return themeController.primaryColor;
      case 5: // 금요일
        return themeController.primaryColor;
      case 6: // 토요일
        return const Color(0xFF9177E0); // 보라색 (토요일)
      case 7: // 일요일
        return const Color(0xFFE2A949); // 노란색 (일요일)
      default:
        return themeController.primaryColor;
    }
  }
}