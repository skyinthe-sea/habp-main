import '../repositories/expense_repository.dart';

class AddBudget {
  final ExpenseRepository repository;

  AddBudget(this.repository);

  Future<bool> call({
    required int userId,
    required int categoryId,
    required double amount,
    required String periodStart,
    required String periodEnd,
  }) async {
    return await repository.addBudget(
      userId: userId,
      categoryId: categoryId,
      amount: amount,
      periodStart: periodStart,
      periodEnd: periodEnd,
    );
  }
}