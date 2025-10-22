/// 챌린지 템플릿 엔티티 (미리 정의된 챌린지)
class ChallengeTemplate {
  final int? id;
  final String title;
  final String? description;
  final String type; // EXPENSE_LIMIT, SAVING_GOAL, STREAK
  final double? targetAmount;
  final int? categoryId;
  final String durationType; // WEEKLY, MONTHLY
  final String? icon;
  final String? color;
  final String? difficulty; // EASY, NORMAL, HARD
  final String? badgeReward;
  final DateTime createdAt;

  const ChallengeTemplate({
    this.id,
    required this.title,
    this.description,
    required this.type,
    this.targetAmount,
    this.categoryId,
    required this.durationType,
    this.icon,
    this.color,
    this.difficulty,
    this.badgeReward,
    required this.createdAt,
  });

  /// 챌린지 기간 (일 수)
  int get durationDays {
    switch (durationType) {
      case 'WEEKLY':
        return 7;
      case 'MONTHLY':
        return 30;
      default:
        return 7;
    }
  }

  /// 난이도 텍스트
  String get difficultyText {
    switch (difficulty) {
      case 'EASY':
        return '쉬움';
      case 'NORMAL':
        return '보통';
      case 'HARD':
        return '어려움';
      default:
        return '보통';
    }
  }

  /// 난이도 색상
  String get difficultyColor {
    switch (difficulty) {
      case 'EASY':
        return '#4CAF50'; // 초록
      case 'NORMAL':
        return '#FF9800'; // 주황
      case 'HARD':
        return '#F44336'; // 빨강
      default:
        return '#FF9800';
    }
  }
}
