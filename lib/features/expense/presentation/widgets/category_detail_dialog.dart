import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/constants/app_colors.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      _transactions.assignAll(transactions);

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

  // 카테고리 거래 내역 가져오기 (실제 앱에서는 repository를 통해 데이터 가져옴)
  Future<List<Map<String, dynamic>>> _fetchCategoryTransactions(
      int userId, int categoryId, String period) async {
    // 실제 앱에서는 API 또는 로컬 DB에서 데이터 가져오기
    // 임시 데이터 (실제 구현 시 삭제)
    await Future.delayed(const Duration(milliseconds: 800)); // 로딩 시뮬레이션

    final year = int.parse(period.split('-')[0]);
    final month = int.parse(period.split('-')[1]);
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0);

    // 랜덤 데이터 생성 (실제 구현 시 삭제)
    final random = DateTime.now().microsecond % 10 + 3; // 3~12개 항목
    List<Map<String, dynamic>> mockTransactions = [];

    for (int i = 0; i < random; i++) {
      final day = (DateTime.now().day + i) % endDate.day + 1;
      final date = DateTime(year, month, day);
      final amount = (10000 + (i * 5000) + (DateTime.now().microsecond % 20000));

      mockTransactions.add({
        'id': i + 1,
        'category_id': categoryId,
        'amount': (amount * -1).toDouble(),
        'description': '${widget.budgetStatus.categoryName} 지출 ${i + 1}',
        'transaction_date': date.toIso8601String(),
        'day_of_week': date.weekday,
      });
    }

    // 날짜순 정렬
    mockTransactions.sort((a, b) =>
        DateTime.parse(b['transaction_date']).compareTo(DateTime.parse(a['transaction_date'])));

    return mockTransactions;
  }

  // 카테고리 분석 데이터 계산
  Future<Map<String, dynamic>> _analyzeCategoryData(
      int userId, int categoryId, String period) async {

    // 임시 데이터 (실제 구현 시 더 정확한 데이터로 대체)
    final totalExpenses = _transactions.fold<double>(
        0, (sum, item) => sum + item['amount'].abs());

    // 전체 카테고리 지출 중 비율 (실제로는 DB에서 계산)
    final totalMonthExpenses = totalExpenses * (2.5 + (DateTime.now().microsecond % 5) / 10);
    final categoryPercentage = (totalExpenses / totalMonthExpenses * 100);

    // 요일별 지출 분석
    final Map<int, double> dayOfWeekExpenses = {};
    for (int i = 1; i <= 7; i++) {
      dayOfWeekExpenses[i] = 0;
    }

    for (var transaction in _transactions) {
      final dayOfWeek = transaction['day_of_week'] as int;
      dayOfWeekExpenses[dayOfWeek] = (dayOfWeekExpenses[dayOfWeek] ?? 0) + transaction['amount'].abs();
    }

    // 일별 지출 추이 계산
    final Map<int, double> dailyExpenses = {};
    for (var transaction in _transactions) {
      final day = DateTime.parse(transaction['transaction_date']).day;
      dailyExpenses[day] = (dailyExpenses[day] ?? 0) + transaction['amount'].abs();
    }

    // 이전 달 같은 카테고리 지출과 비교 (임시 데이터)
    final lastMonthExpense = totalExpenses * (0.8 + (DateTime.now().microsecond % 40) / 100);
    final changePercentage = ((totalExpenses - lastMonthExpense) / lastMonthExpense * 100);

    // 평균 지출 금액
    final avgExpense = _transactions.isNotEmpty
        ? totalExpenses / _transactions.length
        : 0;

    // 가장 지출이 많은 요일
    int maxExpenseDay = 1;
    double maxExpense = 0;
    dayOfWeekExpenses.forEach((day, amount) {
      if (amount > maxExpense) {
        maxExpense = amount;
        maxExpenseDay = day;
      }
    });

    // 결과 반환
    return {
      'total_expense': totalExpenses,
      'category_percentage': categoryPercentage,
      'day_of_week_expenses': dayOfWeekExpenses,
      'daily_expenses': dailyExpenses,
      'last_month_expense': lastMonthExpense,
      'change_percentage': changePercentage,
      'avg_expense': avgExpense,
      'max_expense_day': maxExpenseDay,
      'max_expense_amount': maxExpense,
    };
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,###', 'ko_KR');
    final categoryName = widget.budgetStatus.categoryName;
    final budgetAmount = widget.budgetStatus.budgetAmount;
    final spentAmount = widget.budgetStatus.spentAmount.abs();
    final remainingAmount = widget.budgetStatus.remainingAmount;
    final progressPercentage = widget.budgetStatus.progressPercentage;

    // 진행 상태에 따른 색상 결정
    final Color progressColor = progressPercentage >= 90
        ? Colors.red
        : (progressPercentage >= 70 ? Colors.orange : AppColors.primary);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
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
                color: AppColors.background,
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
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
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
                            const Text(
                              '예산',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${currencyFormat.format(budgetAmount)}원',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
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
                            const Text(
                              '사용',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
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
                      backgroundColor: Colors.grey.withOpacity(0.2),
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
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
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
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: Colors.grey,
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
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                return TabBarView(
                  controller: _tabController,
                  children: [
                    // 분석 탭
                    _buildAnalyticsTab(),

                    // 지출 내역 탭
                    CategoryTransactionList(transactions: _transactions),

                    // 인사이트 탭
                    _buildInsightsTab(),
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
  Widget _buildAnalyticsTab() {
    final currencyFormat = NumberFormat('#,###', 'ko_KR');

    if (_analytics.isEmpty) {
      return const Center(child: Text('분석 데이터가 없습니다.'));
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
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
                    const Text(
                      '지출 요약',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '전체 지출의 ${categoryPercentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: AppColors.primary,
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
                      ),
                    ),
                    Expanded(
                      child: _buildStatCard(
                        '평균 지출',
                        '${currencyFormat.format(_analytics['avg_expense'].toInt())}원',
                        Icons.bar_chart,
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
                        isPositive: _analytics['change_percentage'] < 0,
                      ),
                    ),
                    Expanded(
                      child: _buildStatCard(
                        '지출 빈도 높은 요일',
                        dayNames[_analytics['max_expense_day'] - 1],
                        Icons.calendar_today,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

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

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // 통계 카드 위젯
  Widget _buildStatCard(String title, String value, IconData icon, {bool isPositive = true}) {
    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
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
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
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
                    ? (isPositive ? Colors.green.shade700 : Colors.red.shade700)
                    : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 인사이트 탭 구성
  Widget _buildInsightsTab() {
    if (_transactions.isEmpty) {
      return const Center(child: Text('지출 내역이 없어 인사이트를 생성할 수 없습니다.'));
    }

    final maxExpenseDay = _analytics['max_expense_day'] as int;
    final dayNames = ['월', '화', '수', '목', '금', '토', '일'];
    final changePercentage = _analytics['change_percentage'] as double;

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
        'content': '이번 달 ${widget.budgetStatus.categoryName} 지출은 지난 달보다 ${changePercentage.abs().toStringAsFixed(1)}% ${changePercentage >= 0 ? '증가' : '감소'}했습니다.',
        'actionText': changePercentage >= 0 ? '지출 줄이는 팁 보기' : '잘 하고 있어요!',
        'action': () {
          // 지출 줄이는 팁 가이드 또는 축하 메시지
          Get.snackbar(
            changePercentage >= 0 ? '지출 관리 팁' : '축하합니다!',
            changePercentage >= 0
                ? '계획적인 소비와 필요한 지출만 하는 습관을 들여보세요.'
                : '지난 달보다 지출을 줄였네요. 잘 하고 있습니다!',
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
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
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      insight['title'] as String,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  insight['content'] as String,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: insight['action'] as Function(),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
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