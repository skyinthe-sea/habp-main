// lib/features/dashboard/presentation/widgets/monthly_expense_chart.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/controllers/theme_controller.dart';
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
  final DateFormat _yearFormat = DateFormat('yyyy');

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
    final ThemeController themeController = Get.find<ThemeController>();
    
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
            year: expense.date.year,
          )
      ).toList();

      // 날짜 정렬 (오래된 날짜부터)
      chartData.sort((a, b) => a.date.compareTo(b.date));

      // 선택된 월 (마지막 데이터)
      final selectedMonth = expenses.last.date;
      final selectedMonthText = _monthYearFormat.format(selectedMonth);

      // 년도 구분 표시를 위한 데이터 준비
      final yearChanges = _getYearChanges(chartData);

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
                          color: themeController.primaryColor.withOpacity(0.1),
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
                              color: themeController.primaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _showLineChart.value ? '라인' : '막대',
                              style: TextStyle(
                                fontSize: 10,
                                color: themeController.primaryColor,
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

          // 차트 영역 (년도 표시 줄 포함)
          SizedBox(
            height: 220,
            child: Stack(
              children: [
                // 메인 차트
                _showLineChart.value
                    ? _buildLineChart(chartData, yearChanges.cast<int, DateTime>())
                    : _buildColumnChart(chartData, yearChanges.cast<int, DateTime>()),

                // 년도 변경 표시 오버레이
                _buildYearOverlay(chartData, yearChanges, themeController),
              ],
            ),
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
                    activeColor: themeController.primaryColor,
                    inactiveColor: themeController.primaryColor.withOpacity(0.2),
                    onChangeStart: (_) {
                      // 슬라이더 드래그 시작 시 컨트롤러에 알림
                      widget.controller.onSlideStart();
                    },
                    onChanged: (value) {
                      // 즉시 컨트롤러의 임시 값 업데이트 (UI가 즉시 반응)
                      widget.controller.updateSliderValue(value);
                    },
                    onChangeEnd: (value) {
                      // 슬라이더 드래그 종료 처리 - 개선된 메서드 호출
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

  // 년도 변경 지점 계산 - 정확히 12월과 1월 사이 중앙에 위치하도록 수정
  Map<String, List<Object>> _getYearChanges(List<ExpenseData> chartData) {
    // 차트에 표시된 데이터의 년도-월 정보 수집
    Map<int, List<int>> yearMonths = {};
    for (var data in chartData) {
      if (!yearMonths.containsKey(data.year)) {
        yearMonths[data.year] = [];
      }
      if (!yearMonths[data.year]!.contains(data.date.month)) {
        yearMonths[data.year]!.add(data.date.month);
      }
    }

    // 결과를 저장할 맵 (특정 키와 위치 정보)
    Map<String, List<Object>> result = {};

    // 년도가 2개 이상일 때만 처리
    if (yearMonths.length > 1) {
      // 년도 리스트 정렬
      List<int> years = yearMonths.keys.toList()..sort();

      // 각 년도 변화에 대해
      for (int i = 0; i < years.length - 1; i++) {
        int currentYear = years[i];
        int nextYear = years[i + 1];

        // 년도 라벨을 고정 비율 위치에 배치 (12월과 1월 사이 중앙)
        // 실제 데이터와 상관없이, 12월과 1월 사이 정확한 위치에 배치

        // 변경: 위치를 chartData의 인덱스가 아닌
        // 날짜 범위 내 상대적 위치로 계산 (0.0 ~ 1.0)

        // 전체 차트 날짜 범위
        DateTime chartStart = chartData.first.date;
        DateTime chartEnd = chartData.last.date;
        int totalDays = chartEnd.difference(chartStart).inDays;

        // 년도 변경 지점 날짜 (12월 31일과 1월 1일의 중간점)
        DateTime yearChangeDate = DateTime(currentYear, 12, 31);

        // 중간점의 상대적 위치 계산 (전체 차트 범위 내에서 비율)
        double relativePosition = yearChangeDate.difference(chartStart).inDays / totalDays;

        // 위치가 0과 1 사이에 있을 때만 표시
        if (relativePosition >= 0 && relativePosition <= 1) {
          result["${currentYear}_${nextYear}"] = [
            nextYear.toString(),  // 표시할 년도
            relativePosition,     // 상대적 위치 (0.0 ~ 1.0)
            yearChangeDate,       // 날짜 객체
          ];
        }
      }
    }

    return result;
  }

  // 년도 변경 오버레이 위젯 - 완전히 새롭게 개선
  Widget _buildYearOverlay(List<ExpenseData> chartData, Map<String, List<Object>> yearChanges, ThemeController themeController) {
    if (yearChanges.isEmpty) return const SizedBox();

    return LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: yearChanges.entries.map((entry) {
              final year = entry.value[0] as String;
              final position = (entry.value[1] as double) * constraints.maxWidth;

              // 경계 검사: 화면 밖으로 벗어나지 않도록
              final adjustedPosition = position.clamp(10.0, constraints.maxWidth - 30);

              return Positioned(
                left: adjustedPosition,
                top: 0,
                bottom: 0,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // 세로 구분선
                    Container(
                      width: 1,
                      color: Colors.grey.withOpacity(0.3),
                    ),
                    // 년도 표시 뱃지
                    Positioned(
                      top: 10,
                      left: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: themeController.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: themeController.primaryColor.withOpacity(0.4)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Text(
                          year,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: themeController.primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        }
    );
  }

  // 라인 차트 구현 - 수정됨
  Widget _buildLineChart(List<ExpenseData> chartData, Map<int, DateTime> yearChanges) {
    final themeController = Get.find<ThemeController>();
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
        // 단순히 월만 표시하도록 수정
        axisLabelFormatter: (AxisLabelRenderDetails details) {
          if (details.value is num) {
            final DateTime date = DateTime.fromMillisecondsSinceEpoch(details.value.floor());

            // 데이터 포인트와 일치하는 날짜인지 확인
            bool isDataPoint = chartData.any((data) =>
            data.date.year == date.year && data.date.month == date.month);

            if (isDataPoint) {
              // 모든 월에 동일하게 "M월" 형식으로 표시
              return ChartAxisLabel(
                '${date.month}월',
                details.textStyle,
              );
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
      // 툴팁 설정 수정 - 간결하고 현대적인 디자인
      tooltipBehavior: TooltipBehavior(
        enable: true,
        color: Colors.white,
        borderColor: themeController.primaryColor.withOpacity(0.5),
        borderWidth: 1,
        elevation: 5,
        duration: 2000,
        format: '', // 기본 포맷 제거
        header: '', // 헤더 제거
        canShowMarker: false, // 마커 표시 제거
        shadowColor: Colors.black26,
        textStyle: const TextStyle(
          color: Colors.black87,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      series: <CartesianSeries<ExpenseData, DateTime>>[
        // 스플라인 시리즈
        SplineAreaSeries<ExpenseData, DateTime>(
          dataSource: chartData,
          xValueMapper: (ExpenseData data, _) => data.date,
          yValueMapper: (ExpenseData data, _) => data.amount,
          xAxisName: 'primaryXAxis', // 명시적으로 X축 이름 지정
          color: themeController.primaryColor.withOpacity(0.2),
          borderColor: themeController.primaryColor,
          borderWidth: 3,
          name: '', // 빈 이름으로 설정하여 'Series 0' 제거
          // 애니메이션 지속 시간 조정 - 더 일관된 경험 제공
          animationDuration: widget.controller.isSliding.value ? 200 : 300,
          markerSettings: MarkerSettings(
            isVisible: true,
            height: 8,
            width: 8,
            borderWidth: 2,
            borderColor: themeController.primaryColor,
            color: Colors.white,
          ),
          splineType: SplineType.natural,
          gradient: LinearGradient(
            colors: [
              themeController.primaryColor.withOpacity(0.3),
              themeController.primaryColor.withOpacity(0.05),
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
        ),
        // 마지막 데이터 포인트 강조를 위한 별도 시리즈
        ScatterSeries<ExpenseData, DateTime>(
          dataSource: [chartData.last],
          xValueMapper: (ExpenseData data, _) => data.date,
          yValueMapper: (ExpenseData data, _) => data.amount,
          name: '', // 빈 이름으로 설정하여 'Series 0' 제거
          markerSettings: MarkerSettings(
            isVisible: true,
            height: 14,
            width: 14,
            borderWidth: 3,
            borderColor: themeController.primaryColor,
            color: themeController.primaryColor.withOpacity(0.3),
            shape: DataMarkerType.circle,
          ),
          // 애니메이션 지속 시간 조정 - 라인 차트와 일치시킴
          animationDuration: widget.controller.isSliding.value ? 200 : 300,
          // 마지막 포인트에 대한 툴팁 정보 설정
          enableTooltip: true,
        ),
      ],
      onMarkerRender: (MarkerRenderArgs args) {
        // 마지막 포인트 강조
        if (args.pointIndex == chartData.length - 1) {
          args.markerHeight = 12;
          args.markerWidth = 12;
          args.color = themeController.primaryColor;
        }
      },
      // 툴팁 렌더링 이벤트 - 더 간단하고 안정적인 방식으로 구현
      onTooltipRender: (TooltipArgs args) {
        if (args.pointIndex != null) {
          final pointIndex = args.pointIndex!.toInt();

          // 시리즈 인덱스를 확인하여 올바른 차트 데이터 접근
          if (args.seriesIndex != null) {
            // 라인 차트의 경우 시리즈 인덱스가 0 (첫 번째 시리즈)
            if (args.seriesIndex == 0 && pointIndex >= 0 && pointIndex < chartData.length) {
              final data = chartData[pointIndex];
              args.text = '${data.formattedMonthYear}\n₩ ${_formatAmount(data.amount)}';
            }
            // 마지막 데이터 포인트 강조용 시리즈 (점)의 경우 시리즈 인덱스가 1
            else if (args.seriesIndex == 1) {
              final data = chartData.last; // 항상 마지막 데이터 사용
              args.text = '${data.formattedMonthYear}\n₩ ${_formatAmount(data.amount)}';
            }
          }
        }
      },
    );
  }

  // monthly_expense_chart.dart 파일에서 _buildColumnChart 메서드를 아래와 같이 수정

  Widget _buildColumnChart(List<ExpenseData> chartData, Map<int, DateTime> yearChanges) {
    final themeController = Get.find<ThemeController>();
    return SfCartesianChart(
      margin: const EdgeInsets.all(10),
      plotAreaBorderWidth: 0,
      primaryXAxis: DateTimeAxis(
        // 1. 명시적으로 최소/최대 범위 설정 - 마지막 데이터 이후에 약간의 여백 추가
        minimum: chartData.isNotEmpty ? chartData.first.date : null,
        // 마지막 날짜에 15일 추가하여 충분한 공간 확보
        maximum: chartData.isNotEmpty ?
        DateTime(chartData.last.date.year, chartData.last.date.month, chartData.last.date.day + 15) : null,
        // 2. 간격 유형은 월로 유지하되, 명시적 간격 값 설정
        intervalType: DateTimeIntervalType.months,
        interval: 1, // 명시적으로 1개월 간격 설정
        // 3. 패딩 설정 변경 - additional로 설정하여 양끝에 여백 추가
        rangePadding: ChartRangePadding.additional,
        // 4. 레이블 표시를 위한 설정 유지
        dateFormat: _monthFormat,
        majorGridLines: const MajorGridLines(width: 0),
        axisLine: const AxisLine(width: 1, color: Colors.grey),
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 10),
        // 5. 원하는 간격 조정 - 모든 데이터 포인트에 레이블 표시
        desiredIntervals: chartData.length,
        // 6. 레이블 포지셔닝 개선
        labelAlignment: LabelAlignment.center,
        // 7. 레이블 포맷터 개선
        axisLabelFormatter: (AxisLabelRenderDetails details) {
          if (details.value is num) {
            final DateTime date = DateTime.fromMillisecondsSinceEpoch(details.value.floor());

            // 데이터 포인트와 매칭되는 월인지 확인
            bool isDataPoint = chartData.any((data) =>
            data.date.year == date.year && data.date.month == date.month);

            if (isDataPoint) {
              return ChartAxisLabel(
                '${date.month}월',
                details.textStyle,
              );
            }
          }
          return ChartAxisLabel('', details.textStyle); // 빈 레이블 반환하여 표시 안함
        },
        // 8. X축 플롯 오프셋 설정으로 정확한 위치 조정
        plotOffset: 0,
      ),
      primaryYAxis: NumericAxis(
        numberFormat: NumberFormat.compact(locale: 'ko'),
        axisLine: const AxisLine(width: 0),
        majorTickLines: const MajorTickLines(size: 0),
        labelFormat: '{value}원',
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 10),
      ),
      // 툴팁 설정
      tooltipBehavior: TooltipBehavior(
        enable: true,
        color: Colors.white,
        borderColor: themeController.primaryColor.withOpacity(0.5),
        borderWidth: 1,
        elevation: 5,
        duration: 2000,
        shadowColor: Colors.black26,
        textStyle: const TextStyle(
          color: Colors.black87,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      series: <CartesianSeries<ExpenseData, DateTime>>[
        ColumnSeries<ExpenseData, DateTime>(
          dataSource: chartData,
          xValueMapper: (ExpenseData data, _) => data.date,
          yValueMapper: (ExpenseData data, _) => data.amount,
          // 9. 정확한 X축 이름 지정
          xAxisName: 'primaryXAxis',
          name: '',
          borderRadius: BorderRadius.circular(4),
          // 10. 너비 조정으로 막대 위치 개선 - 너비를 약간 줄임
          width: 0.7,
          // 애니메이션 지속 시간
          animationDuration: widget.controller.isSliding.value ? 200 : 300,
          // 막대 색상 설정 - 마지막 항목 강조
          pointColorMapper: (ExpenseData data, index) {
            return index == chartData.length - 1
                ? themeController.primaryColor
                : themeController.primaryColor.withOpacity(0.5);
          },
          dataLabelSettings: const DataLabelSettings(
            isVisible: false,
            labelAlignment: ChartDataLabelAlignment.top,
            textStyle: TextStyle(fontSize: 10, color: Colors.black),
          ),
          // 11. 데이터 정렬을 확실히 하기 위한 설정
          sortingOrder: SortingOrder.ascending,
          sortFieldValueMapper: (ExpenseData data, _) => data.date,
          // 12. 스페이싱 모드 추가 - 약간 더 넓게 설정
          spacing: 0.15,
          enableTooltip: true,
        ),
      ],
      // 툴팁 렌더링 이벤트
      onTooltipRender: (TooltipArgs args) {
        if (args.pointIndex != null) {
          final pointIndex = args.pointIndex!.toInt();

          if (pointIndex >= 0 && pointIndex < chartData.length) {
            final data = chartData[pointIndex];
            args.text = '${data.formattedMonthYear}\n₩ ${_formatAmount(data.amount)}';
          }
        }
      },
    );
  }

  // 금액 포맷팅 - 대규모 금액 처리 로직 추가
  String _formatAmount(double amount) {
    // 100만원 이상인 경우 간단한 단위 표시 추가
    if (amount >= 1000000) {
      // 100만 단위로 나누어 소수점 한 자리까지 표시 (ex: 1.5백만)
      final millionAmount = amount / 1000000;
      final formatter = NumberFormat('#,##0.0', 'ko');
      return '${formatter.format(millionAmount)}백만';
    } else if (amount >= 10000) {
      // 1만원 이상인 경우 만 단위로 표시
      final tenThousandAmount = amount / 10000;
      final formatter = NumberFormat('#,##0.0', 'ko');
      return '${formatter.format(tenThousandAmount)}만';
    } else {
      // 일반 금액은 기존 방식대로 콤마 포맷팅
      final formatter = NumberFormat('#,###', 'ko');
      return formatter.format(amount);
    }
  }
}

// 차트 데이터 모델 (연도 필드 추가)
class ExpenseData {
  final DateTime date;
  final double amount;
  final String formattedMonth;
  final String formattedMonthYear;
  final int year;  // 연도 필드 추가

  ExpenseData({
    required this.date,
    required this.amount,
    required this.formattedMonth,
    required this.formattedMonthYear,
    required this.year,
  });
}