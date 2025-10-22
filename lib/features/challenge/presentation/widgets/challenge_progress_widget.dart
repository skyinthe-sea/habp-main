import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/controllers/theme_controller.dart';
import '../../../../core/constants/app_colors.dart';
import '../controllers/challenge_controller.dart';
import '../pages/challenge_list_page.dart';

/// 대시보드에 표시되는 진행 중인 챌린지 위젯
class ChallengeProgressWidget extends StatelessWidget {
  const ChallengeProgressWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    // ChallengeController가 등록되어 있는지 확인
    if (!Get.isRegistered<ChallengeController>()) {
      return const SizedBox.shrink();
    }

    final challengeController = Get.find<ChallengeController>();

    return Obx(() {
      final challenges = challengeController.inProgressChallenges;

      if (challenges.isEmpty) {
        return const SizedBox.shrink();
      }

      // 첫 번째 챌린지만 표시
      final challenge = challenges.first;
      final icon = challenge.type == 'EXPENSE_LIMIT' ? '🎯' : '💰';

      // 다크모드일 때는 녹색 계열로 표시
      final color = themeController.isDarkMode
          ? AppColors.darkPrimary
          : (challenge.type == 'EXPENSE_LIMIT'
              ? const Color(0xFFFF6347)
              : const Color(0xFFFFD700));

      final formatter = NumberFormat('#,###');
      final formattedCurrent = formatter.format(challenge.currentAmount.toInt());
      final formattedTarget = formatter.format(challenge.targetAmount.toInt());

      return GestureDetector(
        onTap: () => Get.to(() => const ChallengeListPage()),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.8),
                color.withOpacity(0.6),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '진행 중인 챌린지 🔥',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white70,
                          ),
                        ),
                        Text(
                          challenge.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'D-${challenge.daysRemaining}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 진행률
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: challenge.progress,
                  minHeight: 8,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(height: 8),

              // 금액 정보
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(challenge.progress * 100).toInt()}% 달성',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '$formattedCurrent원 / $formattedTarget원',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),

              // 여러 개일 경우 더보기 표시
              if (challenges.length > 1) ...[
                const SizedBox(height: 8),
                Text(
                  '외 ${challenges.length - 1}개 진행 중',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white60,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }
}
