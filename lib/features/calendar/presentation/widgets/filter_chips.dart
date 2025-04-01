import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../controllers/calendar_filter_controller.dart';
import '../../domain/entities/calendar_filter.dart';

class FilterChips extends StatelessWidget {
  final CalendarFilterController controller;

  const FilterChips({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final currentFilter = controller.currentFilter.value;

      return Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            // 전체 필터 칩
            _buildFilterChip(
              isSelected: currentFilter.categoryType == null && currentFilter.selectedCategoryIds.isEmpty,
              label: '전체',
              onTap: () => controller.setFilter(CalendarFilter.all),
            ),

            // 소득 필터 칩
            _buildFilterChip(
              isSelected: currentFilter.categoryType == 'INCOME' && currentFilter.selectedCategoryIds.isEmpty,
              label: '소득',
              onTap: () => controller.setFilter(CalendarFilter.income),
            ),

            // 지출 필터 칩
            _buildFilterChip(
              isSelected: currentFilter.categoryType == 'EXPENSE' && currentFilter.selectedCategoryIds.isEmpty,
              label: '지출',
              onTap: () => controller.setFilter(CalendarFilter.expense),
            ),

            // 재테크 필터 칩
            _buildFilterChip(
              isSelected: currentFilter.categoryType == 'FINANCE' && currentFilter.selectedCategoryIds.isEmpty,
              label: '재테크',
              onTap: () => controller.setFilter(CalendarFilter.finance),
            ),

            // 사용자 정의 필터 또는 카테고리 선택됨
            if (currentFilter.selectedCategoryIds.isNotEmpty)
              _buildFilterChip(
                isSelected: true,
                label: '카테고리 ${currentFilter.selectedCategoryIds.length}개',
                onTap: controller.openFilterModal,
              ),

            // 커스텀 필터 버튼
            _buildFilterButton(
              onTap: controller.openFilterModal,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildFilterChip({
    required bool isSelected,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppColors.primary,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton({
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primary,
            width: 1,
          ),
        ),
        child: const Icon(
          Icons.filter_list,
          color: AppColors.primary,
          size: 18,
        ),
      ),
    );
  }
}