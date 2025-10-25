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
      version: 7,  // 버전 7으로 업그레이드 (명언 시스템 추가)
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

    if (oldVersion < 7) {
      // Version 7: 오늘의 명언 시스템 테이블 추가

      // 명언 마스터 테이블 (200개의 명언)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS daily_quote (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          quote_text TEXT NOT NULL,
          author TEXT,
          category TEXT,
          created_at TEXT NOT NULL
        )
      ''');

      // 사용자 명언 조회 기록 테이블
      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_quote_history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER,
          quote_id INTEGER,
          viewed_date TEXT NOT NULL,
          is_collected INTEGER DEFAULT 1,
          created_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES user (id),
          FOREIGN KEY (quote_id) REFERENCES daily_quote (id)
        )
      ''');

      // 사용자 마지막 명언 표시 날짜 테이블
      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_last_quote_date (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER UNIQUE,
          last_shown_date TEXT NOT NULL,
          last_quote_id INTEGER,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES user (id),
          FOREIGN KEY (last_quote_id) REFERENCES daily_quote (id)
        )
      ''');

      debugPrint('데이터베이스 업그레이드 완료: 오늘의 명언 테이블 추가');

      // 200개의 명언 데이터 초기화
      await _initializeQuotes(db);
    }
  }

  /// Initialize 200 financial wisdom quotes
  Future<void> _initializeQuotes(Database db) async {
    final quotes = _getFinancialQuotes();
    final now = DateTime.now().toIso8601String();

    for (var quote in quotes) {
      await db.insert('daily_quote', {
        'quote_text': quote['text'],
        'author': quote['author'],
        'category': quote['category'],
        'created_at': now,
      });
    }

    debugPrint('✅ 200개의 명언 데이터 초기화 완료');
  }

  /// Get 200 curated financial wisdom quotes
  List<Map<String, String>> _getFinancialQuotes() {
    return [
      // 저축과 절약 (40개)
      {'text': '부자가 되는 비결은 많이 버는 것이 아니라, 적게 쓰는 것이다', 'author': '워렌 버핏', 'category': '저축'},
      {'text': '작은 돈도 모으면 큰돈이 된다', 'author': '벤자민 프랭클린', 'category': '저축'},
      {'text': '오늘의 절약이 내일의 여유를 만든다', 'author': '', 'category': '저축'},
      {'text': '커피 한 잔 값도 10년이면 차 한 대 값', 'author': '', 'category': '저축'},
      {'text': '필요와 욕구를 구분하는 것이 현명한 소비의 시작', 'author': '', 'category': '저축'},
      {'text': '지출을 기록하는 습관이 당신의 재산을 지킨다', 'author': '', 'category': '저축'},
      {'text': '한 달에 수입의 10%는 반드시 저축하라', 'author': '바빌론 부자들', 'category': '저축'},
      {'text': '절약은 미덕이 아니라 생존 전략이다', 'author': '', 'category': '저축'},
      {'text': '돈을 아끼는 것은 미래의 나에게 투자하는 것', 'author': '', 'category': '저축'},
      {'text': '작은 새는 작은 둥지로도 충분하다', 'author': '', 'category': '저축'},

      {'text': '절약한 돈은 벌어들인 돈이나 마찬가지다', 'author': '', 'category': '저축'},
      {'text': '오늘 아낀 1만원은 내일의 10만원', 'author': '', 'category': '저축'},
      {'text': '부자는 남는 돈을 쓰고, 가난한 사람은 쓰고 남는 돈을 저축한다', 'author': '워렌 버핏', 'category': '저축'},
      {'text': '충동구매 3초만 참으면 평생 후회 안 합니다', 'author': '', 'category': '저축'},
      {'text': '필요한 것과 원하는 것을 구분하세요', 'author': '', 'category': '저축'},
      {'text': '세일이라고 다 사지 마세요, 안 쓰는 게 가장 큰 세일', 'author': '', 'category': '저축'},
      {'text': '고정비를 줄이면 가계부가 편해진다', 'author': '', 'category': '저축'},
      {'text': '구독 서비스, 정말 다 쓰고 계신가요?', 'author': '', 'category': '저축'},
      {'text': '월급날 가장 먼저 나에게 월급을 주세요', 'author': '', 'category': '저축'},
      {'text': '재테크의 첫걸음은 씀씀이 줄이기', 'author': '', 'category': '저축'},

      {'text': '배달비도 모으면 여행경비가 됩니다', 'author': '', 'category': '저축'},
      {'text': '브랜드 로고를 위해 돈을 쓰지 마세요', 'author': '', 'category': '저축'},
      {'text': '싸다고 사면 결국 비싼 쇼핑', 'author': '', 'category': '저축'},
      {'text': '가격표를 보기 전에 필요성을 생각하세요', 'author': '', 'category': '저축'},
      {'text': '할인쿠폰보다 지출을 줄이는 게 먼저', 'author': '', 'category': '저축'},
      {'text': '가계부를 쓰면 돈이 보인다', 'author': '', 'category': '저축'},
      {'text': '지금 아끼는 작은 돈이 미래의 큰 자산', 'author': '', 'category': '저축'},
      {'text': '편의점보다 마트가, 마트보다 집밥이 경제적', 'author': '', 'category': '저축'},
      {'text': '택시 대신 대중교통, 작은 선택이 큰 차이', 'author': '', 'category': '저축'},
      {'text': '명품 하나보다 미래의 여유가 더 멋지다', 'author': '', 'category': '저축'},

      {'text': '오늘의 절약은 내일의 선택지를 넓혀준다', 'author': '', 'category': '저축'},
      {'text': '돈을 아껴야 돈이 모인다', 'author': '', 'category': '저축'},
      {'text': '부자의 첫 습관은 절약입니다', 'author': '', 'category': '저축'},
      {'text': '지출을 통제할 수 없으면 수입도 의미없다', 'author': '', 'category': '저축'},
      {'text': '작은 돈을 무시하면 큰돈도 모을 수 없다', 'author': '', 'category': '저축'},
      {'text': '매일 천원씩이면 1년에 36만원', 'author': '', 'category': '저축'},
      {'text': '지출 습관이 당신의 미래를 결정한다', 'author': '', 'category': '저축'},
      {'text': '카드보다 현금, 눈에 보여야 아낄 수 있다', 'author': '', 'category': '저축'},
      {'text': '욕망을 통제하는 자가 돈을 통제한다', 'author': '', 'category': '저축'},
      {'text': '알뜰한 소비가 부자의 시작', 'author': '', 'category': '저축'},

      // 투자와 재테크 (40개)
      {'text': '돈을 위해 일하지 말고, 돈이 당신을 위해 일하게 하라', 'author': '로버트 기요사키', 'category': '투자'},
      {'text': '가장 좋은 투자는 자기 자신에게 하는 투자다', 'author': '워렌 버핏', 'category': '투자'},
      {'text': '시간은 훌륭한 투자자의 친구이다', 'author': '워렌 버핏', 'category': '투자'},
      {'text': '계란을 한 바구니에 담지 마라', 'author': '전통 속담', 'category': '투자'},
      {'text': '투자의 핵심은 인내심이다', 'author': '', 'category': '투자'},
      {'text': '복리의 마법을 믿어라', 'author': '알버트 아인슈타인', 'category': '투자'},
      {'text': '오늘 심은 씨앗이 내일의 숲이 된다', 'author': '', 'category': '투자'},
      {'text': '모르는 것에 투자하지 마라', 'author': '피터 린치', 'category': '투자'},
      {'text': '시장을 이기려 하지 말고 시장과 함께 가라', 'author': '', 'category': '투자'},
      {'text': '장기 투자가 가장 안전한 투자', 'author': '', 'category': '투자'},

      {'text': '주식은 10년 가졌을 때 의미가 있다', 'author': '', 'category': '투자'},
      {'text': '리스크를 이해하고 관리하는 것이 투자', 'author': '', 'category': '투자'},
      {'text': '변동성은 위험이 아니라 기회다', 'author': '', 'category': '투자'},
      {'text': '투자 원칙을 지키는 것이 수익을 지킨다', 'author': '', 'category': '투자'},
      {'text': '감정이 아닌 데이터로 투자하라', 'author': '', 'category': '투자'},
      {'text': '시장이 두려울 때가 기회다', 'author': '', 'category': '투자'},
      {'text': '남이 탐욕적일 때 두려워하고, 남이 두려워할 때 탐욕적이 되라', 'author': '워렌 버핏', 'category': '투자'},
      {'text': '분산투자는 무지에 대한 보호책', 'author': '', 'category': '투자'},
      {'text': '투자 수익률보다 중요한 것은 원금 보존', 'author': '', 'category': '투자'},
      {'text': '천천히 부자가 되려는 사람은 없지만, 빨리 가난해지는 사람은 많다', 'author': '', 'category': '투자'},

      {'text': '재테크는 마라톤, 단거리 달리기가 아니다', 'author': '', 'category': '투자'},
      {'text': '수익보다 손실 방지가 먼저', 'author': '', 'category': '투자'},
      {'text': '투자 전에 목표를 정하라', 'author': '', 'category': '투자'},
      {'text': '부동산은 위치, 주식은 기업', 'author': '', 'category': '투자'},
      {'text': '경제 공부가 최고의 재테크', 'author': '', 'category': '투자'},
      {'text': '금융문맹은 현대의 무기가 아니다', 'author': '', 'category': '투자'},
      {'text': '자산배분이 수익의 90%를 결정한다', 'author': '', 'category': '투자'},
      {'text': '싸게 사서 비싸게 팔아라', 'author': '', 'category': '투자'},
      {'text': '시장을 예측하지 말고 대응하라', 'author': '', 'category': '투자'},
      {'text': '투자는 지식에서 시작된다', 'author': '', 'category': '투자'},

      {'text': '원금을 잃지 않는 것이 첫 번째 규칙', 'author': '', 'category': '투자'},
      {'text': '고수익에는 항상 고위험이 따른다', 'author': '', 'category': '투자'},
      {'text': '재테크 공부에 투자한 시간은 배신하지 않는다', 'author': '', 'category': '투자'},
      {'text': '빚내서 투자하지 마라', 'author': '', 'category': '투자'},
      {'text': '투자도 연습이 필요하다', 'author': '', 'category': '투자'},
      {'text': '배당주는 월급쟁이의 친구', 'author': '', 'category': '투자'},
      {'text': '물가상승률을 이기는 것이 진짜 수익', 'author': '', 'category': '투자'},
      {'text': '복리는 세상에서 가장 강력한 힘', 'author': '', 'category': '투자'},
      {'text': '손절매도 투자 전략이다', 'author': '', 'category': '투자'},
      {'text': '투자는 확률게임, 리스크를 관리하라', 'author': '', 'category': '투자'},

      // 목표와 계획 (40개)
      {'text': '목표가 없는 배는 어디로 가든 순풍이다', 'author': '', 'category': '목표'},
      {'text': '계획 없는 소비는 후회로 돌아온다', 'author': '', 'category': '목표'},
      {'text': '목표를 적으면 실현 가능성이 10배 높아진다', 'author': '', 'category': '목표'},
      {'text': '재정 목표가 명확해야 방향이 보인다', 'author': '', 'category': '목표'},
      {'text': '5년 후를 위해 오늘 계획하라', 'author': '', 'category': '목표'},
      {'text': '꿈은 목표가 있는 계획이다', 'author': '', 'category': '목표'},
      {'text': '작은 목표부터 달성하며 나아가라', 'author': '', 'category': '목표'},
      {'text': '구체적인 목표가 실천을 만든다', 'author': '', 'category': '목표'},
      {'text': '재정 독립은 하루아침에 이루어지지 않는다', 'author': '', 'category': '목표'},
      {'text': '매달 목표 지출을 정하고 지켜라', 'author': '', 'category': '목표'},

      {'text': '지출 계획 없이는 저축도 없다', 'author': '', 'category': '목표'},
      {'text': '가계부는 목표 달성의 지도', 'author': '', 'category': '목표'},
      {'text': '단기 목표와 장기 목표를 함께 세워라', 'author': '', 'category': '목표'},
      {'text': '경제적 자유는 목표가 아니라 과정', 'author': '', 'category': '목표'},
      {'text': '매월 수입과 지출을 점검하라', 'author': '', 'category': '목표'},
      {'text': '목표 없는 저축은 통장에 갇힌 돈', 'author': '', 'category': '목표'},
      {'text': '올해의 재정 목표를 적어보세요', 'author': '', 'category': '목표'},
      {'text': '구체적이고 측정 가능한 목표를 세우세요', 'author': '', 'category': '목표'},
      {'text': '계획대로 안 되면 계획을 수정하라', 'author': '', 'category': '목표'},
      {'text': '돈의 쓰임을 정하면 관리가 쉬워진다', 'author': '', 'category': '목표'},

      {'text': '비상금 목표부터 달성하세요', 'author': '', 'category': '목표'},
      {'text': '월급의 50%는 고정지출, 30%는 변동지출, 20%는 저축', 'author': '', 'category': '목표'},
      {'text': '목표를 달성할 때마다 자신을 칭찬하라', 'author': '', 'category': '목표'},
      {'text': '재무 목표는 인생 목표와 연결되어야 한다', 'author': '', 'category': '목표'},
      {'text': '매년 순자산을 체크하라', 'author': '', 'category': '목표'},
      {'text': '은퇴 계획은 일찍 시작할수록 좋다', 'author': '', 'category': '목표'},
      {'text': '내년의 나를 위해 오늘 계획하라', 'author': '', 'category': '목표'},
      {'text': '재정 목표는 현실적이어야 한다', 'author': '', 'category': '목표'},
      {'text': '목표 달성을 시각화하면 실현된다', 'author': '', 'category': '목표'},
      {'text': '매달 예산을 세우고 점검하라', 'author': '', 'category': '목표'},

      {'text': '작은 성취가 모여 큰 목표가 된다', 'author': '', 'category': '목표'},
      {'text': '재정 계획 없이 부자가 된 사람은 없다', 'author': '', 'category': '목표'},
      {'text': '목표를 가족과 공유하면 동기부여가 된다', 'author': '', 'category': '목표'},
      {'text': '올해의 재무 목표를 점검할 시간', 'author': '', 'category': '목표'},
      {'text': '계획은 언제나 조정 가능하다', 'author': '', 'category': '목표'},
      {'text': '목표를 쪼개면 실천이 쉬워진다', 'author': '', 'category': '목표'},
      {'text': '재정 건강도 건강검진처럼 주기적 점검이 필요', 'author': '', 'category': '목표'},
      {'text': '지출 목표를 정하면 낭비가 줄어든다', 'author': '', 'category': '목표'},
      {'text': '매주 재정 상태를 확인하는 습관', 'author': '', 'category': '목표'},
      {'text': '목표는 동기부여의 원천', 'author': '', 'category': '목표'},

      // 습관과 마인드 (40개)
      {'text': '부자가 되는 것은 습관의 문제다', 'author': '', 'category': '습관'},
      {'text': '작은 습관이 큰 부를 만든다', 'author': '', 'category': '습관'},
      {'text': '매일 가계부 쓰는 습관이 재산을 지킨다', 'author': '', 'category': '습관'},
      {'text': '돈 관리는 의지가 아니라 시스템', 'author': '', 'category': '습관'},
      {'text': '좋은 습관은 복리로 작용한다', 'author': '', 'category': '습관'},
      {'text': '지출을 기록하는 순간 통제가 시작된다', 'author': '', 'category': '습관'},
      {'text': '아침에 일어나자마자 지출을 점검하세요', 'author': '', 'category': '습관'},
      {'text': '매일 조금씩이 1년이면 큰 차이', 'author': '', 'category': '습관'},
      {'text': '소비 전 3초만 생각하는 습관', 'author': '', 'category': '습관'},
      {'text': '부자의 습관을 배우고 따라하라', 'author': '', 'category': '습관'},

      {'text': '돈을 대하는 태도가 인생을 바꾼다', 'author': '', 'category': '습관'},
      {'text': '감사하는 마음이 풍요를 부른다', 'author': '', 'category': '습관'},
      {'text': '지금 가진 것에 만족하며 미래를 준비하라', 'author': '', 'category': '습관'},
      {'text': '비교하지 말고 자신의 속도로 가라', 'author': '', 'category': '습관'},
      {'text': '돈보다 중요한 것은 건강과 관계', 'author': '', 'category': '습관'},
      {'text': '행복은 돈으로 살 수 없지만 선택지를 준다', 'author': '', 'category': '습관'},
      {'text': '부자처럼 생각하고 행동하라', 'author': '', 'category': '습관'},
      {'text': '적게 쓰는 습관이 많이 버는 것보다 중요', 'author': '', 'category': '습관'},
      {'text': '돈 걱정 없는 삶을 위해 오늘 노력하라', 'author': '', 'category': '습관'},
      {'text': '재테크도 꾸준함이 답이다', 'author': '', 'category': '습관'},

      {'text': '하루 10분 재정 점검의 힘', 'author': '', 'category': '습관'},
      {'text': '작은 사치가 큰 빚이 된다', 'author': '', 'category': '습관'},
      {'text': '부자는 시간을 소중히 여긴다', 'author': '', 'category': '습관'},
      {'text': '인내심이 부를 만든다', 'author': '', 'category': '습관'},
      {'text': '매일 조금씩 발전하는 재정 습관', 'author': '', 'category': '습관'},
      {'text': '돈 쓰는 습관을 관찰하라', 'author': '', 'category': '습관'},
      {'text': '충동을 통제하는 능력이 부의 차이', 'author': '', 'category': '습관'},
      {'text': '부자의 마인드는 배울 수 있다', 'author': '', 'category': '습관'},
      {'text': '돈에 대한 스트레스는 관리로 줄어든다', 'author': '', 'category': '습관'},
      {'text': '재정 건강은 습관에서 시작된다', 'author': '', 'category': '습관'},

      {'text': '돈을 존중하면 돈도 당신을 존중한다', 'author': '', 'category': '습관'},
      {'text': '가계부는 거짓말을 하지 않는다', 'author': '', 'category': '습관'},
      {'text': '돈 관리는 자기 관리의 일부', 'author': '', 'category': '습관'},
      {'text': '부자는 욕망을 조절할 줄 안다', 'author': '', 'category': '습관'},
      {'text': '매일 감사일기와 함께 가계부를', 'author': '', 'category': '습관'},
      {'text': '작은 변화가 큰 결과를 만든다', 'author': '', 'category': '습관'},
      {'text': '돈 버는 것보다 지키는 것이 더 어렵다', 'author': '', 'category': '습관'},
      {'text': '일상의 선택이 재정을 결정한다', 'author': '', 'category': '습관'},
      {'text': '절약은 짠돌이가 아니라 현명함', 'author': '', 'category': '습관'},
      {'text': '오늘의 선택이 10년 후를 만든다', 'author': '', 'category': '습관'},

      // 빚과 신용 (20개)
      {'text': '빚은 미래의 수입을 미리 쓰는 것', 'author': '', 'category': '빚'},
      {'text': '이자는 복리로 늘어난다', 'author': '', 'category': '빚'},
      {'text': '빚 청산이 최고의 투자', 'author': '', 'category': '빚'},
      {'text': '신용카드는 도구지 돈이 아니다', 'author': '', 'category': '빚'},
      {'text': '할부는 당장은 편하지만 결국 비싸다', 'author': '', 'category': '빚'},
      {'text': '대출 전에 세 번 생각하라', 'author': '', 'category': '빚'},
      {'text': '좋은 빚과 나쁜 빚을 구분하라', 'author': '', 'category': '빚'},
      {'text': '신용점수는 재정 건강의 지표', 'author': '', 'category': '빚'},
      {'text': '빚 없는 삶이 진정한 자유', 'author': '', 'category': '빚'},
      {'text': '이자보다 원금부터 갚아라', 'author': '', 'category': '빚'},

      {'text': '빚은 눈덩이처럼 불어난다', 'author': '', 'category': '빚'},
      {'text': '카드 돌려막기는 파산의 지름길', 'author': '', 'category': '빚'},
      {'text': '고금리 대출부터 상환하라', 'author': '', 'category': '빚'},
      {'text': '빚을 내서 투자하지 마라', 'author': '', 'category': '빚'},
      {'text': '신용불량은 인생불량', 'author': '', 'category': '빚'},
      {'text': '빚 청산 계획을 세우고 실천하라', 'author': '', 'category': '빚'},
      {'text': '최소 납입금만 내면 평생 빚쟁이', 'author': '', 'category': '빚'},
      {'text': '신용은 한 번 잃으면 회복이 어렵다', 'author': '', 'category': '빚'},
      {'text': '필요 없는 카드는 해지하라', 'author': '', 'category': '빚'},
      {'text': '빚 없는 통장이 최고의 재산', 'author': '', 'category': '빚'},

      // 경제 지식 (20개)
      {'text': '인플레이션은 침묵의 도둑', 'author': '', 'category': '지식'},
      {'text': '금리를 이해하면 경제가 보인다', 'author': '', 'category': '지식'},
      {'text': '세금도 재정 계획의 일부', 'author': '', 'category': '지식'},
      {'text': '경제 뉴스를 읽는 습관을 들여라', 'author': '', 'category': '지식'},
      {'text': '복리 계산법을 이해하라', 'author': '', 'category': '지식'},
      {'text': '환율 변동도 투자 기회', 'author': '', 'category': '지식'},
      {'text': '국내 경제와 세계 경제는 연결되어 있다', 'author': '', 'category': '지식'},
      {'text': '경제 공부는 평생 자산', 'author': '', 'category': '지식'},
      {'text': '기본적인 금융 용어부터 배우라', 'author': '', 'category': '지식'},
      {'text': '투자 전에 반드시 공부하라', 'author': '', 'category': '지식'},

      {'text': '재무제표를 읽을 줄 알아야 투자할 수 있다', 'author': '', 'category': '지식'},
      {'text': '세금 절약도 수익이다', 'author': '', 'category': '지식'},
      {'text': '연금 시스템을 이해하라', 'author': '', 'category': '지식'},
      {'text': '보험은 필요한 만큼만', 'author': '', 'category': '지식'},
      {'text': '금융사기는 공부로 예방한다', 'author': '', 'category': '지식'},
      {'text': '경제 지표를 읽는 법을 배워라', 'author': '', 'category': '지식'},
      {'text': '재테크 책 한 권이 수백만원의 가치', 'author': '', 'category': '지식'},
      {'text': '금융 문맹에서 벗어나라', 'author': '', 'category': '지식'},
      {'text': '경제 상식이 부를 만든다', 'author': '', 'category': '지식'},
      {'text': '모르는 상품에 투자하지 마라', 'author': '', 'category': '지식'},
    ];
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