import 'package:get/get.dart';
import '../../domain/entities/monthly_diary.dart';
import '../../domain/repositories/monthly_diary_repository.dart';

/// 다이어리 컨트롤러
class DiaryController extends GetxController {
  final MonthlyDiaryRepository _repository;

  DiaryController(this._repository);

  // 다이어리 목록 (관찰 가능)
  final RxList<MonthlyDiary> diaries = <MonthlyDiary>[].obs;

  // 로딩 상태
  final RxBool isLoading = false.obs;

  // 선택된 연도 (필터링용)
  final RxInt selectedYear = DateTime.now().year.obs;

  @override
  void onInit() {
    super.onInit();
    loadDiaries();
  }

  /// 모든 다이어리 로드
  Future<void> loadDiaries() async {
    try {
      isLoading.value = true;
      final allDiaries = await _repository.getAllDiaries();
      diaries.value = allDiaries;
    } catch (e) {
      Get.snackbar('오류', '다이어리 목록을 불러오는데 실패했습니다: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// 연도별 다이어리 로드
  Future<void> loadDiariesByYear(int year) async {
    try {
      isLoading.value = true;
      selectedYear.value = year;
      final yearDiaries = await _repository.getDiariesByYear(year);
      diaries.value = yearDiaries;
    } catch (e) {
      Get.snackbar('오류', '다이어리를 불러오는데 실패했습니다: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// 특정 월의 다이어리 조회
  Future<MonthlyDiary?> getDiary(int year, int month) async {
    try {
      return await _repository.getDiary(year, month);
    } catch (e) {
      Get.snackbar('오류', '다이어리를 불러오는데 실패했습니다: $e');
      return null;
    }
  }

  /// 다이어리 생성
  Future<void> createDiary(MonthlyDiary diary) async {
    try {
      await _repository.createDiary(diary);
      await loadDiaries();
      Get.snackbar('성공', '다이어리가 생성되었습니다');
    } catch (e) {
      Get.snackbar('오류', '다이어리 생성에 실패했습니다: $e');
    }
  }

  /// 다이어리 업데이트
  Future<void> updateDiary(MonthlyDiary diary) async {
    try {
      await _repository.updateDiary(diary);
      await loadDiaries();
      Get.snackbar('성공', '다이어리가 저장되었습니다');
    } catch (e) {
      Get.snackbar('오류', '다이어리 저장에 실패했습니다: $e');
    }
  }

  /// 다이어리 삭제
  Future<void> deleteDiary(int id) async {
    try {
      await _repository.deleteDiary(id);
      await loadDiaries();
      Get.snackbar('성공', '다이어리가 삭제되었습니다');
    } catch (e) {
      Get.snackbar('오류', '다이어리 삭제에 실패했습니다: $e');
    }
  }

  /// 현재 월의 다이어리 생성 또는 조회
  Future<MonthlyDiary> getOrCreateCurrentMonthDiary() async {
    try {
      final diary = await _repository.getOrCreateCurrentMonthDiary();
      await loadDiaries();
      return diary;
    } catch (e) {
      Get.snackbar('오류', '다이어리를 생성하는데 실패했습니다: $e');
      rethrow;
    }
  }

  /// 연도 목록 가져오기 (다이어리가 있는 연도만)
  List<int> getAvailableYears() {
    final years = diaries.map((diary) => diary.year).toSet().toList();
    years.sort((a, b) => b.compareTo(a)); // 내림차순 정렬
    return years;
  }
}
