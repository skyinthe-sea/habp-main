import 'package:flutter/foundation.dart';
import '../../../../core/database/db_helper.dart';
import '../entities/category_expense.dart';
import '../entities/monthly_expense.dart';
import '../entities/transaction_with_category.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';

abstract class TransactionLocalDataSource {
  Future<List<TransactionModel>> getTransactions();
  Future<List<CategoryModel>> getCategories();
  Future<List<MonthlyExpense>> getMonthlyExpenses(int months);
  Future<List<CategoryExpense>> getCategoryExpenses();
  Future<List<TransactionWithCategory>> getRecentTransactions(int limit);
}

class TransactionLocalDataSourceImpl implements TransactionLocalDataSource {
  final DBHelper dbHelper;

  TransactionLocalDataSourceImpl({required this.dbHelper});

  @override
  Future<List<TransactionModel>> getTransactions() async {
    try {
      final db = await dbHelper.database;
      final transactions = await db.query('transaction_record');
      return transactions.map((json) => TransactionModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('데이터 소스에서 거래 내역 가져오기 오류: $e');
      return [];
    }
  }

  @override
  Future<List<CategoryModel>> getCategories() async {
    try {
      final db = await dbHelper.database;
      final categories = await db.query('category');
      return categories.map((json) => CategoryModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('데이터 소스에서 카테고리 가져오기 오류: $e');
      return [];
    }
  }

  @override
  Future<List<MonthlyExpense>> getMonthlyExpenses(int months) async {
    try {
      final db = await dbHelper.database;
      final now = DateTime.now();

      List<MonthlyExpense> result = [];

      // 최근 n개월의 데이터를 가져옴 (가장 오래된 달부터)
      for (int i = months - 1; i >= 0; i--) {
        final targetMonth = DateTime(now.year, now.month - i, 1);
        final endOfMonth = DateTime(targetMonth.year, targetMonth.month + 1, 0);

        // SQLite에서 날짜 처리를 위해 형식 변환
        final startDateStr = "${targetMonth.year}-${targetMonth.month.toString().padLeft(2, '0')}-01";
        final endDateStr = "${endOfMonth.year}-${endOfMonth.month.toString().padLeft(2, '0')}-${endOfMonth.day.toString().padLeft(2, '0')}";

        debugPrint('조회 기간: $startDateStr ~ $endDateStr');

        double totalExpense = 0.0;

        // 1. 변동 거래 내역 (해당 월에 직접 기록된 거래)
        final List<Map<String, dynamic>> variableTransactions = await db.rawQuery('''
        SELECT tr.* FROM transaction_record tr
        JOIN category c ON tr.category_id = c.id
        WHERE c.type = 'EXPENSE'
        AND c.is_fixed = 0
        AND date(substr(tr.transaction_date, 1, 10)) BETWEEN date(?) AND date(?)
      ''', [startDateStr, endDateStr]);

        // 변동 거래 금액 합산
        for (var transaction in variableTransactions) {
          totalExpense += (transaction['amount'] as double).abs();
        }

        // 2. 고정 거래 내역 (매달 반복되는 거래)
        final List<Map<String, dynamic>> fixedTransactions = await db.rawQuery('''
        SELECT tr.*, c.type FROM transaction_record tr
        JOIN category c ON tr.category_id = c.id
        WHERE c.type = 'EXPENSE'
        AND c.is_fixed = 1
      ''');

        // 고정 거래 금액 합산 (description을 확인하여 매달/매주/매일 구분)
        for (var transaction in fixedTransactions) {
          final description = transaction['description'] as String;
          final transactionNum = transaction['transaction_num'].toString();
          double amount = transaction['amount'] as double;

          if (description.contains('매월')) {
            // 매월 거래는 그대로 더함
            totalExpense += amount.abs(); // 절대값 사용
          }
          else if (description.contains('매주')) {
            // 매주 거래는 해당 월의 요일 수에 맞게 계산
            int weekday = int.parse(transactionNum);
            int occurrences = _countWeekdaysInMonth(targetMonth.year, targetMonth.month, weekday);
            totalExpense += amount.abs() * occurrences; // 절대값 사용
          }
          else if (description.contains('매일')) {
            // 매일 거래는 해당 월의 일수만큼 더함
            int daysInMonth = endOfMonth.day;
            totalExpense += amount.abs() * daysInMonth; // 절대값 사용
          }
        }

        // 최종 월별 지출 추가
        result.add(MonthlyExpense(
          date: targetMonth,
          amount: totalExpense,
        ));
      }

      return result;
    } catch (e) {
      debugPrint('월별 지출 가져오기 오류: $e');
      return [];
    }
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

  @override
  Future<List<CategoryExpense>> getCategoryExpenses() async {
    try {
      final db = await dbHelper.database;
      final now = DateTime.now();
      final currentMonth = now.month;
      final currentYear = now.year;

      // 현재 월의 시작과 끝 날짜
      final startOfMonth = DateTime(currentYear, currentMonth, 1);
      final endOfMonth = DateTime(currentYear, currentMonth + 1, 0);

      final startDateStr = "${startOfMonth.year}-${startOfMonth.month.toString().padLeft(2, '0')}-01";
      final endDateStr = "${endOfMonth.year}-${endOfMonth.month.toString().padLeft(2, '0')}-${endOfMonth.day.toString().padLeft(2, '0')}";

      // 모든 지출 카테고리 가져오기
      final List<Map<String, dynamic>> allCategories = await db.rawQuery('''
      SELECT * FROM category
      WHERE type = 'EXPENSE'
    ''');

      // 카테고리별 지출 맵 초기화
      Map<int, Map<String, dynamic>> categoryExpenseMap = {};
      for (var category in allCategories) {
        categoryExpenseMap[category['id'] as int] = {
          'id': category['id'],
          'name': category['name'],
          'is_fixed': category['is_fixed'],
          'total_amount': 0.0
        };
      }

      // 1. 변동 거래 내역 (해당 월에 직접 기록된 거래)
      final List<Map<String, dynamic>> variableTransactions = await db.rawQuery('''
      SELECT tr.category_id, SUM(tr.amount) as total_amount
      FROM transaction_record tr
      JOIN category c ON tr.category_id = c.id
      WHERE c.type = 'EXPENSE'
      AND c.is_fixed = 0
      AND date(substr(tr.transaction_date, 1, 10)) BETWEEN date(?) AND date(?)
      GROUP BY tr.category_id
    ''', [startDateStr, endDateStr]);

      // 변동 거래 금액 합산
      for (var transaction in variableTransactions) {
        final categoryId = transaction['category_id'] as int;
        final amount = transaction['total_amount'].abs() as double;

        if (categoryExpenseMap.containsKey(categoryId)) {
          categoryExpenseMap[categoryId]!['total_amount'] =
              (categoryExpenseMap[categoryId]!['total_amount'] as double) + amount;
        }
      }

      // 2. 고정 거래 내역 (매달 반복되는 거래)
      final List<Map<String, dynamic>> fixedTransactions = await db.rawQuery('''
      SELECT tr.* FROM transaction_record tr
      JOIN category c ON tr.category_id = c.id
      WHERE c.type = 'EXPENSE'
      AND c.is_fixed = 1
    ''');

      // 고정 거래 금액 합산
      for (var transaction in fixedTransactions) {
        final categoryId = transaction['category_id'] as int;
        final description = transaction['description'] as String;
        final transactionNum = transaction['transaction_num'].toString();
        double amount = transaction['amount'] as double;

        if (!categoryExpenseMap.containsKey(categoryId)) continue;

        if (description.contains('매월')) {
          // 매월 거래는 그대로 더함
          categoryExpenseMap[categoryId]!['total_amount'] =
              (categoryExpenseMap[categoryId]!['total_amount'] as double) + amount;
        }
        else if (description.contains('매주')) {
          // 매주 거래는 해당 월의 요일 수에 맞게 계산
          int weekday = int.parse(transactionNum);
          int occurrences = _countWeekdaysInMonth(currentYear, currentMonth, weekday);
          categoryExpenseMap[categoryId]!['total_amount'] =
              (categoryExpenseMap[categoryId]!['total_amount'] as double) + (amount * occurrences);
        }
        else if (description.contains('매일')) {
          // 매일 거래는 해당 월의 일수만큼 더함
          int daysInMonth = endOfMonth.day;
          categoryExpenseMap[categoryId]!['total_amount'] =
              (categoryExpenseMap[categoryId]!['total_amount'] as double) + (amount * daysInMonth);
        }
      }

      // 전체 지출 합계 계산
      double totalExpense = 0;
      categoryExpenseMap.forEach((_, data) {
        totalExpense += data['total_amount'] as double;
      });

      // 카테고리별 지출 비율 계산 및 금액이 있는 것만 반환
      List<CategoryExpense> categoryExpenses = [];
      categoryExpenseMap.forEach((_, data) {
        final amount = data['total_amount'] as double;

        // 금액이 있는 카테고리만 추가
        if (amount > 0) {
          final percentage = totalExpense > 0 ? (amount / totalExpense) * 100 : 0;

          categoryExpenses.add(CategoryExpense(
            categoryId: data['id'] as int,
            categoryName: data['name'] as String,
            amount: amount,
            percentage: percentage.toDouble(),
          ));
        }
      });

      // 금액 기준 내림차순 정렬
      categoryExpenses.sort((a, b) => b.amount.compareTo(a.amount));

      return categoryExpenses;
    } catch (e) {
      debugPrint('카테고리별 지출 가져오기 오류: $e');
      return [];
    }
  }

  @override
  Future<List<TransactionWithCategory>> getRecentTransactions(int limit) async {
    try {
      final db = await dbHelper.database;

      // 오늘 날짜 구하기
      final now = DateTime.now();
      final todayDateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      // 오늘 날짜를 포함한 이전의 거래만 조회
      final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT tr.*, c.name as category_name, c.type as category_type 
      FROM transaction_record tr
      JOIN category c ON tr.category_id = c.id
      WHERE date(substr(tr.transaction_date, 1, 10)) <= date(?)
      ORDER BY tr.transaction_date DESC
      LIMIT ?
    ''', [todayDateStr, limit]);

      debugPrint('조회된 최근 거래 내역 수: ${results.length}');

      return results.map((row) => TransactionWithCategory(
        id: row['id'] as int,
        userId: row['user_id'] as int,
        categoryId: row['category_id'] as int,
        categoryName: row['category_name'] as String,
        categoryType: row['category_type'] as String,
        amount: row['amount'] as double,
        description: row['description'] as String,
        transactionDate: DateTime.parse(row['transaction_date']),
        transactionNum: row['transaction_num'].toString(),
        createdAt: DateTime.parse(row['created_at']),
        updatedAt: DateTime.parse(row['updated_at']),
      )).toList();
    } catch (e) {
      debugPrint('최근 거래 내역 가져오기 오류: $e');
      return [];
    }
  }
}