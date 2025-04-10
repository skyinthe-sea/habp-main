// lib/features/onboarding/data/expense_repository.dart

// 실제 구현에서는 Shared Preferences, SQLite, Hive 등의 로컬 저장소 또는
// Firebase, REST API 등의 원격 저장소를 사용할 수 있습니다.
// 현재는 메모리 내 임시 저장소로 구현합니다.

import '../models/expense_entry.dart';

class ExpenseRepository {
  // 싱글톤 패턴 구현
  static final ExpenseRepository _instance = ExpenseRepository._internal();

  factory ExpenseRepository() {
    return _instance;
  }

  ExpenseRepository._internal();

  // 임시 데이터 저장소
  final List<ExpenseEntry> _entries = [];

  // 모든 항목 가져오기
  List<ExpenseEntry> getAllEntries() {
    return List.unmodifiable(_entries);
  }

  // 항목 추가
  void addEntry(ExpenseEntry entry) {
    _entries.add(entry);

    // 실제 구현에서는 여기서 DB에 저장
    _saveToDatabase();
  }

  // 항목 업데이트
  void updateEntry(ExpenseEntry updatedEntry) {
    final index = _entries.indexWhere((e) => e.id == updatedEntry.id);
    if (index != -1) {
      _entries[index] = updatedEntry;

      // 실제 구현에서는 여기서 DB에 저장
      _saveToDatabase();
    }
  }

  // 항목 삭제
  void deleteEntry(String id) {
    _entries.removeWhere((e) => e.id == id);

    // 실제 구현에서는 여기서 DB에서 삭제
    _saveToDatabase();
  }

  // 데이터베이스 저장 (실제 구현에서 사용)
  void _saveToDatabase() {
    // 여기에 실제 DB 저장 로직 구현
    // 예: SharedPreferences, SQLite, Firebase 등

    // 예시 코드:
    // final prefs = await SharedPreferences.getInstance();
    // final jsonList = _entries.map((e) => jsonEncode(e.toJson())).toList();
    // await prefs.setStringList('expense_entries', jsonList);

    print('DB에 저장됨: ${_entries.length}개 항목');
  }

  // 데이터베이스에서 로드 (실제 구현에서 사용)
  Future<void> loadFromDatabase() async {
    // 여기에 실제 DB 로드 로직 구현

    // 예시 코드:
    // final prefs = await SharedPreferences.getInstance();
    // final jsonList = prefs.getStringList('expense_entries') ?? [];
    // _entries.clear();
    // _entries.addAll(
    //   jsonList.map((json) => ExpenseEntry.fromJson(jsonDecode(json))).toList()
    // );

    print('DB에서 로드됨: ${_entries.length}개 항목');
  }

  // 사용자 정의 소득 유형 목록 가져오기
  List<String> getCustomIncomeTypes() {
    // 실제 구현에서는 저장소에서 로드
    // 예시: SharedPreferences에서 문자열 리스트 로드
    // final prefs = await SharedPreferences.getInstance();
    // return prefs.getStringList('custom_income_types') ?? [];

    // 현재 엔트리에서 기본 유형 외의 소득 유형 필터링
    final defaultTypes = ['월급', '용돈', '이자', '기타'];
    return _entries
        .map((e) => e.incomeType)
        .where((type) => !defaultTypes.contains(type))
        .toSet()
        .toList();
  }

// 사용자 정의 소득 유형 저장
  Future<void> saveCustomIncomeTypes(List<String> customTypes) async {
    // 실제 구현에서는 저장소에 저장
    // 예시: SharedPreferences에 문자열 리스트 저장
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.setStringList('custom_income_types', customTypes);

    print('사용자 정의 소득 유형 저장됨: $customTypes');
  }
}