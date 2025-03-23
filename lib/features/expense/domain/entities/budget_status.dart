class BudgetStatus {
  final int categoryId;
  final String categoryName;
  final double budgetAmount;
  final double spentAmount;
  final double remainingAmount;
  final double progressPercentage;

  BudgetStatus({
    required this.categoryId,
    required this.categoryName,
    required this.budgetAmount,
    required this.spentAmount,
    required this.remainingAmount,
    required this.progressPercentage,
  });
}