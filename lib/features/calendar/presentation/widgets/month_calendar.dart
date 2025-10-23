// lib/features/calendar/presentation/widgets/month_calendar.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../controllers/calendar_controller.dart';
import '../../../quick_add/presentation/services/save_animation_service.dart';

class MonthCalendar extends StatelessWidget {
  final CalendarController controller;

  const MonthCalendar({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CalendarController>(
      init: controller,
      builder: (controller) {
        return Obx(() {
          return Container(
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
              children: [
                _buildCalendarHeader(),
                TableCalendar(
                  headerVisible: false, // 커스텀 헤더 사용
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: controller.focusedDay.value,
                  selectedDayPredicate: (day) {
                    return isSameDay(controller.selectedDay.value, day);
                  },
                  onDaySelected: controller.onDaySelected,
                  onPageChanged: controller.onPageChanged,
                  calendarFormat: CalendarFormat.month,
                  startingDayOfWeek: StartingDayOfWeek.sunday,
                  // 디자인 개선: 셀 여백과 패딩 조정으로 전체적인 가독성 향상
                  daysOfWeekHeight: 28, // 요일 헤더 높이 증가
                  rowHeight: 50, // 캘린더 행 높이 조정
                  calendarStyle: CalendarStyle(
                    // 선택된 날짜 스타일 - 빈 스타일 (커스텀 빌더에서 처리)
                    selectedDecoration: const BoxDecoration(
                      color: Colors.transparent,
                    ),
                    selectedTextStyle: const TextStyle(
                      color: Colors.transparent,
                    ),

                    // 오늘 날짜 스타일 - 빈 스타일 (커스텀 빌더에서 처리)
                    todayDecoration: const BoxDecoration(
                      color: Colors.transparent,
                    ),
                    todayTextStyle: const TextStyle(
                      color: Colors.transparent,
                    ),

                    // 주말 색상
                    weekendTextStyle: TextStyle(
                      color: Colors.red[400],
                      fontWeight: FontWeight.w500,
                    ),

                    // 다른 달의 날짜 스타일
                    outsideTextStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 13,
                    ),

                    // 기본 날짜 스타일
                    defaultTextStyle: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 14,
                    ),

                    // 날짜 셀 크기
                    cellMargin: const EdgeInsets.all(2),
                    cellPadding: EdgeInsets.zero,
                  ),
                  daysOfWeekStyle: DaysOfWeekStyle(
                    // 요일 헤더 스타일
                    weekdayStyle: TextStyle(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                    weekendStyle: TextStyle(
                      color: Colors.red[400],
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  calendarBuilders: CalendarBuilders(
                    // 마커 빌더 (거래 금액 표시)
                    // In month_calendar.dart, replace the existing markerBuilder with this version
                    markerBuilder: (context, date, events) {
                      // Get filtered transactions for this day
                      final transactions = controller.getEventsForDay(date);

                      // Calculate totals for each type
                      double income = 0;
                      double expense = 0;
                      double finance = 0;

                      for (var transaction in transactions) {
                        if (transaction.categoryType == 'INCOME') {
                          income += transaction.amount;
                        } else if (transaction.categoryType == 'EXPENSE') {
                          expense += transaction.amount.abs();
                        } else if (transaction.categoryType == 'FINANCE') {
                          finance += transaction.amount;
                        }
                      }

                      // No markers if no transactions
                      if (income == 0 && expense == 0 && finance == 0) {
                        return null;
                      }

                      // Count how many indicators we need to show
                      int indicatorCount = 0;
                      if (income > 0) indicatorCount++;
                      if (expense > 0) indicatorCount++;
                      if (finance != 0) indicatorCount++;

                      // Determine if we should stack vertically based on indicator count
                      bool useVerticalStack = indicatorCount > 2;

                      // Check if this date should be pulsing
                      final saveAnimController = Get.isRegistered<SaveAnimationController>()
                          ? Get.find<SaveAnimationController>()
                          : null;
                      final isPulsing = saveAnimController?.isPulsing(date) ?? false;

                      // Create a more compact display with pulse animation
                      return Positioned(
                        bottom: 1,
                        left: 0,
                        right: 0,
                        child: _PulsingMarker(
                          isPulsing: isPulsing,
                          child: useVerticalStack
                        // Vertical stack for 3 indicators
                            ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Income indicator (green)
                            if (income > 0)
                              _buildCompactIndicator(
                                '+${NumberFormat.compact().format(income)}',
                                Colors.green,
                              ),

                            // Expense indicator (red)
                            if (expense > 0)
                              _buildCompactIndicator(
                                '-${NumberFormat.compact().format(expense)}',
                                Colors.red,
                              ),

                            // Finance indicator (blue)
                            if (finance != 0)
                              _buildCompactIndicator(
                                (finance >= 0 ? '+' : '') + '${NumberFormat.compact().format(finance)}',
                                Colors.blue,
                              ),
                          ],
                        )
                        // Horizontal layout for 1-2 indicators
                            : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Income indicator (green)
                            if (income > 0)
                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: 1),
                                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  '+${NumberFormat.compact().format(income)}',
                                  style: TextStyle(
                                    color: Colors.green[700],
                                    fontSize: 8,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),

                            // Expense indicator (red)
                            if (expense > 0)
                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: 1),
                                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  '-${NumberFormat.compact().format(expense)}',
                                  style: TextStyle(
                                    color: Colors.red[700],
                                    fontSize: 8,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),

                            // Finance indicator (blue)
                            if (finance != 0)
                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: 1),
                                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  (finance >= 0 ? '+' : '') + '${NumberFormat.compact().format(finance)}',
                                  style: TextStyle(
                                    color: Colors.blue[700],
                                    fontSize: 8,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        ),
                      );
                    },

                    // 선택된 날짜 스타일 커스터마이징
                    selectedBuilder: (context, date, _) {
                      return Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          border: Border.all(color: AppColors.primary, width: 1.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            '${date.day}',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    },

                    // 오늘 날짜 스타일 커스터마이징
                    todayBuilder: (context, date, _) {
                      return Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400, width: 1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            '${date.day}',
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  // Helper method for compact vertical indicators
  Widget _buildCompactIndicator(String text, Color baseColor) {
    // Instead of color[700], use the base color directly
    return Container(
      margin: const EdgeInsets.only(top: 1),
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
      decoration: BoxDecoration(
        color: baseColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: baseColor,  // Use the base color directly
          fontSize: 7,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return Obx(() {
      final current = controller.focusedDay.value;
      final month = current.month;
      final year = current.year;
      final monthNames = ['1월', '2월', '3월', '4월', '5월', '6월', '7월', '8월', '9월', '10월', '11월', '12월'];

      return Container(
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.05),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, color: AppColors.primary),
              onPressed: () {
                // 이전 달로 이동
                controller.onPageChanged(
                  DateTime(controller.focusedDay.value.year, controller.focusedDay.value.month - 1, 1),
                );
              },
              tooltip: '이전 달',
            ),
            Text(
              '${year}년 ${monthNames[month - 1]}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, color: AppColors.primary),
              onPressed: () {
                // 다음 달로 이동
                controller.onPageChanged(
                  DateTime(controller.focusedDay.value.year, controller.focusedDay.value.month + 1, 1),
                );
              },
              tooltip: '다음 달',
            ),
          ],
        ),
      );
    });
  }
}

/// Pulsing marker widget with 0.5 → 1.5 → 1.0 scale animation
class _PulsingMarker extends StatefulWidget {
  final bool isPulsing;
  final Widget child;

  const _PulsingMarker({
    required this.isPulsing,
    required this.child,
  });

  @override
  State<_PulsingMarker> createState() => _PulsingMarkerState();
}

class _PulsingMarkerState extends State<_PulsingMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Scale: 0.5 -> 1.5 -> 1.0
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.5, end: 1.5)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.5, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(_PulsingMarker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPulsing && !oldWidget.isPulsing) {
      // Trigger pulse animation
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isPulsing ? _scaleAnimation.value : 1.0,
          child: widget.child,
        );
      },
      child: widget.child,
    );
  }
}