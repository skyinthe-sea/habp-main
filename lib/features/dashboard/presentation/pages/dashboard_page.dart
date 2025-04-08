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

  @override
  void initState() {
    super.initState();
    _initController();
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

    // 개발 중에만 데이터베이스 정보 출력
    //dbHelper.printDatabaseInfo();

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
        child: PageTransitionSwitcher(
          // 페이지 전환 애니메이션을 사용하여 월별 데이터 탐색 시 부드러운 전환 구현
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
            padding: const EdgeInsets.all(10), // 간격 축소
            key: ValueKey<String>(_controller.getMonthYearString()), // 키 사용하여 전환 애니메이션 적용
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 월간 요약 카드 (월 선택 포함)
                MonthlySummaryCard(controller: _controller),
                const SizedBox(height: 10), // 간격 축소

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
                const SizedBox(height: 10), // 간격 축소

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
                const SizedBox(height: 10), // 간격 축소

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