// lib/features/onboarding/presentation/widgets/date_grid.dart

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class DateSelectionGrid extends StatelessWidget {
  final int selectedDay;
  final Function(int) onDaySelected;
  final int currentDay;

  const DateSelectionGrid({
    Key? key,
    required this.selectedDay,
    required this.onDaySelected,
    this.currentDay = 0, // Default to no current day highlight
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Instead of using GridView.builder which causes intrinsic size issues,
    // we'll use a fixed layout with Wrap
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildGridHeader(),
          const Divider(height: 1, thickness: 1),
          const SizedBox(height: 12),
          _buildDaysGrid(),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildGridHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '날짜 선택',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaysGrid() {
    // Create a 7x5 grid (with some empty cells at the end)
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          // Days of week header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: const [
              _WeekdayLabel(day: "월"),
              _WeekdayLabel(day: "화"),
              _WeekdayLabel(day: "수"),
              _WeekdayLabel(day: "목"),
              _WeekdayLabel(day: "금"),
              _WeekdayLabel(day: "토"),
              _WeekdayLabel(day: "일"),
            ],
          ),
          const SizedBox(height: 8),
          // Days grid
          Wrap(
            spacing: 8, // horizontal spacing
            runSpacing: 8, // vertical spacing
            alignment: WrapAlignment.center,
            children: List.generate(31, (index) {
              final day = index + 1;
              final isSelected = day == selectedDay;
              final isCurrentDay = day == currentDay;
              final isLastDay = day == 31;

              return _DayCell(
                day: day,
                isSelected: isSelected,
                isCurrentDay: isCurrentDay,
                isLastDay: isLastDay,
                onTap: () => onDaySelected(day),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  final String day;

  const _WeekdayLabel({required this.day});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      child: Text(
        day,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final bool isSelected;
  final bool isCurrentDay;
  final bool isLastDay;
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    required this.isSelected,
    required this.isCurrentDay,
    required this.isLastDay,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isCurrentDay ? AppColors.primary.withOpacity(0.1) : Colors.transparent),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isCurrentDay ? AppColors.primary : Colors.transparent),
            width: 1.5,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              day.toString(),
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isLastDay ? AppColors.primary : Colors.black87),
                fontSize: 14,
                fontWeight: isSelected || isLastDay ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isLastDay)
              Positioned(
                bottom: -1,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white.withOpacity(0.3) : AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '말일',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : AppColors.primary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Dialog that shows the date grid
class DaySelectionDialog extends StatelessWidget {
  final int initialDay;
  final Function(int) onDaySelected;

  const DaySelectionDialog({
    Key? key,
    required this.initialDay,
    required this.onDaySelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    int selectedDay = initialDay;
    final today = DateTime.now().day;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 5,
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DateSelectionGrid(
                  selectedDay: selectedDay,
                  currentDay: today,
                  onDaySelected: (day) {
                    setState(() {
                      selectedDay = day;
                    });
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          '취소',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          onDaySelected(selectedDay);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          elevation: 0,
                        ),
                        child: const Text(
                          '선택',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}