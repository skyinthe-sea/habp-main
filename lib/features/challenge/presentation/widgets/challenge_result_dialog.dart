import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:confetti/confetti.dart';
import '../../../../core/controllers/theme_controller.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/user_challenge.dart';
import '../controllers/challenge_controller.dart';

/// 챌린지 완료/실패 결과 다이얼로그
class ChallengeResultDialog extends StatefulWidget {
  final UserChallenge challenge;
  final bool isSuccess;

  const ChallengeResultDialog({
    Key? key,
    required this.challenge,
    required this.isSuccess,
  }) : super(key: key);

  @override
  State<ChallengeResultDialog> createState() => _ChallengeResultDialogState();
}

class _ChallengeResultDialogState extends State<ChallengeResultDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    _animationController.forward();

    // 성공 시 confetti 실행
    if (widget.isSuccess) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _confettiController.play();
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final formatter = NumberFormat('#,###');

    // 타입별 아이콘 및 메시지
    final icon = widget.challenge.type == 'EXPENSE_LIMIT' ? '🎯' : '💰';
    final resultIcon = widget.isSuccess ? '🎉' : '😢';
    final title = widget.isSuccess ? '챌린지 성공!' : '챌린지 종료';
    final subtitle = widget.isSuccess
        ? '축하합니다! 목표를 달성했어요!'
        : '아쉽지만 목표에 도달하지 못했어요';

    final backgroundColor = widget.isSuccess
        ? (themeController.isDarkMode ? AppColors.darkPrimary : AppColors.primary)
        : const Color(0xFFFF6B6B);

    return Stack(
      children: [
        Dialog(
          backgroundColor: Colors.transparent,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: themeController.isDarkMode
                    ? AppColors.darkSurface
                    : Colors.white,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 헤더 (그라데이션 배경)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          backgroundColor,
                          backgroundColor.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(28),
                        topRight: Radius.circular(28),
                      ),
                    ),
                    child: Column(
                      children: [
                        // 결과 아이콘
                        Text(
                          resultIcon,
                          style: const TextStyle(fontSize: 80),
                        ),
                        const SizedBox(height: 16),
                        // 제목
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // 부제목
                        Text(
                          subtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 챌린지 정보
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // 챌린지 이름
                        Row(
                          children: [
                            Text(icon, style: const TextStyle(fontSize: 28)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                widget.challenge.title,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: themeController.isDarkMode
                                      ? AppColors.darkTextPrimary
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // 결과 통계
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: backgroundColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              _buildStatRow(
                                themeController,
                                '목표 금액',
                                '${formatter.format(widget.challenge.targetAmount.toInt())}원',
                                Icons.flag,
                              ),
                              const SizedBox(height: 16),
                              _buildStatRow(
                                themeController,
                                widget.challenge.type == 'EXPENSE_LIMIT'
                                    ? '실제 지출'
                                    : '실제 저축',
                                '${formatter.format(widget.challenge.currentAmount.toInt())}원',
                                Icons.account_balance_wallet,
                              ),
                              const SizedBox(height: 16),
                              _buildStatRow(
                                themeController,
                                '달성률',
                                '${(widget.challenge.progress * 100).toInt()}%',
                                Icons.trending_up,
                              ),
                              const SizedBox(height: 16),
                              _buildStatRow(
                                themeController,
                                '기간',
                                '${_formatDate(widget.challenge.startDate)} ~ ${_formatDate(widget.challenge.endDate)}',
                                Icons.calendar_today,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // 완료 버튼
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              // 결과 확인 완료 표시
                              final challengeController = Get.find<ChallengeController>();
                              await challengeController.markChallengeResultAsViewed(widget.challenge.id!);
                              Get.back();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: backgroundColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              '확인',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
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
        ),

        // Confetti (성공 시에만)
        if (widget.isSuccess)
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: 3.14 / 2, // 아래로
              emissionFrequency: 0.05,
              numberOfParticles: 30,
              gravity: 0.3,
              shouldLoop: false,
              colors: const [
                Color(0xFFFFD700),
                Color(0xFFFF6347),
                Color(0xFF4169E1),
                Color(0xFF32CD32),
                Color(0xFFFF1493),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStatRow(
    ThemeController themeController,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: themeController.isDarkMode
              ? AppColors.darkTextSecondary
              : AppColors.textSecondary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: themeController.isDarkMode
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: themeController.isDarkMode
                ? AppColors.darkTextPrimary
                : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('M/d').format(date);
  }
}
