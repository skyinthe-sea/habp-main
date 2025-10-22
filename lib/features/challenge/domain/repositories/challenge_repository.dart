import '../entities/user_challenge.dart';
import '../entities/challenge_template.dart';
import '../entities/badge.dart';

/// 챌린지 저장소 인터페이스
abstract class ChallengeRepository {
  // 챌린지 템플릿
  Future<List<ChallengeTemplate>> getAllTemplates();
  Future<ChallengeTemplate?> getTemplate(int id);

  // 사용자 챌린지
  Future<List<UserChallenge>> getUserChallenges({String? status});
  Future<UserChallenge?> getUserChallenge(int id);
  Future<int> createChallenge(UserChallenge challenge);
  Future<void> updateChallenge(UserChallenge challenge);
  Future<void> deleteChallenge(int id);
  Future<void> completeChallenge(int id);
  Future<void> failChallenge(int id);

  // 챌린지 진행률 업데이트
  Future<void> updateChallengeProgress(int id, double currentAmount, double progress);

  // 통계
  Future<int> getCompletedChallengesCount();
  Future<int> getStreakCount(); // 연속 성공 횟수
  Future<double> getSuccessRate(); // 성공률

  // 뱃지
  Future<List<Badge>> getAllBadges();
  Future<List<UserBadge>> getUserBadges();
  Future<void> awardBadge(int badgeId);
  Future<void> markBadgeAsViewed(int userBadgeId);

  // 챌린지 자동 업데이트 (매일 호출)
  Future<void> updateChallengeStatuses();
}
