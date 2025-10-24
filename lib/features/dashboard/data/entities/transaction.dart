class Transaction {
  final int id;
  final int userId;
  final int categoryId;
  final double amount;
  final String description;
  final DateTime transactionDate;
  final String transactionNum;
  final String? emotionTag;
  final String? imagePath;  // 영수증/사진 경로
  final DateTime createdAt;
  final DateTime updatedAt;

  Transaction({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.amount,
    required this.description,
    required this.transactionDate,
    required this.transactionNum,
    this.emotionTag,
    this.imagePath,
    required this.createdAt,
    required this.updatedAt,
  });
}