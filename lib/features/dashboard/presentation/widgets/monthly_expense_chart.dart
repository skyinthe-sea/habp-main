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
  // 애니메이션 컨트롤러
  late AnimationController _animationController;

  // 차트 표시 모드
  final RxBool _showLineChart = true.obs;

  // 포맷터 정의
  final DateFormat _monthYearFormat = DateFormat('yyyy년 M월');
  final DateFormat _monthFormat = DateFormat('M월');

  @override
  void initState() {
    super.initState();

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
            // 일관된 포맷팅 적용
            formattedMonth: _monthFormat.format(expense.date),
            formattedMonthYear: _monthYearFormat.format(expense.date),
          )
      ).toList();

      // 날짜 정렬 (오래된 날짜부터)
      chartData.sort((a, b) => a.date.compareTo(b.date));

      // 선택된 월 (마지막 데이터)
      final selectedMonth = expenses.last.date;
      final selectedMonthText = _monthYearFormat.format(selectedMonth);

      // 현재 slider 값 가져오기 (sliding 중이면 sliderMonthRange, 아니면 monthRange)
      final currentRangeValue = widget.controller.isSliding.value
          ? widget.controller.sliderMonthRange.value
          : widget.controller.monthRange.value.toDouble();

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
                    // 날짜 범위 표시 개선 (시작월 ~ 종료월)
                    Text(
                      widget.controller.getMonthRangeString(),
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

          // 차트 영역
          SizedBox(
            height: 220,
            child: _showLineChart.value
                ? _buildLineChart(chartData)
                : _buildColumnChart(chartData),
          ),

          // 개월 수 조절 슬라이더 (차트 아래로 이동)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text('3', style: TextStyle(fontSize: 10, color: Colors.grey)),
                Expanded(
                  child: Slider(
                    value: currentRangeValue,
                    min: 3,
                    max: 12,
                    divisions: 9,
                    label: '${currentRangeValue.toInt()}개월',
                    activeColor: AppColors.primary,
                    inactiveColor: AppColors.primary.withOpacity(0.2),
                    onChangeStart: (_) {
                      // 새로 추가: 슬라이더 드래그 시작 시 컨트롤러에 알림
                      widget.controller.onSlideStart();
                    },
                    onChanged: (value) {
                      // 즉시 컨트롤러의 임시 값 업데이트 (UI가 즉시 반응)
                      widget.controller.updateSliderValue(value);
                    },
                    onChangeEnd: (value) {
                      // 슬라이더 드래그 종료 처리
                      widget.controller.onSlideEnd(value);
                    },
                    // 단발성 터치에서도 부드럽게 동작하도록 추가 속성 설정
                    mouseCursor: MouseCursor.defer,
                  ),
                ),
                const Text('12', style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
        ],
      );
    });
  }

  // 라인 차트 구현 - 수정됨
  Widget _buildLineChart(List<ExpenseData> chartData) {
    // 데이터 포인트 디버깅 로그
    // 디버깅을 위해 다음 코드를 활성화하면 콘솔에서 실제 데이터 포인트 확인 가능
    // for (var data in chartData) {
    //   print('${data.date} (${data.formattedMonthYear}): ${data.amount}');
    // }
    return SfCartesianChart(
      margin: const EdgeInsets.all(10),
      plotAreaBorderWidth: 0,
      primaryXAxis: DateTimeAxis(
        name: 'primaryXAxis',
        minimum: chartData.isNotEmpty ? chartData.first.date : null,
        maximum: chartData.isNotEmpty ? chartData.last.date : null,
        dateFormat: _monthFormat, // 기본 x축은 월만 표시
        intervalType: DateTimeIntervalType.months,
        majorGridLines: const MajorGridLines(width: 0),
        axisLine: const AxisLine(width: 1, color: Colors.grey),
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 10),
        rangePadding: ChartRangePadding.none, // Changed from 'round' to 'none' for exact alignment
        desiredIntervals: chartData.length > 6 ? 6 : chartData.length, // Limit interval count
        // 년도는 1월에만 표시하도록 수정
        axisLabelFormatter: (AxisLabelRenderDetails details) {
          if (details.value is num) {
            final DateTime date = DateTime.fromMillisecondsSinceEpoch(details.value.floor());

            // 데이터 포인트와 일치하는 날짜인지 확인
            bool isDataPoint = chartData.any((data) =>
            data.date.year == date.year && data.date.month == date.month);

            if (isDataPoint) {
              // 1월인 경우에만 연도 표시
              if (date.month == 1) {
                return ChartAxisLabel(
                  '${date.year}년\n${date.month}월',
                  details.textStyle,
                );
              }
              // 다른 월은 월만 표시
              else {
                return ChartAxisLabel(
                  '${date.month}월',
                  details.textStyle,
                );
              }
            }
          }
          return ChartAxisLabel(details.text, details.textStyle);
        },
      ),
      primaryYAxis: NumericAxis(
        numberFormat: NumberFormat.compact(locale: 'ko'),
        axisLine: const AxisLine(width: 0),
        majorTickLines: const MajorTickLines(size: 0),
        labelFormat: '{value}원',
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 10),
      ),
      // 툴팁 설정 수정 - 데이터와 동기화되도록 포맷 개선
      tooltipBehavior: TooltipBehavior(
        enable: true,
        format: 'point.x\n₩point.y',
        shared: false,
        builder: null,
      ),
      series: <CartesianSeries<ExpenseData, DateTime>>[
        // 스플라인 시리즈
        SplineAreaSeries<ExpenseData, DateTime>(
          dataSource: chartData,
          xValueMapper: (ExpenseData data, _) => data.date,
          yValueMapper: (ExpenseData data, _) => data.amount,
          xAxisName: 'primaryXAxis', // 명시적으로 X축 이름 지정
          color: AppColors.primary.withOpacity(0.2),
          borderColor: AppColors.primary,
          borderWidth: 3,
          // 변경: 슬라이딩 중에도 미세한 애니메이션 제공 (단발성 터치에서 더 자연스럽게)
          animationDuration: widget.controller.isSliding.value ? 100 : 800,
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
          // 각 데이터 포인트에 대해 해당 날짜를 툴팁에 표시하도록 설정
          dataLabelSettings: DataLabelSettings(
            isVisible: false,
            builder: (dynamic data, dynamic point, dynamic series, int pointIndex, int seriesIndex) {
              final ExpenseData expenseData = chartData[pointIndex];
              return Text(expenseData.formattedMonthYear);
            },
          ),
          // 툴팁 수정 - 기본 툴팁 사용
          enableTooltip: true,
          // 각 데이터 포인트의 정확한 날짜를 X축에 맞추기 위한 설정
          sortingOrder: SortingOrder.ascending,
          sortFieldValueMapper: (ExpenseData data, _) => data.date,
          // 시리즈 이름 설정
          name: 'Series 0',
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
          // 변경: 슬라이딩 중에도 미세한 애니메이션 제공 (단발성 터치에서 더 자연스럽게)
          animationDuration: widget.controller.isSliding.value ? 100 : 800,
          // 마지막 포인트에 대한 툴팁 정보 설정
          enableTooltip: true,
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
      // 툴팁 커스터마이징을 위한 이벤트 처리 추가
      onTooltipRender: (TooltipArgs args) {
        if (args.seriesIndex == 0) { // SplineAreaSeries 시리즈의 경우
          final pointIndex = args.pointIndex?.toInt(); // num을 int로 변환
          if (pointIndex != null && pointIndex >= 0 && pointIndex < chartData.length) {
            final data = chartData[pointIndex];
            // 정확한 날짜 정보로 툴팁 텍스트 교체 (연월 포함)
            args.text = '${data.formattedMonthYear}\n₩${_formatAmount(data.amount)}';
          }
        }
      },
    );
  }

  // 컬럼(막대) 차트 구현 - 수정됨
  Widget _buildColumnChart(List<ExpenseData> chartData) {
    // 데이터 포인트 디버깅 로그
    // 디버깅을 위해 다음 코드를 활성화하면 콘솔에서 실제 데이터 포인트 확인 가능
    // for (var data in chartData) {
    //   print('${data.date} (${data.formattedMonthYear}): ${data.amount}');
    // }
    return SfCartesianChart(
      margin: const EdgeInsets.all(10),
      plotAreaBorderWidth: 0,
      primaryXAxis: DateTimeAxis(
        dateFormat: _monthFormat, // 기본 x축은 월만 표시
        intervalType: DateTimeIntervalType.months,
        majorGridLines: const MajorGridLines(width: 0),
        axisLine: const AxisLine(width: 1, color: Colors.grey),
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 10),
        rangePadding: ChartRangePadding.none, // Changed from 'round' to 'none' for exact alignment
        desiredIntervals: chartData.length > 6 ? 6 : chartData.length, // Limit interval count
        // 년도는 1월에만 표시하도록 수정
        axisLabelFormatter: (AxisLabelRenderDetails details) {
          if (details.value is num) {
            final DateTime date = DateTime.fromMillisecondsSinceEpoch(details.value.floor());

            // 데이터 포인트와 일치하는 날짜인지 확인
            bool isDataPoint = chartData.any((data) =>
            data.date.year == date.year && data.date.month == date.month);

            if (isDataPoint) {
              // 1월인 경우에만 연도 표시
              if (date.month == 1) {
                return ChartAxisLabel(
                  '${date.year}년\n${date.month}월',
                  details.textStyle,
                );
              }
              // 다른 월은 월만 표시
              else {
                return ChartAxisLabel(
                  '${date.month}월',
                  details.textStyle,
                );
              }
            }
          }
          return ChartAxisLabel(details.text, details.textStyle);
        },
      ),
      primaryYAxis: NumericAxis(
        numberFormat: NumberFormat.compact(locale: 'ko'),
        axisLine: const AxisLine(width: 0),
        majorTickLines: const MajorTickLines(size: 0),
        labelFormat: '{value}원',
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 10),
      ),
      // 수정된 툴팁 형식
      tooltipBehavior: TooltipBehavior(
        enable: true,
      ),
      series: <CartesianSeries<ExpenseData, DateTime>>[
        ColumnSeries<ExpenseData, DateTime>(
          dataSource: chartData,
          xValueMapper: (ExpenseData data, _) => data.date,
          yValueMapper: (ExpenseData data, _) => data.amount,
          xAxisName: 'primaryXAxis', // 명시적으로 X축 이름 지정
          borderRadius: BorderRadius.circular(4),
          width: 0.6,
          // 변경: 슬라이딩 중 애니메이션 최적화
          animationDuration: widget.controller.isSliding.value ? 0 : 800,
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
          // 툴팁 커스터마이징
          enableTooltip: true,
          // 데이터 정렬 추가
          sortingOrder: SortingOrder.ascending,
          sortFieldValueMapper: (ExpenseData data, _) => data.date,
          // 시리즈 이름 설정
          name: 'Series 0',
        ),
      ],
      // 툴팁 커스터마이징을 위한 이벤트 처리 추가
      onTooltipRender: (TooltipArgs args) {
        final pointIndex = args.pointIndex?.toInt(); // num을 int로 변환
        if (pointIndex != null && pointIndex >= 0 && pointIndex < chartData.length) {
          final data = chartData[pointIndex];
          // 정확한 날짜 정보로 툴팁 텍스트 교체 (연월 포함)
          args.text = '${data.formattedMonthYear}\n₩${_formatAmount(data.amount)}';
        }
      },
    );
  }

  // 금액 포맷팅
  String _formatAmount(double amount) {
    final formatter = NumberFormat('#,###', 'ko');
    return formatter.format(amount);
  }
}

// 차트 데이터 모델 (동일하게 유지)
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