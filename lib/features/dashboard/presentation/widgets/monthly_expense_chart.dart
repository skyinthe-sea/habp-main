// lib/features/dashboard/presentation/widgets/monthly_expense_chart.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/entities/monthly_expense.dart';
import '../presentation/dashboard_controller.dart';

class MonthlyExpenseChart extends StatefulWidget {
  final DashboardController controller;

  const MonthlyExpenseChart({Key? key, required this.controller}) : super(key: key);

  @override
  State<MonthlyExpenseChart> createState() => _MonthlyExpenseChartState();
}

class _MonthlyExpenseChartState extends State<MonthlyExpenseChart> with SingleTickerProviderStateMixin {
  // 현재 슬라이더 값을 내부적으로 관리
  double _currentSliderValue = 6.0;
  bool _isDragging = false;

  // 애니메이션 컨트롤러
  late AnimationController _animationController;

  // 차트 표시 모드
  final RxBool _showLineChart = true.obs;

  @override
  void initState() {
    super.initState();
    _currentSliderValue = widget.controller.monthRange.value.toDouble();

    // 애니메이션 컨트롤러 초기화
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.controller.onChartAnimationComplete();
      }
    });

    // 초기 애니메이션 실행
    _animationController.forward();
  }

  @override
  void didUpdateWidget(MonthlyExpenseChart oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 데이터가 변경되면 애니메이션 재시작
    if (widget.controller.isChartAnimating.value) {
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (widget.controller.isExpenseTrendLoading.value) {
        return Container(
          height: 280,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(),
        );
      }

      final expenses = widget.controller.monthlyExpenses;

      if (expenses.isEmpty) {
        return Container(
          height: 280,
          alignment: Alignment.center,
          child: const Text('데이터가 없습니다'),
        );
      }

      // 데이터 가공 - 월별 지출 데이터 포인트 생성
      final chartData = expenses.map((expense) =>
          ExpenseData(
            date: expense.date,
            amount: expense.amount,
            formattedMonth: DateFormat('M월').format(expense.date),
            formattedMonthYear: DateFormat('yyyy년 M월').format(expense.date),
          )
      ).toList();

      // 선택된 월 (마지막 데이터)
      final selectedMonth = expenses.last.date;
      final selectedMonthText = DateFormat('yyyy년 M월').format(selectedMonth);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더: 제목, 차트 유형 선택, 현재 선택된 월 표시
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
                Row(
                  children: [
                    // 차트 유형 토글 버튼
                    InkWell(
                      onTap: () => _showLineChart.value = !_showLineChart.value,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _showLineChart.value
                                  ? Icons.show_chart
                                  : Icons.bar_chart,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _showLineChart.value ? '라인' : '막대',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 현재 선택된 월 및 데이터 범위
                    Text(
                      '~$selectedMonthText (${expenses.length}개월)',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 개월 수 조절 슬라이더
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text('3', style: TextStyle(fontSize: 10, color: Colors.grey)),
                Expanded(
                  child: Slider(
                    value: _currentSliderValue,
                    min: 3,
                    max: 12,
                    divisions: 9,
                    label: '${_currentSliderValue.toInt()}개월',
                    activeColor: AppColors.primary,
                    inactiveColor: AppColors.primary.withOpacity(0.2),
                    onChanged: (value) {
                      setState(() {
                        _currentSliderValue = value;
                        _isDragging = true;
                      });
                    },
                    onChangeEnd: (value) {
                      if (_isDragging) {
                        widget.controller.setMonthRange(value.toInt());
                        setState(() {
                          _isDragging = false;
                        });
                      }
                    },
                  ),
                ),
                const Text('12', style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),

          // 차트 영역
          SizedBox(
            height: 220,
            child: _showLineChart.value
                ? _buildLineChart(chartData)
                : _buildColumnChart(chartData),
          ),
        ],
      );
    });
  }

  // 라인 차트 구현
  Widget _buildLineChart(List<ExpenseData> chartData) {
    return SfCartesianChart(
      margin: const EdgeInsets.all(10),
      plotAreaBorderWidth: 0,
      primaryXAxis: DateTimeAxis(
        dateFormat: DateFormat('M월'),
        intervalType: DateTimeIntervalType.months,
        majorGridLines: const MajorGridLines(width: 0),
        axisLine: const AxisLine(width: 1, color: Colors.grey),
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 10),
        rangePadding: ChartRangePadding.round,
      ),
      primaryYAxis: NumericAxis(
        numberFormat: NumberFormat.compact(locale: 'ko'),
        axisLine: const AxisLine(width: 0),
        majorTickLines: const MajorTickLines(size: 0),
        labelFormat: '{value}원',
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 10),
      ),
      tooltipBehavior: TooltipBehavior(
        enable: true,
        builder: (data, point, series, pointIndex, seriesIndex) {
          final ExpenseData expenseData = chartData[pointIndex];
          return Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expenseData.formattedMonthYear,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatAmount(expenseData.amount)}원',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          );
        },
      ),
      series: <CartesianSeries<ExpenseData, DateTime>>[
        // 스풀라인 시리즈
        SplineAreaSeries<ExpenseData, DateTime>(
          dataSource: chartData,
          xValueMapper: (ExpenseData data, _) => data.date,
          yValueMapper: (ExpenseData data, _) => data.amount,
          color: AppColors.primary.withOpacity(0.2),
          borderColor: AppColors.primary,
          borderWidth: 3,
          animationDuration: 800,
          markerSettings: const MarkerSettings(
            isVisible: true,
            height: 8,
            width: 8,
            borderWidth: 2,
            borderColor: AppColors.primary,
            color: Colors.white,
          ),
          splineType: SplineType.natural,
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withOpacity(0.3),
              AppColors.primary.withOpacity(0.05),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        // 마지막 데이터 포인트 강조를 위한 별도 시리즈
        ScatterSeries<ExpenseData, DateTime>(
          dataSource: [chartData.last],
          xValueMapper: (ExpenseData data, _) => data.date,
          yValueMapper: (ExpenseData data, _) => data.amount,
          markerSettings: MarkerSettings(
            isVisible: true,
            height: 14,
            width: 14,
            borderWidth: 3,
            borderColor: AppColors.primary,
            color: AppColors.primary.withOpacity(0.3),
            shape: DataMarkerType.circle,
          ),
          animationDuration: 800,
        ),
      ],
      onMarkerRender: (MarkerRenderArgs args) {
        // 마지막 포인트 강조
        if (args.pointIndex == chartData.length - 1) {
          args.markerHeight = 12;
          args.markerWidth = 12;
          args.color = AppColors.primary;
        }
      },
    );
  }

  // 컬럼(막대) 차트 구현
  Widget _buildColumnChart(List<ExpenseData> chartData) {
    return SfCartesianChart(
      margin: const EdgeInsets.all(10),
      plotAreaBorderWidth: 0,
      primaryXAxis: DateTimeAxis(
        dateFormat: DateFormat('M월'),
        intervalType: DateTimeIntervalType.months,
        majorGridLines: const MajorGridLines(width: 0),
        axisLine: const AxisLine(width: 1, color: Colors.grey),
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 10),
        rangePadding: ChartRangePadding.round,
      ),
      primaryYAxis: NumericAxis(
        numberFormat: NumberFormat.compact(locale: 'ko'),
        axisLine: const AxisLine(width: 0),
        majorTickLines: const MajorTickLines(size: 0),
        labelFormat: '{value}원',
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 10),
      ),
      tooltipBehavior: TooltipBehavior(
        enable: true,
        builder: (data, point, series, pointIndex, seriesIndex) {
          final ExpenseData expenseData = chartData[pointIndex];
          return Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expenseData.formattedMonthYear,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatAmount(expenseData.amount)}원',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          );
        },
      ),
      series: <CartesianSeries<ExpenseData, DateTime>>[
        ColumnSeries<ExpenseData, DateTime>(
          dataSource: chartData,
          xValueMapper: (ExpenseData data, _) => data.date,
          yValueMapper: (ExpenseData data, _) => data.amount,
          borderRadius: BorderRadius.circular(4),
          width: 0.6,
          animationDuration: 800,
          // 막대 색상 설정 - 마지막 항목만 강조
          pointColorMapper: (ExpenseData data, index) {
            return index == chartData.length - 1
                ? AppColors.primary
                : AppColors.primary.withOpacity(0.5);
          },
          dataLabelSettings: const DataLabelSettings(
            isVisible: false,
            labelAlignment: ChartDataLabelAlignment.top,
            textStyle: TextStyle(fontSize: 10, color: Colors.black),
          ),
          onPointTap: (ChartPointDetails details) {
            // 터치 이벤트 처리 (필요시)
          },
        ),
      ],
    );
  }

  // 금액 포맷팅
  String _formatAmount(double amount) {
    final formatter = NumberFormat('#,###', 'ko');
    return formatter.format(amount);
  }
}

// 차트 데이터 모델
class ExpenseData {
  final DateTime date;
  final double amount;
  final String formattedMonth;
  final String formattedMonthYear;

  ExpenseData({
    required this.date,
    required this.amount,
    required this.formattedMonth,
    required this.formattedMonthYear,
  });
}