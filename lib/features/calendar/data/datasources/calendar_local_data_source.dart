import 'package:flutter/foundation.dart';
import '../../../../core/database/db_helper.dart';
import '../../domain/entities/calendar_transaction.dart';
import '../../domain/entities/day_summary.dart';

abstract class CalendarLocalDataSource {
  Future<List<CalendarTransaction>> getMonthTransactions(DateTime month);
  Future<Map<DateTime, List<CalendarTransaction>>> getMonthTransactionsGroupedByDay(DateTime month);
  Future<DaySummary> getDaySummary(DateTime date);
}

class CalendarLocalDataSourceImpl implements CalendarLocalDataSource {
  final DBHelper dbHelper;

  CalendarLocalDataSourceImpl({required this.dbHelper});

  @override
  Future<List<CalendarTransaction>> getMonthTransactions(DateTime month) async {
    try {
      final db = await dbHelper.database;

      final firstDayOfMonth = DateTime(month.year, month.month, 1);
      final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);

      // 변동 거래 내역 가져오기 (실제 해당 월에 있는 거래)
      final List<Map<String, dynamic>> variableTransactions = await db.rawQuery('''
        SELECT tr.*, c.name AS category_name, c.type AS category_type, c.is_fixed
        FROM transaction_record tr
        JOIN category c ON tr.category_id = c.id
        WHERE date(substr(tr.transaction_date, 1, 10)) BETWEEN date(?) AND date(?)
      ''', [
        firstDayOfMonth.toIso8601String().substring(0, 10),
        lastDayOfMonth.toIso8601String().substring(0, 10)
      ]);

      // 고정 거래 내역 가져오기 (모든 고정 거래)
      final List<Map<String, dynamic>> fixedTransactions = await db.rawQuery('''
        SELECT tr.*, c.name AS category_name, c.type AS category_type, c.is_fixed
        FROM transaction_record tr
        JOIN category c ON tr.category_id = c.id
        WHERE c.is_fixed = 1
      ''');

      List<CalendarTransaction> resultTransactions = [];

      // 변동 거래 추가
      for (var transaction in variableTransactions) {
        if (transaction['is_fixed'] == 0) { // 변동 거래만 추가
          resultTransactions.add(CalendarTransaction(
            id: transaction['id'],
            categoryId: transaction['category_id'],
            categoryName: transaction['category_name'],
            categoryType: transaction['category_type'],
            amount: transaction['amount'],
            description: transaction['description'],
            transactionDate: DateTime.parse(transaction['transaction_date']),
            isFixed: false,
          ));
        }
      }

      // 고정 거래 추가 (해당 월의 날짜에 맞게 조정)
      for (var transaction in fixedTransactions) {
        final description = transaction['description'] as String;
        final transactionNum = transaction['transaction_num'].toString();

        if (description.contains('매월')) {
          // 매월 고정 거래는 해당 월의 특정 날짜에 추가
          final day = int.parse(transactionNum);
          final adjustedDate = DateTime(month.year, month.month, day);

          // 해당 월에 유효한 날짜인지 확인 (예: 30일까지 있는 달에 31일 거래 처리)
          final validDate = adjustedDate.month == month.month
              ? adjustedDate
              : DateTime(month.year, month.month + 1, 0);

          resultTransactions.add(CalendarTransaction(
            id: transaction['id'],
            categoryId: transaction['category_id'],
            categoryName: transaction['category_name'],
            categoryType: transaction['category_type'],
            amount: transaction['amount'],
            description: transaction['description'],
            transactionDate: validDate,
            isFixed: true,
          ));
        }
        else if (description.contains('매주')) {
          // 매주 고정 거래는 해당 월의 모든 특정 요일에 추가
          final weekday = int.parse(transactionNum);

          final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
          for (int day = 1; day <= daysInMonth; day++) {
            final date = DateTime(month.year, month.month, day);
            if (date.weekday == weekday) {
              resultTransactions.add(CalendarTransaction(
                id: transaction['id'],
                categoryId: transaction['category_id'],
                categoryName: transaction['category_name'],
                categoryType: transaction['category_type'],
                amount: transaction['amount'],
                description: transaction['description'],
                transactionDate: date,
                isFixed: true,
              ));
            }
          }
        }
        else if (description.contains('매일')) {
          // 매일 고정 거래는 해당 월의 모든 날짜에 추가
          final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
          for (int day = 1; day <= daysInMonth; day++) {
            resultTransactions.add(CalendarTransaction(
              id: transaction['id'],
              categoryId: transaction['category_id'],
              categoryName: transaction['category_name'],
              categoryType: transaction['category_type'],
              amount: transaction['amount'],
              description: transaction['description'],
              transactionDate: DateTime(month.year, month.month, day),
              isFixed: true,
            ));
          }
        }
      }

      return resultTransactions;
    } catch (e) {
      debugPrint('월 거래 내역 가져오기 오류: $e');
      return [];
    }
  }

  @override
  Future<Map<DateTime, List<CalendarTransaction>>> getMonthTransactionsGroupedByDay(DateTime month) async {
    try {
      final transactions = await getMonthTransactions(month);

      // 날짜별로 그룹화
      Map<DateTime, List<CalendarTransaction>> groupedTransactions = {};

      for (var transaction in transactions) {
        // 날짜만 사용하기 위해 시간 정보는 제거
        final date = DateTime(
          transaction.transactionDate.year,
          transaction.transactionDate.month,
          transaction.transactionDate.day,
        );

        if (!groupedTransactions.containsKey(date)) {
          groupedTransactions[date] = [];
        }

        groupedTransactions[date]!.add(transaction);
      }

      return groupedTransactions;
    } catch (e) {
      debugPrint('날짜별 거래 내역 그룹화 오류: $e');
      return {};
    }
  }

  @override
  Future<DaySummary> getDaySummary(DateTime date) async {
    try {
      // 해당 날짜의 모든 거래 가져오기
      final db = await dbHelper.database;

      // 날짜만 비교하기 위해 시간 정보 제거
      final targetDate = DateTime(date.year, date.month, date.day);

      // 변동 거래 내역
      final List<Map<String, dynamic>> variableTransactions = await db.rawQuery('''
        SELECT tr.*, c.name AS category_name, c.type AS category_type, c.is_fixed
        FROM transaction_record tr
        JOIN category c ON tr.category_id = c.id
        WHERE date(substr(tr.transaction_date, 1, 10)) = date(?)
      ''', [targetDate.toIso8601String().substring(0, 10)]);

      // 고정 거래 내역
      final List<Map<String, dynamic>> fixedTransactions = await db.rawQuery('''
        SELECT tr.*, c.name AS category_name, c.type AS category_type, c.is_fixed
        FROM transaction_record tr
        JOIN category c ON tr.category_id = c.id
        WHERE c.is_fixed = 1
      ''');

      List<CalendarTransaction> dayTransactions = [];
      double income = 0.0;
      double expense = 0.0;

      // 변동 거래 처리
      for (var transaction in variableTransactions) {
        if (transaction['is_fixed'] == 0) {
          final amount = transaction['amount'] as double;
          final type = transaction['category_type'] as String;

          if (type == 'INCOME') {
            income += amount;
          } else if (type == 'EXPENSE') {
            expense += amount.abs();
          } else if (type == 'FINANCE') {
            // Handle FINANCE type properly for calculations
            if (amount >= 0) {
              income += amount; // Positive finance amounts add to income for total calculations
            } else {
              expense += amount.abs(); // Negative finance amounts add to expenses for total calculations
            }
          }

          dayTransactions.add(CalendarTransaction(
            id: transaction['id'],
            categoryId: transaction['category_id'],
            categoryName: transaction['category_name'],
            categoryType: transaction['category_type'],
            amount: amount,
            description: transaction['description'],
            transactionDate: DateTime.parse(transaction['transaction_date']),
            isFixed: false,
          ));
        }
      }

      // 고정 거래 처리
      for (var transaction in fixedTransactions) {
        final description = transaction['description'] as String;
        final transactionNum = transaction['transaction_num'].toString();
        final amount = transaction['amount'] as double;
        final type = transaction['category_type'] as String;

        bool shouldInclude = false;

        if (description.contains('매월')) {
          // 매월 고정 거래
          final day = int.parse(transactionNum);
          shouldInclude = targetDate.day == day;
        }
        else if (description.contains('매주')) {
          // 매주 고정 거래
          final weekday = int.parse(transactionNum);
          shouldInclude = targetDate.weekday == weekday;
        }
        else if (description.contains('매일')) {
          // 매일 고정 거래
          shouldInclude = true;
        }

        // 고정 거래 처리 부분을 업데이트
        if (shouldInclude) {
          if (type == 'INCOME') {
            income += amount;
          } else if (type == 'EXPENSE') {
            expense += amount.abs();
          }

          // 거래 시간 추출 (고정 거래의 경우 임의로 시간 설정)
          final String timeStr = description.contains('매월') ?
          "${transactionNum.toString().padLeft(2, '0')}:00:00" : // 매월 거래는 날짜:00시로 설정
          (description.contains('매주') ? "12:00:00" : "00:00:00"); // 매주는 12시, 매일은 00시로 설정

          final DateTime transactionDateTime = DateTime.parse(
              "${targetDate.toIso8601String().split('T')[0]}T$timeStr"
          );

          dayTransactions.add(CalendarTransaction(
            id: transaction['id'],
            categoryId: transaction['category_id'],
            categoryName: transaction['category_name'],
            categoryType: transaction['category_type'],
            amount: amount,
            description: transaction['description'],
            transactionDate: transactionDateTime,
            isFixed: true,
          ));
        }
      }

      return DaySummary(
        date: targetDate,
        income: income,
        expense: expense,
        transactions: dayTransactions,
      );
    } catch (e) {
      debugPrint('일별 요약 가져오기 오류: $e');
      return DaySummary(date: date);
    }
  }
}