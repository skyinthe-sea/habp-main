// lib/features/dashboard/presentation/pages/dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/database/db_helper.dart';
import '../../data/datasources/transaction_local_data_source.dart';
import '../../data/repositories/transaction_repository_impl.dart';
import '../../domain/usecases/get_assets.dart';
import '../../domain/usecases/get_category_income.dart';
import '../../domain/usecases/get_category_finance.dart';
import '../../domain/usecases/get_monthly_summary.dart';
import '../../domain/usecases/get_monthly_expenses_trend.dart';
import '../../domain/usecases/get_category_expenses.dart';
import '../../domain/usecases/get_recent_transactions.dart';
import '../presentation/dashboard_controller.dart';
import '../widgets/monthly_summary_card.dart';
import '../widgets/monthly_expense_chart.dart';
import '../widgets/category_chart_tabs.dart';
import '../widgets/recent_transactions_list.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with SingleTickerProviderStateMixin {
  late DashboardController _controller;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _initController() {
    // 의존성 주입
    final dbHelper = DBHelper();
    final dataSource = TransactionLocalDataSourceImpl(dbHelper: dbHelper);
    final repository = TransactionRepositoryImpl(localDataSource: dataSource);

    final summaryUseCase = GetMonthlySummary(repository);
    final expensesTrendUseCase = GetMonthlyExpensesTrend(repository);
    final categoryExpensesUseCase = GetCategoryExpenses(repository);
    final categoryIncomeUseCase = GetCategoryIncome(repository);
    final categoryFinanceUseCase = GetCategoryFinance(repository);
    final recentTransactionsUseCase = GetRecentTransactions(repository);
    final assetsUseCase = GetAssets(repository);

    dbHelper.printDatabaseInfo();

    _controller = DashboardController(
      getMonthlySummary: summaryUseCase,
      getMonthlyExpensesTrend: expensesTrendUseCase,
      getCategoryExpenses: categoryExpensesUseCase,
      getCategoryIncome: categoryIncomeUseCase,
      getCategoryFinance: categoryFinanceUseCase,
      getRecentTransactions: recentTransactionsUseCase,
      getAssets: assetsUseCase,
    );
    Get.put(_controller);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // 고정된 월 선택 컨트롤러 영역
            _buildMonthSelectorBar(),

            // 스크롤 가능한 나머지 콘텐츠
            Expanded(
              child: PageTransitionSwitcher(
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.1, 0.0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(10),
                  key: ValueKey<String>(_controller.getMonthYearString()),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 월간 요약 카드 (월 선택 제외)
                      MonthlySummaryCard(controller: _controller, excludeMonthSelector: true),
                      const SizedBox(height: 10),

                      // 월별 지출 추이 차트
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: MonthlyExpenseChart(controller: _controller),
                      ),
                      const SizedBox(height: 10),

                      // 카테고리별 차트 (탭으로 전환 가능)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: CategoryChartTabs(controller: _controller),
                      ),
                      const SizedBox(height: 10),

                      // 최근 거래 내역
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: RecentTransactionsList(controller: _controller),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthSelectorBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _buildMonthSelector(),
    );
  }


  Widget _buildMonthSelector() {
    return Obx(() {
      final isCurrentMonth = _controller.selectedMonth.value.year == DateTime.now().year &&
          _controller.selectedMonth.value.month == DateTime.now().month;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.pink.shade50,
              const Color(0xFFF5F5F5),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 이전 달로 이동 버튼
            _buildNavigationButton(
              icon: Icons.chevron_left,
              onTap: _controller.goToPreviousMonth,
            ),

            // 월 선택 및 현재 월 버튼
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 월 선택 드롭다운 버튼
                InkWell(
                  onTap: () => _showMonthPickerDialog(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _controller.getMonthYearString(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.arrow_drop_down,
                          size: 18,
                          color: Colors.black54,
                        ),
                      ],
                    ),
                  ),
                ),

                // 현재 월로 이동 버튼 (항상 표시되도록 수정)
                const SizedBox(width: 8),
                InkWell(
                  onTap: _controller.goToCurrentMonth,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: isCurrentMonth ? Colors.grey.shade100 : AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.today,
                          size: 12,
                          color: isCurrentMonth ? Colors.grey : AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // 다음 달로 이동 버튼
            _buildNavigationButton(
              icon: Icons.chevron_right,
              onTap: isCurrentMonth ? null : _controller.goToNextMonth,
              isDisabled: isCurrentMonth,
            ),
          ],
        ),
      );
    });
  }

  Future<void> _showMonthPickerDialog(BuildContext context) async {
    final initialDate = _controller.selectedMonth.value;
    int selectedYear = initialDate.year;

    final result = await showDialog<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      setState(() {
                        selectedYear--;
                      });
                    },
                  ),
                  Text('$selectedYear년', style: const TextStyle(fontSize: 16)),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: selectedYear >= DateTime.now().year ? null : () {
                      setState(() {
                        selectedYear++;
                      });
                    },
                  ),
                ],
              ),
              content: SizedBox(
                width: 300,
                height: 180,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 1.5,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    final month = index + 1;
                    final isSelected = month == initialDate.month && selectedYear == initialDate.year;
                    final isDisabled = selectedYear == DateTime.now().year && month > DateTime.now().month;

                    return InkWell(
                      onTap: isDisabled ? null : () {
                        Navigator.of(context).pop(DateTime(selectedYear, month, 1));
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : Colors.grey.shade300,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '$month월',
                            style: TextStyle(
                              color: isDisabled
                                  ? Colors.grey.shade400
                                  : isSelected ? Colors.white : Colors.black87,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('취소', style: TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(DateTime(
                      DateTime.now().year,
                      DateTime.now().month,
                      1,
                    ));
                  },
                  child: const Text('오늘', style: TextStyle(color: AppColors.primary)),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      _controller.selectedMonth.value = result;
    }
  }

  Widget _buildNavigationButton({
    required IconData icon,
    required VoidCallback? onTap,
    bool isDisabled = false,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: isDisabled ? Colors.grey.shade100 : Colors.white,
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(
              icon,
              color: isDisabled ? Colors.grey.shade400 : AppColors.primary,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

// 페이지 전환 애니메이션을 위한 위젯
class PageTransitionSwitcher extends StatelessWidget {
  final Widget child;
  final Widget Function(Widget, Animation<double>) transitionBuilder;

  const PageTransitionSwitcher({
    Key? key,
    required this.child,
    required this.transitionBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: transitionBuilder,
      child: child,
    );
  }
}