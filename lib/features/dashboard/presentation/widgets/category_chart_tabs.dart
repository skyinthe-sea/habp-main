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

  // 카테고리별 고유 색상 맵핑 - 더 조화로운 색상 팔레트로 업데이트
  final Map<String, Color> _categoryColors = {
    '술약속': Color(0xFFFF6B6B),    // 빨간색
    '통신': Color(0xFF4ECDC4),      // 민트색
    '이건뭐지': Color(0xFFFFD166),  // 노란색
    '이것도': Color(0xFF9B5DE5),    // 보라색
    '기타': Color(0xFFBFBFBF),      // 회색
    '하나더': Color(0xFF00A8E8),    // 파란색
  };

  // 새로운 색상 팔레트 - 2번째 이미지와 더 유사하게
  final List<Color> _harmonizedPalette = [
    Color(0xFFF76C6C),  // 연한 빨간색
    Color(0xFF4ECDC4),  // 민트색
    Color(0xFFFFD166),  // 노란색
    Color(0xFF9B5DE5),  // 보라색
    Color(0xFF00A8E8),  // 파란색
    Color(0xFFBFBFBF),  // 회색
  ];

  // 소득 카테고리 색상 - 초록색 계열로 통일
  final List<Color> _incomeColors = [
    Color(0xFF2ECC71),
    Color(0xFF27AE60),
    Color(0xFF1E8449),
    Color(0xFF52BE80),
    Color(0xFF82E0AA),
  ];

  // 재테크 카테고리 색상 - 파란색 계열로 통일
  final List<Color> _financeColors = [
    Color(0xFF3498DB),
    Color(0xFF2980B9),
    Color(0xFF1F618D),
    Color(0xFF5DADE2),
    Color(0xFF85C1E9),
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
                Row(
                  children: [
                    Text(
                      '터치하여 상세보기',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[400],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '이번 달',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
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

    for (var item in data) {
      if (item.percentage >= 5) {
        mainCategories.add(item);
      } else {
        smallCategories.add(item);
        otherAmount += item.amount;
      }
    }

    // '기타' 카테고리 추가 (작은 항목들 통합)
    if (smallCategories.isNotEmpty) {
      mainCategories.add(CategoryExpense(
        categoryId: -1,
        categoryName: '기타',
        amount: otherAmount,
        percentage: (otherAmount / total) * 100,
      ));
    }

    // 금액 기준 내림차순 정렬
    mainCategories.sort((a, b) => b.amount.compareTo(a.amount));

    // 탭 시 상세 보기 표시
    return GestureDetector(
      onTap: () => _showDetailChart(Get.context!, data, title.replaceAll('소득', '수입'), baseColor, type, total),
      child: Padding(
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

              // 차트와 범례를 좌우로 배치 (2번째 이미지 스타일로 업데이트)
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

                    // 오른쪽 범례 영역 (Right)
                    Expanded(
                      child: _buildLegend(mainCategories, type),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 범례 위젯 구현 (2번째 이미지 스타일로 업데이트)
  Widget _buildLegend(List<CategoryExpense> data, String type) {
    if (data.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 12, top: 4, bottom: 4),
      child: ListView.builder(
        itemCount: data.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          final item = data[index];
          Color color = _getCategoryColor(item.categoryName, index, type);

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Container(
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 색상 아이콘과 카테고리명
                  Row(
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
                      Text(
                        item.categoryName,
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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

  // 카테고리별 색상 가져오기 (더 일관된 색상 팔레트 사용)
  Color _getCategoryColor(String categoryName, int index, String type) {
    if (type == 'EXPENSE') {
      // 2번째 이미지 스타일 처럼 조화로운 색상 사용
      return _harmonizedPalette[index % _harmonizedPalette.length];
    } else if (type == 'INCOME') {
      // 소득은 초록색 계열 사용
      return _incomeColors[index % _incomeColors.length];
    } else {
      // 재테크는 파란색 계열 사용
      return _financeColors[index % _financeColors.length];
    }
  }

  // 도넛 차트 섹션 생성
  List<PieChartSectionData> _createSections(
      List<CategoryExpense> categories,
      String type) {
    return categories.map((item) {
      final color = _getCategoryColor(item.categoryName, categories.indexOf(item), type);
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

  // 상세 차트 다이얼로그 표시 (업데이트된 디자인)
  void _showDetailChart(BuildContext context, List<CategoryExpense> data, String title, Color baseColor, String type, double total) {
    // 금액 기준 내림차순 정렬
    final sortedData = List<CategoryExpense>.from(data)
      ..sort((a, b) => b.amount.compareTo(a.amount));

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: double.maxFinite,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 다이얼로그 헤더
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$title 상세',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: baseColor,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),

              // 총액 정보 (금액 크게 표시)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: baseColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      '총 금액',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatAmount(total)}원',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: baseColor,
                      ),
                    ),
                  ],
                ),
              ),

              // 차트와 카테고리 목록
              SizedBox(
                height: 350,
                child: Column(
                  children: [
                    // 차트 (상단 40%)
                    SizedBox(
                      height: 140,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 40,
                              sections: sortedData.map((item) {
                                final color = _getCategoryColor(item.categoryName, sortedData.indexOf(item), type);
                                return PieChartSectionData(
                                  color: color,
                                  value: item.amount,
                                  title: '${item.percentage.toInt()}%',
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
                                  radius: 55,
                                  badgeWidget: null,
                                );
                              }).toList(),
                              startDegreeOffset: 180,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 구분선
                    Divider(color: Colors.grey.shade200, thickness: 1),

                    // 카테고리 목록 (하단 60%, 2번째 이미지의 모양과 비슷하게)
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: sortedData.length,
                        itemBuilder: (context, index) {
                          final item = sortedData[index];
                          final color = _getCategoryColor(item.categoryName, index, type);

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: color.withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                // 색상 표시
                                Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),

                                // 카테고리명
                                Expanded(
                                  flex: 5,
                                  child: Text(
                                    item.categoryName,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),

                                // 금액
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    '${_formatAmount(item.amount)}원',
                                    style: const TextStyle(
                                      fontSize: 13,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ),

                                const SizedBox(width: 8),

                                // 퍼센트
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${item.percentage.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: color,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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