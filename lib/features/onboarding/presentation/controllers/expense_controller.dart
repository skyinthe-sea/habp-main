// lib/features/onboarding/controllers/expense_controller.dart

import '../../data/models/expense_entry.dart';
import '../../data/repositories/expense_repository.dart';

class ExpenseController {
  final ExpenseRepository _repository = ExpenseRepository();

  // 모든 항목 가져오기
  List<ExpenseEntry> getAllEntries() {
    return _repository.getAllEntries();
  }

  // 항목 추가
  void addEntry(ExpenseEntry entry) {
    _repository.addEntry(entry);
  }

  // 항목 업데이트
  void updateEntry(ExpenseEntry entry) {
    _repository.updateEntry(entry);
  }

  // 항목 삭제
  void deleteEntry(String id) {
    _repository.deleteEntry(id);
  }

  // DB에서 로드
  Future<void> loadData() async {
    await _repository.loadFromDatabase();
  }

  // 사용자 정의 소득 유형 가져오기
  List<String> getCustomIncomeTypes() {
    return _repository.getCustomIncomeTypes();
  }

// 사용자 정의 소득 유형 저장
  Future<void> saveCustomIncomeTypes(List<String> customTypes) async {
    await _repository.saveCustomIncomeTypes(customTypes);
  }
}