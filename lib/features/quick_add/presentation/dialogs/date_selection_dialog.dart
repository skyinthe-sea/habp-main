// lib/features/quick_add/presentation/dialogs/date_selection_dialog.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../core/constants/app_colors.dart';
import '../controllers/quick_add_controller.dart';
import 'amount_input_dialog.dart';
import 'category_selection_dialog.dart';

/// Third dialog in the quick add flow
/// Allows selecting the transaction date
class DateSelectionDialog extends StatefulWidget {
  const DateSelectionDialog({Key? key}) : super(key: key);

  @override
  State<DateSelectionDialog> createState() => _DateSelectionDialogState();
}

class _DateSelectionDialogState extends State<DateSelectionDialog> {
  late DateTime _selectedDate;
  late DateTime _focusedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _focusedDate = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<QuickAddController>();

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dialog title and back button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '날짜 선택',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_back, size: 20),
                  onPressed: () {
                    // Go back to the previous dialog
                    Navigator.of(context).pop();

                    // Show the category selection dialog again
                    showGeneralDialog(
                      context: context,
                      pageBuilder: (_, __, ___) => const CategorySelectionDialog(),
                      transitionBuilder: (context, animation, secondaryAnimation, child) {
                        // 풍선 터지는 효과를 위한 커브 설정
                        final curve = CurvedAnimation(
                          parent: animation,
                          curve: Curves.elasticOut, // 가장 중요한 설정! 풍선 튕김 효과
                        );

                        // 크기 애니메이션을 적용
                        return ScaleTransition(
                          scale: curve, // elasticOut 커브를 적용
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        );
                      },
                      // 매우 빠른 애니메이션을 위해 시간 단축
                      transitionDuration: const Duration(milliseconds: 150),
                      barrierDismissible: true,
                      barrierLabel: '',
                      barrierColor: Colors.black.withOpacity(0.5),
                    );
                  },
                  color: Colors.grey,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Calendar widget
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDate,
              calendarFormat: CalendarFormat.month,
              startingDayOfWeek: StartingDayOfWeek.sunday,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDate, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDate = selectedDay;
                  _focusedDate = focusedDay; // update focused day for UI
                });

                // Set date in the controller
                controller.setTransactionDate(_selectedDate);

                // Proceed to the next dialog immediately after selecting a date
                Navigator.of(context).pop();

                // Show amount input dialog with animation
                showGeneralDialog(
                  context: context,
                  pageBuilder: (_, __, ___) => const AmountInputDialog(), // 다음 다이얼로그 컴포넌트
                  transitionBuilder: (context, animation, secondaryAnimation, child) {
                    // 풍선 터지는 효과를 위한 커브 설정
                    final curve = CurvedAnimation(
                      parent: animation,
                      curve: Curves.elasticOut, // 가장 중요한 설정! 풍선 튕김 효과
                    );

                    // 크기 애니메이션을 적용
                    return ScaleTransition(
                      scale: curve, // elasticOut 커브를 적용
                      child: FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                    );
                  },
                  // 매우 빠른 애니메이션을 위해 시간 단축
                  transitionDuration: const Duration(milliseconds: 150),
                  barrierDismissible: true,
                  barrierLabel: '',
                  barrierColor: Colors.black.withOpacity(0.5),
                );
              },
              headerStyle: HeaderStyle(
                titleCentered: true,
                formatButtonVisible: false,
                titleTextStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                leftChevronIcon: const Icon(
                  Icons.chevron_left,
                  color: AppColors.primary,
                ),
                rightChevronIcon: const Icon(
                  Icons.chevron_right,
                  color: AppColors.primary,
                ),
              ),
              calendarStyle: CalendarStyle(
                markersMaxCount: 0, // No markers
                todayDecoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Today button for quick selection
            Center(
              child: TextButton(
                onPressed: () {
                  final today = DateTime.now();
                  setState(() {
                    _selectedDate = today;
                    _focusedDate = today;
                  });
                  controller.setTransactionDate(today);

                  // Proceed to next dialog
                  Navigator.of(context).pop();

                  // Show amount input dialog with animation
                  showGeneralDialog(
                    context: context,
                    pageBuilder: (_, __, ___) => const AmountInputDialog(), // 다음 다이얼로그 컴포넌트
                    transitionBuilder: (context, animation, secondaryAnimation, child) {
                      // 풍선 터지는 효과를 위한 커브 설정
                      final curve = CurvedAnimation(
                        parent: animation,
                        curve: Curves.elasticOut, // 가장 중요한 설정! 풍선 튕김 효과
                      );

                      // 크기 애니메이션을 적용
                      return ScaleTransition(
                        scale: curve, // elasticOut 커브를 적용
                        child: FadeTransition(
                          opacity: animation,
                          child: child,
                        ),
                      );
                    },
                    // 매우 빠른 애니메이션을 위해 시간 단축
                    transitionDuration: const Duration(milliseconds: 150),
                    barrierDismissible: true,
                    barrierLabel: '',
                    barrierColor: Colors.black.withOpacity(0.5),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: const Text('오늘 선택'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}