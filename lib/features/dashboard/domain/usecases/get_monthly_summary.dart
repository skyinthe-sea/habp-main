import 'package:flutter/foundation.dart';
import '../repositories/transaction_repository.dart';

class GetMonthlySummary {
  final TransactionRepository repository;

  GetMonthlySummary(this.repository);

  Future<Map<String, dynamic>> execute(int year, int month) async {
    return await repository.getMonthlySummary(year, month);
  }
}
