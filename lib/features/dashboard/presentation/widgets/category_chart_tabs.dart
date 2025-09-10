// lib/features/dashboard/presentation/widgets/category_chart_tabs.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/controllers/theme_controller.dart';
import '../../../../core/database/db_helper.dart';
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
    final ThemeController themeController = Get.find<ThemeController>();
    
    return Obx(() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '카테고리별 내역',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: themeController.textPrimaryColor,
                  ),
                ),
                Text(
                  '해당 월',
                  style: TextStyle(
                    fontSize: 12,
                    color: themeController.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),

          // Tab bar for selecting category type
          TabBar(
            controller: _tabController,
            labelColor: themeController.isDarkMode 
                ? _getTabColorForDarkMode(_tabController.index)
                : _tabColors[_tabController.index],
            unselectedLabelColor: themeController.textSecondaryColor,
            indicatorColor: themeController.isDarkMode
                ? _getTabColorForDarkMode(_tabController.index)
                : _tabColors[_tabController.index],
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
                final isActive = _tabController.index == index;
                final activeColor = themeController.isDarkMode 
                    ? _getTabColorForDarkMode(index)
                    : _tabColors[index];
                final inactiveColor = themeController.isDarkMode
                    ? Colors.grey.shade600
                    : Colors.grey.shade300;
                
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: isActive ? 24 : 8,
                  decoration: BoxDecoration(
                    color: isActive ? activeColor : inactiveColor,
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
    final ThemeController themeController = Get.find<ThemeController>();
    
    if (isLoading) {
      return Center(child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: themeController.primaryColor,
          )
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
          border: Border.all(
            color: themeController.isDarkMode
                ? Colors.grey.shade700
                : Colors.grey.shade100, 
            width: 1,
          ),
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
                                color: themeController.textSecondaryColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatAmount(total),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: themeController.isDarkMode
                                    ? _getBaseColorForDarkMode(type, baseColor)
                                    : baseColor,
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

  // 카테고리별 월평균 데이터 계산
  Future<Map<String, dynamic>> _calculateCategoryMonthlyAverage(int categoryId, String type) async {
    try {
      final db = await DBHelper().database;
      final now = DateTime.now();
      final oneYearAgo = DateTime(now.year - 1, now.month, now.day);

      // SQLite용 날짜 형식
      final oneYearAgoStr = "${oneYearAgo.year}-${oneYearAgo.month.toString().padLeft(2, '0')}-${oneYearAgo.day.toString().padLeft(2, '0')}";
      final nowStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      // 1. 변동 거래 내역 가져오기
      final List<Map<String, dynamic>> variableTransactions = await db.rawQuery('''
        SELECT tr.amount
        FROM transaction_record tr
        JOIN category c ON tr.category_id = c.id
        WHERE tr.category_id = ?
        AND c.type = ?
        AND date(substr(tr.transaction_date, 1, 10)) BETWEEN date(?) AND date(?)
      ''', [categoryId, type, oneYearAgoStr, nowStr]);

      // 2. 고정 거래 내역 가져오기 (매월 발생하므로 1년치 12개월로 계산)
      final List<Map<String, dynamic>> fixedTransactions = await db.rawQuery('''
        SELECT tr.amount, tr.description, tr.transaction_num
        FROM transaction_record2 tr
        JOIN category c ON tr.category_id = c.id
        WHERE tr.category_id = ?
        AND c.type = ?
        AND c.is_fixed = 1
      ''', [categoryId, type]);

      // 거래 내역 개수
      int transactionCount = variableTransactions.length;

      // 총 거래 금액
      double totalAmount = 0.0;

      // 변동 거래 금액 합산
      for (var transaction in variableTransactions) {
        totalAmount += (transaction['amount'] as double).abs();
      }

      // 고정 거래는 매월 발생으로 계산 (최근 1년간 12개월로 처리)
      double monthlyFixedAmount = 0.0;

      for (var transaction in fixedTransactions) {
        final amount = (transaction['amount'] as double).abs();
        final description = transaction['description'] as String;
        final transactionNum = transaction['transaction_num'].toString();

        if (description.contains('매월')) {
          // 매월 고정 거래는 1년에 12번 발생
          monthlyFixedAmount += amount;
        }
        else if (description.contains('매주')) {
          // 매주 고정 거래는 1년에 약 52번 발생 (4.33주/월 × 12개월)
          final weeklyAmount = amount * 4.33;  // 월 평균 4.33주
          monthlyFixedAmount += weeklyAmount;
        }
        else if (description.contains('매일')) {
          // 매일 고정 거래는 1년에 약 365번 발생 (30.42일/월 × 12개월)
          final dailyAmount = amount * 30.42;  // 월 평균 30.42일
          monthlyFixedAmount += dailyAmount;
        }
      }

      // 고정 거래가 있으면 12개월치 데이터가 있다고 가정
      if (fixedTransactions.isNotEmpty) {
        totalAmount += (monthlyFixedAmount * 12);
        transactionCount += 12;  // 1년 12개월
      }

      // 평균 계산
      final double averageAmount = transactionCount > 0 ? totalAmount / transactionCount : 0.0;

      // 데이터 포인트 개수
      final int dataPoints = transactionCount;

      // 결과 반환
      return {
        'averageAmount': averageAmount,
        'dataPoints': dataPoints,
        'period': transactionCount > 0 ? '최근 1년' : '데이터 없음'
      };
    } catch (e) {
      debugPrint('카테고리 월평균 계산 오류: $e');
      return {
        'averageAmount': 0.0,
        'dataPoints': 0,
        'period': '계산 실패'
      };
    }
  }

  // 스크롤 가능한 범례 위젯 구현 - 모든 카테고리 표시
  Widget _buildScrollableLegend(List<CategoryExpense> data, String type) {
    final ThemeController themeController = Get.find<ThemeController>();
    
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
                                  style: TextStyle(
                                    fontSize: 12, 
                                    fontWeight: FontWeight.w500,
                                    color: themeController.textPrimaryColor,
                                  ),
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
                          color: themeController.textSecondaryColor,
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
  void _showCategoryDetailDialog(BuildContext context, CategoryExpense category, Color color, String type) async {
    final ThemeController themeController = Get.find<ThemeController>();
    final titleText = type == 'INCOME' ? '소득 상세' :
    type == 'EXPENSE' ? '지출 상세' : '재테크 상세';

    // 로딩 상태로 다이얼로그 먼저 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: themeController.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            category.categoryName,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            height: 100,
            child: Center(
              child: CircularProgressIndicator(
                color: color,
              ),
            ),
          ),
        );
      },
    );

    // 월 평균 데이터 계산
    final averageData = await _calculateCategoryMonthlyAverage(category.categoryId, type);
    final double averageAmount = averageData['averageAmount'];
    final int dataPoints = averageData['dataPoints'];
    final String period = averageData['period'];

    // 기존 다이얼로그를 닫고 새 다이얼로그 표시
    if (context.mounted) {
      Navigator.of(context).pop();
    }

    // 숫자 포맷팅을 위한 형식
    final NumberFormat numberFormat = NumberFormat('#,###', 'ko');
    final formattedAmount = numberFormat.format(category.amount);
    final formattedAverage = numberFormat.format(averageAmount);
    final formattedAnnual = numberFormat.format(averageAmount * 12);

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: themeController.cardColor,
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
              Text(
                '$titleText (${_formatTypeTitle(type)})',
                style: TextStyle(
                  fontSize: 14, 
                  fontWeight: FontWeight.w500,
                  color: themeController.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 12),

              // 금액 정보
              _buildDetailRow('금액:', '₩$formattedAmount'),
              _buildDetailRow('비율:', '${category.percentage.toStringAsFixed(1)}%'),

              // 예상 정보 (월간/연간)
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    '평균 금액', 
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: themeController.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '($period, $dataPoints개 데이터)',
                    style: TextStyle(
                      fontSize: 10,
                      color: themeController.textSecondaryColor,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              _buildDetailRow('월 평균:', '₩$formattedAverage'),
              _buildDetailRow('연 환산:', '₩$formattedAnnual'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                '닫기',
                style: TextStyle(color: themeController.primaryColor),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildDetailRow(String label, String value) {
    final ThemeController themeController = Get.find<ThemeController>();
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label, 
            style: TextStyle(
              color: themeController.textSecondaryColor, 
              fontSize: 13,
            ),
          ),
          Text(
            value, 
            style: TextStyle(
              fontWeight: FontWeight.w500, 
              fontSize: 13,
              color: themeController.textPrimaryColor,
            ),
          ),
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
    final ThemeController themeController = Get.find<ThemeController>();
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart, 
            size: 24, 
            color: themeController.textSecondaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 12,
              color: themeController.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  // 다크모드용 탭 색상 가져오기
  Color _getTabColorForDarkMode(int index) {
    switch (index) {
      case 0: // 소득
        return AppColors.darkSuccess;
      case 1: // 지출
        return AppColors.darkPrimary;
      case 2: // 재테크
        return AppColors.darkInfo;
      default:
        return AppColors.darkPrimary;
    }
  }
  
  // 다크모드용 베이스 색상 가져오기
  Color _getBaseColorForDarkMode(String type, Color lightColor) {
    switch (type) {
      case 'INCOME':
        return AppColors.darkSuccess;
      case 'EXPENSE':
        return AppColors.darkPrimary;
      case 'FINANCE':
        return AppColors.darkInfo;
      default:
        return lightColor;
    }
  }
}