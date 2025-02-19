// lib/features/onboarding/domain/repositories/onboarding_repository.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/fixed_income_data.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return OnboardingRepository();
});

class OnboardingRepository {
  // DB에 고정 소득 데이터 저장
  Future<void> saveFixedIncome(FixedIncomeData data) async {
    try {
      // 여기서 ref.read(sqfliteProvider)를 사용하여 DB에 저장
      // 예시:
      // final db = await ref.read(sqfliteProvider);
      // await db.insert('fixed_income', data.toMap());
    } catch (e) {
      throw Exception('Failed to save fixed income data: $e');
    }
  }

  // DB에서 고정 소득 데이터 조회
  Future<List<FixedIncomeData>> getFixedIncomes() async {
    try {
      // 여기서 ref.read(sqfliteProvider)를 사용하여 DB에서 조회
      // 예시:
      // final db = await ref.read(sqfliteProvider);
      // final List<Map<String, dynamic>> maps = await db.query('fixed_income');
      // return List.generate(maps.length, (i) => FixedIncomeData.fromMap(maps[i]));
      return []; // 임시 반환값
    } catch (e) {
      throw Exception('Failed to get fixed income data: $e');
    }
  }

  // DB 테이블 생성 쿼리
  static const String createTableQuery = '''
    CREATE TABLE IF NOT EXISTS fixed_income (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      type TEXT NOT NULL,
      cycle TEXT NOT NULL,
      day TEXT NOT NULL,
      amount INTEGER NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
  ''';

  // 선택 가능한 소득 종류 목록
  static const List<String> incomeTypes = [
    '월급',
    '용돈',
    '연금',
    '이자수입',
    '임대수입',
    '기타',
  ];

  // 선택 가능한 주기 목록
  static const List<String> cycles = [
    '매월',
    '매주',
    '격주',
    '분기',
    '반기',
    '매년',
  ];

  // 선택 가능한 일자 목록 생성
  List<String> getDays() {
    return List.generate(31, (index) => '${index + 1}일');
  }
}