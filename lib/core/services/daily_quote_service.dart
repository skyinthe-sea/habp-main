// lib/core/services/daily_quote_service.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/db_helper.dart';

/// Service for managing daily financial wisdom quotes
class DailyQuoteService {
  final DBHelper _dbHelper = DBHelper();
  final int userId = 1; // In a real app, this would come from auth

  static const String _lastShownDateKey = 'last_quote_shown_date';

  /// Check if should show quote (after 5 AM)
  Future<bool> shouldShowQuote() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastShownStr = prefs.getString(_lastShownDateKey);

      final now = DateTime.now();

      // Check if it's after 5 AM
      final today5AM = DateTime(now.year, now.month, now.day, 5, 0, 0);
      if (now.isBefore(today5AM)) {
        // Before 5 AM, use yesterday as reference
        return false;
      }

      // If never shown, show it
      if (lastShownStr == null) {
        return true;
      }

      final lastShown = DateTime.parse(lastShownStr);
      final lastShown5AM = DateTime(lastShown.year, lastShown.month, lastShown.day, 5, 0, 0);

      // Check if last shown date is before today's 5 AM
      return lastShown5AM.isBefore(today5AM);
    } catch (e) {
      debugPrint('Error checking should show quote: $e');
      return false;
    }
  }

  /// Get today's quote (next in sequence that hasn't been viewed)
  Future<Map<String, dynamic>?> getTodaysQuote() async {
    try {
      final db = await _dbHelper.database;

      // Get the last viewed quote ID
      final lastQuoteResult = await db.query(
        'user_last_quote_date',
        where: 'user_id = ?',
        whereArgs: [userId],
        limit: 1,
      );

      int nextQuoteId = 1;
      if (lastQuoteResult.isNotEmpty) {
        final lastQuoteId = lastQuoteResult.first['last_quote_id'] as int?;
        if (lastQuoteId != null) {
          nextQuoteId = lastQuoteId + 1;
        }
      }

      // Get the next quote
      var quoteResult = await db.query(
        'daily_quote',
        where: 'id = ?',
        whereArgs: [nextQuoteId],
        limit: 1,
      );

      // If no next quote found, start from beginning
      if (quoteResult.isEmpty) {
        nextQuoteId = 1;
        quoteResult = await db.query(
          'daily_quote',
          where: 'id = ?',
          whereArgs: [nextQuoteId],
          limit: 1,
        );
      }

      if (quoteResult.isEmpty) {
        return null;
      }

      return quoteResult.first;
    } catch (e) {
      debugPrint('Error getting today\'s quote: $e');
      return null;
    }
  }

  /// Mark quote as viewed and save to history
  Future<void> markQuoteAsViewed(int quoteId) async {
    try {
      final db = await _dbHelper.database;
      final now = DateTime.now();
      final nowStr = now.toIso8601String();
      final dateStr = DateTime(now.year, now.month, now.day).toIso8601String();

      // Save to quote history
      await db.insert('user_quote_history', {
        'user_id': userId,
        'quote_id': quoteId,
        'viewed_date': dateStr,
        'is_collected': 1,
        'created_at': nowStr,
      });

      // Update or insert last quote date
      final existingRecord = await db.query(
        'user_last_quote_date',
        where: 'user_id = ?',
        whereArgs: [userId],
        limit: 1,
      );

      if (existingRecord.isNotEmpty) {
        await db.update(
          'user_last_quote_date',
          {
            'last_shown_date': dateStr,
            'last_quote_id': quoteId,
            'updated_at': nowStr,
          },
          where: 'user_id = ?',
          whereArgs: [userId],
        );
      } else {
        await db.insert('user_last_quote_date', {
          'user_id': userId,
          'last_shown_date': dateStr,
          'last_quote_id': quoteId,
          'updated_at': nowStr,
        });
      }

      // Update SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastShownDateKey, now.toIso8601String());

      debugPrint('✅ Quote $quoteId marked as viewed');
    } catch (e) {
      debugPrint('Error marking quote as viewed: $e');
    }
  }

  /// Get all collected quotes
  Future<List<Map<String, dynamic>>> getCollectedQuotes() async {
    try {
      final db = await _dbHelper.database;

      final result = await db.rawQuery('''
        SELECT
          dq.id,
          dq.quote_text,
          dq.author,
          dq.category,
          uqh.viewed_date
        FROM user_quote_history uqh
        INNER JOIN daily_quote dq ON uqh.quote_id = dq.id
        WHERE uqh.user_id = ? AND uqh.is_collected = 1
        ORDER BY uqh.viewed_date DESC
      ''', [userId]);

      return result;
    } catch (e) {
      debugPrint('Error getting collected quotes: $e');
      return [];
    }
  }

  /// Get collection statistics
  Future<Map<String, int>> getCollectionStats() async {
    try {
      final db = await _dbHelper.database;

      // Total quotes available
      final totalResult = await db.rawQuery('SELECT COUNT(*) as count FROM daily_quote');
      final totalQuotes = totalResult.first['count'] as int;

      // Collected quotes
      final collectedResult = await db.rawQuery('''
        SELECT COUNT(DISTINCT quote_id) as count
        FROM user_quote_history
        WHERE user_id = ? AND is_collected = 1
      ''', [userId]);
      final collectedQuotes = collectedResult.first['count'] as int;

      return {
        'total': totalQuotes,
        'collected': collectedQuotes,
        'remaining': totalQuotes - collectedQuotes,
      };
    } catch (e) {
      debugPrint('Error getting collection stats: $e');
      return {'total': 200, 'collected': 0, 'remaining': 200};
    }
  }

  /// Get quotes by category
  Future<List<Map<String, dynamic>>> getQuotesByCategory(String category) async {
    try {
      final db = await _dbHelper.database;

      final result = await db.rawQuery('''
        SELECT
          dq.id,
          dq.quote_text,
          dq.author,
          dq.category,
          uqh.viewed_date,
          CASE WHEN uqh.id IS NOT NULL THEN 1 ELSE 0 END as is_collected
        FROM daily_quote dq
        LEFT JOIN user_quote_history uqh
          ON dq.id = uqh.quote_id AND uqh.user_id = ?
        WHERE dq.category = ?
        ORDER BY dq.id
      ''', [userId, category]);

      return result;
    } catch (e) {
      debugPrint('Error getting quotes by category: $e');
      return [];
    }
  }

  /// Check if user has seen today's quote
  Future<bool> hasSeenTodaysQuote() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastShownStr = prefs.getString(_lastShownDateKey);

      if (lastShownStr == null) return false;

      final lastShown = DateTime.parse(lastShownStr);
      final now = DateTime.now();

      // Check if it's the same day after 5 AM
      final today5AM = DateTime(now.year, now.month, now.day, 5, 0, 0);
      final lastShown5AM = DateTime(lastShown.year, lastShown.month, lastShown.day, 5, 0, 0);

      if (now.isBefore(today5AM)) {
        // Before 5 AM, check against yesterday
        final yesterday5AM = today5AM.subtract(const Duration(days: 1));
        return lastShown5AM.isAfter(yesterday5AM) || lastShown5AM.isAtSameMomentAs(yesterday5AM);
      }

      return lastShown5AM.isAtSameMomentAs(today5AM) || lastShown5AM.isAfter(today5AM);
    } catch (e) {
      debugPrint('Error checking if seen today\'s quote: $e');
      return false;
    }
  }
}
