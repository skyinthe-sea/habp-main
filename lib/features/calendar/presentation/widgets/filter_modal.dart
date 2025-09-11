import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/controllers/theme_controller.dart';
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
    final ThemeController themeController = Get.find<ThemeController>();
    
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
                    color: themeController.cardColor,
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
                      _buildModalHeader(themeController),
                      // 스크롤 가능한 영역으로 변경
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildCategoryTypeSection(themeController),
                              const SizedBox(height: 24),
                              _buildCategoriesSection(themeController),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                      // 하단 버튼 영역 (스크롤과 별개로 고정)
                      _buildApplyButton(themeController),
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

  Widget _buildModalHeader(ThemeController themeController) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      decoration: BoxDecoration(
        color: themeController.cardColor,
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
          Text(
            '필터 설정',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: themeController.textPrimaryColor,
            ),
          ),
          InkWell(
            onTap: controller.closeFilterModal,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: themeController.isDarkMode 
                    ? Colors.grey.shade700.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                size: 20,
                color: themeController.textSecondaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTypeSection(ThemeController themeController) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '거래 유형',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: themeController.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: themeController.isDarkMode 
                ? Colors.grey.shade800
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _buildTypeToggle(null, '전체', themeController),
              _buildTypeToggle('INCOME', '소득', themeController),
              _buildTypeToggle('EXPENSE', '지출', themeController),
              _buildTypeToggle('FINANCE', '재테크', themeController),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTypeToggle(String? type, String label, ThemeController themeController) {
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
            color: isSelected ? themeController.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected 
                    ? Colors.white 
                    : themeController.textSecondaryColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesSection(ThemeController themeController) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '카테고리',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: themeController.textPrimaryColor,
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
                color: themeController.isDarkMode 
                    ? Colors.grey.shade800
                    : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: themeController.isDarkMode 
                      ? Colors.grey.shade600
                      : Colors.grey.shade200
                ),
              ),
              child: Text(
                '표시할 카테고리가 없습니다.',
                style: TextStyle(color: themeController.textSecondaryColor),
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
              return _buildCategoryChip(categories[index], themeController);
            },
          );
        }),
      ],
    );
  }

  Widget _buildCategoryChip(CategoryItem category, ThemeController themeController) {
    final isSelected = controller.currentFilter.value.selectedCategoryIds
        .contains(category.id);

    return GestureDetector(
      onTap: () => controller.toggleCategory(category.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected 
              ? themeController.primaryColor 
              : themeController.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? Colors.transparent 
                : themeController.primaryColor,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            category.name,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isSelected 
                  ? Colors.white 
                  : themeController.primaryColor,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildApplyButton(ThemeController themeController) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        color: themeController.cardColor,
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
          backgroundColor: themeController.primaryColor,
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