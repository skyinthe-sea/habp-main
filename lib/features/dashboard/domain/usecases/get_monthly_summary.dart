import '../repositories/transaction_repository.dart';

class GetMonthlySummary {
  final TransactionRepository repository;

  GetMonthlySummary(this.repository);

  Future<Map<String, double>> execute() async {
    final transactions = await repository.getTransactions();
    final categories = await repository.getCategories();

    // 현재 년월 구하기
    final now = DateTime.now();
    final currentYear = now.year;
    final currentMonth = now.month;

    double monthlyIncome = 0;
    double monthlyExpense = 0;

    // 카테고리 id -> 카테고리 맵 생성
    final categoryMap = {for (var c in categories) c.id: c};

    for (var transaction in transactions) {
      final category = categoryMap[transaction.categoryId];
      if (category == null) continue;

      double amount = 0;

      // 매월 거래
      if (transaction.description.contains('매월')) {
        if (category.type == 'INCOME') {
          monthlyIncome += transaction.amount;
        } else if (category.type == 'EXPENSE') {
          monthlyExpense += transaction.amount;
        }
      }
      // 매주 거래
      else if (transaction.description.contains('매주')) {
        // 이번달에 해당 요일이 몇 번 있는지 계산
        int weekdayCount = _countWeekdaysInMonth(
            currentYear,
            currentMonth,
            int.parse(transaction.transactionNum)
        );
        amount = transaction.amount * weekdayCount;

        if (category.type == 'INCOME') {
          monthlyIncome += amount;
        } else if (category.type == 'EXPENSE') {
          monthlyExpense += amount;
        }
      }
      // 매일 거래
      else if (transaction.description.contains('매일')) {
        // 이번달의 일수
        int daysInMonth = DateTime(currentYear, currentMonth + 1, 0).day;
        amount = transaction.amount * daysInMonth;

        if (category.type == 'INCOME') {
          monthlyIncome += amount;
        } else if (category.type == 'EXPENSE') {
          monthlyExpense += amount;
        }
      }
    }

    double monthlyBalance = monthlyIncome - monthlyExpense;

    return {
      'income': monthlyIncome,
      'expense': monthlyExpense,
      'balance': monthlyBalance,
    };
  }

  // 한 달에 특정 요일이 몇 번 있는지 계산하는 함수
  int _countWeekdaysInMonth(int year, int month, int weekday) {
    int count = 0;
    int daysInMonth = DateTime(year, month + 1, 0).day;

    for (int day = 1; day <= daysInMonth; day++) {
      if (DateTime(year, month, day).weekday == weekday) {
        count++;
      }
    }

    return count;
  }
}