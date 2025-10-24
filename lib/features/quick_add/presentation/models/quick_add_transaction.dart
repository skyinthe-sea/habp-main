// lib/features/quick_add/presentation/models/quick_add_transaction.dart

/// Model class for handling a transaction during the quick add flow
class QuickAddTransaction {
  /// Category type (INCOME, EXPENSE, FINANCE)
  String categoryType = '';

  /// Selected category ID
  int? categoryId;

  /// Selected category name (for display)
  String categoryName = '';

  /// Transaction date
  DateTime transactionDate = DateTime.now();

  /// Transaction amount
  double amount = 0.0;

  /// Optional description
  String description = '';

  /// Optional emotion tag (HAPPY, NEUTRAL, STRESSED)
  String? emotionTag;

  /// Optional image path (영수증/사진)
  String? imagePath;

  QuickAddTransaction({
    this.categoryType = '',
    this.categoryId,
    this.categoryName = '',
    DateTime? transactionDate,
    this.amount = 0.0,
    this.description = '',
    this.emotionTag,
    this.imagePath,
  }) : transactionDate = transactionDate ?? DateTime.now();

  /// Check if this transaction has all required fields
  bool get isValid =>
      categoryType.isNotEmpty &&
          categoryId != null &&
          amount > 0;
}