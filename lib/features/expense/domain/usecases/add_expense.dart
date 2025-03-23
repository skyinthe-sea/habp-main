import '../repositories/expense_repository.dart';

class AddExpense {
  final ExpenseRepository repository;

  AddExpense(this.repository);

  Future<bool> call({
    required int userId,
    required int categoryId,
    required double amount,
    required String description,
    required String transactionDate,
  }) async {
    return await repository.addExpense(
      userId: userId,
      categoryId: categoryId,
      amount: amount,
      description: description,
      transactionDate: transactionDate,
    );
  }
}