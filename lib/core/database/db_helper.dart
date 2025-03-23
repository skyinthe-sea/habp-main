// lib/core/database/db_helper.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

class DBHelper {
  // 싱글톤 패턴
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  static Database? _database;

  // 데이터베이스 인스턴스 가져오기
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // 데이터베이스 초기화
  Future<Database> _initDatabase() async {
    final String path = join(await getDatabasesPath(), 'finance_manager.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  // 데이터베이스 테이블 생성
  Future<void> _createDB(Database db, int version) async {
    // 사용자 테이블
    await db.execute('''
      CREATE TABLE user (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT,
        password_hash TEXT,
        name TEXT,
        membership_type TEXT DEFAULT 'FREE',
        premium_expiry_date TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 카테고리 테이블
    await db.execute('''
      CREATE TABLE category (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        is_fixed INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 거래 내역 테이블
    await db.execute('''
      CREATE TABLE transaction_record (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        category_id INTEGER,
        amount REAL NOT NULL,
        description TEXT,
        transaction_date TEXT NOT NULL,
        transaction_num TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES user (id),
        FOREIGN KEY (category_id) REFERENCES category (id)
      )
    ''');

    // 예산 테이블
    await db.execute('''
      CREATE TABLE budget (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        category_id INTEGER,
        amount REAL NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES user (id),
        FOREIGN KEY (category_id) REFERENCES category (id)
      )
    ''');

    // 금융 계좌 테이블
    await db.execute('''
      CREATE TABLE financial_account (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        balance REAL NOT NULL,
        interest_rate REAL,
        maturity_date TEXT,
        is_fixed INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES user (id)
      )
    ''');

    // 기본 카테고리 데이터 추가
    await _insertDefaultCategories(db);
  }

  // 기본 카테고리 데이터 삽입
  Future<void> _insertDefaultCategories(Database db) async {
    final now = DateTime.now().toIso8601String();

    try {
      // 소득 카테고리
      final incomeCategories = [
        {'name': '월급', 'type': 'INCOME', 'is_fixed': 1},
        {'name': '용돈', 'type': 'INCOME', 'is_fixed': 1},
        {'name': '이자', 'type': 'INCOME', 'is_fixed': 1},
      ];

      // 지출 카테고리
      final expenseCategories = [
        {'name': '통신비', 'type': 'EXPENSE', 'is_fixed': 1},
        {'name': '유튜브', 'type': 'EXPENSE', 'is_fixed': 1},
        {'name': '월세', 'type': 'EXPENSE', 'is_fixed': 1},
        {'name': '보험', 'type': 'EXPENSE', 'is_fixed': 1},
      ];

      // 금융 카테고리
      final financeCategories = [
        {'name': '저축', 'type': 'FINANCE', 'is_fixed': 1},
        {'name': '투자', 'type': 'FINANCE', 'is_fixed': 1},
        {'name': '대출', 'type': 'FINANCE', 'is_fixed': 1},
      ];

      final allCategories = [...incomeCategories, ...expenseCategories, ...financeCategories];

      for (var category in allCategories) {
        await db.insert('category', {
          'name': category['name'],
          'type': category['type'],
          'is_fixed': category['is_fixed'],
          'created_at': now,
          'updated_at': now,
        });
      }

      debugPrint('기본 카테고리 추가 완료: ${allCategories.length}개');
    } catch (e) {
      debugPrint('기본 카테고리 추가 중 오류: $e');
    }
  }

  // 데이터베이스 리셋 (개발 및 테스트용)
  Future<void> resetDatabase() async {
    final db = await database;
    await db.execute('DROP TABLE IF EXISTS financial_account');
    await db.execute('DROP TABLE IF EXISTS budget');
    await db.execute('DROP TABLE IF EXISTS transaction_record');
    await db.execute('DROP TABLE IF EXISTS category');
    await db.execute('DROP TABLE IF EXISTS user');
    await _createDB(db, 1);
  }

  // 데이터베이스 정보 출력 (개발 및 테스트용)
  Future<void> printDatabaseInfo() async {
    final db = await database;

    debugPrint("\n=== 데이터베이스 정보 ===");

    // 사용자 정보
    final users = await db.query('user');
    debugPrint("\n사용자 목록: ${users.length}개");
    for (var user in users) {
      debugPrint(user.toString());
    }

    // 카테고리 정보
    final categories = await db.query('category');
    debugPrint("\n카테고리 목록: ${categories.length}개");
    for (var category in categories) {
      debugPrint(category.toString());
    }

    // 거래 내역
    final transactions = await db.query('transaction_record');
    debugPrint("\n거래 내역: ${transactions.length}개");
    for (var transaction in transactions) {
      debugPrint(transaction.toString());
    }

    // 예산 정보
    final budgets = await db.query('budget');
    debugPrint("\n예산 정보: ${budgets.length}개");
    for (var budget in budgets) {
      debugPrint(budget.toString());
    }

    // 금융 계좌
    final accounts = await db.query('financial_account');
    debugPrint("\n금융 계좌: ${accounts.length}개");
    for (var account in accounts) {
      debugPrint(account.toString());
    }

    debugPrint("\n=========================");
  }
}