import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/controllers/theme_controller.dart';
import '../../../../core/constants/app_colors.dart';
import '../controllers/challenge_controller.dart';
import '../widgets/create_challenge_dialog.dart';
import 'package:intl/intl.dart';

/// 챌린지 목록 페이지 (게임 스타일)
class ChallengeListPage extends StatelessWidget {
  const ChallengeListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final challengeController = Get.find<ChallengeController>();
    final primaryColor = themeController.isDarkMode
        ? AppColors.darkPrimary
        : AppColors.primary;

    return Scaffold(
      backgroundColor: themeController.isDarkMode
          ? AppColors.darkBackground
          : AppColors.background,
      body: CustomScrollView(
        slivers: [
          // 게임 스타일 앱바
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                '챌린지 모드 🎮',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primaryColor,
                      primaryColor.withOpacity(0.7),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // 배경 아이콘들
                    Positioned(
                      top: 40,
                      right: 20,
                      child: Text('🎯', style: TextStyle(fontSize: 40)),
                    ),
                    Positioned(
                      top: 80,
                      left: 30,
                      child: Text('💪', style: TextStyle(fontSize: 35)),
                    ),
                    Positioned(
                      bottom: 40,
                      right: 60,
                      child: Text('⭐', style: TextStyle(fontSize: 30)),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 통계 카드
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Obx(() => _buildStatsCard(
                themeController,
                challengeController,
              )),
            ),
          ),

          // 진행 중인 챌린지 섹션
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  const Text(
                    '🔥',
                    style: TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '진행 중인 챌린지',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: themeController.isDarkMode
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 진행 중인 챌린지 목록 (실제 데이터)
          Obx(() {
            final challenges = challengeController.inProgressChallenges;

            if (challenges.isEmpty) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Text(
                        '😴',
                        style: const TextStyle(fontSize: 48),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '진행 중인 챌린지가 없어요',
                        style: TextStyle(
                          fontSize: 16,
                          color: themeController.isDarkMode
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '아래 버튼을 눌러 새 챌린지를 시작하세요!',
                        style: TextStyle(
                          fontSize: 14,
                          color: themeController.isDarkMode
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final challenge = challenges[index];
                    return _buildChallengeCard(
                      themeController,
                      challenge: challenge,
                    );
                  },
                  childCount: challenges.length,
                ),
              ),
            );
          }),

          // 추천 챌린지 섹션
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Row(
                children: [
                  const Text(
                    '✨',
                    style: TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '추천 챌린지',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: themeController.isDarkMode
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 추천 챌린지 그리드
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  // 다크모드 여부에 따라 다른 색상 사용
                  final templates = themeController.isDarkMode
                      ? [
                          {'icon': '🛍️', 'title': '쇼핑 금지령', 'difficulty': '어려움', 'color': AppColors.darkPrimary},
                          {'icon': '🍽️', 'title': '외식 절제', 'difficulty': '보통', 'color': AppColors.darkAccent2},
                          {'icon': '📝', 'title': '완벽한 기록', 'difficulty': '쉬움', 'color': AppColors.darkAccent3},
                        ]
                      : [
                          {'icon': '🛍️', 'title': '쇼핑 금지령', 'difficulty': '어려움', 'color': const Color(0xFFFF1493)},
                          {'icon': '🍽️', 'title': '외식 절제', 'difficulty': '보통', 'color': const Color(0xFFFF6347)},
                          {'icon': '📝', 'title': '완벽한 기록', 'difficulty': '쉬움', 'color': const Color(0xFF4169E1)},
                        ];

                  final template = templates[index];
                  return _buildTemplateCard(
                    themeController,
                    icon: template['icon'] as String,
                    title: template['title'] as String,
                    difficulty: template['difficulty'] as String,
                    color: template['color'] as Color,
                  );
                },
                childCount: 3,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Obx(() {
        final themeController = Get.find<ThemeController>();
        final primaryColor = themeController.isDarkMode
            ? AppColors.darkPrimary
            : AppColors.primary;

        return FloatingActionButton.extended(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => const CreateChallengeDialog(),
            );
          },
          backgroundColor: primaryColor,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            '챌린지 시작',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        );
      }),
    );
  }

  Widget _buildStatsCard(ThemeController themeController, ChallengeController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            themeController.isDarkMode
                ? AppColors.darkSurface
                : Colors.white,
            themeController.isDarkMode
                ? AppColors.darkSurface.withOpacity(0.8)
                : Colors.grey.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: themeController.isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(themeController, '🏆', '완료', '${controller.completedCount.value}'),
          _buildStatItem(themeController, '🔥', '연속', '${controller.streakCount.value}'),
          _buildStatItem(themeController, '📊', '성공률', '${controller.successRate.value.toInt()}%'),
        ],
      ),
    );
  }

  Widget _buildStatItem(ThemeController themeController, String icon, String label, String value) {
    final primaryColor = themeController.isDarkMode
        ? AppColors.darkPrimary
        : AppColors.primary;

    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: themeController.isDarkMode
                ? AppColors.darkTextSecondary
                : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildChallengeCard(
    ThemeController themeController, {
    required challenge,
  }) {
    final icon = challenge.type == 'EXPENSE_LIMIT' ? '🎯' : '💰';
    final color = themeController.isDarkMode
        ? AppColors.darkPrimary
        : (challenge.type == 'EXPENSE_LIMIT'
            ? const Color(0xFFFF6347)
            : const Color(0xFFFFD700));

    final formatter = NumberFormat('#,###');
    final formattedCurrent = formatter.format(challenge.currentAmount.toInt());
    final formattedTarget = formatter.format(challenge.targetAmount.toInt());

    return GestureDetector(
      onTap: () => _showChallengeDetailDialog(challenge, themeController),
      onLongPress: () => _showDeleteChallengeDialog(challenge),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: themeController.isDarkMode
              ? AppColors.darkSurface
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: themeController.isDarkMode
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
        children: [
          // 헤더
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.7)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        challenge.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        challenge.type == 'EXPENSE_LIMIT'
                            ? '${formattedTarget}원 이하로 지출하기'
                            : '${formattedTarget}원 저축하기',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'D-${challenge.daysRemaining}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 진행률
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(challenge.progress * 100).toInt()}% 달성',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: themeController.isDarkMode
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '$formattedCurrent원 / $formattedTarget원',
                      style: TextStyle(
                        fontSize: 14,
                        color: themeController.isDarkMode
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: challenge.progress,
                    minHeight: 12,
                    backgroundColor: themeController.isDarkMode
                        ? Colors.grey.shade800
                        : Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }

  /// 챌린지 삭제 확인 다이얼로그
  /// 챌린지 상세 정보 다이얼로그
  void _showChallengeDetailDialog(challenge, ThemeController themeController) {
    final icon = challenge.type == 'EXPENSE_LIMIT' ? '🎯' : '💰';
    final color = themeController.isDarkMode
        ? AppColors.darkPrimary
        : (challenge.type == 'EXPENSE_LIMIT'
            ? const Color(0xFFFF6347)
            : const Color(0xFFFFD700));

    final formatter = NumberFormat('#,###');
    final formattedCurrent = formatter.format(challenge.currentAmount.toInt());
    final formattedTarget = formatter.format(challenge.targetAmount.toInt());

    // 날짜 포맷터
    final dateFormatter = DateFormat('yyyy년 MM월 dd일');
    final startDateStr = dateFormatter.format(challenge.startDate);
    final endDateStr = dateFormatter.format(challenge.endDate);

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: themeController.isDarkMode
                ? AppColors.darkSurface
                : AppColors.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 헤더
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.7)],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(icon, style: const TextStyle(fontSize: 40)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                challenge.title,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                challenge.type == 'EXPENSE_LIMIT'
                                    ? '지출 제한 챌린지'
                                    : '저축 목표 챌린지',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Get.back(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 상세 정보
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 진행률 정보
                    _buildDetailRow(
                      themeController,
                      '진행률',
                      '${(challenge.progress * 100).toStringAsFixed(0)}%',
                      Icons.trending_up,
                    ),
                    const SizedBox(height: 16),

                    // 목표 금액
                    _buildDetailRow(
                      themeController,
                      '목표 금액',
                      '$formattedTarget원',
                      Icons.flag,
                    ),
                    const SizedBox(height: 16),

                    // 현재 금액
                    _buildDetailRow(
                      themeController,
                      challenge.type == 'EXPENSE_LIMIT' ? '현재 지출' : '현재 저축',
                      '$formattedCurrent원',
                      Icons.account_balance_wallet,
                    ),
                    const SizedBox(height: 16),

                    // 남은 기간
                    _buildDetailRow(
                      themeController,
                      '남은 기간',
                      'D-${challenge.daysRemaining} (${challenge.daysRemaining}일)',
                      Icons.calendar_today,
                    ),
                    const SizedBox(height: 16),

                    // 시작일
                    _buildDetailRow(
                      themeController,
                      '시작일',
                      startDateStr,
                      Icons.play_arrow,
                    ),
                    const SizedBox(height: 16),

                    // 종료일
                    _buildDetailRow(
                      themeController,
                      '종료일',
                      endDateStr,
                      Icons.stop,
                    ),

                    const SizedBox(height: 24),

                    // 안내 메시지
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: color,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '진행 중인 챌린지는 수정할 수 없습니다.\n취소하려면 길게 눌러주세요.',
                              style: TextStyle(
                                fontSize: 13,
                                color: themeController.isDarkMode
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 확인 버튼
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Get.back(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          '확인',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 상세 정보 행 위젯
  Widget _buildDetailRow(
    ThemeController themeController,
    String label,
    String value,
    IconData icon,
  ) {
    final primaryColor = themeController.isDarkMode
        ? AppColors.darkPrimary
        : AppColors.primary;

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: primaryColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: themeController.isDarkMode
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: themeController.isDarkMode
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showDeleteChallengeDialog(challenge) {
    final themeController = Get.find<ThemeController>();

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: themeController.isDarkMode
                ? AppColors.darkSurface
                : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 아이콘
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 30,
                ),
              ),
              const SizedBox(height: 20),

              // 제목
              Text(
                '챌린지를 취소할까요?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: themeController.isDarkMode
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              // 설명
              Text(
                '"${challenge.title}" 챌린지를 취소합니다.\n진행 중인 기록은 사라집니다.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: themeController.isDarkMode
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // 버튼
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('아니요'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back(); // 다이얼로그 닫기
                        final challengeController = Get.find<ChallengeController>();
                        challengeController.deleteChallenge(challenge.id!);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '취소하기',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateCard(
    ThemeController themeController, {
    required String icon,
    required String title,
    required String difficulty,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () {
        Get.snackbar(
          '준비 중',
          '$title 챌린지를 시작하시겠습니까? (곧 추가됩니다)',
          backgroundColor: color,
          colorText: Colors.white,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: themeController.isDarkMode
              ? AppColors.darkSurface
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: themeController.isDarkMode
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                difficulty,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
