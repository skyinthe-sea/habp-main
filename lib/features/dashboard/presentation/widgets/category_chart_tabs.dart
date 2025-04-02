// lib/features/dashboard/presentation/widgets/category_chart_tabs.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/entities/category_expense.dart';
import '../presentation/dashboard_controller.dart';

class CategoryChartTabs extends StatefulWidget {
  final DashboardController controller;

  const CategoryChartTabs({Key? key, required this.controller}) : super(key: key);

  @override
  State<CategoryChartTabs> createState() => _CategoryChartTabsState();
}

class _CategoryChartTabsState extends State<CategoryChartTabs> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _pageController = PageController(initialPage: 0);

    // Load initial data
    _loadInitialData();

    // Listen to tab change
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _currentIndex = _tabController.index;
          _pageController.animateToPage(
            _currentIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        });
      }
    });
  }

  void _loadInitialData() {
    widget.controller.fetchCategoryExpenses();
    widget.controller.fetchCategoryIncome();
    widget.controller.fetchCategoryFinance();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '카테고리별 내역',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '이번 달',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          // PageView for swiping
          SizedBox(
            height: 300,
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                  _tabController.animateTo(index);
                });
              },
              children: [
                _buildExpenseChart(),
                _buildIncomeChart(),
                _buildFinanceChart(),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildExpenseChart() {
    if (widget.controller.isCategoryExpenseLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.controller.categoryExpenses.isEmpty) {
      return _buildEmptyState('지출 데이터가 없습니다');
    }

    final expenses = widget.controller.categoryExpenses;
    return _buildCategoryChart(expenses, '지출');
  }

  Widget _buildIncomeChart() {
    if (widget.controller.isCategoryIncomeLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.controller.categoryIncome.isEmpty) {
      return _buildEmptyState('수입 데이터가 없습니다');
    }

    final income = widget.controller.categoryIncome;
    return _buildCategoryChart(income, '수입');
  }

  Widget _buildFinanceChart() {
    if (widget.controller.isCategoryFinanceLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.controller.categoryFinance.isEmpty) {
      return _buildEmptyState('재테크 데이터가 없습니다');
    }

    final finance = widget.controller.categoryFinance;
    return _buildCategoryChart(finance, '재테크');
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChart(List<CategoryExpense> data, String type) {
    // Define colors based on type
    Color baseColor;
    switch (type) {
      case '수입':
        baseColor = Colors.green.shade400;
        break;
      case '재테크':
        baseColor = Colors.blue.shade400;
        break;
      default:
        baseColor = AppColors.primary;
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        // Animated Pie Chart
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
          builder: (context, value, child) {
            return PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 70,
                sections: _createSections(data, baseColor, value),
                startDegreeOffset: 180,
              ),
            );
          },
        ),

        // Center Text
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              type,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: baseColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '카테고리 비율',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),

        // Legend below the chart (optional)
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: _buildLegend(data, type),
        ),
      ],
    );
  }

  List<PieChartSectionData> _createSections(List<CategoryExpense> data, Color baseColor, double animationValue) {
    return data.map((item) {
      // Color varies based on the type and index for visual distinction
      Color color;
      if (baseColor == AppColors.primary) {
        // For expenses, use category colors
        color = AppColors.getCategoryColor(item.categoryId);
      } else if (baseColor == Colors.green.shade400) {
        // For income, use shades of green
        color = Color.lerp(Colors.lightGreen, Colors.green.shade700, data.indexOf(item) / data.length)!;
      } else {
        // For finance, use shades of blue
        color = Color.lerp(Colors.lightBlue, Colors.indigo, data.indexOf(item) / data.length)!;
      }

      // Animate the radius and value
      final radius = 60 * animationValue;
      final value = item.amount * animationValue;
      final percentage = item.percentage * animationValue;

      return PieChartSectionData(
        color: color,
        value: value,
        title: '',
        radius: radius,
        titlePositionPercentageOffset: 0.6,
        badgeWidget: percentage > 5 ? _getBadgeWidget(item.categoryName, percentage, color) : null,
        badgePositionPercentageOffset: 1.2,
      );
    }).toList();
  }

  Widget _getBadgeWidget(String categoryName, double percentage, Color color) {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$categoryName ',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            TextSpan(
              text: '${percentage.toInt()}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
                shadows: const [
                  Shadow(
                    offset: Offset(1.0, 1.0),
                    blurRadius: 2.0,
                    color: Colors.black,
                  ),
                  Shadow(
                    offset: Offset(-1.0, -1.0),
                    blurRadius: 2.0,
                    color: Colors.black,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(List<CategoryExpense> data, String type) {
    // Only show for items with smaller percentages that don't have badges
    final smallItems = data.where((item) => item.percentage <= 5).toList();
    if (smallItems.isEmpty) return const SizedBox.shrink();

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Wrap(
          spacing: 8,
          runSpacing: 4,
          alignment: WrapAlignment.center,
          children: smallItems.map((item) {
            Color color;
            // Determine color based on type
            if (type == '지출') {
              color = AppColors.getCategoryColor(item.categoryId);
            } else if (type == '수입') {
              color = Color.lerp(Colors.lightGreen, Colors.green.shade700, data.indexOf(item) / data.length)!;
            } else {
              color = Color.lerp(Colors.lightBlue, Colors.indigo, data.indexOf(item) / data.length)!;
            }

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${item.categoryName} ${item.percentage.toInt()}%',
                  style: const TextStyle(fontSize: 10),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}