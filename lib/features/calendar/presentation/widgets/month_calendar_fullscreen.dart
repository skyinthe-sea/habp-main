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
          // Use CustomScrollView to support both scrolling and swiping
          return CustomScrollView(
            // Use BouncingScrollPhysics for a smoother scroll experience
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Sticky header that stays at the top during scrolling
              SliverAppBar(
                backgroundColor: Colors.white,
                pinned: true,
                elevation: 0,
                automaticallyImplyLeading: false,
                title: _buildCalendarHeader(),
                toolbarHeight: 60,
              ),

              // Calendar content in a sliver
              SliverToBoxAdapter(
                child: TableCalendar(
                  headerVisible: false, // Custom header is used in SliverAppBar
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: controller.focusedDay.value,
                  selectedDayPredicate: (day) {
                    return isSameDay(controller.selectedDay.value, day);
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    // Update controller state
                    controller.onDaySelected(selectedDay, focusedDay);
                    // Show dialog on date tap
                    onDateTap(selectedDay);
                  },
                  onPageChanged: controller.onPageChanged,
                  calendarFormat: CalendarFormat.month,
                  startingDayOfWeek: StartingDayOfWeek.sunday,
                  // Compact design for better fit
                  daysOfWeekHeight: 26,
                  rowHeight: 70, // Reduced height to prevent bottom cutoff
                  calendarStyle: CalendarStyle(
                    // Selected date style - empty style (handled in custom builder)
                    selectedDecoration: const BoxDecoration(
                      color: Colors.transparent,
                    ),
                    selectedTextStyle: const TextStyle(
                      color: Colors.transparent,
                    ),

                    // Today's date style - empty style (handled in custom builder)
                    todayDecoration: const BoxDecoration(
                      color: Colors.transparent,
                    ),
                    todayTextStyle: const TextStyle(
                      color: Colors.transparent,
                    ),

                    // Weekend color
                    weekendTextStyle: TextStyle(
                      color: Colors.red[400],
                      fontWeight: FontWeight.w500,
                    ),

                    // Other month date style
                    outsideTextStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 11,
                    ),

                    // Default date style
                    defaultTextStyle: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 13,
                    ),

                    // Date cell size
                    cellMargin: const EdgeInsets.all(4),
                    cellPadding: EdgeInsets.zero,
                  ),
                  daysOfWeekStyle: DaysOfWeekStyle(
                    // Weekday header style
                    weekdayStyle: TextStyle(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                    weekendStyle: TextStyle(
                      color: Colors.red[400],
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  calendarBuilders: CalendarBuilders(
                    // Marker builder (showing transaction amounts)
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

                      // Vertical layout for markers
                      return Positioned(
                        top: 24, // Position below date text (reduced from 30)
                        left: 2,
                        right: 2,
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

                    // Selected date style customization - square design
                    selectedBuilder: (context, date, _) {
                      return Container(
                        margin: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          border: Border.all(color: AppColors.primary, width: 1.5),
                          borderRadius: BorderRadius.circular(6),
                          shape: BoxShape.rectangle,
                        ),
                        child: Column(
                          children: [
                            // Date at the top
                            Container(
                              width: 24,
                              height: 24,
                              margin: const EdgeInsets.only(top: 4),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${date.day}',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            // Markers handled in markerBuilder
                          ],
                        ),
                      );
                    },

                    // Today's date style customization - square design
                    todayBuilder: (context, date, _) {
                      return Container(
                        margin: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400, width: 1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Column(
                          children: [
                            // Date at the top with circular background
                            Container(
                              width: 24,
                              height: 24,
                              margin: const EdgeInsets.only(top: 4),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${date.day}',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            // Markers handled in markerBuilder
                          ],
                        ),
                      );
                    },

                    // Default date style customization - space for markers
                    defaultBuilder: (context, date, _) {
                      // Weekend color setting
                      Color textColor = Colors.grey[800]!;
                      if (date.weekday == DateTime.sunday || date.weekday == DateTime.saturday) {
                        textColor = Colors.red[400]!;
                      }

                      return Container(
                        margin: const EdgeInsets.all(3),
                        child: Column(
                          children: [
                            // Date at the top
                            Container(
                              width: 24,
                              height: 24,
                              margin: const EdgeInsets.only(top: 4),
                              alignment: Alignment.center,
                              child: Text(
                                '${date.day}',
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            // Markers handled in markerBuilder
                          ],
                        ),
                      );
                    },

                    // Other month date style customization
                    outsideBuilder: (context, date, _) {
                      return Container(
                        margin: const EdgeInsets.all(3),
                        child: Column(
                          children: [
                            // Date at the top
                            Container(
                              width: 24,
                              height: 24,
                              margin: const EdgeInsets.only(top: 4),
                              alignment: Alignment.center,
                              child: Text(
                                '${date.day}',
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            // No markers for dates outside current month
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Add extra space at the bottom for small devices
              const SliverToBoxAdapter(
                child: SizedBox(height: 40),
              ),
            ],
          );
        });
      },
    );
  }

  // Vertical indicator for markers
  Widget _buildVerticalIndicator(String text, Color baseColor) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      decoration: BoxDecoration(
        color: baseColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: baseColor,
            fontSize: 8,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  // Calendar header widget
  Widget _buildCalendarHeader() {
    final current = controller.focusedDay.value;
    final month = current.month;
    final year = current.year;
    final monthNames = ['1월', '2월', '3월', '4월', '5월', '6월', '7월', '8월', '9월', '10월', '11월', '12월'];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
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
              // Move to previous month
              controller.onPageChanged(
                DateTime(controller.focusedDay.value.year, controller.focusedDay.value.month - 1, 1),
              );
            },
            tooltip: '이전 달',
          ),
          Text(
            '${year}년 ${monthNames[month - 1]}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: AppColors.primary),
            onPressed: () {
              // Move to next month
              controller.onPageChanged(
                DateTime(controller.focusedDay.value.year, controller.focusedDay.value.month + 1, 1),
              );
            },
            tooltip: '다음 달',
          ),
        ],
      ),
    );
  }
}