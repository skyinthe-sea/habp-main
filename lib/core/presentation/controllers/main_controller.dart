import 'package:get/get.dart';

import '../../../features/expense/data/datasources/expense_local_data_source.dart';
import '../../../features/expense/data/repositories/expense_repository_impl.dart';
import '../../../features/expense/domain/usecases/add_budget.dart';
import '../../../features/expense/domain/usecases/add_category.dart';
import '../../../features/expense/domain/usecases/add_expense.dart';
import '../../../features/expense/domain/usecases/delete_category.dart';
import '../../../features/expense/domain/usecases/get_budget_status.dart';
import '../../../features/expense/domain/usecases/get_variable_categories.dart';
import '../../../features/expense/domain/usecases/update_budget.dart';
import '../../../features/expense/domain/usecases/update_category.dart';
import '../../../features/expense/presentation/controllers/expense_controller.dart';
import '../../../features/diary/data/datasources/monthly_diary_local_data_source.dart';
import '../../../features/diary/data/repositories/monthly_diary_repository_impl.dart';
import '../../../features/diary/presentation/controllers/diary_controller.dart';
import '../../database/db_helper.dart';

class MainController extends GetxController {
  final RxInt selectedIndex = 0.obs;
  late ExpenseController expenseController;
  late DiaryController diaryController;

  @override
  void onInit() {
    super.onInit();
    _initExpenseController();
    _initDiaryController();
  }

  void changeTab(int index) {
    selectedIndex.value = index;
  }

  void _initExpenseController() {
    // ExpenseController 초기화 및 의존성 주입
    final dbHelper = DBHelper();
    final dataSource = ExpenseLocalDataSourceImpl(dbHelper: dbHelper);
    final repository = ExpenseRepositoryImpl(localDataSource: dataSource);

    final getBudgetStatusUseCase = GetBudgetStatus(repository);
    final getVariableCategoriesUseCase = GetVariableCategories(repository);
    final addBudgetUseCase = AddBudget(repository);
    final addCategoryUseCase = AddCategory(repository);
    final deleteCategoryUseCase = DeleteCategory(repository);
    final addExpenseUseCase = AddExpense(repository);
    final updateBudgetUseCase = UpdateBudget(repository);
    final updateCategoryUseCase = UpdateCategory(repository);

    expenseController = ExpenseController(
      getBudgetStatusUseCase: getBudgetStatusUseCase,
      getVariableCategoriesUseCase: getVariableCategoriesUseCase,
      addBudgetUseCase: addBudgetUseCase,
      addCategoryUseCase: addCategoryUseCase,
      deleteCategoryUseCase: deleteCategoryUseCase,
      addExpenseUseCase: addExpenseUseCase,
      updateBudgetUseCase: updateBudgetUseCase,
      updateCategoryUseCase: updateCategoryUseCase,
    );

    // GetX DI에 등록
    Get.put(expenseController);
  }

  void _initDiaryController() {
    // DiaryController 초기화 및 의존성 주입
    final dbHelper = DBHelper();
    final dataSource = MonthlyDiaryLocalDataSource(dbHelper);
    final repository = MonthlyDiaryRepositoryImpl(dataSource, 1); // userId = 1 (기본 사용자)

    diaryController = DiaryController(repository);

    // GetX DI에 등록
    Get.put(diaryController);
  }

  // ExpensePage에서도 사용할 수 있도록 ExpenseController를 반환하는 getter
  ExpenseController get getExpenseController => expenseController;

  // DiaryPage에서도 사용할 수 있도록 DiaryController를 반환하는 getter
  DiaryController get getDiaryController => diaryController;
}