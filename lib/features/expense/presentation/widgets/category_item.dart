import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/category_model.dart';

class CategoryItem extends StatelessWidget {
  final CategoryModel category;
  final bool isSelected;
  final bool isNewlyAdded;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const CategoryItem({
    Key? key,
    required this.category,
    required this.isSelected,
    required this.isNewlyAdded,
    required this.onTap,
    required this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'category-${category.id}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary
                  : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
              boxShadow: isNewlyAdded
                  ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                )
              ]
                  : null,
            ),
            child: Text(
              category.name,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : Colors.black87,
                fontWeight: isSelected
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}