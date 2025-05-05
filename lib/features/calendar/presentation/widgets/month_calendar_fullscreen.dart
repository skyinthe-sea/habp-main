// lib/features/calendar/presentation/widgets/month_calendar_fullscreen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../controllers/calendar_controller.dart';

class MonthCalendarFullscreen extends StatelessWidget {
  final CalendarController controller;
  final Function(DateTime) onDateTap;

  const MonthCalendarFullscreen({
    Key? key,
    required this.controller,
    required this.onDateTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CalendarController>(
      init: controller,
      builder: (controller) {
        return Obx(() {
          return Column(
            children: [
              _buildCalendarHeader(),
              Expanded(
                child: TableCalendar(
                  headerVisible: false, // 커스텀 헤더 사용
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: controller.focusedDay.value,
                  selectedDayPredicate: (day) {
                    return isSameDay(controller.selectedDay.value, day);
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    // 컨트롤러 상태 업데이트
                    controller.onDaySelected(selectedDay, focusedDay);

                    // 날짜 선택 시 항상 다이얼로그 표시 (동일한 날짜 재선택 시에도)
                    onDateTap(selectedDay);
                  },
                  onPageChanged: controller.onPageChanged,
                  calendarFormat: CalendarFormat.month,
                  startingDayOfWeek: StartingDayOfWeek.sunday,
                  // 디자인 개선: 더 여유로운 공간 확보를 위해 높이 증가
                  daysOfWeekHeight: 32,
                  rowHeight: 70, // 더 큰 달력 셀 높이 설정
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
                      fontSize: 15,
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
                    // 마커 빌더 (거래 금액 표시) - 날짜 아래에 표시되도록 새로 구현
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

                      // 마크업을 보여줄 영역 - 날짜 아래에 고정 위치
                      return Positioned(
                        bottom: 6, // 하단에서의 여백
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Income indicator (green)
                              if (income > 0)
                                _buildIndicator(
                                  '+${NumberFormat.compact().format(income)}',
                                  Colors.green,
                                ),

                              // Expense indicator (red)
                              if (expense > 0)
                                _buildIndicator(
                                  '-${NumberFormat.compact().format(expense)}',
                                  Colors.red,
                                ),

                              // Finance indicator (blue)
                              if (finance != 0)
                                _buildIndicator(
                                  (finance >= 0 ? '+' : '') + '${NumberFormat.compact().format(finance)}',
                                  Colors.blue,
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
                        child: Column(
                          children: [
                            // 날짜는 상단에 배치
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '${date.day}',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            // 마커는 markerBuilder에서 처리됨
                          ],
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
                        child: Column(
                          children: [
                            // 날짜는 상단에 배치
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '${date.day}',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            // 마커는 markerBuilder에서 처리됨
                          ],
                        ),
                      );
                    },

                    // 기본 날짜 스타일 커스터마이징 (마커 공간 확보)
                    defaultBuilder: (context, date, _) {
                      // 주말 색상 설정
                      Color textColor = Colors.grey[800]!;
                      if (date.weekday == DateTime.sunday || date.weekday == DateTime.saturday) {
                        textColor = Colors.red[400]!;
                      }

                      return Container(
                        margin: const EdgeInsets.all(4),
                        child: Column(
                          children: [
                            // 날짜는 상단에 배치
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '${date.day}',
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            // 마커는 markerBuilder에서 처리됨
                          ],
                        ),
                      );
                    },

                    // 다른 달 날짜 스타일 커스터마이징
                    outsideBuilder: (context, date, _) {
                      return Container(
                        margin: const EdgeInsets.all(4),
                        child: Column(
                          children: [
                            // 날짜는 상단에 배치
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '${date.day}',
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            // 마커는 표시하지 않음
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        });
      },
    );
  }

  // 고정된 사이즈의 일관된 마크업 인디케이터 생성
  Widget _buildIndicator(String text, Color baseColor) {
    return Container(
      width: 35, // 모든 인디케이터에 동일한 너비 적용
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      decoration: BoxDecoration(
        color: baseColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: baseColor,
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
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
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.05),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
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