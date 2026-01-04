// lib/features/dashboard/presentation/widgets/category_chart_tabs.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
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

  // 지출 카테고리 색상을 테마에 따라 동적으로 생성하는 메서드
  List<Color> _getExpenseColors(ThemeController themeController) {
    final baseColor = themeController.expenseColor;
    
    return [
      baseColor, // 메인 빨강 색상
      Color.lerp(baseColor, Colors.red.shade300, 0.5) ?? baseColor,
      Color.lerp(baseColor, Colors.red.shade400, 0.3) ?? baseColor,
      Color.lerp(baseColor, Colors.pink.shade300, 0.4) ?? baseColor,
      baseColor.withOpacity(0.8),
      baseColor.withOpacity(0.6),
      Color.lerp(baseColor, Colors.red.shade600, 0.2) ?? baseColor,
    ];
  }

  // 소득 카테고리 색상을 테마에 따라 동적으로 생성하는 메서드
  List<Color> _getIncomeColors(ThemeController themeController) {
    final baseColor = themeController.incomeColor;
    
    return [
      baseColor, // 메인 초록 색상
      Color.lerp(baseColor, Colors.green.shade300, 0.5) ?? baseColor,
      Color.lerp(baseColor, Colors.green.shade400, 0.3) ?? baseColor,
      Color.lerp(baseColor, Colors.teal.shade300, 0.4) ?? baseColor,
      baseColor.withOpacity(0.8),
      baseColor.withOpacity(0.6),
      Color.lerp(baseColor, Colors.green.shade600, 0.2) ?? baseColor,
    ];
  }

  // 재테크 카테고리 색상을 테마에 따라 동적으로 생성하는 메서드  
  List<Color> _getFinanceColors(ThemeController themeController) {
    final baseColor = themeController.financeColor;
    
    return [
      baseColor, // 메인 파랑 색상
      Color.lerp(baseColor, Colors.blue.shade300, 0.5) ?? baseColor,
      Color.lerp(baseColor, Colors.blue.shade400, 0.3) ?? baseColor,
      Color.lerp(baseColor, Colors.cyan.shade300, 0.4) ?? baseColor,
      baseColor.withOpacity(0.8),
      baseColor.withOpacity(0.6),
      Color.lerp(baseColor, Colors.blue.shade600, 0.2) ?? baseColor,
    ];
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _pageController = PageController();

    // Sync tab controller with page controller - 빠른 전환
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _pageController.animateToPage(
          _tabController.index,
          duration: const Duration(milliseconds: 150), // 더 빠른 전환
          curve: Curves.easeOut,
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
          // 2026 트렌디 헤더 섹션
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            themeController.primaryColor,
                            themeController.primaryColor.withOpacity(0.5),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '카테고리별 내역',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: themeController.textPrimaryColor,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: themeController.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: themeController.primaryColor.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '해당 월',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: themeController.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Swipeable chart container - 탭 제거, 스와이프로 전환
          SizedBox(
            height: 280,
            child: PageView(
              controller: _pageController,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (index) {
                _tabController.animateTo(
                  index,
                  duration: const Duration(milliseconds: 150),
                );
                setState(() {});
              },
              children: [
                // 소득 차트
                _buildMiniChart(
                  data: widget.controller.categoryIncome,
                  title: '소득',
                  centerTitle: '총소득',
                  isLoading: widget.controller.isCategoryIncomeLoading.value,
                  emptyMessage: '소득 데이터가 없습니다',
                  baseColor: themeController.incomeColor,
                  type: 'INCOME',
                ),

                // 지출 차트
                _buildMiniChart(
                  data: widget.controller.categoryExpenses,
                  title: '지출',
                  centerTitle: '총지출',
                  isLoading: widget.controller.isCategoryExpenseLoading.value,
                  emptyMessage: '지출 데이터가 없습니다',
                  baseColor: themeController.expenseColor,
                  type: 'EXPENSE',
                ),

                // 재테크 차트
                _buildMiniChart(
                  data: widget.controller.categoryFinance,
                  title: '재테크',
                  centerTitle: '총투자',
                  isLoading: widget.controller.isCategoryFinanceLoading.value,
                  emptyMessage: '재테크 데이터가 없습니다',
                  baseColor: themeController.financeColor,
                  type: 'FINANCE',
                ),
              ],
            ),
          ),

          // 인디케이터 부활
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                final isActive = _tabController.index == index;
                final activeColor = _getTabColorForLightMode(index);
                final inactiveColor = themeController.isDarkMode
                    ? Colors.grey.shade600
                    : Colors.grey.shade300;

                return GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: isActive ? 24 : 8,
                    decoration: BoxDecoration(
                      color: isActive ? activeColor : inactiveColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
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
    required String centerTitle,
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
      padding: const EdgeInsets.all(10.0),
      child: Container(
        decoration: BoxDecoration(
          color: themeController.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: baseColor.withOpacity(themeController.isDarkMode ? 0.2 : 0.1),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: baseColor.withOpacity(0.08),
              blurRadius: 15,
              spreadRadius: 0,
              offset: const Offset(0, 5),
            ),
            BoxShadow(
              color: themeController.isDarkMode
                  ? Colors.black.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.05),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
          ],
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
                            sections: _createSections(mainCategories, type, themeController.primaryColor),
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
                                        touchedCategory.categoryName, sectionIndex, type, themeController);
                                    _showCategoryDetailDialog(context, touchedCategory, color, type);
                                  }
                                }
                              },
                            ),
                          ),
                        ),

                        // 중앙에 총액 표시 - centerTitle 사용
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              centerTitle,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
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
          Color color = _getCategoryColor(item.categoryName, index, type, themeController);

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

  // 2026 트렌디한 카테고리 상세 다이얼로그 - 최적화 버전
  void _showCategoryDetailDialog(BuildContext context, CategoryExpense category, Color color, String type) {
    final titleText = type == 'INCOME' ? '소득 상세' :
    type == 'EXPENSE' ? '지출 상세' : '재테크 상세';

    showDialog(
      context: context,
      builder: (context) => _AnimatedCategoryDetailDialog(
        category: category,
        color: color,
        type: type,
        titleText: titleText,
        calculateAverage: () => _calculateCategoryMonthlyAverage(category.categoryId, type),
      ),
    );
  }

  Widget _buildTrendyDetailRow(String label, String value, Color accentColor) {
    final ThemeController themeController = Get.find<ThemeController>();

    return Row(
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
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: themeController.textPrimaryColor,
          ),
        ),
      ],
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
  Color _getCategoryColor(String categoryName, int index, String type, ThemeController themeController) {
    // 카테고리 유형에 따라 적절한 색상 팔레트 사용
    if (type == 'EXPENSE') {
      final expenseColors = _getExpenseColors(themeController);
      return expenseColors[index % expenseColors.length];
    } else if (type == 'INCOME') {
      final incomeColors = _getIncomeColors(themeController);
      return incomeColors[index % incomeColors.length];
    } else {
      final financeColors = _getFinanceColors(themeController);
      return financeColors[index % financeColors.length];
    }
  }

  // 도넛 차트 섹션 생성 (수정됨 - 모든 카테고리명 표시)
  List<PieChartSectionData> _createSections(
      List<CategoryExpense> categories,
      String type,
      Color primaryColor) {
    return categories.map((item) {
      final index = categories.indexOf(item);
      final color = _getCategoryColor(item.categoryName, index, type, Get.find<ThemeController>());

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
  
  // 라이트모드용 탭 색상 가져오기
  Color _getTabColorForLightMode(int index) {
    final themeController = Get.find<ThemeController>();
    switch (index) {
      case 0: // 소득
        return themeController.incomeColor;
      case 1: // 지출
        return themeController.expenseColor;
      case 2: // 재테크
        return themeController.financeColor;
      default:
        return themeController.expenseColor;
    }
  }
  
  // 다크모드용 탭 색상 가져오기
  Color _getTabColorForDarkMode(int index) {
    final themeController = Get.find<ThemeController>();
    switch (index) {
      case 0: // 소득
        return themeController.incomeColor;
      case 1: // 지출
        return themeController.expenseColor;
      case 2: // 재테크
        return themeController.financeColor;
      default:
        return themeController.expenseColor;
    }
  }
  
  // 다크모드용 베이스 색상 가져오기
  Color _getBaseColorForDarkMode(String type, Color lightColor) {
    final themeController = Get.find<ThemeController>();
    switch (type) {
      case 'INCOME':
        return themeController.incomeColor;
      case 'EXPENSE':
        return themeController.expenseColor;
      case 'FINANCE':
        return themeController.financeColor;
      default:
        return lightColor;
    }
  }
}

/// 숫자 카운트업 애니메이션이 포함된 카테고리 상세 다이얼로그
class _AnimatedCategoryDetailDialog extends StatefulWidget {
  final CategoryExpense category;
  final Color color;
  final String type;
  final String titleText;
  final Future<Map<String, dynamic>> Function() calculateAverage;

  const _AnimatedCategoryDetailDialog({
    required this.category,
    required this.color,
    required this.type,
    required this.titleText,
    required this.calculateAverage,
  });

  @override
  State<_AnimatedCategoryDetailDialog> createState() => _AnimatedCategoryDetailDialogState();
}

class _AnimatedCategoryDetailDialogState extends State<_AnimatedCategoryDetailDialog>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _countController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _countAnimation;

  bool _isLoading = true;
  double _averageAmount = 0;
  int _dataPoints = 0;
  String _period = '';

  ThemeController get themeController => Get.find<ThemeController>();

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadData();
  }

  void _initAnimations() {
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutBack,
    );

    _countController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _countAnimation = CurvedAnimation(
      parent: _countController,
      curve: Curves.easeOutCubic,
    );

    _scaleController.forward();
  }

  Future<void> _loadData() async {
    final data = await widget.calculateAverage();
    if (mounted) {
      setState(() {
        _averageAmount = data['averageAmount'];
        _dataPoints = data['dataPoints'];
        _period = data['period'];
        _isLoading = false;
      });
      _countController.forward();
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _countController.dispose();
    super.dispose();
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

  String _formatCurrency(double amount) {
    return amount.toInt().toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: themeController.cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: widget.color.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.15),
                blurRadius: 24,
                spreadRadius: 0,
              ),
              BoxShadow(
                color: themeController.isDarkMode
                    ? Colors.black.withOpacity(0.4)
                    : Colors.grey.withOpacity(0.1),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더
              _buildHeader(),
              const SizedBox(height: 20),
              // 금액 정보 카드
              _buildAmountCard(),
              const SizedBox(height: 16),
              // 평균 금액 섹션
              _buildAverageSection(),
              const SizedBox(height: 24),
              // 닫기 버튼
              _buildCloseButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 4,
          height: 28,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [widget.color, widget.color.withOpacity(0.4)],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.category.categoryName,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: widget.color,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${widget.titleText} (${_formatTypeTitle(widget.type)})',
                style: TextStyle(
                  fontSize: 12,
                  color: themeController.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAmountCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.color.withOpacity(themeController.isDarkMode ? 0.1 : 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.color.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: AnimatedBuilder(
        animation: _countAnimation,
        builder: (context, child) {
          final animatedAmount = widget.category.amount * _countAnimation.value;
          final animatedPercent = widget.category.percentage * _countAnimation.value;

          return Column(
            children: [
              _buildDetailRow(
                '금액',
                '₩${_formatCurrency(animatedAmount)}',
                widget.color,
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                '비율',
                '${animatedPercent.toStringAsFixed(1)}%',
                widget.color,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAverageSection() {
    if (_isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '평균 금액',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: themeController.textPrimaryColor,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: widget.color,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return AnimatedBuilder(
      animation: _countAnimation,
      builder: (context, child) {
        final animatedAverage = _averageAmount * _countAnimation.value;
        final animatedAnnual = _averageAmount * 12 * _countAnimation.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '평균 금액',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: themeController.textPrimaryColor,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: themeController.isDarkMode
                        ? Colors.grey.shade800
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$_period · $_dataPoints개',
                    style: TextStyle(
                      fontSize: 10,
                      color: themeController.textSecondaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              '월 평균',
              '₩${_formatCurrency(animatedAverage)}',
              themeController.primaryColor,
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              '연 환산',
              '₩${_formatCurrency(animatedAnnual)}',
              themeController.primaryColor,
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, Color accentColor) {
    return Row(
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
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: themeController.textPrimaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildCloseButton() {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: () => Navigator.of(context).pop(),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: widget.color.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          '닫기',
          style: TextStyle(
            color: widget.color,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}