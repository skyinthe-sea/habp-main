import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/controllers/theme_controller.dart';
import '../controllers/expense_controller.dart';

class PeriodSelector extends StatelessWidget {
  final ExpenseController controller;

  const PeriodSelector({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: themeController.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: themeController.isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _buildMonthSelector(themeController),
    );
  }

  Widget _buildMonthSelector(ThemeController themeController) {
    return Obx(() {
      final current = DateTime.parse('${controller.selectedPeriod.value}-01');
      final isCurrentMonth = current.year == DateTime.now().year && current.month == DateTime.now().month;
      final monthNames = ['1월', '2월', '3월', '4월', '5월', '6월', '7월', '8월', '9월', '10월', '11월', '12월'];
      
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: themeController.isDarkMode ? [
              themeController.primaryColor.withOpacity(0.2),
              themeController.surfaceColor,
            ] : [
              Colors.pink.shade50,
              const Color(0xFFF5F5F5),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: themeController.primaryColor.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 이전 달로 이동 버튼
            _buildNavigationButton(
              themeController: themeController,
              icon: Icons.chevron_left,
              onTap: controller.previousMonth,
            ),
            // 월 선택 드롭다운 버튼
            InkWell(
              onTap: () => _showMonthPickerDialog(Get.context!, themeController),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: themeController.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: themeController.primaryColor.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 14,
                      color: themeController.primaryColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${current.year}년 ${monthNames[current.month - 1]}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: themeController.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.arrow_drop_down,
                      size: 18,
                      color: themeController.primaryColor,
                    ),
                  ],
                ),
              ),
            ),
            // 다음 달로 이동 버튼
            _buildNavigationButton(
              themeController: themeController,
              icon: Icons.chevron_right,
              onTap: isCurrentMonth ? null : controller.nextMonth,
              isDisabled: isCurrentMonth,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildNavigationButton({
    required ThemeController themeController,
    required IconData icon,
    required VoidCallback? onTap,
    bool isDisabled = false,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: isDisabled 
                ? (themeController.isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100)
                : themeController.cardColor,
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(
              icon,
              color: isDisabled 
                  ? (themeController.isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400)
                  : themeController.primaryColor,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showMonthPickerDialog(BuildContext context, ThemeController themeController) async {
    final current = DateTime.parse('${controller.selectedPeriod.value}-01');
    int selectedYear = current.year;
    final monthNames = ['1월', '2월', '3월', '4월', '5월', '6월', '7월', '8월', '9월', '10월', '11월', '12월'];
    
    final result = await showDialog<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: themeController.cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      setState(() {
                        selectedYear--;
                      });
                    },
                  ),
                  Text(
                    '$selectedYear년',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: themeController.textPrimaryColor,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: selectedYear < DateTime.now().year
                        ? () {
                            setState(() {
                              selectedYear++;
                            });
                          }
                        : null,
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 3,
                  childAspectRatio: 2.5,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  children: List.generate(12, (index) {
                    final month = index + 1;
                    final isSelected = selectedYear == current.year && month == current.month;
                    final isFutureMonth = selectedYear == DateTime.now().year && month > DateTime.now().month;
                    
                    return InkWell(
                      onTap: isFutureMonth ? null : () {
                        Navigator.of(context).pop(DateTime(selectedYear, month));
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? themeController.primaryColor
                              : (isFutureMonth 
                                  ? Colors.grey.withOpacity(0.2)
                                  : themeController.surfaceColor),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? themeController.primaryColor
                                : Colors.grey.withOpacity(0.3),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            monthNames[index],
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : (isFutureMonth
                                      ? Colors.grey
                                      : themeController.textPrimaryColor),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    '취소',
                    style: TextStyle(color: themeController.textSecondaryColor),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      // ExpenseController의 period format에 맞게 변경
      final formattedPeriod = '${result.year}-${result.month.toString().padLeft(2, '0')}';
      controller.selectedPeriod.value = formattedPeriod;
      controller.fetchBudgetStatus();
    }
  }
}