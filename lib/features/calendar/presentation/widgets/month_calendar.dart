// lib/features/calendar/presentation/widgets/month_calendar.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../controllers/calendar_controller.dart';

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

                      // 마커가 없으면 빈 위젯 반환
                      if (income == 0 && expense == 0 && finance == 0) {
                        return null;
                      }

                      // 날짜 셀의 크기를 고려하여 마커 크기와 여백 조정
                      return Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none, // 자식 위젯이 잘리지 않도록 설정
                          children: [
                            // 부모 컨테이너 (최대 크기 제한)
                            Container(
                              constraints: const BoxConstraints(maxWidth: 52),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Income display (green)
                                  if (income > 0)
                                    Container(
                                      key: ValueKey('income-$date-$income'),
                                      margin: const EdgeInsets.only(bottom: 2),
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        income >= 1000000
                                            ? '+${(income / 1000000).toStringAsFixed(1)}M'
                                            : '+${NumberFormat.compact().format(income)}',
                                        style: TextStyle(
                                          color: Colors.green[700],
                                          fontSize: 9,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),

                                  // Expense display (red)
                                  if (expense > 0)
                                    Container(
                                      key: ValueKey('expense-$date-$expense'),
                                      margin: const EdgeInsets.only(bottom: 2),
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '-${NumberFormat.compact().format(expense)}',
                                        style: TextStyle(
                                          color: Colors.red[700],
                                          fontSize: 9,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),

                                  // Finance display (blue)
                                  if (finance != 0)
                                    Container(
                                      key: ValueKey('finance-$date-$finance'),
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        (finance >= 0 ? '+' : '') + '${NumberFormat.compact().format(finance)}',
                                        style: TextStyle(
                                          color: Colors.blue[700],
                                          fontSize: 9,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
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

  Widget _buildCalendarHeader() {
    return Obx(() {
      final current = controller.focusedDay.value;
      final month = current.month;
      final year = current.year;
      final monthNames = ['1월', '2월', '3월', '4월', '5월', '6월', '7월', '8월', '9월', '10월', '11월', '12월'];

      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
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