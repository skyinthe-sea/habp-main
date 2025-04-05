// lib/features/onboarding/domain/services/onboarding_service.dart

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../../../core/database/db_helper.dart';
import '../../data/models/expense_category.dart';
import '../../data/models/transaction_record.dart';
import '../../data/models/user.dart';

class OnboardingService {
  final DBHelper _dbHelper = DBHelper();

  // 소득 정보 저장 (온보딩에서 수집된 데이터)
  Future<void> saveIncomeInfo({
    required String incomeType,
    required String frequency,
    required int day,
    required double amount,
    required ExpenseCategoryType type,
  }) async {
    try {
      // 1. 활성 사용자 가져오기 (없으면 자동 생성)
      final db = await _dbHelper.database;
      final userRepository = await _getUserRepository(db);
      final user = await userRepository.getActiveUser();

      // 2. 소득 카테고리 조회 또는 생성
      final categoryRepository = await _getCategoryRepository(db);
      final category = await categoryRepository.getOrCreateCategory(
        incomeType,
        type,
        frequency == '매월', // 매월이면 고정 소득으로 간주
      );

      // 3. 거래 내역 생성
      final now = DateTime.now();

      // 거래 날짜 계산 (현재 달 기준)
      DateTime transactionDate;
      if (frequency == '매월') {
        transactionDate = DateTime(now.year, now.month, day);
      } else if (frequency == '매주') {
        // 요일을 날짜로 변환 (1=월요일, 7=일요일)
        final today = now;
        final difference = day - today.weekday;
        transactionDate = today.add(Duration(days: difference));
      } else { // 매일
        transactionDate = now;
      }

      // 거래 내역 저장
      final transactionRepository = await _getTransactionRepository(db);
      final transaction = TransactionRecord(
        userId: user.id,
        categoryId: category.id!,
        amount: amount,
        description: '$frequency $incomeType',
        transactionNum: '$day',
        transactionDate: transactionDate,
        createdAt: now,
        updatedAt: now,
      );

      await transactionRepository.createTransaction(transaction);

      debugPrint('소득 정보 저장 완료: $incomeType $frequency ${day}일 금액: $amount원');
    } catch (e) {
      debugPrint('소득 정보 저장 중 오류 발생: $e');
      rethrow;
    }
  }

  // 온보딩 완료 후 데이터베이스 정보 출력
  Future<void> printOnboardingData() async {
    try {
      await _dbHelper.printDatabaseInfo();
    } catch (e) {
      debugPrint('데이터베이스 정보 출력 중 오류 발생: $e');
      rethrow;
    }
  }

  // 테스트용 데이터베이스 초기화
  Future<void> resetDatabase() async {
    await _dbHelper.resetDatabase();
  }

  // 레포지토리 획득 메서드들 (중복 코드 방지)
  Future<UserRepository> _getUserRepository(Database db) async {
    return UserRepository(db);
  }

  Future<CategoryRepository> _getCategoryRepository(Database db) async {
    return CategoryRepository(db);
  }

  Future<TransactionRepository> _getTransactionRepository(Database db) async {
    return TransactionRepository(db);
  }
}

// 간소화된 리포지토리 구현 (기존 코드와 연결용)

class UserRepository {
  final Database _db;

  UserRepository(this._db);

  Future<User> getActiveUser() async {
    final now = DateTime.now();
    final List<Map<String, dynamic>> maps = await _db.query('user', limit: 1);

    if (maps.isEmpty) {
      // 사용자가 없으면 기본 사용자 생성
      final defaultUser = User(
        createdAt: now,
        updatedAt: now,
        membershipType: MembershipType.FREE,
      );

      final id = await _db.insert('user', defaultUser.toMap());
      return defaultUser.copyWith(id: id);
    }

    return User.fromMap(maps.first);
  }
}

class CategoryRepository {
  final Database _db;

  CategoryRepository(this._db);

  Future<ExpenseCategory> getOrCreateCategory(String name, ExpenseCategoryType type, bool isFixed) async {
    // 이미 존재하는지 확인
    final List<Map<String, dynamic>> maps = await _db.query(
      'category',
      where: 'name = ? AND type = ?',
      whereArgs: [name, type.toString().split('.').last],
    );

    if (maps.isNotEmpty) {
      return ExpenseCategory.fromMap(maps.first);
    }

    // 존재하지 않으면 새로 생성
    final now = DateTime.now();
    final newCategory = ExpenseCategory(
      name: name,
      type: type,
      isFixed: isFixed,
      createdAt: now,
      updatedAt: now,
    );

    final id = await _db.insert('category', newCategory.toMap());
    return newCategory.copyWith(id: id);
  }
}

class TransactionRepository {
  final Database _db;

  TransactionRepository(this._db);

  Future<int> createTransaction(TransactionRecord transaction) async {
    return await _db.insert('transaction_record2', transaction.toMap());
  }
}