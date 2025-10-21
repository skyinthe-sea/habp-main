import '../entities/monthly_diary.dart';

/// 월별 다이어리 저장소 인터페이스
abstract class MonthlyDiaryRepository {
  /// 특정 월의 다이어리 조회
  Future<MonthlyDiary?> getDiary(int year, int month);

  /// 모든 다이어리 조회 (최신순)
  Future<List<MonthlyDiary>> getAllDiaries();

  /// 연도별 다이어리 조회
  Future<List<MonthlyDiary>> getDiariesByYear(int year);

  /// 다이어리 생성
  Future<int> createDiary(MonthlyDiary diary);

  /// 다이어리 업데이트
  Future<void> updateDiary(MonthlyDiary diary);

  /// 다이어리 삭제
  Future<void> deleteDiary(int id);

  /// 특정 월의 다이어리가 존재하는지 확인
  Future<bool> diaryExists(int year, int month);

  /// 현재 월의 다이어리 생성 (없을 경우)
  Future<MonthlyDiary> getOrCreateCurrentMonthDiary();
}
