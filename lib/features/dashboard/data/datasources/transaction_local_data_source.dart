// lib/features/dashboard/data/datasources/transaction_local_data_source.dart
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
  Future<List<CategoryExpense>> getCategoryIncome(); // New method for income
  Future<List<CategoryExpense>> getCategoryFinance(); // New method for finance
  Future<List<TransactionWithCategory>> getRecentTransactions(int limit);
  Future<List<TransactionModel>> getTransactionsByDateRange(DateTime start, DateTime end);
  Future<double> getAssets();
}

class TransactionLocalDataSourceImpl implements TransactionLocalDataSource {
  final DBHelper dbHelper;

  TransactionLocalDataSourceImpl({required this.dbHelper});

  @override
  Future<List<TransactionModel>> getTransactions() async {
    try {
      final db = await dbHelper.database;
      final transactions = await db.query('transaction_record2');
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
          SELECT tr.*, c.type FROM transaction_record2 tr
          JOIN category c ON tr.category_id = c.id
          WHERE c.type = 'EXPENSE'
          AND c.is_fixed = 1
        ''');

        // 고정 거래 금액 합산 (description을 확인하여 매달/매주/매일 구분)
        for (var transaction in fixedTransactions) {
          final description = transaction['description'] as String;
          final transactionNum = transaction['transaction_num'].toString();
          final categoryId = transaction['category_id'] as int;

          // 해당 월에 적용되는 설정 찾기
          final List<Map<String, dynamic>> settings = await db.rawQuery('''
            SELECT * FROM fixed_transaction_setting
            WHERE category_id = ? AND date(effective_from) <= date(?)
            ORDER BY effective_from DESC
            LIMIT 1
          ''', [categoryId, endOfMonth.toIso8601String()]);

          // 설정이 있으면 그 금액 사용, 없으면 기존 금액 사용
          double amount = (transaction['amount'] as double).abs();
          if (settings.isNotEmpty) {
            amount = (settings.first['amount'] as double).abs();
          }

          if (description.contains('매월')) {
            // 매월 거래는 그대로 더함
            totalExpense += amount;
          }
          else if (description.contains('매주')) {
            // 매주 거래는 해당 월의 요일 수에 맞게 계산
            int weekday = int.parse(transactionNum);
            int occurrences = _countWeekdaysInMonth(targetMonth.year, targetMonth.month, weekday);
            totalExpense += amount * occurrences;
          }
          else if (description.contains('매일')) {
            // 매일 거래는 해당 월의 일수만큼 더함
            int daysInMonth = endOfMonth.day;
            totalExpense += amount * daysInMonth;
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

  @override
  Future<List<CategoryExpense>> getCategoryExpenses() async {
    try {
      return await _getCategoryData('EXPENSE');
    } catch (e) {
      debugPrint('카테고리별 지출 가져오기 오류: $e');
      return [];
    }
  }

  @override
  Future<List<CategoryExpense>> getCategoryIncome() async {
    try {
      return await _getCategoryData('INCOME');
    } catch (e) {
      debugPrint('카테고리별 수입 가져오기 오류: $e');
      return [];
    }
  }

  @override
  Future<List<CategoryExpense>> getCategoryFinance() async {
    try {
      return await _getCategoryData('FINANCE');
    } catch (e) {
      debugPrint('카테고리별 재테크 가져오기 오류: $e');
      return [];
    }
  }

  // Common method to fetch category data by type (refactored from getCategoryExpenses)
  Future<List<CategoryExpense>> _getCategoryData(String categoryType) async {
    final db = await dbHelper.database;
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

    // 현재 월의 시작과 끝 날짜
    final startOfMonth = DateTime(currentYear, currentMonth, 1);
    final endOfMonth = DateTime(currentYear, currentMonth + 1, 0);

    final startDateStr = "${startOfMonth.year}-${startOfMonth.month.toString().padLeft(2, '0')}-01";
    final endDateStr = "${endOfMonth.year}-${endOfMonth.month.toString().padLeft(2, '0')}-${endOfMonth.day.toString().padLeft(2, '0')}";

    // 해당 타입의 카테고리 가져오기
    final List<Map<String, dynamic>> allCategories = await db.rawQuery('''
      SELECT * FROM category
      WHERE type = ?
    ''', [categoryType]);

    // 카테고리별 금액 맵 초기화
    Map<int, Map<String, dynamic>> categoryDataMap = {};
    for (var category in allCategories) {
      categoryDataMap[category['id'] as int] = {
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
      WHERE c.type = ?
      AND c.is_fixed = 0
      AND date(substr(tr.transaction_date, 1, 10)) BETWEEN date(?) AND date(?)
      GROUP BY tr.category_id
    ''', [categoryType, startDateStr, endDateStr]);

    // 변동 거래 금액 합산
    for (var transaction in variableTransactions) {
      final categoryId = transaction['category_id'] as int;
      final amount = transaction['total_amount'].abs() as double;

      if (categoryDataMap.containsKey(categoryId)) {
        categoryDataMap[categoryId]!['total_amount'] =
            (categoryDataMap[categoryId]!['total_amount'] as double) + amount;
      }
    }

    // 2. 고정 거래 내역 (매달 반복되는 거래)
    final List<Map<String, dynamic>> fixedTransactions = await db.rawQuery('''
      SELECT tr.* FROM transaction_record2 tr
      JOIN category c ON tr.category_id = c.id
      WHERE c.type = ?
      AND c.is_fixed = 1
    ''', [categoryType]);

    // 고정 거래 금액 합산
    for (var transaction in fixedTransactions) {
      final categoryId = transaction['category_id'] as int;
      final description = transaction['description'] as String;
      final transactionNum = transaction['transaction_num'].toString();

      if (!categoryDataMap.containsKey(categoryId)) continue;

      // 해당 카테고리의 가장 최근 설정 찾기
      final List<Map<String, dynamic>> settings = await db.rawQuery('''
        SELECT * FROM fixed_transaction_setting
        WHERE category_id = ? AND date(effective_from) <= date(?)
        ORDER BY effective_from DESC
        LIMIT 1
      ''', [categoryId, endOfMonth.toIso8601String()]);

      // 설정이 있으면 그 금액 사용, 없으면 기존 금액 사용
      double amount = (transaction['amount'] as double).abs();
      if (settings.isNotEmpty) {
        amount = (settings.first['amount'] as double).abs();
      }

      if (description.contains('매월')) {
        // 매월 거래는 그대로 더함
        categoryDataMap[categoryId]!['total_amount'] =
            (categoryDataMap[categoryId]!['total_amount'] as double) + amount;
      }
      else if (description.contains('매주')) {
        // 매주 거래는 해당 월의 요일 수에 맞게 계산
        int weekday = int.parse(transactionNum);
        int occurrences = _countWeekdaysInMonth(currentYear, currentMonth, weekday);
        categoryDataMap[categoryId]!['total_amount'] =
            (categoryDataMap[categoryId]!['total_amount'] as double) + (amount * occurrences);
      }
      else if (description.contains('매일')) {
        // 매일 거래는 해당 월의 일수만큼 더함
        int daysInMonth = endOfMonth.day;
        categoryDataMap[categoryId]!['total_amount'] =
            (categoryDataMap[categoryId]!['total_amount'] as double) + (amount * daysInMonth);
      }
    }

    // 전체 금액 합계 계산
    double totalAmount = 0;
    categoryDataMap.forEach((_, data) {
      totalAmount += data['total_amount'].abs() as double;
    });

    // 카테고리별 비율 계산 및 금액이 있는 것만 반환
    List<CategoryExpense> categoryData = [];
    categoryDataMap.forEach((_, data) {
      final amount = data['total_amount'].abs() as double;

      // 금액이 있는 카테고리만 추가
      if (amount > 0) {
        final percentage = totalAmount > 0 ? (amount / totalAmount) * 100 : 0;

        categoryData.add(CategoryExpense(
          categoryId: data['id'] as int,
          categoryName: data['name'] as String,
          amount: amount,
          percentage: percentage.toDouble(),
        ));
      }
    });

    // 금액 기준 내림차순 정렬
    categoryData.sort((a, b) => b.amount.compareTo(a.amount));

    return categoryData;
  }

  @override
  Future<List<TransactionWithCategory>> getRecentTransactions(int limit) async {
    try {
      final db = await dbHelper.database;

      // 오늘 날짜 구하기
      final now = DateTime.now();
      final todayDateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      // 변동 거래 내역
      final List<Map<String, dynamic>> variableResults = await db.rawQuery('''
        SELECT tr.*, c.name as category_name, c.type as category_type 
        FROM transaction_record tr
        JOIN category c ON tr.category_id = c.id
        WHERE date(substr(tr.transaction_date, 1, 10)) <= date(?)
        ORDER BY transaction_date DESC
        LIMIT ?
      ''', [todayDateStr, limit]);

      // 고정 거래 내역
      final List<Map<String, dynamic>> fixedResults = await db.rawQuery('''
        SELECT tr2.*, c.name as category_name, c.type as category_type 
        FROM transaction_record2 tr2
        JOIN category c ON tr2.category_id = c.id
        WHERE date(substr(tr2.transaction_date, 1, 10)) <= date(?)
        ORDER BY transaction_date DESC
        LIMIT ?
      ''', [todayDateStr, limit]);

      // 변동 거래 처리
      List<TransactionWithCategory> variableTransactions = variableResults.map((row) =>
          TransactionWithCategory(
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
          )
      ).toList();

      // 고정 거래 처리 (fixed_transaction_setting 테이블 활용)
      List<TransactionWithCategory> fixedTransactions = [];

      for (var row in fixedResults) {
        final transactionDate = DateTime.parse(row['transaction_date']);
        final categoryId = row['category_id'] as int;

        // 해당 거래 날짜에 유효한 설정 찾기
        final List<Map<String, dynamic>> settings = await db.rawQuery('''
          SELECT * FROM fixed_transaction_setting
          WHERE category_id = ? AND date(effective_from) <= date(?)
          ORDER BY effective_from DESC
          LIMIT 1
        ''', [categoryId, row['transaction_date']]);

        // 설정이 있으면 금액 업데이트, 없으면 원래 금액 사용
        double amount = row['amount'] as double;
        if (settings.isNotEmpty) {
          amount = settings.first['amount'] as double;
        }

        fixedTransactions.add(TransactionWithCategory(
          id: row['id'] as int,
          userId: row['user_id'] as int,
          categoryId: categoryId,
          categoryName: row['category_name'] as String,
          categoryType: row['category_type'] as String,
          amount: amount,
          description: row['description'] as String,
          transactionDate: transactionDate,
          transactionNum: row['transaction_num'].toString(),
          createdAt: DateTime.parse(row['created_at']),
          updatedAt: DateTime.parse(row['updated_at']),
        ));
      }

      // 두 리스트 병합 및 날짜순 정렬
      List<TransactionWithCategory> allTransactions = [...variableTransactions, ...fixedTransactions];
      allTransactions.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

      // 개수 제한
      if (allTransactions.length > limit) {
        allTransactions = allTransactions.sublist(0, limit);
      }

      debugPrint('조회된 최근 거래 내역 수: ${allTransactions.length}');
      return allTransactions;
    } catch (e) {
      debugPrint('최근 거래 내역 가져오기 오류: $e');
      return [];
    }
  }

  @override
  Future<List<TransactionModel>> getTransactionsByDateRange(DateTime start, DateTime end) async {
    try {
      final db = await dbHelper.database;
      List<TransactionModel> result = [];

      // 날짜 형식 변환 (YYYY-MM-DD)
      final startDateStr = "${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}";
      final endDateStr = "${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}";

      // 1. 변동 거래 내역 가져오기
      final List<Map<String, dynamic>> variableTransactions = await db.rawQuery('''
        SELECT * FROM transaction_record
        WHERE date(substr(transaction_date, 1, 10)) BETWEEN date(?) AND date(?)
      ''', [startDateStr, endDateStr]);

      for (var transaction in variableTransactions) {
        result.add(TransactionModel.fromJson(transaction));
      }

      // 2. 고정 거래 내역 가져오기
      final List<Map<String, dynamic>> fixedTransactions = await db.rawQuery('''
        SELECT * FROM transaction_record2
        WHERE date(substr(transaction_date, 1, 10)) BETWEEN date(?) AND date(?)
      ''', [startDateStr, endDateStr]);

      // 3. 각 고정 거래에 대해 해당 날짜에 유효한 설정 찾기
      for (var transaction in fixedTransactions) {
        final categoryId = transaction['category_id'] as int;
        final transactionDate = DateTime.parse(transaction['transaction_date']);

        // 해당 거래 날짜에 유효한 설정 찾기
        final List<Map<String, dynamic>> settings = await db.rawQuery('''
          SELECT * FROM fixed_transaction_setting
          WHERE category_id = ? AND date(effective_from) <= date(?)
          ORDER BY effective_from DESC
          LIMIT 1
        ''', [categoryId, transaction['transaction_date']]);

        Map<String, dynamic> transactionCopy = Map<String, dynamic>.from(transaction);

        // 설정이 있으면 금액 업데이트
        if (settings.isNotEmpty) {
          transactionCopy['amount'] = settings.first['amount'];
        }

        result.add(TransactionModel.fromJson(transactionCopy));
      }

      // 4. 날짜 기준 정렬
      result.sort((a, b) =>
          b.transactionDate.compareTo(a.transactionDate)); // 내림차순 정렬

      return result;
    } catch (e) {
      debugPrint('날짜 범위 기준 거래 내역 가져오기 오류: $e');
      return [];
    }
  }

  @override
  Future<double> getAssets() async {
    try {
      final db = await dbHelper.database;
      final now = DateTime.now();
      final currentMonth = now.month;
      final currentYear = now.year;

      // Current month date range
      final startOfMonth = DateTime(currentYear, currentMonth, 1);
      final endOfMonth = DateTime(currentYear, currentMonth + 1, 0, 23, 59, 59);

      // Format dates for query
      final startDateStr = "${startOfMonth.year}-${startOfMonth.month.toString().padLeft(2, '0')}-01";
      final endDateStr = "${endOfMonth.year}-${endOfMonth.month.toString().padLeft(2, '0')}-${endOfMonth.day.toString().padLeft(2, '0')}";

      debugPrint('재테크 조회 기간: $startDateStr ~ $endDateStr');

      // 1. 변동 거래 내역 (해당 월에 직접 기록된 거래)
      final List<Map<String, dynamic>> variableResults = await db.rawQuery('''
      SELECT SUM(ABS(tr.amount)) as total_assets
      FROM transaction_record tr
      JOIN category c ON tr.category_id = c.id
      WHERE c.type = 'FINANCE'
      AND c.is_fixed = 0
      AND date(substr(tr.transaction_date, 1, 10)) BETWEEN date(?) AND date(?)
    ''', [startDateStr, endDateStr]);

      double totalVariableAssets = 0.0;

      if (variableResults.isNotEmpty && variableResults[0]['total_assets'] != null) {
        totalVariableAssets = variableResults[0]['total_assets'] as double;
      }

      // 2. 고정 거래 내역 (매달 반복되는 거래)
      final List<Map<String, dynamic>> fixedTransactions = await db.rawQuery('''
      SELECT tr.*
      FROM transaction_record2 tr
      JOIN category c ON tr.category_id = c.id
      WHERE c.type = 'FINANCE'
      AND c.is_fixed = 1
    ''');

      // 고정 거래 금액 합산
      double totalFixedAssets = 0.0;

      for (var transaction in fixedTransactions) {
        final description = transaction['description'] as String;
        final transactionNum = transaction['transaction_num'].toString();
        final categoryId = transaction['category_id'] as int;

        // 해당 카테고리와 날짜에 맞는 설정 가져오기
        final List<Map<String, dynamic>> settings = await db.rawQuery('''
          SELECT * FROM fixed_transaction_setting
          WHERE category_id = ? AND date(effective_from) <= date(?)
          ORDER BY effective_from DESC
          LIMIT 1
        ''', [categoryId, endOfMonth.toIso8601String()]);

        // 설정이 있으면 그 금액 사용, 없으면 기존 금액 사용
        double amount = (transaction['amount'] as double).abs();
        if (settings.isNotEmpty) {
          amount = (settings.first['amount'] as double).abs();
        }

        if (description.contains('매월')) {
          // 매월 거래는 그대로 더함
          totalFixedAssets += amount;
        }
        else if (description.contains('매주')) {
          // 매주 거래는 해당 월의 요일 수에 맞게 계산
          int weekday = int.parse(transactionNum);
          int occurrences = _countWeekdaysInMonth(currentYear, currentMonth, weekday);
          totalFixedAssets += amount * occurrences;
        }
        else if (description.contains('매일')) {
          // 매일 거래는 해당 월의 일수만큼 더함
          int daysInMonth = endOfMonth.day;
          totalFixedAssets += amount * daysInMonth;
        }
      }

      // 변동과 고정 자산 합산
      final totalAssets = totalVariableAssets + totalFixedAssets;

      debugPrint('조회된 재테크 총액 (변동: $totalVariableAssets, 고정: $totalFixedAssets): $totalAssets');
      return totalAssets;
    } catch (e) {
      debugPrint('재테크 가져오기 오류: $e');
      return 0.0;
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
}