import 'package:get/get.dart';
import '../../domain/entities/user_challenge.dart';
import '../../domain/repositories/challenge_repository.dart';
import '../../../../core/services/event_bus_service.dart';

class ChallengeController extends GetxController {
  final ChallengeRepository _repository;

  ChallengeController(this._repository);

  // 챌린지 목록
  final RxList<UserChallenge> inProgressChallenges = <UserChallenge>[].obs;
  final RxList<UserChallenge> completedChallenges = <UserChallenge>[].obs;

  // 통계
  final RxInt completedCount = 0.obs;
  final RxInt streakCount = 0.obs;
  final RxDouble successRate = 0.0.obs;

  // 로딩 상태
  final RxBool isLoading = false.obs;

  // EventBusService 인스턴스
  late final EventBusService _eventBusService;

  @override
  void onInit() {
    super.onInit();

    // EventBusService 가져오기
    _eventBusService = Get.find<EventBusService>();

    // 트랜잭션 변경 이벤트 구독 (거래 추가/수정/삭제 시 자동 업데이트)
    ever(_eventBusService.transactionChanged, (_) {
      print('챌린지: 거래 변경 감지 - 진행률 자동 업데이트');
      refreshProgress();
    });

    loadChallenges();
    loadStats();
  }

  /// 챌린지 목록 로드
  Future<void> loadChallenges() async {
    try {
      isLoading.value = true;

      // 이전 완료된 챌린지 ID 저장
      final previousCompletedIds = completedChallenges.map((c) => c.id).toSet();

      // 챌린지 상태 업데이트 (자동으로 종료된 챌린지 체크)
      await _repository.updateChallengeStatuses();

      final inProgress = await _repository.getUserChallenges(status: 'IN_PROGRESS');
      final completed = await _repository.getUserChallenges(status: 'COMPLETED');
      final failed = await _repository.getUserChallenges(status: 'FAILED');

      // 새로 완료된 챌린지 확인
      for (var challenge in completed) {
        if (!previousCompletedIds.contains(challenge.id)) {
          _showSuccessMessage(challenge);
        }
      }

      // 새로 실패한 챌린지 확인
      for (var challenge in failed) {
        if (!previousCompletedIds.contains(challenge.id)) {
          _showFailureMessage(challenge);
        }
      }

      inProgressChallenges.value = inProgress;
      completedChallenges.value = [...completed, ...failed];
    } catch (e) {
      Get.snackbar('오류', '챌린지를 불러오는데 실패했습니다: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// 성공 메시지 표시
  void _showSuccessMessage(UserChallenge challenge) {
    final messages = [
      '축하합니다! 🎉 "${challenge.title}" 챌린지를 완료했어요!',
      '대단해요! 🌟 "${challenge.title}" 성공! 계속 이 기세로!',
      '완벽해요! 🏆 "${challenge.title}" 챌린지 클리어!',
      '멋져요! 💪 "${challenge.title}"를 해냈네요!',
    ];

    Get.snackbar(
      '챌린지 성공! 🎉',
      messages[DateTime.now().millisecond % messages.length],
      backgroundColor: Get.theme.colorScheme.primary,
      colorText: Get.theme.colorScheme.onPrimary,
      duration: const Duration(seconds: 4),
      snackPosition: SnackPosition.TOP,
    );
  }

  /// 실패 메시지 표시
  void _showFailureMessage(UserChallenge challenge) {
    final messages = [
      '아쉬워요 😢 "${challenge.title}" 챌린지가 종료되었어요. 다음엔 성공!',
      '괜찮아요! 💙 "${challenge.title}"는 다음 기회에 도전해봐요!',
      '포기하지 마세요! 🌈 "${challenge.title}"를 다시 시작해보는 건 어때요?',
    ];

    Get.snackbar(
      '챌린지 종료',
      messages[DateTime.now().millisecond % messages.length],
      backgroundColor: Get.theme.colorScheme.error.withOpacity(0.8),
      colorText: Get.theme.colorScheme.onError,
      duration: const Duration(seconds: 4),
      snackPosition: SnackPosition.TOP,
    );
  }

  /// 통계 로드
  Future<void> loadStats() async {
    try {
      completedCount.value = await _repository.getCompletedChallengesCount();
      streakCount.value = await _repository.getStreakCount();
      successRate.value = await _repository.getSuccessRate();
    } catch (e) {
      print('통계 로드 오류: $e');
    }
  }

  /// 챌린지 생성
  Future<void> createChallenge(UserChallenge challenge) async {
    try {
      await _repository.createChallenge(challenge);
      await loadChallenges();
      await loadStats();
      Get.back(); // 다이얼로그 닫기
      Get.snackbar(
        '성공',
        '챌린지가 시작되었습니다! 🎯',
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Get.theme.colorScheme.onPrimary,
      );
    } catch (e) {
      Get.snackbar('오류', '챌린지 생성에 실패했습니다: $e');
    }
  }

  /// 챌린지 삭제
  Future<void> deleteChallenge(int id) async {
    try {
      await _repository.deleteChallenge(id);
      await loadChallenges();
      Get.snackbar('성공', '챌린지가 삭제되었습니다');
    } catch (e) {
      Get.snackbar('오류', '챌린지 삭제에 실패했습니다: $e');
    }
  }

  /// 챌린지 진행률 갱신
  Future<void> refreshProgress() async {
    try {
      await _repository.updateChallengeStatuses();
      await loadChallenges();
      await loadStats();
    } catch (e) {
      print('진행률 갱신 오류: $e');
    }
  }
}
