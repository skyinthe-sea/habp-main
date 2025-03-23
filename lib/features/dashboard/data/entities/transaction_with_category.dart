class TransactionWithCategory {
  final int id;
  final int userId;
  final int categoryId;
  final String categoryName;
  final String categoryType;
  final double amount;
  final String description;
  final DateTime transactionDate;
  final String transactionNum;
  final DateTime createdAt;
  final DateTime updatedAt;

  TransactionWithCategory({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.categoryName,
    required this.categoryType,
    required this.amount,
    required this.description,
    required this.transactionDate,
    required this.transactionNum,
    required this.createdAt,
    required this.updatedAt,
  });
}