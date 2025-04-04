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
  final int _currentIndex = 0;
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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12), // 16에서 12로 감소
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 월간 요약 카드
              MonthlySummaryCard(controller: _controller),
              const SizedBox(height: 16), // 24에서 16으로 감소

              // 월별 지출 추이 차트
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14), // 16에서 14로 감소
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 8, // 10에서 8로 감소
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: MonthlyExpenseChart(controller: _controller),
              ),
              const SizedBox(height: 16), // 24에서 16으로 감소

              // 카테고리별 차트 (탭으로 전환 가능)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14), // 16에서 14로 감소
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 8, // 10에서 8로 감소
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: CategoryChartTabs(controller: _controller),
              ),
              const SizedBox(height: 16), // 24에서 16으로 감소

              // 최근 거래 내역
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14), // 16에서 14로 감소
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 8, // 10에서 8로 감소
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
    );
  }
}