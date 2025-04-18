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
import '../widgets/add_budget_dialog.dart';
import '../widgets/budget_pie_chart.dart';
import '../widgets/category_budget_grid.dart';

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

  // AutomaticKeepAliveClientMixin 상태 유지
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
    // 화면이 보일 때마다 데이터 새로고침
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

    // 의존성 주입
    final dbHelper = DBHelper();
    final dataSource = ExpenseLocalDataSourceImpl(dbHelper: dbHelper);
    final repository = ExpenseRepositoryImpl(localDataSource: dataSource);
    final budgetStatusUseCase = GetBudgetStatus(repository);
    final variableCategoriesUseCase = GetVariableCategories(repository);
    final addBudgetUseCase = AddBudget(repository);

    // 컨트롤러를 영구적으로 등록 (앱 재시작할 때도 유지)
    return Get.put(
        ExpenseController(
          getBudgetStatusUseCase: budgetStatusUseCase,
          getVariableCategoriesUseCase: variableCategoriesUseCase,
          addBudgetUseCase: addBudgetUseCase,
          addCategoryUseCase: AddCategory(repository),
          deleteCategoryUseCase: DeleteCategory(repository),
          addExpenseUseCase: AddExpense(repository),
        ),
        permanent: true);
  }

  // 초기 데이터 로드
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

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin 필수

    return FutureBuilder(
      future: _initFuture,
      builder: (context, snapshot) {
        // 초기 데이터 로드 중일 때 로딩 표시
        if (snapshot.connectionState == ConnectionState.waiting &&
            !_isInitialized) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 1,
              title: const Text(
                '수기가계부',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: GetBuilder<ExpenseController>(
                init: _controller,
                builder: (controller) {
                  return Column(
                    children: [
                      // 고정된 달력 내비게이션
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: PeriodSelector(controller: controller),
                      ),

                      // 스크롤 가능한 콘텐츠
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
                                    // 전체 예산 카드 (간소화된 버전)
                                    OverallBudgetCard(controller: controller),
                                    const SizedBox(height: 16),

                                    // 파이 차트 추가
                                    BudgetPieChart(controller: controller),
                                    const SizedBox(height: 24),

                                    // 카테고리별 예산 섹션 헤더
                                    const Text(
                                      '카테고리별 예산',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    // 그리드 형태의 카테고리 목록
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
          floatingActionButton: FloatingActionButton(
            mini: true, // <-- 크기를 작게 만듭니다.
            backgroundColor: AppColors.primary.withOpacity(0.7), // <-- 배경색에 투명도(70% 불투명)를 적용합니다.
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AddBudgetDialog(controller: _controller),
              );
            },
            // mini 사이즈에 맞춰 아이콘 크기도 조절하고 싶다면 Transform.scale 또는 SizedBox로 감싸고 Icon size 조정
            child: const Icon(
              Icons.settings,
              color: Colors.white,
              // size: 18, // 필요하다면 아이콘 크기를 직접 조절할 수도 있습니다.
            ),
          ),
        );
      },
    );
  }
}