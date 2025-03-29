import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/calendar_filter.dart';
import '../../domain/entities/category_item.dart';
import '../../../../core/database/db_helper.dart';

class CalendarFilterController extends GetxController {
  final DBHelper dbHelper;

  // 현재 적용된 필터
  final Rx<CalendarFilter> currentFilter = CalendarFilter.all.obs;

  // 모든 카테고리 목록
  final RxList<CategoryItem> allCategories = <CategoryItem>[].obs;

  // 카테고리 타입별 필터링된 카테고리 목록
  final RxList<CategoryItem> filteredCategories = <CategoryItem>[].obs;

  // 필터 변경 콜백 (캘린더 컨트롤러가 구독)
  final filterChanged = false.obs;

  // 필터 모달 표시 중 여부
  final RxBool isFilterModalVisible = false.obs;

  CalendarFilterController({
    required this.dbHelper,
  });

  @override
  void onInit() {
    super.onInit();
    loadCategories();
    loadSavedFilter();
  }

  // 모든 카테고리 로드
  Future<void> loadCategories() async {
    try {
      final db = await dbHelper.database;

      final List<Map<String, dynamic>> categoriesMap = await db.query(
        'category',
        where: 'is_deleted = ?',
        whereArgs: [0], // 삭제되지 않은 카테고리만
      );

      final categories = categoriesMap.map((map) => CategoryItem(
        id: map['id'],
        name: map['name'],
        type: map['type'],
        isFixed: map['is_fixed'] == 1,
      )).toList();

      allCategories.value = categories;
      _updateFilteredCategories();

    } catch (e) {
      debugPrint('카테고리 로드 오류: $e');
    }
  }

  // 마지막으로 사용된 필터 불러오기
  Future<void> loadSavedFilter() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final categoryType = prefs.getString('filter_categoryType');
      final selectedIds = prefs.getStringList('filter_selectedCategoryIds');
      final filterName = prefs.getString('filter_name');

      // 저장된 필터가 있으면 복원
      if (categoryType != null || (selectedIds != null && selectedIds.isNotEmpty)) {
        currentFilter.value = CalendarFilter(
          categoryType: categoryType,
          selectedCategoryIds: selectedIds?.map((id) => int.parse(id)).toList() ?? [],
          name: filterName,
        );

        filterChanged.toggle(); // 필터 변경 이벤트 발생
        _updateFilteredCategories();
      }
    } catch (e) {
      debugPrint('필터 불러오기 오류: $e');
    }
  }

  // 현재 필터 저장
  Future<void> saveCurrentFilter() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (currentFilter.value.categoryType != null) {
        prefs.setString('filter_categoryType', currentFilter.value.categoryType!);
      } else {
        prefs.remove('filter_categoryType');
      }

      if (currentFilter.value.selectedCategoryIds.isNotEmpty) {
        prefs.setStringList(
          'filter_selectedCategoryIds',
          currentFilter.value.selectedCategoryIds.map((id) => id.toString()).toList(),
        );
      } else {
        prefs.remove('filter_selectedCategoryIds');
      }

      if (currentFilter.value.name != null) {
        prefs.setString('filter_name', currentFilter.value.name!);
      } else {
        prefs.remove('filter_name');
      }
    } catch (e) {
      debugPrint('필터 저장 오류: $e');
    }
  }

  // 현재 필터 변경
  void setFilter(CalendarFilter filter) {
    currentFilter.value = filter;
    _updateFilteredCategories();
    filterChanged.toggle(); // 필터 변경 이벤트 발생
    saveCurrentFilter(); // 변경된 필터 저장
  }

  // 카테고리 타입 변경
  void setCategoryType(String? type) {
    currentFilter.value = currentFilter.value.copyWith(
      categoryType: type,
      selectedCategoryIds: [], // 타입 변경 시 선택된 카테고리 초기화
    );
    _updateFilteredCategories();
  }

  // 카테고리 선택/해제
  void toggleCategory(int categoryId) {
    final selectedIds = List<int>.from(currentFilter.value.selectedCategoryIds);

    if (selectedIds.contains(categoryId)) {
      selectedIds.remove(categoryId);
    } else {
      selectedIds.add(categoryId);
    }

    currentFilter.value = currentFilter.value.copyWith(
      selectedCategoryIds: selectedIds,
    );
  }

  // 필터 적용
  void applyFilter() {
    filterChanged.toggle(); // 필터 변경 이벤트 발생
    saveCurrentFilter(); // 변경된 필터 저장
    isFilterModalVisible.value = false; // 필터 모달 닫기
  }

  // 필터 초기화
  void resetFilter() {
    currentFilter.value = CalendarFilter.all;
    _updateFilteredCategories();
    filterChanged.toggle();
    saveCurrentFilter();
  }

  // 카테고리 타입에 따라 필터링된 카테고리 목록 업데이트
  void _updateFilteredCategories() {
    if (currentFilter.value.categoryType == null) {
      // 모든 카테고리 표시
      filteredCategories.value = allCategories;
    } else {
      // 선택된 타입의 카테고리만 표시
      filteredCategories.value = allCategories
          .where((c) => c.type == currentFilter.value.categoryType)
          .toList();
    }
  }

  // 필터 모달 열기
  void openFilterModal() {
    isFilterModalVisible.value = true;
  }

  // 필터 모달 닫기
  void closeFilterModal() {
    isFilterModalVisible.value = false;
  }

  // 거래가 현재 필터에 맞는지 확인
  bool matchesFilter(String transactionType, int categoryId) {
    // 카테고리 타입 필터
    if (currentFilter.value.categoryType != null &&
        currentFilter.value.categoryType != transactionType) {
      return false;
    }

    // 선택된 카테고리 필터
    if (currentFilter.value.selectedCategoryIds.isNotEmpty &&
        !currentFilter.value.selectedCategoryIds.contains(categoryId)) {
      return false;
    }

    return true;
  }
}