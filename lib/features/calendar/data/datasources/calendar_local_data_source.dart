import 'package:flutter/foundation.dart';
import '../../../../core/database/db_helper.dart';
import '../../domain/entities/calendar_transaction.dart';
import '../../domain/entities/day_summary.dart';

abstract class CalendarLocalDataSource {
  Future<List<CalendarTransaction>> getMonthTransactions(DateTime month);
  Future<Map<DateTime, List<CalendarTransaction>>> getMonthTransactionsGroupedByDay(DateTime month);
  Future<DaySummary> getDaySummary(DateTime date);
  Future<void> updateTransaction(CalendarTransaction transaction);
  Future<void> deleteTransaction(CalendarTransaction transaction);
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
        SELECT tr.id, tr.category_id, tr.amount, tr.description, tr.transaction_date,
               tr.transaction_num, tr.emotion_tag, tr.image_path,
               c.name AS category_name, c.type AS category_type, c.is_fixed
        FROM transaction_record tr
        JOIN category c ON tr.category_id = c.id
        WHERE date(substr(tr.transaction_date, 1, 10)) BETWEEN date(?) AND date(?)
      ''', [
        firstDayOfMonth.toIso8601String().substring(0, 10),
        lastDayOfMonth.toIso8601String().substring(0, 10)
      ]);

      // 고정 거래 내역 가져오기 (모든 고정 거래)
      final List<Map<String, dynamic>> fixedTransactions = await db.rawQuery('''
        SELECT tr.id, tr.category_id, tr.amount, tr.description, tr.transaction_date,
               tr.transaction_num, tr.emotion_tag,
               c.name AS category_name, c.type AS category_type, c.is_fixed
        FROM transaction_record2 tr
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
            emotionTag: transaction['emotion_tag'],
            imagePath: transaction['image_path'],
          ));
        }
      }

      // 고정 거래 추가 (해당 월의 날짜에 맞게 조정)
      for (var transaction in fixedTransactions) {
        final description = transaction['description'] as String;
        final transactionNum = transaction['transaction_num'].toString();
        final categoryId = transaction['category_id'] as int;

        if (description.contains('매월')) {
          // 매월 거래를 처리하기 위한 새로운 로직

          // 기본 날짜는 transaction_num에서 가져옴
          int defaultDay = int.parse(transactionNum);

          // 해당 날짜에 유효한 설정 찾기
          final List<Map<String, dynamic>> allSettings = await db.rawQuery('''
            SELECT * FROM fixed_transaction_setting
            WHERE category_id = ?
            ORDER BY effective_from ASC
          ''', [categoryId]);

          // 선택된 달에 적용해야 할 설정의 날짜(day)를 결정
          int dayToUse = defaultDay;
          DateTime selectedMonthDate = DateTime(month.year, month.month, 1);

          // 달력에 표시할 거래 날짜를 결정하기 위한 로직
          // 모든 설정을 확인하고 해당 월에 적용될 설정 찾기
          for (var setting in allSettings) {
            final effectiveFrom = DateTime.parse(setting['effective_from']);

            // 효력 시작일이 선택된 월 이전이거나 같은 달인 경우
            if (effectiveFrom.isBefore(selectedMonthDate) ||
                (effectiveFrom.year == selectedMonthDate.year &&
                    effectiveFrom.month == selectedMonthDate.month)) {
              // 이 설정의 날짜 사용
              dayToUse = effectiveFrom.day;
            } else {
              // 효력 시작일이 선택된 월보다 나중이면 이전 설정 사용
              break;
            }
          }

          // 가장 최신 설정을 찾아 해당 월에 적용 (효력 날짜가 해당 월 이전인 설정 중 가장 최신)
          final List<Map<String, dynamic>> settings = await db.rawQuery('''
            SELECT * FROM fixed_transaction_setting
            WHERE category_id = ? AND date(effective_from) <= date(?)
            ORDER BY effective_from DESC
            LIMIT 1
          ''', [categoryId, lastDayOfMonth.toIso8601String()]);

          // 결정된 날짜가 해당 월에 유효한지 확인 (예: 31일이 없는 달 처리)
          final dayInMonth = DateTime(month.year, month.month, 1).add(Duration(days: dayToUse - 1));
          final validDate = dayInMonth.month == month.month
              ? dayInMonth
              : DateTime(month.year, month.month + 1, 0); // 해당 월의 마지막 날

          // 설정이 있으면 그 금액 사용, 없으면 기존 금액 사용
          double amount = transaction['amount'] as double;
          if (settings.isNotEmpty) {
            amount = settings.first['amount'] as double;
          }

          resultTransactions.add(CalendarTransaction(
            id: transaction['id'],
            categoryId: transaction['category_id'],
            categoryName: transaction['category_name'],
            categoryType: transaction['category_type'],
            amount: amount,
            description: transaction['description'],
            transactionDate: validDate,
            isFixed: true,
            emotionTag: transaction['emotion_tag'],
            imagePath: null,  // 고정 거래는 이미지 없음
          ));
        }
        else if (description.contains('매주')) {
          // 매주 고정 거래는 해당 월의 모든 특정 요일에 추가
          final weekday = int.parse(transactionNum);

          final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
          for (int day = 1; day <= daysInMonth; day++) {
            final date = DateTime(month.year, month.month, day);
            if (date.weekday == weekday) {
              // 해당 날짜에 유효한 설정 찾기
              final List<Map<String, dynamic>> settings = await db.rawQuery('''
                SELECT * FROM fixed_transaction_setting
                WHERE category_id = ? AND date(effective_from) <= date(?)
                ORDER BY effective_from DESC
                LIMIT 1
              ''', [categoryId, date.toIso8601String()]);

              // 설정이 있으면 그 금액 사용, 없으면 기존 금액 사용
              double amount = transaction['amount'] as double;
              if (settings.isNotEmpty) {
                amount = settings.first['amount'] as double;
              }

              resultTransactions.add(CalendarTransaction(
                id: transaction['id'],
                categoryId: transaction['category_id'],
                categoryName: transaction['category_name'],
                categoryType: transaction['category_type'],
                amount: amount,
                description: transaction['description'],
                transactionDate: date,
                isFixed: true,
                emotionTag: transaction['emotion_tag'],
                imagePath: null,  // 고정 거래는 이미지 없음
              ));
            }
          }
        }
        else if (description.contains('매일')) {
          // 매일 고정 거래는 해당 월의 모든 날짜에 추가
          final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
          for (int day = 1; day <= daysInMonth; day++) {
            final date = DateTime(month.year, month.month, day);

            // 해당 날짜에 유효한 설정 찾기
            final List<Map<String, dynamic>> settings = await db.rawQuery('''
              SELECT * FROM fixed_transaction_setting
              WHERE category_id = ? AND date(effective_from) <= date(?)
              ORDER BY effective_from DESC
              LIMIT 1
            ''', [categoryId, date.toIso8601String()]);

            // 설정이 있으면 그 금액 사용, 없으면 기존 금액 사용
            double amount = transaction['amount'] as double;
            if (settings.isNotEmpty) {
              amount = settings.first['amount'] as double;
            }

            resultTransactions.add(CalendarTransaction(
              id: transaction['id'],
              categoryId: transaction['category_id'],
              categoryName: transaction['category_name'],
              categoryType: transaction['category_type'],
              amount: amount,
              description: transaction['description'],
              transactionDate: date,
              isFixed: true,
              emotionTag: transaction['emotion_tag'],
              imagePath: null,  // 고정 거래는 이미지 없음
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
        SELECT tr.id, tr.category_id, tr.amount, tr.description, tr.transaction_date,
               tr.transaction_num, tr.emotion_tag, tr.image_path,
               c.name AS category_name, c.type AS category_type, c.is_fixed
        FROM transaction_record tr
        JOIN category c ON tr.category_id = c.id
        WHERE date(substr(tr.transaction_date, 1, 10)) = date(?)
      ''', [targetDate.toIso8601String().substring(0, 10)]);

      // 고정 거래 내역
      final List<Map<String, dynamic>> fixedTransactions = await db.rawQuery('''
        SELECT tr.id, tr.category_id, tr.amount, tr.description, tr.transaction_date,
               tr.transaction_num, tr.emotion_tag,
               c.name AS category_name, c.type AS category_type, c.is_fixed
        FROM transaction_record2 tr
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
            emotionTag: transaction['emotion_tag'],
            imagePath: transaction['image_path'],
          ));
        }
      }

      // 고정 거래 처리 (업데이트된 로직)
      for (var transaction in fixedTransactions) {
        final description = transaction['description'] as String;
        final transactionNum = transaction['transaction_num'].toString();
        final categoryId = transaction['category_id'] as int;
        final type = transaction['category_type'] as String;

        if (description.contains('매월')) {
          // 카테고리에 적용된 모든 설정 가져오기
          final List<Map<String, dynamic>> allSettings = await db.rawQuery('''
            SELECT * FROM fixed_transaction_setting
            WHERE category_id = ?
            ORDER BY effective_from ASC
          ''', [categoryId]);

          // 기본 날짜는 transaction_num에서 가져오기
          int defaultDay = int.parse(transactionNum);

          // 현재 선택된 날짜에 적용해야할 설정 날짜 찾기
          int dayToUse = defaultDay;
          DateTime currentDate = targetDate;

          // 설정 날짜를 결정하는 로직
          for (var setting in allSettings) {
            final effectiveFrom = DateTime.parse(setting['effective_from']);

            // 효력 시작일이 현재 날짜보다 이전이거나 같은 달인 경우
            if (effectiveFrom.isBefore(DateTime(currentDate.year, currentDate.month, 1)) ||
                (effectiveFrom.year == currentDate.year &&
                    effectiveFrom.month == currentDate.month)) {
              dayToUse = effectiveFrom.day;
            } else {
              // 효력 시작일이 현재 날짜의 달보다 후라면 loop 종료
              break;
            }
          }

          // 선택된 날짜가 설정된 날짜와 일치하는지 확인
          final shouldInclude = targetDate.day == dayToUse;

          if (shouldInclude) {
            // 해당 날짜에 유효한 설정 찾기
            final List<Map<String, dynamic>> settings = await db.rawQuery('''
              SELECT * FROM fixed_transaction_setting
              WHERE category_id = ? AND date(effective_from) <= date(?)
              ORDER BY effective_from DESC
              LIMIT 1
            ''', [categoryId, targetDate.toIso8601String()]);

            // 설정이 있으면 그 금액 사용, 없으면 기존 금액 사용
            double amount = transaction['amount'] as double;
            if (settings.isNotEmpty) {
              amount = settings.first['amount'] as double;
            }

            if (type == 'INCOME') {
              income += amount;
            } else if (type == 'EXPENSE') {
              expense += amount.abs();
            } else if (type == 'FINANCE') {
              if (amount >= 0) {
                income += amount;
              } else {
                expense += amount.abs();
              }
            }

            // 거래 시간 추출 (고정 거래의 경우 임의로 시간 설정)
            final String timeStr = "${dayToUse.toString().padLeft(2, '0')}:00:00"; // 설정된 날짜:00시로 설정

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
              emotionTag: transaction['emotion_tag'],
              imagePath: null,  // 고정 거래는 이미지 없음
            ));
          }
        }
        else if (description.contains('매주')) {
          // 매주 고정 거래
          final weekday = int.parse(transactionNum);
          final shouldInclude = targetDate.weekday == weekday;

          if (shouldInclude) {
            // 해당 날짜에 유효한 설정 찾기
            final List<Map<String, dynamic>> settings = await db.rawQuery('''
              SELECT * FROM fixed_transaction_setting
              WHERE category_id = ? AND date(effective_from) <= date(?)
              ORDER BY effective_from DESC
              LIMIT 1
            ''', [categoryId, targetDate.toIso8601String()]);

            // 설정이 있으면 그 금액 사용, 없으면 기존 금액 사용
            double amount = transaction['amount'] as double;
            if (settings.isNotEmpty) {
              amount = settings.first['amount'] as double;
            }

            if (type == 'INCOME') {
              income += amount;
            } else if (type == 'EXPENSE') {
              expense += amount.abs();
            } else if (type == 'FINANCE') {
              if (amount >= 0) {
                income += amount;
              } else {
                expense += amount.abs();
              }
            }

            // 거래 시간 설정
            final String timeStr = "12:00:00"; // 매주는 12시로 설정

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
              emotionTag: transaction['emotion_tag'],
              imagePath: null,  // 고정 거래는 이미지 없음
            ));
          }
        }
        else if (description.contains('매일')) {
          // 매일 고정 거래는 항상 포함
          final shouldInclude = true;

          if (shouldInclude) {
            // 해당 날짜에 유효한 설정 찾기
            final List<Map<String, dynamic>> settings = await db.rawQuery('''
              SELECT * FROM fixed_transaction_setting
              WHERE category_id = ? AND date(effective_from) <= date(?)
              ORDER BY effective_from DESC
              LIMIT 1
            ''', [categoryId, targetDate.toIso8601String()]);

            // 설정이 있으면 그 금액 사용, 없으면 기존 금액 사용
            double amount = transaction['amount'] as double;
            if (settings.isNotEmpty) {
              amount = settings.first['amount'] as double;
            }

            if (type == 'INCOME') {
              income += amount;
            } else if (type == 'EXPENSE') {
              expense += amount.abs();
            } else if (type == 'FINANCE') {
              if (amount >= 0) {
                income += amount;
              } else {
                expense += amount.abs();
              }
            }

            // 거래 시간 설정
            final String timeStr = "00:00:00"; // 매일은 00시로 설정

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
              emotionTag: transaction['emotion_tag'],
              imagePath: null,  // 고정 거래는 이미지 없음
            ));
          }
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

  @override
  Future<void> updateTransaction(CalendarTransaction transaction) async {
    try {
      // 고정 거래는 수정 불가
      if (transaction.isFixed) {
        throw Exception('고정 거래는 수정할 수 없습니다.');
      }

      final db = await dbHelper.database;
      final now = DateTime.now().toIso8601String();

      debugPrint('💾 [CalendarLocalDataSource] Updating transaction ID: ${transaction.id}');
      debugPrint('💾 [CalendarLocalDataSource] imagePath to save: ${transaction.imagePath}');

      // transaction_record 테이블의 일반 거래만 업데이트
      final result = await db.update(
        'transaction_record',
        {
          'amount': transaction.amount,
          'description': transaction.description,
          'transaction_date': transaction.transactionDate.toIso8601String(),
          'emotion_tag': transaction.emotionTag,
          'image_path': transaction.imagePath,  // imagePath 추가!
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [transaction.id],
      );

      if (result == 0) {
        throw Exception('거래 내역을 찾을 수 없습니다.');
      }

      debugPrint('✅ [CalendarLocalDataSource] 거래 수정 완료: ID ${transaction.id}, rows affected: $result');
    } catch (e) {
      debugPrint('❌ [CalendarLocalDataSource] 거래 수정 오류: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteTransaction(CalendarTransaction transaction) async {
    try {
      // 고정 거래는 삭제 불가
      if (transaction.isFixed) {
        throw Exception('고정 거래는 삭제할 수 없습니다.');
      }

      final db = await dbHelper.database;

      // transaction_record 테이블에서 일반 거래 삭제
      final result = await db.delete(
        'transaction_record',
        where: 'id = ?',
        whereArgs: [transaction.id],
      );

      if (result == 0) {
        throw Exception('삭제할 거래 내역을 찾을 수 없습니다.');
      }

      debugPrint('거래 삭제 완료: ID ${transaction.id} - ${transaction.description}');
    } catch (e) {
      debugPrint('거래 삭제 오류: $e');
      rethrow;
    }
  }
}