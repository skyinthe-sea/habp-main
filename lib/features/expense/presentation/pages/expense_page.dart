import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/database/db_helper.dart';
import '../../data/datasources/expense_local_data_source.dart';
import '../../data/repositories/expense_repository_impl.dart';
import '../../domain/usecases/add_category.dart';
import '../../domain/usecases/add_expense.dart';
import '../../domain/usecases/delete_category.dart';
import '../../domain/usecases/get_budget_status.dart';
import '../../domain/usecases/get_variable_categories.dart';
import '../../domain/usecases/add_budget.dart';
import '../controllers/expense_controller.dart';
import '../widgets/period_selector.dart';
import '../widgets/overall_budget_card.dart';
import '../widgets/category_budget_list.dart';
import '../widgets/add_budget_dialog.dart';

class ExpensePage extends StatefulWidget {
  const ExpensePage({Key? key}) : super(key: key);

  @override
  State<ExpensePage> createState() => _ExpensePageState();
}

class _ExpensePageState extends State<ExpensePage> {
  late ExpenseController _controller;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    // 의존성 주입
    final dbHelper = DBHelper();
    final dataSource = ExpenseLocalDataSourceImpl(dbHelper: dbHelper);
    final repository = ExpenseRepositoryImpl(localDataSource: dataSource);
    final budgetStatusUseCase = GetBudgetStatus(repository);
    final variableCategoriesUseCase = GetVariableCategories(repository);
    final addBudgetUseCase = AddBudget(repository);

    _controller = ExpenseController(
      getBudgetStatusUseCase: budgetStatusUseCase,
      getVariableCategoriesUseCase: variableCategoriesUseCase,
      addBudgetUseCase: addBudgetUseCase,
      addCategoryUseCase: AddCategory(repository),
      deleteCategoryUseCase: DeleteCategory(repository),
      addExpenseUseCase: AddExpense(repository),
    );
    Get.put(_controller);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          '예산 관리',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.primary),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AddBudgetDialog(controller: _controller),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 고정된 달력 내비게이션
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: PeriodSelector(controller: _controller),
            ),

            // 스크롤 가능한 콘텐츠
            Expanded(
              child: Obx(() {
                return _controller.isLoading.value && _controller.budgetStatusList.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '이번 달 예산 현황',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OverallBudgetCard(controller: _controller),
                      const SizedBox(height: 24),
                      const Text(
                        '카테고리별 예산',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      CategoryBudgetList(controller: _controller),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}