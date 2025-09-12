import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/controllers/theme_controller.dart';
import '../../../../core/database/db_helper.dart';
import '../../domain/entities/budget_status.dart';
import '../controllers/expense_controller.dart';
import '../widgets/category_transaction_list.dart';
import '../widgets/category_analytics_charts.dart';

class CategoryDetailDialog extends StatefulWidget {
  final BudgetStatus budgetStatus;
  final ExpenseController controller;

  const CategoryDetailDialog({
    Key? key,
    required this.budgetStatus,
    required this.controller,
  }) : super(key: key);

  @override
  State<CategoryDetailDialog> createState() => _CategoryDetailDialogState();
}

class _CategoryDetailDialogState extends State<CategoryDetailDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final RxBool _isLoading = true.obs;
  final RxList<Map<String, dynamic>> _transactions = <Map<String, dynamic>>[].obs;
  final RxMap<String, dynamic> _analytics = <String, dynamic>{}.obs;

  // DB Helper 추가
  final DBHelper _dbHelper = DBHelper();

  // 현재 선택된 탭을 저장
  final RxInt _currentTabIndex = 0.obs;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // 탭 변경 리스너 추가
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _currentTabIndex.value = _tabController.index;
        debugPrint('탭 변경됨: ${_tabController.index}');

        // 탭이 변경될 때 필요에 따라 데이터 다시 로드
        if (_tabController.index == 1 && _transactions.isEmpty) { // 지출 내역 탭
          debugPrint('지출 내역 탭 선택 - 데이터 없음, 다시 로드');
          _loadCategoryData();
        }
      }
    });

    _loadCategoryData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCategoryData() async {
    _isLoading.value = true;

    try {
      // 이 카테고리에 대한 모든 거래 내역 로드
      final transactions = await _fetchCategoryTransactions(
        widget.controller.userId,
        widget.budgetStatus.categoryId,
        widget.controller.selectedPeriod.value,
      );

      debugPrint('카테고리 상세 (_loadCategoryData) - 조회된 거래 내역 수: ${transactions.length}');

      // 중요: RxList를 초기화하고 새 데이터로 채우기
      _transactions.clear();
      if (transactions.isNotEmpty) {
        _transactions.addAll(transactions);
      }

      debugPrint('_transactions 업데이트 후 크기: ${_transactions.length}');

      // 해당 카테고리에 대한 분석 데이터 계산
      _analytics.value = await _analyzeCategoryData(
        widget.controller.userId,
        widget.budgetStatus.categoryId,
        widget.controller.selectedPeriod.value,
      );
    } catch (e) {
      debugPrint('카테고리 데이터 로드 중 오류: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  // 카테고리 거래 내역 가져오기 (실제 DB에서 데이터 조회)
  Future<List<Map<String, dynamic>>> _fetchCategoryTransactions(
      int userId, int categoryId, String period) async {
    try {
      final db = await _dbHelper.database;

      // 기간에서 연도와 월 추출 (형식: YYYY-MM)
      final year = int.parse(period.split('-')[0]);
      final month = int.parse(period.split('-')[1]);

      // 해당 월의 시작일과 종료일 계산
      final startDate = DateTime(year, month, 1).toIso8601String();
      final endDate = DateTime(year, month + 1, 0).toIso8601String();

      debugPrint('카테고리 ID: $categoryId, 시작일: $startDate, 종료일: $endDate');

      // 거래 내역 전체 로깅 (디버깅용)
      final allTransactions = await db.query('transaction_record');
      debugPrint('전체 거래 내역 수: ${allTransactions.length}');

      // 해당 카테고리의 거래 내역만 조회 (단순 쿼리로 테스트)
      final categoryTransactions = await db.query(
        'transaction_record',
        where: 'category_id = ?',
        whereArgs: [categoryId],
      );
      debugPrint('카테고리 ID $categoryId의 단순 조회 거래 내역 수: ${categoryTransactions.length}');
      for (var tx in categoryTransactions) {
        debugPrint('카테고리 거래: $tx');
      }

      // 날짜 범위를 포함한 쿼리
      final List<Map<String, dynamic>> dbResults = await db.rawQuery('''
        SELECT 
          *
        FROM 
          transaction_record
        WHERE 
          category_id = ? 
          AND date(substr(transaction_date, 1, 10)) BETWEEN date(?) AND date(?)
        ORDER BY 
          transaction_date DESC
      ''', [categoryId, startDate, endDate]);

      debugPrint('조회된 거래 내역 수: ${dbResults.length}');

      // 중요: 읽기 전용 Map을 수정 가능한 Map으로 복사
      final List<Map<String, dynamic>> transactionsData = [];

      for (var result in dbResults) {
        // 새로운 Map 객체에 복사
        final Map<String, dynamic> transaction = Map<String, dynamic>.from(result);

        try {
          // 요일 정보 추가
          final dateStr = transaction['transaction_date'] as String;
          final date = DateTime.parse(dateStr);
          // 1(월요일) ~ 7(일요일)로 변환
          int weekday = date.weekday;
          transaction['day_of_week'] = weekday;
          debugPrint('거래 날짜: $dateStr => 요일: $weekday');
        } catch (e) {
          debugPrint('날짜 변환 오류: ${transaction['transaction_date']} - $e');
          transaction['day_of_week'] = 1; // 기본값
        }

        transactionsData.add(transaction);
        debugPrint('가공된 거래: $transaction');
      }

      debugPrint('최종 처리된 거래 내역 수: ${transactionsData.length}');
      return transactionsData;

    } catch (e) {
      debugPrint('카테고리 거래 내역 조회 중 오류: $e');
      return [];
    }
  }

  // 카테고리 분석 데이터 계산 (실제 거래 내역 기반)
  Future<Map<String, dynamic>> _analyzeCategoryData(
      int userId, int categoryId, String period) async {
    try {
      final db = await _dbHelper.database;

      // 기간에서 연도와 월 추출 (형식: YYYY-MM)
      final year = int.parse(period.split('-')[0]);
      final month = int.parse(period.split('-')[1]);

      // 해당 월과 이전 월의 시작일과 종료일 계산
      final currentStartDate = DateTime(year, month, 1).toIso8601String();
      final currentEndDate = DateTime(year, month + 1, 0).toIso8601String();

      final lastMonth = month == 1 ? 12 : month - 1;
      final lastYear = month == 1 ? year - 1 : year;
      final lastStartDate = DateTime(lastYear, lastMonth, 1).toIso8601String();
      final lastEndDate = DateTime(lastYear, lastMonth + 1, 0).toIso8601String();

      debugPrint('분석 - 카테고리 ID: $categoryId');
      debugPrint('분석 - 현재 기간: $currentStartDate ~ $currentEndDate');

      // 1. 현재 월 총 지출액 조회 (음수 금액만 집계하도록 수정)
      final currentMonthTotalResult = await db.rawQuery('''
        SELECT SUM(ABS(amount)) as total_expense
        FROM transaction_record
        WHERE category_id = ? 
          AND amount < 0
          AND date(substr(transaction_date, 1, 10)) BETWEEN date(?) AND date(?)
      ''', [categoryId, currentStartDate, currentEndDate]);

      final totalExpense = currentMonthTotalResult.isNotEmpty &&
          currentMonthTotalResult[0]['total_expense'] != null
          ? (currentMonthTotalResult[0]['total_expense'] as num).toDouble()
          : 0.0;

      debugPrint('현재 월 총 지출액: $totalExpense');

      // 2. 이전 월 총 지출액 조회 (음수 금액만 집계)
      final lastMonthTotalResult = await db.rawQuery('''
        SELECT SUM(ABS(amount)) as total_expense
        FROM transaction_record
        WHERE category_id = ? 
          AND amount < 0
          AND date(substr(transaction_date, 1, 10)) BETWEEN date(?) AND date(?)
      ''', [categoryId, lastStartDate, lastEndDate]);

      final lastMonthExpense = lastMonthTotalResult.isNotEmpty &&
          lastMonthTotalResult[0]['total_expense'] != null
          ? (lastMonthTotalResult[0]['total_expense'] as num).toDouble()
          : 0.0;

      debugPrint('이전 월 총 지출액: $lastMonthExpense');

      // 3. 전체 지출 중 해당 카테고리 비율 계산을 위한 전체 지출액 조회
      final totalMonthExpenseResult = await db.rawQuery('''
        SELECT SUM(ABS(amount)) as total_expense
        FROM transaction_record tr
        JOIN category c ON tr.category_id = c.id
        WHERE c.type = 'EXPENSE'
          AND tr.amount < 0
          AND date(substr(tr.transaction_date, 1, 10)) BETWEEN date(?) AND date(?)
      ''', [currentStartDate, currentEndDate]);

      final totalMonthExpenses = totalMonthExpenseResult.isNotEmpty &&
          totalMonthExpenseResult[0]['total_expense'] != null
          ? (totalMonthExpenseResult[0]['total_expense'] as num).toDouble()
          : 0.0;

      debugPrint('전체 지출액: $totalMonthExpenses');

      // 4. 요일별 지출 분석
      final Map<int, double> dayOfWeekExpenses = {};
      for (int i = 1; i <= 7; i++) {
        dayOfWeekExpenses[i] = 0.0;
      }

      // 요일별 지출 조회
      final dayOfWeekResult = await db.rawQuery('''
        SELECT 
          CASE 
            WHEN strftime('%w', substr(transaction_date, 1, 10)) = '0' THEN 7
            ELSE CAST(strftime('%w', substr(transaction_date, 1, 10)) AS INTEGER)
          END as weekday,
          SUM(ABS(amount)) as day_expense
        FROM transaction_record
        WHERE category_id = ? 
          AND amount < 0
          AND date(substr(transaction_date, 1, 10)) BETWEEN date(?) AND date(?)
        GROUP BY weekday
      ''', [categoryId, currentStartDate, currentEndDate]);

      for (var row in dayOfWeekResult) {
        final weekday = row['weekday'] as int;
        final expense = (row['day_expense'] as num).toDouble();
        dayOfWeekExpenses[weekday] = expense;
      }

      debugPrint('요일별 지출: $dayOfWeekExpenses');

      // 5. 일별 지출 추이 계산
      final Map<int, double> dailyExpenses = {};

      final dailyResult = await db.rawQuery('''
        SELECT 
          CAST(strftime('%d', substr(transaction_date, 1, 10)) AS INTEGER) as day,
          SUM(ABS(amount)) as day_expense
        FROM transaction_record
        WHERE category_id = ? 
          AND amount < 0
          AND date(substr(transaction_date, 1, 10)) BETWEEN date(?) AND date(?)
        GROUP BY day
        ORDER BY day
      ''', [categoryId, currentStartDate, currentEndDate]);

      for (var row in dailyResult) {
        final day = row['day'] as int;
        final expense = (row['day_expense'] as num).toDouble();
        dailyExpenses[day] = expense;
      }

      debugPrint('일별 지출: $dailyExpenses');

      // 변경 퍼센트 계산 (이전 달 데이터가 없으면 100% 증가로 처리)
      double changePercentage = 0.0;
      if (lastMonthExpense > 0) {
        changePercentage = ((totalExpense - lastMonthExpense) / lastMonthExpense) * 100;
      } else if (totalExpense > 0) {
        changePercentage = 100.0; // 이전 달에 지출이 없고 현재 달에 지출이 있는 경우
      }

      // 카테고리 퍼센트 계산
      double categoryPercentage = 0.0;
      if (totalMonthExpenses > 0) {
        categoryPercentage = (totalExpense / totalMonthExpenses) * 100;
      }

      // 평균 지출 금액 계산
      final avgExpense = _transactions.isNotEmpty
          ? totalExpense / _transactions.length
          : 0.0;

      // 가장 지출이 많은 요일 찾기
      int maxExpenseDay = 1;
      double maxExpense = 0.0;
      dayOfWeekExpenses.forEach((day, amount) {
        if (amount > maxExpense) {
          maxExpense = amount;
          maxExpenseDay = day;
        }
      });

      // 결과 반환
      return {
        'total_expense': totalExpense,
        'category_percentage': categoryPercentage,
        'day_of_week_expenses': dayOfWeekExpenses,
        'daily_expenses': dailyExpenses,
        'last_month_expense': lastMonthExpense,
        'change_percentage': changePercentage,
        'avg_expense': avgExpense,
        'max_expense_day': maxExpenseDay,
        'max_expense_amount': maxExpense,
      };
    } catch (e) {
      debugPrint('카테고리 분석 데이터 계산 중 오류: $e');
      // 오류 발생 시 기본 빈 데이터 반환
      return {
        'total_expense': 0.0,
        'category_percentage': 0.0,
        'day_of_week_expenses': {1: 0.0, 2: 0.0, 3: 0.0, 4: 0.0, 5: 0.0, 6: 0.0, 7: 0.0},
        'daily_expenses': {},
        'last_month_expense': 0.0,
        'change_percentage': 0.0,
        'avg_expense': 0.0,
        'max_expense_day': 1,
        'max_expense_amount': 0.0,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    final currencyFormat = NumberFormat('#,###', 'ko_KR');
    final categoryName = widget.budgetStatus.categoryName;
    final budgetAmount = widget.budgetStatus.budgetAmount;
    final spentAmount = widget.budgetStatus.spentAmount.abs();
    final remainingAmount = widget.budgetStatus.remainingAmount;
    final progressPercentage = widget.budgetStatus.progressPercentage;

    // 진행 상태에 따른 색상 결정
    final Color progressColor = progressPercentage >= 90
        ? (themeController.isDarkMode ? Colors.red.shade400 : Colors.red)
        : (progressPercentage >= 70 
            ? (themeController.isDarkMode ? Colors.orange.shade400 : Colors.orange)
            : themeController.primaryColor);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: themeController.cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: themeController.isDarkMode 
                  ? Colors.black.withOpacity(0.4)
                  : Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // 헤더 섹션
            Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: BoxDecoration(
                color: themeController.surfaceColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        categoryName,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: themeController.textPrimaryColor,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: themeController.textPrimaryColor),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 예산 정보
                  Row(
                    children: [
                      // 남은 예산 표시
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '예산',
                              style: TextStyle(
                                fontSize: 14,
                                color: themeController.textSecondaryColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${currencyFormat.format(budgetAmount)}원',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: themeController.textPrimaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 사용한 금액 표시
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '사용',
                              style: TextStyle(
                                fontSize: 14,
                                color: themeController.textSecondaryColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${currencyFormat.format(spentAmount)}원',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: progressColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 진행 바
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progressPercentage / 100,
                      backgroundColor: themeController.isDarkMode 
                          ? Colors.grey.shade700.withOpacity(0.3)
                          : Colors.grey.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                      minHeight: 10,
                    ),
                  ),

                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${progressPercentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: progressColor,
                        ),
                      ),
                      Text(
                        '남은 예산: ${currencyFormat.format(remainingAmount)}원',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: themeController.textPrimaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 탭 바
            Container(
              decoration: BoxDecoration(
                color: themeController.cardColor,
                boxShadow: [
                  BoxShadow(
                    color: themeController.isDarkMode 
                        ? Colors.black.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.1),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: themeController.primaryColor,
                labelColor: themeController.primaryColor,
                unselectedLabelColor: themeController.textSecondaryColor,
                tabs: const [
                  Tab(text: '분석'),
                  Tab(text: '지출 내역'),
                  Tab(text: '인사이트'),
                ],
              ),
            ),

            // 탭 콘텐츠
            Expanded(
              child: Obx(() {
                if (_isLoading.value) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: themeController.primaryColor,
                    ),
                  );
                }

                // 거래 내역 디버깅 로그
                debugPrint('탭 콘텐츠 빌드 - 거래 내역 개수: ${_transactions.length}');

                return TabBarView(
                  controller: _tabController,
                  children: [
                    // 분석 탭
                    _buildAnalyticsTab(themeController),

                    // 지출 내역 탭 - 변경: Obx로 감싸기
                    Obx(() => CategoryTransactionList(transactions: _transactions.toList())),

                    // 인사이트 탭
                    _buildInsightsTab(themeController),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // 분석 탭 구성
  Widget _buildAnalyticsTab(ThemeController themeController) {
    final currencyFormat = NumberFormat('#,###', 'ko_KR');

    if (_analytics.isEmpty) {
      return Center(
        child: Text(
          '분석 데이터가 없습니다.',
          style: TextStyle(color: themeController.textSecondaryColor),
        ),
      );
    }

    final totalExpense = _analytics['total_expense'] as double;
    final categoryPercentage = _analytics['category_percentage'] as double;
    final dayOfWeekExpenses = _analytics['day_of_week_expenses'] as Map<int, double>;
    final dailyExpenses = _analytics['daily_expenses'] as Map<int, double>;

    // 요일 이름 변환
    final dayNames = ['월', '화', '수', '목', '금', '토', '일'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 통계 카드
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: themeController.cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: themeController.isDarkMode
                      ? Colors.black.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '지출 요약',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: themeController.textPrimaryColor,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: themeController.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '전체 지출의 ${categoryPercentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: themeController.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        '이번 달 총액',
                        '${currencyFormat.format(totalExpense.toInt())}원',
                        Icons.account_balance_wallet,
                        themeController,
                      ),
                    ),
                    Expanded(
                      child: _buildStatCard(
                        '평균 지출',
                        '${currencyFormat.format(_analytics['avg_expense'].toInt())}원',
                        Icons.bar_chart,
                        themeController,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        '지난 달 대비',
                        '${_analytics['change_percentage'] >= 0 ? '+' : ''}${_analytics['change_percentage'].toStringAsFixed(1)}%',
                        Icons.timeline,
                        themeController,
                        isPositive: _analytics['change_percentage'] < 0,
                      ),
                    ),
                    Expanded(
                      child: _buildStatCard(
                        '지출 빈도 높은 요일',
                        dayNames[_analytics['max_expense_day'] - 1],
                        Icons.calendar_today,
                        themeController,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 데이터가 없는 경우 표시할 메시지
          if (totalExpense == 0)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bar_chart,
                    size: 48,
                    color: themeController.isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '아직 ${widget.budgetStatus.categoryName} 카테고리의 지출 데이터가 없습니다.',
                    style: TextStyle(
                      color: themeController.textSecondaryColor,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else ...[
            // 요일별 지출 차트
            CategoryAnalyticsCharts(
              title: '요일별 지출',
              chartType: 'dayOfWeek',
              dayOfWeekExpenses: dayOfWeekExpenses,
              dailyExpenses: dailyExpenses,
              selectedPeriod: widget.controller.selectedPeriod.value,
            ),

            const SizedBox(height: 24),

            // 일별 지출 추이 차트
            CategoryAnalyticsCharts(
              title: '일별 지출 추이',
              chartType: 'daily',
              dayOfWeekExpenses: dayOfWeekExpenses,
              dailyExpenses: dailyExpenses,
              selectedPeriod: widget.controller.selectedPeriod.value,
            ),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // 통계 카드 위젯
  Widget _buildStatCard(String title, String value, IconData icon, ThemeController themeController, {bool isPositive = true}) {
    return Card(
      elevation: 0,
      color: themeController.isDarkMode ? Colors.grey.shade800.withOpacity(0.3) : Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: themeController.textSecondaryColor,
                ),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: themeController.textSecondaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: title == '지난 달 대비'
                    ? (isPositive 
                        ? (themeController.isDarkMode ? Colors.green.shade400 : Colors.green.shade700)
                        : (themeController.isDarkMode ? Colors.red.shade400 : Colors.red.shade700))
                    : themeController.textPrimaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 인사이트 탭 구성
  Widget _buildInsightsTab(ThemeController themeController) {
    // 거래 내역 여부 체크
    debugPrint('인사이트 탭 빌드 - 거래 내역 수: ${_transactions.length}');

    // 지출 거래만 필터링
    final expenseTransactions = _transactions.where((tx) {
      final amount = tx['amount'];
      return amount is num && amount < 0;
    }).toList();

    debugPrint('인사이트 탭 - 지출 거래 수: ${expenseTransactions.length}');

    if (expenseTransactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 64,
              color: themeController.isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              '${widget.budgetStatus.categoryName} 카테고리의 지출 내역이 없어\n인사이트를 생성할 수 없습니다.',
              style: TextStyle(
                color: themeController.textSecondaryColor,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final maxExpenseDay = _analytics['max_expense_day'] as int;
    final dayNames = ['월', '화', '수', '목', '금', '토', '일'];
    final changePercentage = _analytics['change_percentage'] as double;
    final totalExpense = _analytics['total_expense'] as double;

    // 충분한 데이터가 없는 경우 기본 메시지 표시
    if (totalExpense == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 64,
              color: themeController.isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              '아직 충분한 지출 데이터가 없어 인사이트를 제공할 수 없습니다.\n지출을 기록하면 다양한 인사이트를 얻을 수 있습니다.',
              style: TextStyle(
                color: themeController.textSecondaryColor,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // 인사이트 목록 생성
    List<Map<String, dynamic>> insights = [
      {
        'title': '지출 패턴',
        'icon': Icons.insights,
        'content': '${widget.budgetStatus.categoryName} 카테고리에서 가장 지출이 많은 요일은 ${dayNames[maxExpenseDay-1]}요일입니다.',
        'actionText': '요일별 지출 확인하기',
        'action': () {
          _tabController.animateTo(0);
        },
      },
      {
        'title': '전월 대비',
        'icon': Icons.trending_up,
        'content': _analytics['last_month_expense'] > 0
            ? '이번 달 ${widget.budgetStatus.categoryName} 지출은 지난 달보다 ${changePercentage.abs().toStringAsFixed(1)}% ${changePercentage >= 0 ? '증가' : '감소'}했습니다.'
            : '이번 달에 처음으로 ${widget.budgetStatus.categoryName} 카테고리에 지출이 발생했습니다.',
        'actionText': changePercentage >= 0 ? '지출 줄이는 팁 보기' : '잘 하고 있어요!',
        'action': () {
          // 지출 줄이는 팁 가이드 또는 축하 메시지
          final ThemeController themeController = Get.find<ThemeController>();
          Get.snackbar(
            changePercentage >= 0 ? '지출 관리 팁' : '축하합니다!',
            changePercentage >= 0
                ? '계획적인 소비와 필요한 지출만 하는 습관을 들여보세요.'
                : '지난 달보다 지출을 줄였네요. 잘 하고 있습니다!',
            backgroundColor: changePercentage >= 0 
                ? (themeController.isDarkMode ? AppColors.darkInfo : AppColors.info)
                : (themeController.isDarkMode ? AppColors.darkSuccess : AppColors.success),
            snackPosition: SnackPosition.TOP,
          );
        },
      },
      {
        'title': '예산 진행 상황',
        'icon': Icons.pie_chart,
        'content': widget.budgetStatus.progressPercentage >= 80
            ? '예산의 ${widget.budgetStatus.progressPercentage.toStringAsFixed(1)}%를 이미 사용했습니다. 이번 달 남은 기간 동안 지출을 줄이는 것이 좋겠습니다.'
            : '예산의 ${widget.budgetStatus.progressPercentage.toStringAsFixed(1)}%를 사용했습니다. 현재 페이스라면 예산 내에서 지출을 유지할 수 있어요.',
        'actionText': '지출 내역 확인하기',
        'action': () {
          _tabController.animateTo(1);
        },
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: insights.length,
      itemBuilder: (context, index) {
        final insight = insights[index];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 16),
          color: themeController.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: themeController.isDarkMode 
                  ? Colors.grey.shade700 
                  : Colors.grey.shade200,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      insight['icon'] as IconData,
                      color: themeController.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      insight['title'] as String,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: themeController.textPrimaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  insight['content'] as String,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: themeController.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: insight['action'] as Function(),
                  style: TextButton.styleFrom(
                    foregroundColor: themeController.primaryColor,
                    padding: EdgeInsets.zero,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        insight['actionText'] as String,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward, size: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}