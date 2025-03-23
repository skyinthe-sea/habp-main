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
              calendarStyle: CalendarStyle(
                // 선택된 날짜 스타일
                selectedDecoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border.all(color: AppColors.primary, width: 1),
                  borderRadius: BorderRadius.circular(12),
                ),
                selectedTextStyle: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),

                // 오늘 날짜 스타일
                todayDecoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                todayTextStyle: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),

                // 주말 색상
                weekendTextStyle: const TextStyle(color: Colors.red),

                // 다른 달의 날짜 스타일
                outsideTextStyle: TextStyle(color: Colors.grey.shade400),

                // 기본 날짜 스타일
                defaultTextStyle: const TextStyle(color: Colors.black),

                // 날짜 셀 크기
                cellMargin: const EdgeInsets.all(2),
                cellPadding: EdgeInsets.zero,
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                // 요일 헤더 스타일
                weekdayStyle: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
                weekendStyle: TextStyle(
                  color: Colors.red[400],
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
              calendarBuilders: CalendarBuilders(
                // 마커 빌더 (거래 금액 표시)
                markerBuilder: (context, date, events) {
                  final income = controller.getDayIncome(date);
                  final expense = controller.getDayExpense(date);

                  print('data = :$date, 수입: $income, 지출: $expense');

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 수입 표시
                      if (income > 0)
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            income >= 1000000
                                ? '+${(income / 1000000).toStringAsFixed(1)}M원'
                                : '+${NumberFormat.compact().format(income)}원',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                      // 지출 표시
                      if (expense > 0)
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '-${NumberFormat.compact().format(expense)}원',
                            style: TextStyle(
                              color: Colors.red[700],
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  );
                },

                // 선택된 날짜 스타일 커스터마이징
                selectedBuilder: (context, date, _) {
                  return Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.primary, width: 1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '${date.day}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
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
  }

  Widget _buildCalendarHeader() {
    // 현재 표시 중인 년월 포맷
    final headerText = DateFormat('yyyy년 M월').format(controller.focusedDay.value);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.grey),
            onPressed: () {
              // 이전 달로 이동
              controller.onPageChanged(
                DateTime(controller.focusedDay.value.year, controller.focusedDay.value.month - 1, 1),
              );
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          Text(
            headerText,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.grey),
            onPressed: () {
              // 다음 달로 이동
              controller.onPageChanged(
                DateTime(controller.focusedDay.value.year, controller.focusedDay.value.month + 1, 1),
              );
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}