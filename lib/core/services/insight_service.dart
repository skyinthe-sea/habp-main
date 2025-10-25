// lib/core/services/insight_service.dart

import 'package:flutter/material.dart';
import '../database/db_helper.dart';

/// Service for generating financial insights based on user's transaction history
class InsightService {
  final DBHelper _dbHelper = DBHelper();
  final int userId = 1; // In a real app, this would come from auth

  /// Generate insight for daily notification based on today's activity
  Future<String> generateDailyInsight() async {
    try {
      final db = await _dbHelper.database;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final todayEnd = today.add(const Duration(days: 1));

      // Check if user recorded any transactions today
      final todayTransactions = await db.query(
        'transaction_record',
        where: 'user_id = ? AND transaction_date >= ? AND transaction_date < ?',
        whereArgs: [userId, today.toIso8601String(), todayEnd.toIso8601String()],
      );

      // If no transactions today, return reminder message
      if (todayTransactions.isEmpty) {
        return '오늘의 소비를 기록해볼까요?';
      }

      // User has recorded transactions today, generate insight
      return await _generateInsightMessage();
    } catch (e) {
      debugPrint('Error generating daily insight: $e');
      return '오늘의 소비를 기록해볼까요?';
    }
  }

  /// Generate detailed insight message based on weekly/monthly data
  Future<String> _generateInsightMessage() async {
    try {
      final db = await _dbHelper.database;
      final now = DateTime.now();

      // Get this week's data
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekStartNormalized = DateTime(weekStart.year, weekStart.month, weekStart.day);

      // Get last week's data for comparison
      final lastWeekStart = weekStartNormalized.subtract(const Duration(days: 7));
      final lastWeekEnd = weekStartNormalized;

      // This week's transactions
      final thisWeekTransactions = await db.rawQuery('''
        SELECT
          c.type AS category_type,
          SUM(CASE WHEN tr.amount > 0 THEN tr.amount ELSE 0 END) as income,
          SUM(CASE WHEN tr.amount < 0 THEN ABS(tr.amount) ELSE 0 END) as expense
        FROM transaction_record tr
        INNER JOIN category c ON tr.category_id = c.id
        WHERE tr.user_id = ?
          AND tr.transaction_date >= ?
          AND c.type IN ('INCOME', 'EXPENSE')
        GROUP BY c.type
      ''', [userId, weekStartNormalized.toIso8601String()]);

      // Last week's transactions
      final lastWeekTransactions = await db.rawQuery('''
        SELECT
          c.type AS category_type,
          SUM(CASE WHEN tr.amount > 0 THEN tr.amount ELSE 0 END) as income,
          SUM(CASE WHEN tr.amount < 0 THEN ABS(tr.amount) ELSE 0 END) as expense
        FROM transaction_record tr
        INNER JOIN category c ON tr.category_id = c.id
        WHERE tr.user_id = ?
          AND tr.transaction_date >= ?
          AND tr.transaction_date < ?
          AND c.type IN ('INCOME', 'EXPENSE')
        GROUP BY c.type
      ''', [userId, lastWeekStart.toIso8601String(), lastWeekEnd.toIso8601String()]);

      // Calculate this week's totals
      double thisWeekIncome = 0;
      double thisWeekExpense = 0;
      for (var row in thisWeekTransactions) {
        if (row['category_type'] == 'INCOME') {
          thisWeekIncome = (row['income'] as num?)?.toDouble() ?? 0;
        } else if (row['category_type'] == 'EXPENSE') {
          thisWeekExpense = (row['expense'] as num?)?.toDouble() ?? 0;
        }
      }

      // Calculate last week's totals
      double lastWeekIncome = 0;
      double lastWeekExpense = 0;
      for (var row in lastWeekTransactions) {
        if (row['category_type'] == 'INCOME') {
          lastWeekIncome = (row['income'] as num?)?.toDouble() ?? 0;
        } else if (row['category_type'] == 'EXPENSE') {
          lastWeekExpense = (row['expense'] as num?)?.toDouble() ?? 0;
        }
      }

      // Generate insight based on comparison
      return _createInsightMessage(
        thisWeekIncome: thisWeekIncome,
        thisWeekExpense: thisWeekExpense,
        lastWeekIncome: lastWeekIncome,
        lastWeekExpense: lastWeekExpense,
      );
    } catch (e) {
      debugPrint('Error generating insight message: $e');
      return '오늘도 알뜰하게 기록하셨네요! 💰';
    }
  }

  /// Create insight message based on spending patterns
  String _createInsightMessage({
    required double thisWeekIncome,
    required double thisWeekExpense,
    required double lastWeekIncome,
    required double lastWeekExpense,
  }) {
    final List<String> insights = [];

    // Expense comparison
    if (lastWeekExpense > 0) {
      final expenseChange = ((thisWeekExpense - lastWeekExpense) / lastWeekExpense * 100).abs();

      if (thisWeekExpense < lastWeekExpense * 0.9) {
        // Significant decrease in spending
        insights.add('이번 주 지출이 지난 주보다 ${expenseChange.toStringAsFixed(0)}% 줄었어요! 🎉');
      } else if (thisWeekExpense > lastWeekExpense * 1.2) {
        // Significant increase in spending
        insights.add('이번 주 지출이 지난 주보다 ${expenseChange.toStringAsFixed(0)}% 늘었네요. 소비를 점검해보세요 💡');
      }
    }

    // Income comparison
    if (lastWeekIncome > 0 && thisWeekIncome > lastWeekIncome * 1.1) {
      final incomeIncrease = ((thisWeekIncome - lastWeekIncome) / lastWeekIncome * 100);
      insights.add('수입이 ${incomeIncrease.toStringAsFixed(0)}% 증가했어요! 👏');
    }

    // Savings rate
    if (thisWeekIncome > 0) {
      final savingsRate = ((thisWeekIncome - thisWeekExpense) / thisWeekIncome * 100);
      if (savingsRate > 30) {
        insights.add('이번 주 저축률 ${savingsRate.toStringAsFixed(0)}%! 훌륭해요 💪');
      } else if (savingsRate < 0) {
        insights.add('이번 주 지출이 수입을 초과했어요. 계획을 다시 세워보세요 📊');
      }
    }

    // Get top spending category this week
    _getTopSpendingCategory().then((category) {
      if (category != null) {
        insights.add('가장 많이 쓴 카테고리: $category');
      }
    });

    // Return a random insight or default message
    if (insights.isNotEmpty) {
      return insights.first;
    }

    // Default positive messages
    final defaultMessages = [
      '오늘도 알뜰하게 기록하셨네요! 💰',
      '꾸준한 기록이 현명한 소비를 만들어요 ✨',
      '매일 기록하는 습관, 정말 대단해요! 👍',
      '돈 관리의 첫걸음은 기록부터! 잘하고 계세요 📝',
    ];

    return defaultMessages[DateTime.now().millisecond % defaultMessages.length];
  }

  /// Get the top spending category for this week
  Future<String?> _getTopSpendingCategory() async {
    try {
      final db = await _dbHelper.database;
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekStartNormalized = DateTime(weekStart.year, weekStart.month, weekStart.day);

      final result = await db.rawQuery('''
        SELECT c.name, SUM(ABS(tr.amount)) as total
        FROM transaction_record tr
        INNER JOIN category c ON tr.category_id = c.id
        WHERE tr.user_id = ?
          AND tr.transaction_date >= ?
          AND c.type = 'EXPENSE'
        GROUP BY c.id
        ORDER BY total DESC
        LIMIT 1
      ''', [userId, weekStartNormalized.toIso8601String()]);

      if (result.isNotEmpty) {
        return result.first['name'] as String?;
      }
    } catch (e) {
      debugPrint('Error getting top spending category: $e');
    }
    return null;
  }

  /// Check if user has recorded any transaction today
  Future<bool> hasRecordedToday() async {
    try {
      final db = await _dbHelper.database;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final todayEnd = today.add(const Duration(days: 1));

      final result = await db.query(
        'transaction_record',
        where: 'user_id = ? AND transaction_date >= ? AND transaction_date < ?',
        whereArgs: [userId, today.toIso8601String(), todayEnd.toIso8601String()],
        limit: 1,
      );

      return result.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking today\'s records: $e');
      return false;
    }
  }
}
