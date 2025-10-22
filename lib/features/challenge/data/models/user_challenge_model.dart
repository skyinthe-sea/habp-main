import '../../domain/entities/user_challenge.dart';

class UserChallengeModel extends UserChallenge {
  const UserChallengeModel({
    super.id,
    super.userId,
    super.templateId,
    required super.title,
    super.description,
    required super.type,
    required super.targetAmount,
    super.currentAmount,
    super.categoryId,
    required super.startDate,
    required super.endDate,
    super.status,
    super.progress,
    required super.createdAt,
    required super.updatedAt,
    super.completedAt,
  });

  factory UserChallengeModel.fromEntity(UserChallenge entity) {
    return UserChallengeModel(
      id: entity.id,
      userId: entity.userId,
      templateId: entity.templateId,
      title: entity.title,
      description: entity.description,
      type: entity.type,
      targetAmount: entity.targetAmount,
      currentAmount: entity.currentAmount,
      categoryId: entity.categoryId,
      startDate: entity.startDate,
      endDate: entity.endDate,
      status: entity.status,
      progress: entity.progress,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      completedAt: entity.completedAt,
    );
  }

  factory UserChallengeModel.fromMap(Map<String, dynamic> map) {
    return UserChallengeModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int?,
      templateId: map['template_id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String?,
      type: map['type'] as String,
      targetAmount: (map['target_amount'] as num).toDouble(),
      currentAmount: (map['current_amount'] as num?)?.toDouble() ?? 0.0,
      categoryId: map['category_id'] as int?,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: DateTime.parse(map['end_date'] as String),
      status: map['status'] as String,
      progress: (map['progress'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (templateId != null) 'template_id': templateId,
      'title': title,
      'description': description,
      'type': type,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      if (categoryId != null) 'category_id': categoryId,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'status': status,
      'progress': progress,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (completedAt != null) 'completed_at': completedAt!.toIso8601String(),
    };
  }

  UserChallenge toEntity() {
    return UserChallenge(
      id: id,
      userId: userId,
      templateId: templateId,
      title: title,
      description: description,
      type: type,
      targetAmount: targetAmount,
      currentAmount: currentAmount,
      categoryId: categoryId,
      startDate: startDate,
      endDate: endDate,
      status: status,
      progress: progress,
      createdAt: createdAt,
      updatedAt: updatedAt,
      completedAt: completedAt,
    );
  }
}
