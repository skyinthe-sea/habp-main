import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/controllers/theme_controller.dart';
import '../../../../core/database/db_helper.dart';
import '../../data/datasources/expense_local_data_source.dart';
import '../../data/repositories/expense_repository_impl.dart';
import '../../domain/usecases/add_category.dart';
import '../../domain/usecases/add_expense.dart';
import '../../domain/usecases/delete_category.dart';
import '../../domain/usecases/get_budget_status.dart';
import '../../domain/usecases/get_variable_categories.dart';
import '../../domain/usecases/add_budget.dart';
import '../../domain/usecases/update_budget.dart';
import '../../domain/usecases/update_category.dart';
import '../controllers/expense_controller.dart';
import '../widgets/period_selector.dart';
import '../widgets/overall_budget_card.dart';
import '../widgets/budget_pie_chart.dart';
import '../widgets/category_budget_grid.dart';
import '../widgets/multi_category_budget_dialog.dart';

class ExpensePage extends StatefulWidget {
  const ExpensePage({Key? key}) : super(key: key);

  @override
  State<ExpensePage> createState() => _ExpensePageState();
}

class _ExpensePageState extends State<ExpensePage>
    with AutomaticKeepAliveClientMixin {
  late ExpenseController _controller;
  late Future<void> _initFuture;
  bool _isInitialized = false;

  // AutomaticKeepAliveClientMixin state maintenance
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _controller = _initController();
    _initFuture = _loadInitialData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when screen becomes visible
    if (_isInitialized) {
      _refreshData();
    }
  }

  void _refreshData() {
    if (!_controller.isLoading.value) {
      debugPrint('ExpensePage: 데이터 새로고침');
      _controller.fetchBudgetStatus();
      _controller.fetchVariableCategories();
    }
  }

  ExpenseController _initController() {
    // Check if controller already exists to avoid duplication on hot restart
    if (Get.isRegistered<ExpenseController>()) {
      final controller = Get.find<ExpenseController>();
      // Reset any necessary state
      controller.dataInitialized.value = false;
      // Trigger data reload
      controller.fetchBudgetStatus();
      controller.fetchVariableCategories();
      return controller;
    }

    // Dependency injection
    final dbHelper = DBHelper();
    final dataSource = ExpenseLocalDataSourceImpl(dbHelper: dbHelper);
    final repository = ExpenseRepositoryImpl(localDataSource: dataSource);
    final budgetStatusUseCase = GetBudgetStatus(repository);
    final variableCategoriesUseCase = GetVariableCategories(repository);
    final addBudgetUseCase = AddBudget(repository);
    final updateBudgetUseCase = UpdateBudget(repository);
    final updateCategoryUseCase = UpdateCategory(repository);

    // Register controller permanently
    return Get.put(
        ExpenseController(
          getBudgetStatusUseCase: budgetStatusUseCase,
          getVariableCategoriesUseCase: variableCategoriesUseCase,
          addBudgetUseCase: addBudgetUseCase,
          addCategoryUseCase: AddCategory(repository),
          deleteCategoryUseCase: DeleteCategory(repository),
          addExpenseUseCase: AddExpense(repository),
          updateBudgetUseCase: updateBudgetUseCase,
          updateCategoryUseCase: updateCategoryUseCase,
        ),
        permanent: true);
  }

  // Load initial data
  Future<void> _loadInitialData() async {
    debugPrint('ExpensePage: 초기 데이터 로드 시작');
    try {
      await _controller.fetchBudgetStatus();
      await _controller.fetchVariableCategories();
      _isInitialized = true;
      debugPrint('ExpensePage: 초기 데이터 로드 완료');
    } catch (e) {
      debugPrint('ExpensePage: 초기 데이터 로드 오류 - $e');
    }
  }

  void _showBudgetDialog() {
    showDialog(
      context: context,
      builder: (context) => MultiCategoryBudgetDialog(controller: _controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return FutureBuilder(
      future: _initFuture,
      builder: (context, snapshot) {
        // Show loading indicator while initial data is being loaded
        if (snapshot.connectionState == ConnectionState.waiting &&
            !_isInitialized) {
          final ThemeController themeController = Get.find<ThemeController>();
          return Scaffold(
            backgroundColor: themeController.backgroundColor,
            appBar: AppBar(
              backgroundColor: themeController.cardColor,
              elevation: 1,
              title: Text(
                '수기가계부',
                style: TextStyle(
                  color: themeController.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            body: Center(
              child: CircularProgressIndicator(
                color: themeController.primaryColor,
              ),
            ),
          );
        }

        return GetBuilder<ThemeController>(
          builder: (themeController) {
            return Scaffold(
              backgroundColor: themeController.backgroundColor,
              body: SafeArea(
                child: GetBuilder<ExpenseController>(
                    init: _controller,
                    builder: (controller) {
                  return Column(
                    children: [
                      // Fixed period selector
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: PeriodSelector(controller: controller),
                      ),

                      // Scrollable content
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: () async {
                            await controller.fetchBudgetStatus();
                          },
                          child: Obx(() {
                            return controller.isLoading.value &&
                                controller.budgetStatusList.isEmpty
                                ? const Center(
                                child: CircularProgressIndicator())
                                : SingleChildScrollView(
                              physics:
                              const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(16),
                              // Add this to ensure the ScrollView has a minimum height
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight:
                                  MediaQuery.of(context).size.height -
                                      200, // Adjust as needed
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    // Overall budget card
                                    OverallBudgetCard(controller: controller),
                                    const SizedBox(height: 16),

                                    // Budget pie chart
                                    BudgetPieChart(controller: controller),
                                    const SizedBox(height: 24),

                                    // Category section header with new button
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '카테고리별 예산',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: themeController.textPrimaryColor,
                                          ),
                                        ),
                                        ElevatedButton.icon(
                                          onPressed: _showBudgetDialog,
                                          icon: const Icon(Icons.edit, size: 16),
                                          label: const Text('예산 설정'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: themeController.primaryColor,
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 8
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),

                                    // Category budget grid
                                    CategoryBudgetGrid(controller: controller),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            );
          },
        );
      },
    );
  }
}