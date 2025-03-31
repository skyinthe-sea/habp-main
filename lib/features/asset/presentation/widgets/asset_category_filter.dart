// lib/features/asset/presentation/widgets/asset_category_filter.dart
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/asset_category_model.dart';

class AssetCategoryFilter extends StatelessWidget {
  final List<AssetCategoryModel> categories;
  final String selectedCategory;
  final Function(String) onCategorySelected;

  const AssetCategoryFilter({
    Key? key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '자산 유형별 보기',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // 전체 카테고리 필터
              _buildCategoryChip(
                label: '전체',
                value: 'ALL',
                isSelected: selectedCategory == 'ALL',
                onSelected: onCategorySelected,
              ),

              // 각 카테고리별 필터
              ...categories.map((category) {
                return _buildCategoryChip(
                  label: category.name,
                  value: category.name,
                  isSelected: selectedCategory == category.name,
                  onSelected: onCategorySelected,
                );
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip({
    required String label,
    required String value,
    required bool isSelected,
    required Function(String) onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        onSelected: (selected) {
          if (selected) {
            onSelected(value);
          }
        },
      ),
    );
  }
}