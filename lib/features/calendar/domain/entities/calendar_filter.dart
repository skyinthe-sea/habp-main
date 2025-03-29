class CalendarFilter {
  // 거래 유형 필터 (null일 경우 모든 유형 표시)
  final String? categoryType; // INCOME, EXPENSE, FINANCE 중 하나

  // 선택된 카테고리 ID 리스트 (비어있을 경우 모든 카테고리 표시)
  final List<int> selectedCategoryIds;

  // 필터 이름 (사용자 정의 필터 프리셋을 위한 옵션)
  final String? name;

  const CalendarFilter({
    this.categoryType,
    this.selectedCategoryIds = const [],
    this.name,
  });

  // 필터 없음 (모든 거래 표시)
  static const CalendarFilter all = CalendarFilter(
    name: '전체',
  );

  // 소득 필터
  static const CalendarFilter income = CalendarFilter(
    categoryType: 'INCOME',
    name: '소득',
  );

  // 지출 필터
  static const CalendarFilter expense = CalendarFilter(
    categoryType: 'EXPENSE',
    name: '지출',
  );

  // 금융 필터
  static const CalendarFilter finance = CalendarFilter(
    categoryType: 'FINANCE',
    name: '금융',
  );

  // 복사본 생성 (필터 수정 시 사용)
  CalendarFilter copyWith({
    String? categoryType,
    List<int>? selectedCategoryIds,
    String? name,
  }) {
    return CalendarFilter(
      categoryType: categoryType ?? this.categoryType,
      selectedCategoryIds: selectedCategoryIds ?? this.selectedCategoryIds,
      name: name ?? this.name,
    );
  }
}