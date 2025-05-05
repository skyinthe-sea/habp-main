// lib/features/dashboard/presentation/widgets/category_chart_tabs.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
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
            height: 320, // 차트 영역 높이 증가
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
            // 차트와 범례를 좌우로 배치
            Expanded(
              child: Row(
                children: [
                  // 차트 부분 (Left) - 비율 증가
                  Expanded(
                    flex: 3, // 차트 영역 비율 증가
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // 차트 영역 - 직접 터치 이벤트 처리
                        PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 40, // 도넛 차트 중앙 구멍 크기
                            sections: _createSections(mainCategories, type),
                            startDegreeOffset: 180,
                            pieTouchData: PieTouchData(
                              enabled: true,
                              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                // 터치 이벤트 처리
                                if (event is FlTapUpEvent && pieTouchResponse != null &&
                                    pieTouchResponse.touchedSection != null) {
                                  final sectionIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                  if (sectionIndex >= 0 && sectionIndex < mainCategories.length) {
                                    final touchedCategory = mainCategories[sectionIndex];
                                    final color = _getCategoryColor(
                                        touchedCategory.categoryName, sectionIndex, type);
                                    _showCategoryDetailDialog(context, touchedCategory, color, type);
                                  }
                                }
                              },
                            ),
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

                  // 오른쪽 범례 영역 (Right) - 비율 감소
                  Expanded(
                    flex: 2, // 범례 영역 비율 감소
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

  // 차트 터치 처리 메서드는 더 이상 필요 없음 - PieTouchData에서 직접 처리

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
            child: InkWell(
              onTap: () => _showCategoryDetailDialog(context, item, color, type),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 첫 번째 행: 카테고리명과 퍼센트
                    Row(
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
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
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

                    // 두 번째 행: 실제 금액 표시 (추가된 부분)
                    Padding(
                      padding: const EdgeInsets.only(left: 16, top: 2),
                      child: Text(
                        _formatAmount(item.amount),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // 카테고리 상세 정보를 보여주는 다이얼로그
  void _showCategoryDetailDialog(BuildContext context, CategoryExpense category, Color color, String type) {
    final titleText = type == 'INCOME' ? '소득 상세' :
    type == 'EXPENSE' ? '지출 상세' : '재테크 상세';

    // 숫자 포맷팅을 위한 형식
    final NumberFormat numberFormat = NumberFormat('#,###', 'ko');
    final formattedAmount = numberFormat.format(category.amount);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          category.categoryName,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$titleText (${_formatTypeTitle(type)})',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),

            // 금액 정보
            _buildDetailRow('금액:', '₩$formattedAmount'),
            _buildDetailRow('비율:', '${category.percentage.toStringAsFixed(1)}%'),

            // 예상 정보 (월간/연간)
            const SizedBox(height: 12),
            const Text('예상 금액', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            _buildDetailRow('월 평균:', '₩${numberFormat.format(category.amount)}'),
            _buildDetailRow('연 환산:', '₩${numberFormat.format(category.amount * 12)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 10000).toStringAsFixed(0)}만';
    } else if (amount >= 10000) {
      return '${(amount / 10000).toStringAsFixed(1)}만';
    } else {
      return '${amount.toStringAsFixed(0)}';
    }
  }

  String _formatTypeTitle(String type) {
    switch (type) {
      case 'INCOME':
        return '수입';
      case 'EXPENSE':
        return '지출';
      case 'FINANCE':
        return '재테크';
      default:
        return '';
    }
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

  // 도넛 차트 섹션 생성 (수정됨 - 모든 카테고리명 표시)
  List<PieChartSectionData> _createSections(
      List<CategoryExpense> categories,
      String type) {
    return categories.map((item) {
      final index = categories.indexOf(item);
      final color = _getCategoryColor(item.categoryName, index, type);

      // 모든 섹션에 라벨 표시 (5% 이상인 경우)
      final showLabel = item.percentage >= 5;

      // 퍼센티지와 카테고리명을 함께 표시
      String displayText = '';
      if (showLabel) {
        // 카테고리명이 짧은 경우 함께 표시, 긴 경우 퍼센트만 표시
        if (item.categoryName.length <= 4 || item.percentage >= 16) {
          displayText = '${item.categoryName}\n${item.percentage.toInt()}%';
        } else {
          displayText = '${item.percentage.toInt()}%';
        }
      }

      return PieChartSectionData(
        color: color,
        value: item.amount,
        title: displayText,
        titleStyle: TextStyle(
          fontSize: 11, // 폰트 크기 조정
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: const [
            Shadow(
              offset: Offset(0, 1),
              blurRadius: 2,
              color: Colors.black54,
            ),
          ],
        ),
        radius: 60, // 섹션 반지름 유지
        badgeWidget: null,
        titlePositionPercentageOffset: 0.58, // 라벨 위치 안쪽으로 조정
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
}