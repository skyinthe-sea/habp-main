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

  final List<String> _tabs = ['소득', '지출', '재테크'];
  final List<Color> _tabColors = [Colors.green.shade400, AppColors.primary, Colors.blue.shade400];

  // 지출 카테고리 색상 - 핑크/빨강 계열로 통일
  final List<Color> _expenseColors = [
    Color(0xFFE07777), // 빨간색 계열
    Color(0xFFE495C0), // 핑크색 계열 (primary)
    Color(0xFFFF6B6B), // 밝은 빨간색
    Color(0xFFE5A5A5), // 연한 빨간색
    Color(0xFFD87AAE), // 진한 핑크색
    Color(0xFFF3B8D3), // 연한 핑크색
    Color(0xFFE84A5F), // 선명한 빨간색
  ];

  // 소득 카테고리 색상 - 초록색 계열로 통일
  final List<Color> _incomeColors = [
    Color(0xFF2ECC71), // 밝은 초록색
    Color(0xFF27AE60), // 중간 초록색
    Color(0xFF1E8449), // 진한 초록색
    Color(0xFF52BE80), // 연한 초록색
    Color(0xFF82E0AA), // 아주 연한 초록색
    Color(0xFF49E292), // 민트색
    Color(0xFF7CC576), // 옅은 초록색
  ];

  // 재테크 카테고리 색상 - 파란색 계열로 통일
  final List<Color> _financeColors = [
    Color(0xFF3498DB), // 밝은 파란색
    Color(0xFF2980B9), // 중간 파란색
    Color(0xFF1F618D), // 진한 파란색
    Color(0xFF5DADE2), // 연한 파란색
    Color(0xFF85C1E9), // 아주 연한 파란색
    Color(0xFF49C5E2), // 하늘색
    Color(0xFF4990E2), // 옅은 파란색
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _pageController = PageController();

    // Sync tab controller with page controller
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _pageController.animateToPage(
          _tabController.index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
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
                  '해당 월',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          // Tab bar for selecting category type
          TabBar(
            controller: _tabController,
            labelColor: _tabColors[_tabController.index],
            unselectedLabelColor: Colors.grey,
            indicatorColor: _tabColors[_tabController.index],
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            tabs: _tabs.map((title) => Tab(text: title)).toList(),
            onTap: (index) {
              // Update indicator color when tab changes
              setState(() {});
            },
          ),

          // Swipeable chart container
          SizedBox(
            height: 280,
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                _tabController.animateTo(index);
                // Update indicator color when page changes
                setState(() {});
              },
              children: [
                // 소득 차트
                _buildMiniChart(
                  data: widget.controller.categoryIncome,
                  title: '소득',
                  isLoading: widget.controller.isCategoryIncomeLoading.value,
                  emptyMessage: '소득 데이터가 없습니다',
                  baseColor: Colors.green.shade400,
                  type: 'INCOME',
                ),

                // 지출 차트
                _buildMiniChart(
                  data: widget.controller.categoryExpenses,
                  title: '지출',
                  isLoading: widget.controller.isCategoryExpenseLoading.value,
                  emptyMessage: '지출 데이터가 없습니다',
                  baseColor: AppColors.primary,
                  type: 'EXPENSE',
                ),

                // 재테크 차트
                _buildMiniChart(
                  data: widget.controller.categoryFinance,
                  title: '재테크',
                  isLoading: widget.controller.isCategoryFinanceLoading.value,
                  emptyMessage: '재테크 데이터가 없습니다',
                  baseColor: Colors.blue.shade400,
                  type: 'FINANCE',
                ),
              ],
            ),
          ),

          // Custom page indicator
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: _tabController.index == index ? 24 : 8,
                  decoration: BoxDecoration(
                    color: _tabController.index == index
                        ? _tabColors[index]
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(12),
                  ),
                );
              }),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildMiniChart({
    required List<CategoryExpense> data,
    required String title,
    required bool isLoading,
    required String emptyMessage,
    required Color baseColor,
    required String type,
  }) {
    if (isLoading) {
      return const Center(child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2)
      ));
    }

    if (data.isEmpty) {
      return _buildEmptyState(emptyMessage);
    }

    // 합계 계산
    double total = 0;
    for (var item in data) {
      total += item.amount;
    }

    // 5% 미만 항목 처리를 위한 데이터 가공
    List<CategoryExpense> mainCategories = [];
    List<CategoryExpense> smallCategories = [];
    double otherAmount = 0;

    // 금액 기준 내림차순 정렬
    List<CategoryExpense> sortedData = List<CategoryExpense>.from(data)
      ..sort((a, b) => b.amount.compareTo(a.amount));

    for (var item in sortedData) {
      if (item.percentage >= 5) {
        mainCategories.add(item);
      } else {
        smallCategories.add(item);
        otherAmount += item.amount;
      }
    }

    // '기타' 카테고리 추가 (작은 항목들 통합) - 그래프에만 표시
    if (smallCategories.isNotEmpty) {
      mainCategories.add(CategoryExpense(
        categoryId: -1,
        categoryName: '기타',
        amount: otherAmount,
        percentage: (otherAmount / total) * 100,
      ));
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade100, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // 차트 타이틀
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              decoration: BoxDecoration(
                color: baseColor.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
              ),
              width: double.infinity,
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: baseColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 8),

            // 차트와 범례를 좌우로 배치
            Expanded(
              child: Row(
                children: [
                  // 차트 부분 (Left)
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 40, // 도넛 차트 중앙 구멍 크기
                            sections: _createSections(mainCategories, type),
                            startDegreeOffset: 180,
                          ),
                        ),

                        // 중앙에 총액 표시
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '총 금액',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.normal,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatAmount(total),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: baseColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 오른쪽 범례 영역 (Right) - 모든 카테고리 표시 (스크롤 가능)
                  Expanded(
                    child: _buildScrollableLegend(sortedData, type),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 스크롤 가능한 범례 위젯 구현 - 모든 카테고리 표시
  Widget _buildScrollableLegend(List<CategoryExpense> data, String type) {
    if (data.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 8, top: 4, bottom: 4),
      child: ListView.builder(
        itemCount: data.length,
        shrinkWrap: true,
        // 스크롤 가능하도록 physics 속성 수정
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final item = data[index];
          Color color = _getCategoryColor(item.categoryName, index, type);

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Container(
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 색상 아이콘과 카테고리명
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item.categoryName,
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 퍼센트
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${item.percentage.toInt()}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // 카테고리별 색상 가져오기 (각 유형별로 일관된 색상 팔레트 사용)
  Color _getCategoryColor(String categoryName, int index, String type) {
    // 카테고리 유형에 따라 적절한 색상 팔레트 사용
    if (type == 'EXPENSE') {
      return _expenseColors[index % _expenseColors.length];
    } else if (type == 'INCOME') {
      return _incomeColors[index % _incomeColors.length];
    } else {
      return _financeColors[index % _financeColors.length];
    }
  }

  // 도넛 차트 섹션 생성
  List<PieChartSectionData> _createSections(
      List<CategoryExpense> categories,
      String type) {
    return categories.map((item) {
      final index = categories.indexOf(item);
      final color = _getCategoryColor(item.categoryName, index, type);
      final showLabel = item.percentage >= 10; // 10% 이상일 때만 라벨 표시

      return PieChartSectionData(
        color: color,
        value: item.amount,
        title: showLabel ? '${item.percentage.toInt()}%' : '',
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [
            Shadow(
              offset: Offset(0, 1),
              blurRadius: 2,
              color: Colors.black54,
            ),
          ],
        ),
        radius: 50,
        badgeWidget: null,
      );
    }).toList();
  }

  // 빈 상태 위젯
  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 24, color: Colors.grey.shade300),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // 금액 포맷팅
  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 10000).toStringAsFixed(0)}만';
    } else if (amount >= 10000) {
      return '${(amount / 10000).toStringAsFixed(1)}만';
    } else {
      return amount.toStringAsFixed(0);
    }
  }
}