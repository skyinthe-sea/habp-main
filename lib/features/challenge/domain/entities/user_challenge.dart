/// 사용자 챌린지 엔티티
class UserChallenge {
  final int? id;
  final int? userId;
  final int? templateId;
  final String title;
  final String? description;
  final String type; // EXPENSE_LIMIT, SAVING_GOAL, STREAK
  final double targetAmount;
  final double currentAmount;
  final int? categoryId;
  final DateTime startDate;
  final DateTime endDate;
  final String status; // IN_PROGRESS, COMPLETED, FAILED
  final double progress; // 0.0 ~ 1.0
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  const UserChallenge({
    this.id,
    this.userId,
    this.templateId,
    required this.title,
    this.description,
    required this.type,
    required this.targetAmount,
    this.currentAmount = 0.0,
    this.categoryId,
    required this.startDate,
    required this.endDate,
    this.status = 'IN_PROGRESS',
    this.progress = 0.0,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });

  /// 챌린지가 진행 중인지
  bool get isInProgress => status == 'IN_PROGRESS';

  /// 챌린지가 완료되었는지
  bool get isCompleted => status == 'COMPLETED';

  /// 챌린지가 실패했는지
  bool get isFailed => status == 'FAILED';

  /// 챌린지 종료까지 남은 일수
  int get daysRemaining {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return 0;
    return endDate.difference(now).inDays;
  }

  /// 진행률 백분율 (0-100)
  double get progressPercentage => progress * 100;

  /// 챌린지 성공 여부 확인
  bool get isSuccess {
    if (type == 'EXPENSE_LIMIT') {
      return currentAmount <= targetAmount;
    } else if (type == 'SAVING_GOAL') {
      return currentAmount >= targetAmount;
    } else if (type == 'STREAK') {
      return currentAmount >= targetAmount;
    }
    return false;
  }

  UserChallenge copyWith({
    int? id,
    int? userId,
    int? templateId,
    String? title,
    String? description,
    String? type,
    double? targetAmount,
    double? currentAmount,
    int? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    double? progress,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
  }) {
    return UserChallenge(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      templateId: templateId ?? this.templateId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      categoryId: categoryId ?? this.categoryId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
