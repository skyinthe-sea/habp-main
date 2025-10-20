class CalendarTransaction {
  final int id;
  final int categoryId;
  final String categoryName;
  final String categoryType;
  final double amount;
  final String description;
  final DateTime transactionDate;
  final bool isFixed;
  final String? emotionTag;

  CalendarTransaction({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.categoryType,
    required this.amount,
    required this.description,
    required this.transactionDate,
    required this.isFixed,
    this.emotionTag,
  });
}