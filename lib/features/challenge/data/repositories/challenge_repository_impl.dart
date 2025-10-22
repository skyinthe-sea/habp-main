import '../../domain/entities/user_challenge.dart';
import '../../domain/entities/challenge_template.dart';
import '../../domain/entities/badge.dart';
import '../../domain/repositories/challenge_repository.dart';
import '../datasources/challenge_local_data_source.dart';
import '../models/user_challenge_model.dart';

class ChallengeRepositoryImpl implements ChallengeRepository {
  final ChallengeLocalDataSource _localDataSource;
  final int _userId;

  ChallengeRepositoryImpl(this._localDataSource, this._userId);

  @override
  Future<List<ChallengeTemplate>> getAllTemplates() async {
    // 템플릿 기능은 현재 사용하지 않음 (사용자 직접 생성)
    return [];
  }

  @override
  Future<ChallengeTemplate?> getTemplate(int id) async {
    return null;
  }

  @override
  Future<List<UserChallenge>> getUserChallenges({String? status}) async {
    final models = await _localDataSource.getUserChallenges(status: status);
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<UserChallenge?> getUserChallenge(int id) async {
    final model = await _localDataSource.getUserChallenge(id);
    return model?.toEntity();
  }

  @override
  Future<int> createChallenge(UserChallenge challenge) async {
    final model = UserChallengeModel.fromEntity(challenge);
    return await _localDataSource.createChallenge(model);
  }

  @override
  Future<void> updateChallenge(UserChallenge challenge) async {
    final model = UserChallengeModel.fromEntity(challenge);
    await _localDataSource.updateChallenge(model);
  }

  @override
  Future<void> deleteChallenge(int id) async {
    await _localDataSource.deleteChallenge(id);
  }

  @override
  Future<void> completeChallenge(int id) async {
    await _localDataSource.completeChallenge(id);
  }

  @override
  Future<void> failChallenge(int id) async {
    await _localDataSource.failChallenge(id);
  }

  @override
  Future<void> updateChallengeProgress(int id, double currentAmount, double progress) async {
    await _localDataSource.updateProgress(id, currentAmount, progress);
  }

  @override
  Future<void> markResultAsViewed(int id) async {
    await _localDataSource.markResultAsViewed(id);
  }

  @override
  Future<int> getCompletedChallengesCount() async {
    return await _localDataSource.getCompletedCount();
  }

  @override
  Future<int> getStreakCount() async {
    return await _localDataSource.getStreakCount();
  }

  @override
  Future<double> getSuccessRate() async {
    return await _localDataSource.getSuccessRate();
  }

  @override
  Future<void> updateChallengeStatuses() async {
    final challenges = await getUserChallenges(status: 'IN_PROGRESS');
    final now = DateTime.now();

    for (var challenge in challenges) {
      // 종료일이 지났는지 확인
      if (now.isAfter(challenge.endDate)) {
        // 성공 여부 판단
        if (challenge.isSuccess) {
          await completeChallenge(challenge.id!);
        } else {
          await failChallenge(challenge.id!);
        }
      } else if (challenge.categoryId != null) {
        // 진행 중이면 현재 금액 업데이트 (카테고리가 있는 경우만)
        final currentAmount = await _localDataSource.getCategoryExpense(
          challenge.categoryId!,
          challenge.startDate,
          now,
        );

        double progress = 0.0;
        if (challenge.type == 'EXPENSE_LIMIT') {
          progress = currentAmount / challenge.targetAmount;
          if (progress > 1.0) progress = 1.0;
        } else if (challenge.type == 'SAVING_GOAL') {
          progress = currentAmount / challenge.targetAmount;
          if (progress > 1.0) progress = 1.0;
        }

        await updateChallengeProgress(challenge.id!, currentAmount, progress);

        // 실시간으로 목표 달성/초과 체크
        final updatedChallenge = challenge.copyWith(
          currentAmount: currentAmount,
          progress: progress,
        );

        // 지출 제한 챌린지: 목표 금액 초과 시 즉시 실패 처리
        if (updatedChallenge.type == 'EXPENSE_LIMIT' && currentAmount > updatedChallenge.targetAmount) {
          await failChallenge(challenge.id!);
        }
        // 저축 목표 챌린지: 목표 금액 달성 시 즉시 성공 처리
        else if (updatedChallenge.type == 'SAVING_GOAL' && currentAmount >= updatedChallenge.targetAmount) {
          await completeChallenge(challenge.id!);
        }
      }
    }
  }

  @override
  Future<List<Badge>> getAllBadges() async {
    // 뱃지 기능은 1차 버전에서 생략
    return [];
  }

  @override
  Future<List<UserBadge>> getUserBadges() async {
    return [];
  }

  @override
  Future<void> awardBadge(int badgeId) async {
    // 1차 버전에서 생략
  }

  @override
  Future<void> markBadgeAsViewed(int userBadgeId) async {
    // 1차 버전에서 생략
  }
}
