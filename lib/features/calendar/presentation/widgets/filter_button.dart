// lib/features/calendar/presentation/widgets/filter_button.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
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
    return Obx(() {
      final currentFilter = controller.currentFilter.value;
      final hasActiveFilter = currentFilter.categoryType != null ||
          currentFilter.selectedCategoryIds.isNotEmpty;

      return Positioned(
        right: 16,
        bottom: 16,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _showFilterOptions,
            borderRadius: BorderRadius.circular(28),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: hasActiveFilter ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.filter_list_rounded,
                    size: 20,
                    color: hasActiveFilter ? Colors.white : AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getFilterLabel(currentFilter),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: hasActiveFilter ? Colors.white : AppColors.primary,
                    ),
                  ),
                  if (hasActiveFilter) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        currentFilter.selectedCategoryIds.isNotEmpty
                            ? '${currentFilter.selectedCategoryIds.length}'
                            : '',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
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

  void _showFilterOptions() {
    Get.bottomSheet(
      FilterBottomSheet(controller: controller),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}

class FilterBottomSheet extends StatelessWidget {
  final CalendarFilterController controller;

  const FilterBottomSheet({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle indicator
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "필터 선택",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Obx(() {
                  final hasFilter = controller.currentFilter.value.categoryType != null ||
                      controller.currentFilter.value.selectedCategoryIds.isNotEmpty;

                  return hasFilter ? TextButton(
                    onPressed: controller.resetFilter,
                    child: const Text("초기화"),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                    ),
                  ) : const SizedBox.shrink();
                }),
              ],
            ),
          ),

          // Filter options
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
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
                  ),
                  _buildFilterChip(
                    label: "소득",
                    isSelected: currentFilter.categoryType == 'INCOME' &&
                        currentFilter.selectedCategoryIds.isEmpty,
                    onTap: () => controller.setFilter(CalendarFilter.income),
                    color: Colors.green,
                  ),
                  _buildFilterChip(
                    label: "지출",
                    isSelected: currentFilter.categoryType == 'EXPENSE' &&
                        currentFilter.selectedCategoryIds.isEmpty,
                    onTap: () => controller.setFilter(CalendarFilter.expense),
                    color: Colors.red,
                  ),
                  _buildFilterChip(
                    label: "재테크",
                    isSelected: currentFilter.categoryType == 'FINANCE' &&
                        currentFilter.selectedCategoryIds.isEmpty,
                    onTap: () => controller.setFilter(CalendarFilter.finance),
                    color: Colors.blue,
                  ),
                  _buildFilterChip(
                    label: "상세 필터",
                    isSelected: false,
                    onTap: () {
                      Get.back();
                      controller.openFilterModal();
                    },
                    icon: Icons.tune,
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? color,
    IconData? icon,
  }) {
    final effectiveColor = color ?? AppColors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          onTap();
          if (label != "상세 필터") {
            Get.back(); // Close bottom sheet after selection
          }
        },
        borderRadius: BorderRadius.circular(100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? effectiveColor.withOpacity(0.1) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: isSelected ? effectiveColor : Colors.grey.shade300,
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
                  color: isSelected ? effectiveColor : Colors.grey.shade700,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? effectiveColor : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}