import '../repositories/expense_repository.dart';

class UpdateBudget {
  final ExpenseRepository repository;

  UpdateBudget(this.repository);

  Future<bool> call({
    required int userId,
    required int categoryId,
    required double amount,
    required String periodStart,
    required String periodEnd,
  }) async {
    return await repository.updateBudget(
      userId: userId,
      categoryId: categoryId,
      amount: amount,
      periodStart: periodStart,
      periodEnd: periodEnd,
    );
  }
}