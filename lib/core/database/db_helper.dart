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
      version: 6,  // 버전 6으로 업그레이드
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  // 데이터베이스 업그레이드
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Version 2: emotion_tag 컬럼 추가
      await db.execute('''
        ALTER TABLE transaction_record ADD COLUMN emotion_tag TEXT
      ''');
      await db.execute('''
        ALTER TABLE transaction_record2 ADD COLUMN emotion_tag TEXT
      ''');
      debugPrint('데이터베이스 업그레이드 완료: emotion_tag 컬럼 추가');
    }

    if (oldVersion < 3) {
      // Version 3: monthly_diary 테이블 추가
      await db.execute('''
        CREATE TABLE IF NOT EXISTS monthly_diary (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER,
          year INTEGER NOT NULL,
          month INTEGER NOT NULL,
          title TEXT,
          memo TEXT,
          images TEXT,
          stickers TEXT,
          monthly_summary TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES user (id)
        )
      ''');
      debugPrint('데이터베이스 업그레이드 완료: monthly_diary 테이블 추가');
    }

    if (oldVersion < 4) {
      // Version 4: 챌린지 모드 테이블 추가

      // 챌린지 템플릿 테이블
      await db.execute('''
        CREATE TABLE IF NOT EXISTS challenge_template (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          description TEXT,
          type TEXT NOT NULL,
          target_amount REAL,
          category_id INTEGER,
          duration_type TEXT NOT NULL,
          icon TEXT,
          color TEXT,
          difficulty TEXT,
          badge_reward TEXT,
          created_at TEXT NOT NULL
        )
      ''');

      // 사용자 챌린지 테이블
      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_challenge (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER,
          template_id INTEGER,
          title TEXT NOT NULL,
          description TEXT,
          type TEXT NOT NULL,
          target_amount REAL NOT NULL,
          current_amount REAL DEFAULT 0,
          category_id INTEGER,
          start_date TEXT NOT NULL,
          end_date TEXT NOT NULL,
          status TEXT NOT NULL,
          progress REAL DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          completed_at TEXT,
          result_viewed INTEGER DEFAULT 0,
          FOREIGN KEY (user_id) REFERENCES user (id),
          FOREIGN KEY (template_id) REFERENCES challenge_template (id),
          FOREIGN KEY (category_id) REFERENCES category (id)
        )
      ''');

      // 뱃지 테이블
      await db.execute('''
        CREATE TABLE IF NOT EXISTS badge (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          description TEXT,
          icon TEXT NOT NULL,
          type TEXT NOT NULL,
          rarity TEXT NOT NULL,
          unlock_condition TEXT,
          created_at TEXT NOT NULL
        )
      ''');

      // 사용자 획득 뱃지 테이블
      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_badge (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER,
          badge_id INTEGER,
          earned_at TEXT NOT NULL,
          is_new INTEGER DEFAULT 1,
          FOREIGN KEY (user_id) REFERENCES user (id),
          FOREIGN KEY (badge_id) REFERENCES badge (id)
        )
      ''');

      // 보상 테이블 (테마, 스티커 등)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS reward (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          description TEXT,
          type TEXT NOT NULL,
          data TEXT,
          unlock_condition TEXT,
          created_at TEXT NOT NULL
        )
      ''');

      // 사용자 획득 보상 테이블
      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_reward (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER,
          reward_id INTEGER,
          unlocked_at TEXT NOT NULL,
          is_active INTEGER DEFAULT 0,
          FOREIGN KEY (user_id) REFERENCES user (id),
          FOREIGN KEY (reward_id) REFERENCES reward (id)
        )
      ''');

      debugPrint('데이터베이스 업그레이드 완료: 챌린지 모드 테이블 추가');
    }

    if (oldVersion < 5) {
      // Version 5: user_challenge 테이블에 result_viewed 컬럼 추가
      await db.execute('''
        ALTER TABLE user_challenge ADD COLUMN result_viewed INTEGER DEFAULT 0
      ''');
      debugPrint('데이터베이스 업그레이드 완료: result_viewed 컬럼 추가');
    }

    if (oldVersion < 6) {
      // Version 6: image_path 컬럼 추가 (영수증/사진 첨부 기능)
      await db.execute('''
        ALTER TABLE transaction_record ADD COLUMN image_path TEXT
      ''');
      await db.execute('''
        ALTER TABLE transaction_record2 ADD COLUMN image_path TEXT
      ''');
      debugPrint('데이터베이스 업그레이드 완료: image_path 컬럼 추가');
    }
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
        is_deleted INTEGER DEFAULT 0,
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
        emotion_tag TEXT,
        image_path TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES user (id),
        FOREIGN KEY (category_id) REFERENCES category (id)
      )
    ''');

    // 거래 내역 테이블
    await db.execute('''
      CREATE TABLE transaction_record2 (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        category_id INTEGER,
        amount REAL NOT NULL,
        description TEXT,
        transaction_date TEXT NOT NULL,
        transaction_num TEXT,
        emotion_tag TEXT,
        image_path TEXT,
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

    // 자산 테이블
    await db.execute('''
    CREATE TABLE asset (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER,
      category_id INTEGER,
      name TEXT NOT NULL,
      current_value REAL NOT NULL,
      purchase_value REAL,
      purchase_date TEXT,
      interest_rate REAL,
      loan_amount REAL,
      description TEXT,
      location TEXT,
      details TEXT,
      icon_type TEXT,
      is_active INTEGER DEFAULT 1,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (user_id) REFERENCES user (id),
      FOREIGN KEY (category_id) REFERENCES category (id)
    )
  ''');

    // 자산 가치 변동 히스토리 테이블
    await db.execute('''
    CREATE TABLE asset_valuation_history (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      asset_id INTEGER,
      valuation_date TEXT NOT NULL,
      value REAL NOT NULL,
      created_at TEXT NOT NULL,
      FOREIGN KEY (asset_id) REFERENCES asset (id)
    )
  ''');

    // 고정 거래 설정 테이블
    await db.execute('''
    CREATE TABLE fixed_transaction_setting (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      category_id INTEGER,
      amount REAL NOT NULL,
      effective_from TEXT NOT NULL,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (category_id) REFERENCES category (id)
    )
  ''');

    // 월별 다이어리 테이블
    await db.execute('''
    CREATE TABLE monthly_diary (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER,
      year INTEGER NOT NULL,
      month INTEGER NOT NULL,
      title TEXT,
      memo TEXT,
      images TEXT,
      stickers TEXT,
      monthly_summary TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (user_id) REFERENCES user (id)
    )
  ''');

    // 챌린지 템플릿 테이블
    await db.execute('''
    CREATE TABLE challenge_template (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      description TEXT,
      type TEXT NOT NULL,
      target_amount REAL,
      category_id INTEGER,
      duration_type TEXT NOT NULL,
      icon TEXT,
      color TEXT,
      difficulty TEXT,
      badge_reward TEXT,
      created_at TEXT NOT NULL
    )
  ''');

    // 사용자 챌린지 테이블
    await db.execute('''
    CREATE TABLE user_challenge (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER,
      template_id INTEGER,
      title TEXT NOT NULL,
      description TEXT,
      type TEXT NOT NULL,
      target_amount REAL NOT NULL,
      current_amount REAL DEFAULT 0,
      category_id INTEGER,
      start_date TEXT NOT NULL,
      end_date TEXT NOT NULL,
      status TEXT NOT NULL,
      progress REAL DEFAULT 0,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      completed_at TEXT,
      FOREIGN KEY (user_id) REFERENCES user (id),
      FOREIGN KEY (template_id) REFERENCES challenge_template (id),
      FOREIGN KEY (category_id) REFERENCES category (id)
    )
  ''');

    // 뱃지 테이블
    await db.execute('''
    CREATE TABLE badge (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      description TEXT,
      icon TEXT NOT NULL,
      type TEXT NOT NULL,
      rarity TEXT NOT NULL,
      unlock_condition TEXT,
      created_at TEXT NOT NULL
    )
  ''');

    // 사용자 획득 뱃지 테이블
    await db.execute('''
    CREATE TABLE user_badge (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER,
      badge_id INTEGER,
      earned_at TEXT NOT NULL,
      is_new INTEGER DEFAULT 1,
      FOREIGN KEY (user_id) REFERENCES user (id),
      FOREIGN KEY (badge_id) REFERENCES badge (id)
    )
  ''');

    // 보상 테이블
    await db.execute('''
    CREATE TABLE reward (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      description TEXT,
      type TEXT NOT NULL,
      data TEXT,
      unlock_condition TEXT,
      created_at TEXT NOT NULL
    )
  ''');

    // 사용자 획득 보상 테이블
    await db.execute('''
    CREATE TABLE user_reward (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER,
      reward_id INTEGER,
      unlocked_at TEXT NOT NULL,
      is_active INTEGER DEFAULT 0,
      FOREIGN KEY (user_id) REFERENCES user (id),
      FOREIGN KEY (reward_id) REFERENCES reward (id)
    )
  ''');

    // 기본 카테고리 데이터 추가
    await _insertDefaultCategories(db);

    // 기본 챌린지 템플릿 및 뱃지 데이터 추가
    await _insertDefaultChallengeData(db);
  }

  // 기본 카테고리 데이터 삽입
  Future<void> _insertDefaultCategories(Database db) async {
    final now = DateTime.now().toIso8601String();

    try {
      // 소득 카테고리
      final incomeCategories = [
        {'name': '급여', 'type': 'INCOME', 'is_fixed': 1},
        {'name': '용돈', 'type': 'INCOME', 'is_fixed': 1},
        {'name': '이자', 'type': 'INCOME', 'is_fixed': 1},
      ];

      // 지출 카테고리
      final expenseCategories = [
        {'name': '통신비', 'type': 'EXPENSE', 'is_fixed': 1},
        {'name': '보험', 'type': 'EXPENSE', 'is_fixed': 1},
        {'name': '월세', 'type': 'EXPENSE', 'is_fixed': 1},
      ];

      // 금융 카테고리
      final financeCategories = [
        {'name': '적금', 'type': 'FINANCE', 'is_fixed': 1},
        {'name': '투자', 'type': 'FINANCE', 'is_fixed': 1},
        {'name': '대출이자', 'type': 'FINANCE', 'is_fixed': 1},
      ];

      // 자산 카테고리 추가
      final assetCategories = [
        {'name': '부동산', 'type': 'ASSET', 'is_fixed': 1},
        {'name': '자동차', 'type': 'ASSET', 'is_fixed': 1},
        {'name': '주식', 'type': 'ASSET', 'is_fixed': 1},
        {'name': '가상화폐', 'type': 'ASSET', 'is_fixed': 1},
        {'name': '현금', 'type': 'ASSET', 'is_fixed': 1},
        {'name': '귀금속', 'type': 'ASSET', 'is_fixed': 1},
        {'name': '적금', 'type': 'ASSET', 'is_fixed': 1},
        {'name': '예금', 'type': 'ASSET', 'is_fixed': 1},
        {'name': '기타', 'type': 'ASSET', 'is_fixed': 1},
      ];

      final allCategories = [...incomeCategories, ...expenseCategories, ...financeCategories, ...assetCategories];

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

  // 기본 챌린지 템플릿 및 뱃지 데이터 삽입
  Future<void> _insertDefaultChallengeData(Database db) async {
    final now = DateTime.now().toIso8601String();

    try {
      // 기본 챌린지 템플릿
      final challengeTemplates = [
        {
          'title': '커피 다이어트',
          'description': '이번 주 커피값 1만 원 이하로!',
          'type': 'EXPENSE_LIMIT',
          'target_amount': 10000.0,
          'duration_type': 'WEEKLY',
          'icon': '☕',
          'color': '#8B4513',
          'difficulty': 'EASY',
          'badge_reward': 'coffee_master',
        },
        {
          'title': '쇼핑 금지령',
          'description': '이번 주 쇼핑 없이 버티기!',
          'type': 'EXPENSE_LIMIT',
          'target_amount': 0.0,
          'duration_type': 'WEEKLY',
          'icon': '🛍️',
          'color': '#FF1493',
          'difficulty': 'HARD',
          'badge_reward': 'shopping_free',
        },
        {
          'title': '저축왕',
          'description': '이번 달 저축 목표 30만 원 달성하기!',
          'type': 'SAVING_GOAL',
          'target_amount': 300000.0,
          'duration_type': 'MONTHLY',
          'icon': '💰',
          'color': '#FFD700',
          'difficulty': 'NORMAL',
          'badge_reward': 'saving_master',
        },
        {
          'title': '완벽한 기록',
          'description': '일주일 동안 매일 지출 기록하기!',
          'type': 'STREAK',
          'target_amount': 7.0,
          'duration_type': 'WEEKLY',
          'icon': '📝',
          'color': '#4169E1',
          'difficulty': 'EASY',
          'badge_reward': 'record_keeper',
        },
        {
          'title': '외식 절제',
          'description': '이번 주 외식비 5만 원 이하!',
          'type': 'EXPENSE_LIMIT',
          'target_amount': 50000.0,
          'duration_type': 'WEEKLY',
          'icon': '🍽️',
          'color': '#FF6347',
          'difficulty': 'NORMAL',
          'badge_reward': 'dining_saver',
        },
      ];

      for (var template in challengeTemplates) {
        await db.insert('challenge_template', {
          ...template,
          'created_at': now,
        });
      }

      // 기본 뱃지
      final badges = [
        {
          'name': '첫 걸음',
          'description': '첫 챌린지 도전!',
          'icon': '🥉',
          'type': 'BEGINNER',
          'rarity': 'COMMON',
          'unlock_condition': 'FIRST_CHALLENGE',
        },
        {
          'name': '챌린지 정복자',
          'description': '첫 챌린지 성공!',
          'icon': '🥈',
          'type': 'ACHIEVEMENT',
          'rarity': 'RARE',
          'unlock_condition': 'COMPLETE_CHALLENGE',
        },
        {
          'name': '3연속 성공',
          'description': '챌린지 3개 연속 성공!',
          'icon': '🥇',
          'type': 'STREAK',
          'rarity': 'EPIC',
          'unlock_condition': 'COMPLETE_3_STREAK',
        },
        {
          'name': '전설의 절약왕',
          'description': '챌린지 10개 성공!',
          'icon': '💎',
          'type': 'MASTER',
          'rarity': 'LEGENDARY',
          'unlock_condition': 'COMPLETE_10_CHALLENGES',
        },
        {
          'name': '커피 마스터',
          'description': '커피 다이어트 성공!',
          'icon': '☕',
          'type': 'SPECIFIC',
          'rarity': 'RARE',
          'unlock_condition': 'coffee_master',
        },
        {
          'name': '쇼핑 프리',
          'description': '쇼핑 금지령 성공!',
          'icon': '🛍️',
          'type': 'SPECIFIC',
          'rarity': 'EPIC',
          'unlock_condition': 'shopping_free',
        },
        {
          'name': '저축 마스터',
          'description': '저축왕 챌린지 성공!',
          'icon': '💰',
          'type': 'SPECIFIC',
          'rarity': 'EPIC',
          'unlock_condition': 'saving_master',
        },
        {
          'name': '기록의 달인',
          'description': '완벽한 기록 성공!',
          'icon': '📝',
          'type': 'SPECIFIC',
          'rarity': 'RARE',
          'unlock_condition': 'record_keeper',
        },
      ];

      for (var badge in badges) {
        await db.insert('badge', {
          ...badge,
          'created_at': now,
        });
      }

      debugPrint('기본 챌린지 템플릿 추가 완료: ${challengeTemplates.length}개');
      debugPrint('기본 뱃지 추가 완료: ${badges.length}개');
    } catch (e) {
      debugPrint('기본 챌린지 데이터 추가 중 오류: $e');
    }
  }

  // 데이터베이스 리셋 (개발 및 테스트용)
  Future<void> resetDatabase() async {
    final db = await database;

    // 외래 키 제약 조건 일시적으로 비활성화
    await db.execute('PRAGMA foreign_keys = OFF');

    // 모든 테이블 삭제 (외래 키 종속성 순서대로)
    await db.execute('DROP TABLE IF EXISTS asset_valuation_history');
    await db.execute('DROP TABLE IF EXISTS fixed_transaction_setting');
    await db.execute('DROP TABLE IF EXISTS asset');
    await db.execute('DROP TABLE IF EXISTS financial_account');
    await db.execute('DROP TABLE IF EXISTS budget');
    await db.execute('DROP TABLE IF EXISTS transaction_record2');
    await db.execute('DROP TABLE IF EXISTS transaction_record');
    await db.execute('DROP TABLE IF EXISTS category');
    await db.execute('DROP TABLE IF EXISTS user');

    // 외래 키 제약 조건 다시 활성화
    await db.execute('PRAGMA foreign_keys = ON');

    // 테이블 다시 생성
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

    // 변동 거래 내역
    final transactions = await db.query('transaction_record');
    debugPrint("\n변동 거래 내역: ${transactions.length}개");
    for (var transaction in transactions) {
      debugPrint(transaction.toString());
    }

    // 고정 거래 내역
    final transactions2 = await db.query('transaction_record2');
    debugPrint("\n고정 거래 내역: ${transactions2.length}개");
    for (var transaction in transactions2) {
      debugPrint(transaction.toString());
    }

    // 고정 거래 수정 내역
    final transactions3 = await db.query('fixed_transaction_setting');
    debugPrint("\n고정 거래 수정 내역: ${transactions3.length}개");
    for (var transaction in transactions3) {
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