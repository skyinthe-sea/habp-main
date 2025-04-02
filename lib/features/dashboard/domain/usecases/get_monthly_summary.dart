import 'package:flutter/foundation.dart';
import '../repositories/transaction_repository.dart';

class GetMonthlySummary {
  final TransactionRepository repository;

  GetMonthlySummary(this.repository);

  Future<Map<String, dynamic>> execute() async {
    try {
      // 현재 날짜 정보
      final now = DateTime.now();
      final currentYear = now.year;
      final currentMonth = now.month;

      // 지난달 정보
      final lastMonth = currentMonth == 1
          ? DateTime(currentYear - 1, 12)
          : DateTime(currentYear, currentMonth - 1);
      final lastMonthYear = lastMonth.year;
      final lastMonthMonth = lastMonth.month;

      debugPrint('현재 날짜: $now');
      debugPrint('이번 달: $currentYear년 $currentMonth월');
      debugPrint('지난 달: $lastMonthYear년 $lastMonthMonth월');

      // 이번 달 데이터 계산
      final currentMonthStart = DateTime(currentYear, currentMonth, 1);
      final currentMonthEnd =
      DateTime(currentYear, currentMonth + 1, 0, 23, 59, 59);

      // 지난 달 데이터 계산
      final lastMonthStart = DateTime(lastMonthYear, lastMonthMonth, 1);
      final lastMonthEnd =
      DateTime(lastMonthYear, lastMonthMonth + 1, 0, 23, 59, 59);

      // 1. 이번 달 변동 거래 내역 가져오기 (is_fixed=0인 거래만)
      final currentMonthTransactions = await repository
          .getTransactionsByDateRange(currentMonthStart, currentMonthEnd);

      // 2. 지난 달 변동 거래 내역 가져오기 (is_fixed=0인 거래만)
      final lastMonthTransactions = await repository.getTransactionsByDateRange(
          lastMonthStart, lastMonthEnd);

      debugPrint('이번 달 거래 수: ${currentMonthTransactions.length}');
      debugPrint('지난 달 거래 수: ${lastMonthTransactions.length}');

      // 카테고리 정보 가져오기
      final categories = await repository.getCategories();
      final categoryMap = {for (var c in categories) c.id: c};

      // 이번 달 수입/지출 계산 (변동 거래만)
      double currentMonthIncome = 0;
      double currentMonthExpense = 0;

      for (var transaction in currentMonthTransactions) {
        final category = categoryMap[transaction.categoryId];
        if (category == null) continue;

        // 고정 거래는 건너뛰기 (별도로 계산할 예정)
        if (category.isFixed == 1) continue;

        if (category.type == 'INCOME') {
          currentMonthIncome += transaction.amount.abs(); // 수입은 양수로 변환
        } else if (category.type == 'EXPENSE') {
          currentMonthExpense += transaction.amount.abs(); // 지출은 양수로 변환
        }
      }

      // 지난 달 수입/지출 계산 (변동 거래만)
      double lastMonthIncome = 0;
      double lastMonthExpense = 0;

      for (var transaction in lastMonthTransactions) {
        final category = categoryMap[transaction.categoryId];
        if (category == null) continue;

        // 고정 거래는 건너뛰기 (별도로 계산할 예정)
        if (category.isFixed == 1) continue;

        if (category.type == 'INCOME') {
          lastMonthIncome += transaction.amount.abs(); // 수입은 양수로 변환
        } else if (category.type == 'EXPENSE') {
          lastMonthExpense += transaction.amount.abs(); // 지출은 양수로 변환
        }
      }

      // 3. 이번 달 고정 거래의 수입/지출 계산 (기존 함수 활용)
      final currentMonthFixed = await _calculateFixedTransactions(currentYear, currentMonth);
      currentMonthIncome += currentMonthFixed['income'] ?? 0;
      currentMonthExpense += currentMonthFixed['expense'] ?? 0;

      // 4. 지난 달 고정 거래의 수입/지출 계산 (기존 함수 활용)
      final lastMonthFixed = await _calculateFixedTransactions(lastMonthYear, lastMonthMonth);
      lastMonthIncome += lastMonthFixed['income'] ?? 0;
      lastMonthExpense += lastMonthFixed['expense'] ?? 0;

      debugPrint('이번 달 수입: $currentMonthIncome, 지출: $currentMonthExpense');
      debugPrint('지난 달 수입: $lastMonthIncome, 지출: $lastMonthExpense');

      // 이번 달 잔액 계산
      final currentMonthBalance = currentMonthIncome - currentMonthExpense;

      // 증감율 계산 및 소수점 한 자리로 반올림
      double incomeChangePercentage = 0.0;
      double expenseChangePercentage = 0.0;

      // 예시: 지난달 10만원 → 이번달 11만원 = +10% (증가)
      if (lastMonthIncome > 0) {
        // 정확한 증감율 계산: (이번달 - 지난달) / 지난달 * 100
        incomeChangePercentage =
            ((currentMonthIncome - lastMonthIncome) / lastMonthIncome) * 100;
        // 소수점 한 자리까지 반올림
        incomeChangePercentage =
            double.parse(incomeChangePercentage.toStringAsFixed(1));
        debugPrint(
            '수입 증감율 계산: ($currentMonthIncome - $lastMonthIncome) / $lastMonthIncome * 100 = $incomeChangePercentage%');
      } else if (currentMonthIncome > 0) {
        // 지난 달 수입이 0이고 이번 달 수입이 있는 경우 (100% 신규 증가)
        incomeChangePercentage = 100.0;
        debugPrint('지난달 수입 없음(0), 이번달 처음 발생: 100% 설정');
      }

      // 지출 증감율 계산 (동일한 로직)
      if (lastMonthExpense > 0) {
        expenseChangePercentage =
            ((currentMonthExpense - lastMonthExpense) / lastMonthExpense) * 100;
        // 소수점 한 자리까지 반올림
        expenseChangePercentage =
            double.parse(expenseChangePercentage.toStringAsFixed(1));
        debugPrint(
            '지출 증감율 계산: ($currentMonthExpense - $lastMonthExpense) / $lastMonthExpense * 100 = $expenseChangePercentage%');
      } else if (currentMonthExpense > 0) {
        // 지난 달 지출이 0이고 이번 달 지출이 있는 경우 (100% 신규 증가)
        expenseChangePercentage = 100.0;
        debugPrint('지난달 지출 없음(0), 이번달 처음 발생: 100% 설정');
      }

      debugPrint('수입 증감율: $incomeChangePercentage%');
      debugPrint('지출 증감율: $expenseChangePercentage%');

      return {
        'income': currentMonthIncome,
        'expense': currentMonthExpense,
        'balance': currentMonthBalance,
        'incomeChangePercentage': incomeChangePercentage,
        'expenseChangePercentage': expenseChangePercentage,
      };
    } catch (e) {
      debugPrint('월간 요약 계산 중 오류 발생: $e');
      // 오류 발생시 기본값 반환
      return {
        'income': 0.0,
        'expense': 0.0,
        'balance': 0.0,
        'incomeChangePercentage': 0.0,
        'expenseChangePercentage': 0.0,
      };
    }
  }

  // 고정 거래 (매월, 매주, 매일) 계산
  Future<Map<String, double>> _calculateFixedTransactions(
      int year, int month) async {
    final transactions = await repository.getTransactions();
    final categories = await repository.getCategories();
    final categoryMap = {for (var c in categories) c.id: c};

    double monthlyIncome = 0;
    double monthlyExpense = 0;

    for (var transaction in transactions) {
      final category = categoryMap[transaction.categoryId];
      if (category == null) continue;

      // 고정 거래만 처리
      if (_isFixedTransaction(transaction.description)) {
        double amount = 0;

        // 매월 거래
        if (transaction.description.contains('매월')) {
          amount = transaction.amount;
        }
        // 매주 거래
        else if (transaction.description.contains('매주')) {
          // 해당 월에 요일이 몇 번 등장하는지 계산
          int weekdayCount = _countWeekdaysInMonth(
              year, month, int.parse(transaction.transactionNum));
          amount = transaction.amount * weekdayCount;
        }
        // 매일 거래
        else if (transaction.description.contains('매일')) {
          // 해당 월의 일수
          int daysInMonth = DateTime(year, month + 1, 0).day;
          amount = transaction.amount * daysInMonth;
        }

        // 수입/지출 분류
        if (category.type == 'INCOME') {
          monthlyIncome += amount;
        } else if (category.type == 'EXPENSE') {
          monthlyExpense += amount.abs();
        }
      }
    }

    return {'income': monthlyIncome, 'expense': monthlyExpense};
  }

  // 고정 거래 여부 확인 헬퍼 함수
  bool _isFixedTransaction(String description) {
    return description.contains('매월') ||
        description.contains('매주') ||
        description.contains('매일');
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
