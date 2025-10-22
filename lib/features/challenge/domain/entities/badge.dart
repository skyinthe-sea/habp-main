/// 뱃지 엔티티
class Badge {
  final int? id;
  final String name;
  final String? description;
  final String icon;
  final String type; // BEGINNER, ACHIEVEMENT, STREAK, MASTER, SPECIFIC
  final String rarity; // COMMON, RARE, EPIC, LEGENDARY
  final String? unlockCondition;
  final DateTime createdAt;

  const Badge({
    this.id,
    required this.name,
    this.description,
    required this.icon,
    required this.type,
    required this.rarity,
    this.unlockCondition,
    required this.createdAt,
  });

  /// 희귀도 색상 반환
  String get rarityColor {
    switch (rarity) {
      case 'COMMON':
        return '#9E9E9E'; // 회색
      case 'RARE':
        return '#2196F3'; // 파랑
      case 'EPIC':
        return '#9C27B0'; // 보라
      case 'LEGENDARY':
        return '#FFD700'; // 금색
      default:
        return '#9E9E9E';
    }
  }

  /// 희귀도 텍스트 반환
  String get rarityText {
    switch (rarity) {
      case 'COMMON':
        return '일반';
      case 'RARE':
        return '레어';
      case 'EPIC':
        return '에픽';
      case 'LEGENDARY':
        return '전설';
      default:
        return '일반';
    }
  }
}

/// 사용자가 획득한 뱃지
class UserBadge {
  final int? id;
  final int? userId;
  final int badgeId;
  final Badge badge;
  final DateTime earnedAt;
  final bool isNew;

  const UserBadge({
    this.id,
    this.userId,
    required this.badgeId,
    required this.badge,
    required this.earnedAt,
    this.isNew = true,
  });

  UserBadge copyWith({
    int? id,
    int? userId,
    int? badgeId,
    Badge? badge,
    DateTime? earnedAt,
    bool? isNew,
  }) {
    return UserBadge(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      badgeId: badgeId ?? this.badgeId,
      badge: badge ?? this.badge,
      earnedAt: earnedAt ?? this.earnedAt,
      isNew: isNew ?? this.isNew,
    );
  }
}
