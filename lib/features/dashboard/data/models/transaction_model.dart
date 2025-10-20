import '../entities/transaction.dart';

class TransactionModel extends Transaction {
  TransactionModel({
    required int id,
    required int userId,
    required int categoryId,
    required double amount,
    required String description,
    required DateTime transactionDate,
    required String transactionNum,
    String? emotionTag,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super(
    id: id,
    userId: userId,
    categoryId: categoryId,
    amount: amount,
    description: description,
    transactionDate: transactionDate,
    transactionNum: transactionNum,
    emotionTag: emotionTag,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'],
      userId: json['user_id'],
      categoryId: json['category_id'],
      amount: json['amount'],
      description: json['description'],
      transactionDate: DateTime.parse(json['transaction_date']),
      transactionNum: json['transaction_num'].toString(),
      emotionTag: json['emotion_tag'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}