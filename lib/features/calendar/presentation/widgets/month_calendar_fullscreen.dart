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
                  rowHeight: 100, // 달력 셀 높이 증가 (70 -> 100)
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
                    cellMargin: const EdgeInsets.all(4),
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
                    // 마커 빌더 (거래 금액 표시) - 날짜 아래에 세로로 표시되도록 수정
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

                      // 마크업을 세로로 보여주기 위한 위젯
                      return Positioned(
                        top: 30, // 날짜 텍스트 아래쪽에 위치
                        left: 8,
                        right: 8,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Income indicator (green)
                            if (income > 0)
                              _buildVerticalIndicator(
                                '+${NumberFormat.compact().format(income)}',
                                Colors.green,
                              ),

                            // Expense indicator (red)
                            if (expense > 0)
                              _buildVerticalIndicator(
                                '-${NumberFormat.compact().format(expense)}',
                                Colors.red,
                              ),

                            // Finance indicator (blue)
                            if (finance != 0)
                              _buildVerticalIndicator(
                                (finance >= 0 ? '+' : '') + '${NumberFormat.compact().format(finance)}',
                                Colors.blue,
                              ),
                          ],
                        ),
                      );
                    },

                    // 선택된 날짜 스타일 커스터마이징 - 정사각형으로 변경
                    selectedBuilder: (context, date, _) {
                      return Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          border: Border.all(color: AppColors.primary, width: 1.5),
                          borderRadius: BorderRadius.circular(8), // 약간 둥근 정사각형 모양
                          shape: BoxShape.rectangle, // 명시적으로 직사각형 형태 지정
                        ),
                        child: Column(
                          children: [
                            // 날짜는 상단에 배치
                            Container(
                              width: 30, // 정사각형 효과를 위한 너비 고정
                              height: 30, // 정사각형 효과를 위한 높이 고정
                              margin: const EdgeInsets.only(top: 6),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.2),
                                shape: BoxShape.circle, // 원형 배경으로 날짜 표시
                              ),
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

                    // 오늘 날짜 스타일 커스터마이징 - 정사각형으로 변경
                    todayBuilder: (context, date, _) {
                      return Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400, width: 1),
                          borderRadius: BorderRadius.circular(8), // 약간 둥근 정사각형 모양
                        ),
                        child: Column(
                          children: [
                            // 날짜는 상단에 배치
                            Container(
                              width: 30, // 정사각형 효과를 위한 너비 고정
                              height: 30, // 정사각형 효과를 위한 높이 고정
                              margin: const EdgeInsets.only(top: 6),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                shape: BoxShape.circle, // 원형 배경으로 날짜 표시
                              ),
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

                    // 기본 날짜 스타일 커스터마이징 - 마커 공간 확보를 위한 스타일 조정
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
                            // 날짜는 상단에 배치 - 원형 배경
                            Container(
                              width: 30, // 정사각형 효과를 위한 너비 고정
                              height: 30, // 정사각형 효과를 위한 높이 고정
                              margin: const EdgeInsets.only(top: 6),
                              alignment: Alignment.center,
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
                            // 날짜는 상단에 배치 - 원형 배경
                            Container(
                              width: 30, // 정사각형 효과를 위한 너비 고정
                              height: 30, // 정사각형 효과를 위한 높이 고정
                              margin: const EdgeInsets.only(top: 6),
                              alignment: Alignment.center,
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

  // 세로 배치를 위한 마크업 인디케이터
  Widget _buildVerticalIndicator(String text, Color baseColor) {
    return Container(
      width: double.infinity, // 가로 전체 차지
      margin: const EdgeInsets.only(bottom: 3),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: baseColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: baseColor,
            fontSize: 10,
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