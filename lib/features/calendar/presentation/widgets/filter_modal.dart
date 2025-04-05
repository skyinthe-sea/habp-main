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
                  constraints: BoxConstraints(
                    maxHeight: Get.height * 0.7, // 최대 높이 제한
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // 내용에 맞게 크기 조정
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildModalHeader(),
                      // 스크롤 가능한 영역으로 변경
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildCategoryTypeSection(),
                              const SizedBox(height: 24),
                              _buildCategoriesSection(),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                      // 하단 버튼 영역 (스크롤과 별개로 고정)
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
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '필터 설정',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          InkWell(
            onTap: controller.closeFilterModal,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 20,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
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
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
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
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
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
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Obx(() {
          final categories = controller.filteredCategories;

          if (categories.isEmpty) {
            return Container(
              height: 80,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                '표시할 카테고리가 없습니다.',
                style: TextStyle(color: Colors.grey[600]),
              ),
            );
          }

          // 그리드 형태로 카테고리 표시
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, // 한 줄에 3개씩
              childAspectRatio: 2.5, // 가로:세로 비율
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              return _buildCategoryChip(categories[index]);
            },
          );
        }),
      ],
    );
  }

  Widget _buildCategoryChip(CategoryItem category) {
    final isSelected = controller.currentFilter.value.selectedCategoryIds
        .contains(category.id);

    return GestureDetector(
      onTap: () => controller.toggleCategory(category.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppColors.primary,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            category.name,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.primary,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildApplyButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: controller.applyFilter,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
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