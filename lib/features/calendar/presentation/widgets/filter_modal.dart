import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/calendar_filter.dart';
import '../controllers/calendar_filter_controller.dart';
import '../../domain/entities/category_item.dart';

class FilterModal extends StatelessWidget {
  final CalendarFilterController controller;

  const FilterModal({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.isFilterModalVisible.value) {
        return const SizedBox.shrink();
      }

      return Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: controller.closeFilterModal,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: GestureDetector(
                onTap: () {}, // 모달 내부 클릭 시 이벤트 전파 방지
                child: Container(
                  width: Get.width * 0.85,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildModalHeader(),
                      const Divider(height: 32),
                      _buildCategoryTypeSection(),
                      const SizedBox(height: 24),
                      _buildCategoriesSection(),
                      const SizedBox(height: 24),
                      _buildApplyButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildModalHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          '필터 설정',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: controller.closeFilterModal,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _buildCategoryTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '거래 유형',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              _buildTypeToggle(null, '전체'),
              _buildTypeToggle('INCOME', '소득'),
              _buildTypeToggle('EXPENSE', '지출'),
              _buildTypeToggle('FINANCE', '재테크'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTypeToggle(String? type, String label) {
    final isSelected = controller.currentFilter.value.categoryType == type;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          // 각 타입에 맞는 적절한 필터 객체 설정
          if (type == null) {
            controller.setFilter(CalendarFilter.all);
          } else if (type == 'INCOME') {
            controller.setFilter(CalendarFilter.income);
          } else if (type == 'EXPENSE') {
            controller.setFilter(CalendarFilter.expense);
          } else if (type == 'FINANCE') {
            controller.setFilter(CalendarFilter.finance);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '카테고리',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120, // 적절한 높이로 조정
          child: Obx(() {
            final categories = controller.filteredCategories;

            if (categories.isEmpty) {
              return const Center(
                child: Text('표시할 카테고리가 없습니다.'),
              );
            }

            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories
                  .map((category) => _buildCategoryChip(category))
                  .toList(),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(CategoryItem category) {
    final isSelected = controller.currentFilter.value.selectedCategoryIds
        .contains(category.id);

    return GestureDetector(
      onTap: () => controller.toggleCategory(category.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppColors.primary,
            width: 1.5,
          ),
        ),
        child: Text(
          category.name,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildApplyButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: controller.applyFilter,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          '필터 적용하기',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
