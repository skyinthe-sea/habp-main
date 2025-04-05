// lib/features/calendar/presentation/widgets/filter_floating_button.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../controllers/calendar_filter_controller.dart';
import '../../domain/entities/calendar_filter.dart';

class FilterFloatingButton extends StatefulWidget {
  final CalendarFilterController controller;

  const FilterFloatingButton({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  State<FilterFloatingButton> createState() => _FilterFloatingButtonState();
}

class _FilterFloatingButtonState extends State<FilterFloatingButton> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final currentFilter = widget.controller.currentFilter.value;

      // Get appropriate label for the main button
      String mainButtonLabel = _getFilterLabel(currentFilter);

      return Stack(
        children: [
          // The filter options that appear when expanded
          if (_isExpanded)
            ..._buildFilterOptions(currentFilter),

          // The main floating button - 더 작고 투명하며 텍스트만 표시
          Positioned(
            right: 16,
            bottom: 16,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _toggleExpanded,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    mainButtonLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  String _getFilterLabel(CalendarFilter filter) {
    if (filter.selectedCategoryIds.isNotEmpty) {
      return "카테고리 ${filter.selectedCategoryIds.length}개";
    } else if (filter.categoryType == 'INCOME') {
      return "소득";
    } else if (filter.categoryType == 'EXPENSE') {
      return "지출";
    } else if (filter.categoryType == 'FINANCE') {
      return "재테크";
    } else {
      return "전체";
    }
  }

  List<Widget> _buildFilterOptions(CalendarFilter currentFilter) {
    final options = [
      // Options list omits the currently selected filter
      if (currentFilter.categoryType != null || currentFilter.selectedCategoryIds.isNotEmpty)
        _buildFilterOption("전체", 1, () => widget.controller.setFilter(CalendarFilter.all)),

      if (currentFilter.categoryType != 'INCOME')
        _buildFilterOption("소득", 2, () => widget.controller.setFilter(CalendarFilter.income)),

      if (currentFilter.categoryType != 'EXPENSE')
        _buildFilterOption("지출", 3, () => widget.controller.setFilter(CalendarFilter.expense)),

      if (currentFilter.categoryType != 'FINANCE')
        _buildFilterOption("재테크", 4, () => widget.controller.setFilter(CalendarFilter.finance)),

      // Always show the filter settings button
      _buildFilterOption(
        "필터설정",
        5,
            () {
          _toggleExpanded(); // Close the expanded menu
          widget.controller.openFilterModal(); // Open the filter modal
        },
        isFilterSettings: true,
      ),
    ];

    return options;
  }

  Widget _buildFilterOption(String label, int position, VoidCallback onTap, {bool isFilterSettings = false}) {
    // Calculate position from the bottom based on the item's index - 더 가깝게 배치
    final bottomPosition = 16.0 + (position * 36.0);

    return Positioned(
      right: 16,
      bottom: bottomPosition,
      child: FadeTransition(
        opacity: _animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(_animationController),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                onTap();
                if (!isFilterSettings) {
                  _toggleExpanded(); // Close the menu after selection
                }
              },
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  isFilterSettings ? "필터설정" : label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}