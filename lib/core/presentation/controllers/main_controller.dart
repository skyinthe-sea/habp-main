import 'package:get/get.dart';

import '../../../features/expense/data/datasources/expense_local_data_source.dart';
import '../../../features/expense/data/repositories/expense_repository_impl.dart';
import '../../../features/expense/domain/usecases/add_budget.dart';
import '../../../features/expense/domain/usecases/add_category.dart';
import '../../../features/expense/domain/usecases/add_expense.dart';
import '../../../features/expense/domain/usecases/delete_category.dart';
import '../../../features/expense/domain/usecases/get_budget_status.dart';
import '../../../features/expense/domain/usecases/get_variable_categories.dart';
import '../../../features/expense/presentation/controllers/expense_controller.dart';
import '../../database/db_helper.dart';

class MainController extends GetxController {
  final RxInt selectedIndex = 0.obs;
  late ExpenseController expenseController;

  @override
  void onInit() {
    super.onInit();
    _initExpenseController();
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

    expenseController = ExpenseController(
      getBudgetStatusUseCase: getBudgetStatusUseCase,
      getVariableCategoriesUseCase: getVariableCategoriesUseCase,
      addBudgetUseCase: addBudgetUseCase,
      addCategoryUseCase: addCategoryUseCase,
      deleteCategoryUseCase: deleteCategoryUseCase,
      addExpenseUseCase: addExpenseUseCase,
    );

    // GetX DI에 등록
    Get.put(expenseController);
  }

  // ExpensePage에서도 사용할 수 있도록 ExpenseController를 반환하는 getter
  ExpenseController get getExpenseController => expenseController;
}