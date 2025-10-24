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
  final String? imagePath;  // 영수증/사진 경로

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
    this.imagePath,
  });
}