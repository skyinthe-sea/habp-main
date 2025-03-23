// lib/features/onboarding/domain/models/expense_category.dart

// 파일명과 클래스 이름을 변경하고 충돌 방지를 위해 이름 변경

enum ExpenseCategoryType {
  INCOME,
  EXPENSE,
  FINANCE,
}

class ExpenseCategory {
  final int? id;
  final String name;
  final ExpenseCategoryType type;
  final bool isFixed;
  final DateTime createdAt;
  final DateTime updatedAt;

  ExpenseCategory({
    this.id,
    required this.name,
    required this.type,
    required this.isFixed,
    required this.createdAt,
    required this.updatedAt,
  });

  // 객체를 Map으로 변환 (DB 저장용)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.toString().split('.').last,
      'is_fixed': isFixed ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Map에서 객체로 변환 (DB 조회용)
  factory ExpenseCategory.fromMap(Map<String, dynamic> map) {
    return ExpenseCategory(
      id: map['id'],
      name: map['name'],
      type: ExpenseCategoryType.values.firstWhere(
            (e) => e.toString().split('.').last == map['type'],
        orElse: () => ExpenseCategoryType.EXPENSE,
      ),
      isFixed: map['is_fixed'] == 1,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  // 업데이트된 객체 생성
  ExpenseCategory copyWith({
    int? id,
    String? name,
    ExpenseCategoryType? type,
    bool? isFixed,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExpenseCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      isFixed: isFixed ?? this.isFixed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}