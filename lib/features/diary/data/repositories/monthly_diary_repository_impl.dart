import '../../domain/entities/monthly_diary.dart';
import '../../domain/repositories/monthly_diary_repository.dart';
import '../datasources/monthly_diary_local_data_source.dart';
import '../models/monthly_diary_model.dart';

/// 월별 다이어리 저장소 구현
class MonthlyDiaryRepositoryImpl implements MonthlyDiaryRepository {
  final MonthlyDiaryLocalDataSource _localDataSource;
  final int _userId; // 현재 사용자 ID

  MonthlyDiaryRepositoryImpl(this._localDataSource, this._userId);

  @override
  Future<MonthlyDiary?> getDiary(int year, int month) async {
    final model = await _localDataSource.getDiary(year, month);
    return model?.toEntity();
  }

  @override
  Future<List<MonthlyDiary>> getAllDiaries() async {
    final models = await _localDataSource.getAllDiaries();
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<List<MonthlyDiary>> getDiariesByYear(int year) async {
    final models = await _localDataSource.getDiariesByYear(year);
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<int> createDiary(MonthlyDiary diary) async {
    final model = MonthlyDiaryModel.fromEntity(diary);
    return await _localDataSource.createDiary(model);
  }

  @override
  Future<void> updateDiary(MonthlyDiary diary) async {
    final model = MonthlyDiaryModel.fromEntity(diary);
    await _localDataSource.updateDiary(model);
  }

  @override
  Future<void> deleteDiary(int id) async {
    await _localDataSource.deleteDiary(id);
  }

  @override
  Future<bool> diaryExists(int year, int month) async {
    return await _localDataSource.diaryExists(year, month);
  }

  @override
  Future<MonthlyDiary> getOrCreateCurrentMonthDiary() async {
    final model = await _localDataSource.getOrCreateCurrentMonthDiary(_userId);
    return model.toEntity();
  }
}
