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
  Future<List<CategoryExpense>> getCategoryExpenses(int year, int month);
  Future<List<CategoryExpense>> getCategoryIncome(int year, int month);
  Future<List<CategoryExpense>> getCategoryFinance(int year, int month);
  Future<List<TransactionWithCategory>> getRecentTransactions(int limit);
  Future<List<TransactionModel>> getTransactionsByDateRange(DateTime start, DateTime end);
  Future<double> getAssets(int year, int month);
  Future<Map<String, dynamic>> getMonthlySummary(int year, int month);
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
  Future<List<CategoryExpense>> getCategoryExpenses(int year, int month) async {
    try {
      return await _getCategoryData('EXPENSE', year, month);
    } catch (e) {
      debugPrint('카테고리별 지출 가져오기 오류: $e');
      return [];
    }
  }

  @override
  Future<List<CategoryExpense>> getCategoryIncome(int year, int month) async {
    try {
      return await _getCategoryData('INCOME', year, month);
    } catch (e) {
      debugPrint('카테고리별 수입 가져오기 오류: $e');
      return [];
    }
  }

  @override
  Future<List<CategoryExpense>> getCategoryFinance(int year, int month) async {
    try {
      return await _getCategoryData('FINANCE', year, month);
    } catch (e) {
      debugPrint('카테고리별 재테크 가져오기 오류: $e');
      return [];
    }
  }

// 공통 메서드 수정
  Future<List<CategoryExpense>> _getCategoryData(String categoryType, int year, int month) async {
    final db = await dbHelper.database;

    // 선택된 월의 시작과 끝 날짜
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 0);

    final startDateStr = "${startOfMonth.year}-${startOfMonth.month.toString().padLeft(2, '0')}-01";
    final endDateStr = "${endOfMonth.year}-${endOfMonth.month.toString().padLeft(2, '0')}-${endOfMonth.day.toString().padLeft(2, '0')}";

    debugPrint('카테고리 데이터 조회 기간: $startDateStr ~ $endDateStr');

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
        int occurrences = _countWeekdaysInMonth(year, month, weekday);
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
  Future<double> getAssets(int year, int month) async {
    try {
      final db = await dbHelper.database;

      // 선택된 월의 날짜 범위
      final startOfMonth = DateTime(year, month, 1);
      final endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59);

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
          int occurrences = _countWeekdaysInMonth(year, month, weekday);
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

  @override
  Future<Map<String, dynamic>> getMonthlySummary(int year, int month) async {
    try {
      // 선택된 월 정보
      final selectedYear = year;
      final selectedMonth = month;

      // 지난달 정보
      final lastMonth = selectedMonth == 1
          ? DateTime(selectedYear - 1, 12)
          : DateTime(selectedYear, selectedMonth - 1);
      final lastMonthYear = lastMonth.year;
      final lastMonthMonth = lastMonth.month;

      debugPrint('선택된 달: $selectedYear년 $selectedMonth월');
      debugPrint('지난 달: $lastMonthYear년 $lastMonthMonth월');

      // 선택된 달 데이터 계산
      final selectedMonthStart = DateTime(selectedYear, selectedMonth, 1);
      final selectedMonthEnd = DateTime(selectedYear, selectedMonth + 1, 0, 23, 59, 59);

      // 지난 달 데이터 계산
      final lastMonthStart = DateTime(lastMonthYear, lastMonthMonth, 1);
      final lastMonthEnd = DateTime(lastMonthYear, lastMonthMonth + 1, 0, 23, 59, 59);

      // 1. 선택된 달의 변동 거래 내역 가져오기
      final currentMonthTransactions = await getTransactionsByDateRange(
          selectedMonthStart, selectedMonthEnd);

      // 2. 지난 달 변동 거래 내역 가져오기
      final lastMonthTransactions = await getTransactionsByDateRange(
          lastMonthStart, lastMonthEnd);

      debugPrint('선택된 달 거래 수: ${currentMonthTransactions.length}');
      debugPrint('지난 달 거래 수: ${lastMonthTransactions.length}');

      // 카테고리 정보 가져오기
      final categories = await getCategories();
      final categoryMap = {for (var c in categories) c.id: c};

      // 선택된 달 수입/지출 계산 (변동 거래만)
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

      // 3. 선택된 달 고정 거래의 수입/지출 계산
      final currentMonthFixed = await _calculateFixedTransactions(selectedYear, selectedMonth);
      currentMonthIncome += currentMonthFixed['income'] ?? 0;
      currentMonthExpense += currentMonthFixed['expense'] ?? 0;

      // 4. 지난 달 고정 거래의 수입/지출 계산
      final lastMonthFixed = await _calculateFixedTransactions(lastMonthYear, lastMonthMonth);
      lastMonthIncome += lastMonthFixed['income'] ?? 0;
      lastMonthExpense += lastMonthFixed['expense'] ?? 0;

      debugPrint('선택된 달 수입: $currentMonthIncome, 지출: $currentMonthExpense');
      debugPrint('지난 달 수입: $lastMonthIncome, 지출: $lastMonthExpense');

      // 선택된 달 잔액 계산
      final currentMonthBalance = currentMonthIncome - currentMonthExpense;

      // 증감율 계산 및 소수점 한 자리로 반올림
      double incomeChangePercentage = 0.0;
      double expenseChangePercentage = 0.0;

      // 수입 증감율 계산
      if (lastMonthIncome > 0) {
        incomeChangePercentage =
            ((currentMonthIncome - lastMonthIncome) / lastMonthIncome) * 100;
        incomeChangePercentage =
            double.parse(incomeChangePercentage.toStringAsFixed(1));
      } else if (currentMonthIncome > 0) {
        incomeChangePercentage = 100.0;
      }

      // 지출 증감율 계산
      if (lastMonthExpense > 0) {
        expenseChangePercentage =
            ((currentMonthExpense - lastMonthExpense) / lastMonthExpense) * 100;
        expenseChangePercentage =
            double.parse(expenseChangePercentage.toStringAsFixed(1));
      } else if (currentMonthExpense > 0) {
        expenseChangePercentage = 100.0;
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

// 고정 거래 계산 (기존 _calculateFixedTransactions 메서드 활용)
  Future<Map<String, double>> _calculateFixedTransactions(int year, int month) async {
    final transactions = await getTransactions();
    final categories = await getCategories();
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
}