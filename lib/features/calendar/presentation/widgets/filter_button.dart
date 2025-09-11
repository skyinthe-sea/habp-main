// lib/features/calendar/presentation/widgets/filter_button.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/controllers/theme_controller.dart';
import '../controllers/calendar_filter_controller.dart';
import '../../domain/entities/calendar_filter.dart';

class FilterButton extends StatelessWidget {
  final CalendarFilterController controller;

  const FilterButton({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    
    return Obx(() {
      final currentFilter = controller.currentFilter.value;
      final hasActiveFilter = currentFilter.categoryType != null ||
          currentFilter.selectedCategoryIds.isNotEmpty;

      return Positioned(
        top: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _showFilterDialog,
            borderRadius: BorderRadius.circular(50),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: hasActiveFilter 
                    ? themeController.primaryColor 
                    : themeController.cardColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.filter_list_rounded,
                      size: 24,
                      color: hasActiveFilter 
                          ? Colors.white 
                          : themeController.textPrimaryColor,
                    ),
                  ),
                  if (hasActiveFilter && currentFilter.selectedCategoryIds.isNotEmpty)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${currentFilter.selectedCategoryIds.length}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  String _getFilterLabel(CalendarFilter filter) {
    if (filter.selectedCategoryIds.isNotEmpty) {
      return "카테고리";
    } else if (filter.categoryType == 'INCOME') {
      return "소득";
    } else if (filter.categoryType == 'EXPENSE') {
      return "지출";
    } else if (filter.categoryType == 'FINANCE') {
      return "재테크";
    } else {
      return "필터";
    }
  }

  void _showFilterDialog() {
    Get.dialog(
      FilterDialog(controller: controller),
      barrierDismissible: true,
    );
  }
}

class FilterDialog extends StatelessWidget {
  final CalendarFilterController controller;

  const FilterDialog({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: themeController.cardColor,
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
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "필터 선택",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: themeController.textPrimaryColor,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Obx(() {
                        final hasFilter = controller.currentFilter.value.categoryType != null ||
                            controller.currentFilter.value.selectedCategoryIds.isNotEmpty;

                        return hasFilter ? TextButton(
                          onPressed: controller.resetFilter,
                          child: Text("초기화", style: TextStyle(color: themeController.textSecondaryColor)),
                          style: TextButton.styleFrom(
                            foregroundColor: themeController.textSecondaryColor,
                          ),
                        ) : const SizedBox.shrink();
                      }),
                      IconButton(
                        onPressed: () => Get.back(),
                        icon: Icon(Icons.close, color: themeController.textSecondaryColor),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Filter options
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Obx(() {
                final currentFilter = controller.currentFilter.value;

                return Wrap(
                  spacing: 8,
                  runSpacing: 12,
                  children: [
                    _buildFilterChip(
                      label: "전체",
                      isSelected: currentFilter.categoryType == null &&
                          currentFilter.selectedCategoryIds.isEmpty,
                      onTap: () => controller.setFilter(CalendarFilter.all),
                      themeController: themeController,
                    ),
                    _buildFilterChip(
                      label: "소득",
                      isSelected: currentFilter.categoryType == 'INCOME' &&
                          currentFilter.selectedCategoryIds.isEmpty,
                      onTap: () => controller.setFilter(CalendarFilter.income),
                      color: themeController.isDarkMode ? Colors.green.shade400 : Colors.green,
                      themeController: themeController,
                    ),
                    _buildFilterChip(
                      label: "지출",
                      isSelected: currentFilter.categoryType == 'EXPENSE' &&
                          currentFilter.selectedCategoryIds.isEmpty,
                      onTap: () => controller.setFilter(CalendarFilter.expense),
                      color: themeController.isDarkMode ? Colors.red.shade400 : Colors.red,
                      themeController: themeController,
                    ),
                    _buildFilterChip(
                      label: "재테크",
                      isSelected: currentFilter.categoryType == 'FINANCE' &&
                          currentFilter.selectedCategoryIds.isEmpty,
                      onTap: () => controller.setFilter(CalendarFilter.finance),
                      color: themeController.isDarkMode ? Colors.blue.shade400 : Colors.blue,
                      themeController: themeController,
                    ),
                    _buildFilterChip(
                      label: "상세 필터",
                      isSelected: false,
                      onTap: () {
                        Get.back();
                        controller.openFilterModal();
                      },
                      icon: Icons.tune,
                      themeController: themeController,
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required ThemeController themeController,
    Color? color,
    IconData? icon,
  }) {
    final effectiveColor = color ?? themeController.primaryColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          onTap();
          if (label != "상세 필터") {
            Get.back(); // Close dialog after selection
          }
        },
        borderRadius: BorderRadius.circular(100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected 
                ? effectiveColor.withOpacity(0.1) 
                : themeController.isDarkMode 
                    ? Colors.grey.shade800
                    : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: isSelected 
                  ? effectiveColor 
                  : themeController.isDarkMode 
                      ? Colors.grey.shade600
                      : Colors.grey.shade300,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 18,
                  color: isSelected 
                      ? effectiveColor 
                      : themeController.textSecondaryColor,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isSelected 
                      ? effectiveColor 
                      : themeController.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}