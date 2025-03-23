import '../../domain/entities/budget_status.dart';

class BudgetStatusModel extends BudgetStatus {
  BudgetStatusModel({
    required int categoryId,
    required String categoryName,
    required double budgetAmount,
    required double spentAmount,
    required double remainingAmount,
    required double progressPercentage,
  }) : super(
    categoryId: categoryId,
    categoryName: categoryName,
    budgetAmount: budgetAmount,
    spentAmount: spentAmount,
    remainingAmount: remainingAmount,
    progressPercentage: progressPercentage,
  );

  factory BudgetStatusModel.fromMap(Map<String, dynamic> map) {
    final budgetAmount = (map['budget_amount'] as num?)?.toDouble() ?? 0.0;
    final spentAmount = (map['spent_amount'] as num?)?.toDouble() ?? 0.0;
    final remainingAmount = budgetAmount - spentAmount;
    final progressPercentage = budgetAmount > 0 ? (spentAmount / budgetAmount) * 100 : 0.0;

    return BudgetStatusModel(
      categoryId: map['category_id'] as int,
      categoryName: map['category_name'] as String,
      budgetAmount: budgetAmount,
      spentAmount: spentAmount,
      remainingAmount: remainingAmount,
      progressPercentage: progressPercentage > 100 ? 100.0 : progressPercentage,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'category_id': categoryId,
      'category_name': categoryName,
      'budget_amount': budgetAmount,
      'spent_amount': spentAmount,
      'remaining_amount': remainingAmount,
      'progress_percentage': progressPercentage,
    };
  }
}