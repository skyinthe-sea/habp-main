import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/controllers/theme_controller.dart';
import '../../../../core/constants/app_colors.dart';
import '../controllers/challenge_controller.dart';
import '../../domain/entities/user_challenge.dart';

/// 챌린지 상세 통계 페이지
class ChallengeStatsPage extends StatelessWidget {
  const ChallengeStatsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final challengeController = Get.find<ChallengeController>();

    return Scaffold(
      backgroundColor: themeController.isDarkMode
          ? AppColors.darkBackground
          : AppColors.background,
      body: CustomScrollView(
        slivers: [
          // 앱바
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: themeController.isDarkMode
                ? AppColors.darkPrimary
                : AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                '챌린지 분석 📊',
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
                      themeController.isDarkMode
                          ? AppColors.darkPrimary
                          : AppColors.primary,
                      (themeController.isDarkMode
                              ? AppColors.darkPrimary
                              : AppColors.primary)
                          .withOpacity(0.7),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 컨텐츠
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Obx(() {
                final allChallenges = [
                  ...challengeController.inProgressChallenges,
                  ...challengeController.completedChallenges,
                ];

                if (allChallenges.isEmpty) {
                  return _buildEmptyState(themeController);
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 전체 개요
                    _buildOverviewCard(themeController, challengeController),
                    const SizedBox(height: 16),

                    // 성공률 차트
                    _buildSuccessRateChart(themeController, challengeController),
                    const SizedBox(height: 16),

                    // 타임라인
                    _buildSectionTitle(themeController, '챌린지 타임라인 🕐'),
                    const SizedBox(height: 12),
                    _buildTimeline(themeController, allChallenges),
                    const SizedBox(height: 24),

                    // 인사이트 & 조언
                    _buildSectionTitle(themeController, '인사이트 & 조언 💡'),
                    const SizedBox(height: 12),
                    _buildInsights(themeController, challengeController),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeController themeController) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Text('📊', style: const TextStyle(fontSize: 80)),
            const SizedBox(height: 16),
            Text(
              '아직 챌린지 기록이 없어요',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: themeController.isDarkMode
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '첫 챌린지를 시작해보세요!',
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

  Widget _buildOverviewCard(
    ThemeController themeController,
    ChallengeController controller,
  ) {
    final totalCompleted = controller.completedChallenges.length;
    final successCount = controller.completedChallenges
        .where((c) => c.status == 'COMPLETED')
        .length;
    final failedCount =
        controller.completedChallenges.where((c) => c.status == 'FAILED').length;
    final successRate =
        totalCompleted > 0 ? (successCount / totalCompleted * 100).toInt() : 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            themeController.isDarkMode
                ? AppColors.darkPrimary
                : AppColors.primary,
            (themeController.isDarkMode
                    ? AppColors.darkPrimary
                    : AppColors.primary)
                .withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (themeController.isDarkMode
                    ? AppColors.darkPrimary
                    : AppColors.primary)
                .withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '전체 통계',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildOverviewItem('🎯', '진행 중', '${controller.inProgressChallenges.length}개'),
              _buildOverviewItem('✅', '성공', '$successCount개'),
              _buildOverviewItem('❌', '실패', '$failedCount개'),
              _buildOverviewItem('📈', '성공률', '$successRate%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewItem(String icon, String label, String value) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessRateChart(
    ThemeController themeController,
    ChallengeController controller,
  ) {
    final successCount = controller.completedChallenges
        .where((c) => c.status == 'COMPLETED')
        .length;
    final failedCount =
        controller.completedChallenges.where((c) => c.status == 'FAILED').length;

    if (successCount == 0 && failedCount == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(24),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '성공 vs 실패',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: themeController.isDarkMode
                  ? AppColors.darkTextPrimary
                  : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: successCount.toDouble(),
                    title: '$successCount개\n성공',
                    color: themeController.isDarkMode
                        ? AppColors.darkPrimary
                        : const Color(0xFF4CAF50),
                    radius: 80,
                    titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: failedCount.toDouble(),
                    title: '$failedCount개\n실패',
                    color: const Color(0xFFFF6B6B),
                    radius: 80,
                    titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(
    ThemeController themeController,
    List<UserChallenge> challenges,
  ) {
    // 날짜순 정렬 (최신순)
    final sortedChallenges = challenges.toList()
      ..sort((a, b) => b.startDate.compareTo(a.startDate));

    return Column(
      children: sortedChallenges.map((challenge) {
        return _buildTimelineItem(themeController, challenge);
      }).toList(),
    );
  }

  Widget _buildTimelineItem(
    ThemeController themeController,
    UserChallenge challenge,
  ) {
    final formatter = NumberFormat('#,###');
    final dateFormatter = DateFormat('yyyy.MM.dd');

    final icon = challenge.type == 'EXPENSE_LIMIT' ? '🎯' : '💰';
    final statusIcon = challenge.status == 'IN_PROGRESS'
        ? '🔄'
        : (challenge.status == 'COMPLETED' ? '✅' : '❌');
    final statusText = challenge.status == 'IN_PROGRESS'
        ? '진행 중'
        : (challenge.status == 'COMPLETED' ? '성공' : '실패');
    final statusColor = challenge.status == 'IN_PROGRESS'
        ? (themeController.isDarkMode ? AppColors.darkPrimary : AppColors.primary)
        : (challenge.status == 'COMPLETED'
            ? const Color(0xFF4CAF50)
            : const Color(0xFFFF6B6B));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeController.isDarkMode
            ? AppColors.darkSurface
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  challenge.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: themeController.isDarkMode
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Text(statusIcon, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 기간
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 16,
                color: themeController.isDarkMode
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                '${dateFormatter.format(challenge.startDate)} ~ ${dateFormatter.format(challenge.endDate)}',
                style: TextStyle(
                  fontSize: 13,
                  color: themeController.isDarkMode
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 진행률
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: challenge.progress,
                    minHeight: 8,
                    backgroundColor: themeController.isDarkMode
                        ? Colors.grey.shade800
                        : Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${(challenge.progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 금액 정보
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${formatter.format(challenge.currentAmount.toInt())}원',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: themeController.isDarkMode
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
              Text(
                '/ ${formatter.format(challenge.targetAmount.toInt())}원',
                style: TextStyle(
                  fontSize: 14,
                  color: themeController.isDarkMode
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),

          // 실패 원인 (실패한 경우만)
          if (challenge.status == 'FAILED') ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_rounded,
                    size: 18,
                    color: Color(0xFFFF6B6B),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getFailureReason(challenge),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFFF6B6B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getFailureReason(UserChallenge challenge) {
    if (challenge.type == 'EXPENSE_LIMIT') {
      final over = challenge.currentAmount - challenge.targetAmount;
      final formatter = NumberFormat('#,###');
      return '목표보다 ${formatter.format(over.toInt())}원 초과 지출했어요';
    } else {
      final short = challenge.targetAmount - challenge.currentAmount;
      final formatter = NumberFormat('#,###');
      return '목표까지 ${formatter.format(short.toInt())}원 부족했어요';
    }
  }

  Widget _buildInsights(
    ThemeController themeController,
    ChallengeController controller,
  ) {
    final insights = _generateInsights(controller);

    return Column(
      children: insights.map((insight) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: themeController.isDarkMode
                ? AppColors.darkSurface
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: (themeController.isDarkMode
                      ? AppColors.darkPrimary
                      : AppColors.primary)
                  .withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(insight['icon'] as String,
                  style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      insight['title'] as String,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: themeController.isDarkMode
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      insight['message'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        color: themeController.isDarkMode
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  List<Map<String, String>> _generateInsights(ChallengeController controller) {
    final insights = <Map<String, String>>[];

    final totalCompleted = controller.completedChallenges.length;
    final successCount = controller.completedChallenges
        .where((c) => c.status == 'COMPLETED')
        .length;
    final failedCount =
        controller.completedChallenges.where((c) => c.status == 'FAILED').length;

    // 성공률 기반 인사이트
    if (totalCompleted > 0) {
      final successRate = (successCount / totalCompleted * 100).toInt();

      if (successRate >= 80) {
        insights.add({
          'icon': '🏆',
          'title': '챌린지 마스터!',
          'message': '성공률이 무려 $successRate%! 정말 대단해요. 이 페이스를 유지하세요!',
        });
      } else if (successRate >= 50) {
        insights.add({
          'icon': '💪',
          'title': '꾸준한 성장 중',
          'message': '성공률 $successRate%로 잘하고 있어요. 조금만 더 노력하면 목표 달성이 쉬워질 거예요!',
        });
      } else {
        insights.add({
          'icon': '🎯',
          'title': '도전 정신 최고!',
          'message': '실패를 두려워하지 않는 모습이 멋져요. 목표를 조금 낮춰서 성공 경험을 쌓아보세요.',
        });
      }
    }

    // 실패 패턴 분석
    if (failedCount >= 2) {
      insights.add({
        'icon': '📉',
        'title': '목표 재조정 추천',
        'message': '최근 실패가 많아요. 더 달성 가능한 목표로 시작해서 자신감을 키워보세요!',
      });
    }

    // 진행 중인 챌린지 조언
    if (controller.inProgressChallenges.isNotEmpty) {
      final inProgress = controller.inProgressChallenges.first;
      if (inProgress.progress >= 0.9) {
        insights.add({
          'icon': '🔥',
          'title': '곧 목표 달성!',
          'message': '${inProgress.title} 챌린지가 90% 이상 달성! 마지막까지 힘내세요!',
        });
      } else if (inProgress.daysRemaining <= 2) {
        insights.add({
          'icon': '⏰',
          'title': '마감 임박!',
          'message': '${inProgress.title} 챌린지가 ${inProgress.daysRemaining}일 남았어요. 집중력을 높여보세요!',
        });
      }
    }

    // 기본 조언
    if (insights.isEmpty) {
      insights.add({
        'icon': '💡',
        'title': '첫 챌린지 시작하기',
        'message': '작은 목표부터 시작해보세요. "커피 일주일 2만원 이하"처럼 구체적이고 달성 가능한 목표가 좋아요!',
      });
    }

    return insights;
  }

  Widget _buildSectionTitle(ThemeController themeController, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: themeController.isDarkMode
            ? AppColors.darkTextPrimary
            : AppColors.textPrimary,
      ),
    );
  }
}
