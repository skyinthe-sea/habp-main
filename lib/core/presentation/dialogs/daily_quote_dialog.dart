// lib/core/presentation/dialogs/daily_quote_dialog.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:confetti/confetti.dart';
import '../../constants/app_colors.dart';
import '../../controllers/theme_controller.dart';
import '../../services/daily_quote_service.dart';
import 'dart:math' as math;

/// Animated daily quote card dialog with trendy design
class DailyQuoteDialog extends StatefulWidget {
  final Map<String, dynamic> quote;

  const DailyQuoteDialog({
    Key? key,
    required this.quote,
  }) : super(key: key);

  @override
  State<DailyQuoteDialog> createState() => _DailyQuoteDialogState();
}

class _DailyQuoteDialogState extends State<DailyQuoteDialog>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _shimmerController;
  late AnimationController _rotateController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _rotateAnimation;
  late ConfettiController _confettiController;
  final DailyQuoteService _quoteService = DailyQuoteService();

  @override
  void initState() {
    super.initState();

    // Scale animation (card entrance) - 더 부드럽고 자연스럽게
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutBack, // elasticOut 대신 더 자연스러운 easeOutBack
    );

    // Shimmer animation (sparkle effect) - 더 미묘하게
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
    _shimmerAnimation = CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    );

    // Rotate animation 제거 - 너무 과도한 효과
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1),
    );
    _rotateAnimation = Tween<double>(
      begin: 0,
      end: 0,
    ).animate(_rotateController);

    // Confetti controller - 더 짧고 강렬하게
    _confettiController = ConfettiController(
      duration: const Duration(milliseconds: 800),
    );

    // Start animations
    _scaleController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _confettiController.play();
      }
    });

    // Mark quote as viewed
    _quoteService.markQuoteAsViewed(widget.quote['id'] as int);
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _shimmerController.dispose();
    _rotateController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  /// Get category icon
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case '저축':
        return Icons.savings;
      case '투자':
        return Icons.trending_up;
      case '목표':
        return Icons.flag;
      case '습관':
        return Icons.auto_awesome;
      case '빚':
        return Icons.credit_card_off;
      case '지식':
        return Icons.school;
      default:
        return Icons.lightbulb;
    }
  }

  /// Get category color
  Color _getCategoryColor(String category) {
    switch (category) {
      case '저축':
        return const Color(0xFF10B981);
      case '투자':
        return const Color(0xFF8B5CF6);
      case '목표':
        return const Color(0xFFF59E0B);
      case '습관':
        return const Color(0xFF3B82F6);
      case '빚':
        return const Color(0xFFEF4444);
      case '지식':
        return const Color(0xFF06B6D4);
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    final String quoteText = widget.quote['quote_text'] as String;
    final String? author = widget.quote['author'] as String?;
    final String category = widget.quote['category'] as String;
    final categoryColor = _getCategoryColor(category);
    final categoryIcon = _getCategoryIcon(category);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 120),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: math.pi / 2,
              emissionFrequency: 0.1,
              numberOfParticles: 20,
              gravity: 0.4,
              colors: const [
                Color(0xFF6366F1),
                Color(0xFF8B5CF6),
                Color(0xFFEC4899),
                Color(0xFFF59E0B),
                Color(0xFF10B981),
              ],
            ),
          ),

          // Main card
          ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 350),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: categoryColor.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 0,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    // Background gradient
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: themeController.isDarkMode
                              ? [
                                  themeController.cardColor,
                                  themeController.cardColor.withOpacity(0.95),
                                ]
                              : [
                                  Colors.white,
                                  Colors.white.withOpacity(0.95),
                                ],
                        ),
                      ),
                    ),

                    // Shimmer effect
                    AnimatedBuilder(
                      animation: _shimmerAnimation,
                      builder: (context, child) {
                        return Positioned(
                          top: -100,
                          left: -100 + (_shimmerAnimation.value * 500),
                          child: Transform.rotate(
                            angle: math.pi / 4,
                            child: Container(
                              width: 100,
                              height: 500,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0),
                                    Colors.white.withOpacity(0.1),
                                    Colors.white.withOpacity(0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    // Content
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Category badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: categoryColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      categoryIcon,
                                      size: 14,
                                      color: categoryColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      category,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: categoryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Close button
                              IconButton(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: Icon(
                                  Icons.close,
                                  color: themeController.textSecondaryColor,
                                  size: 18,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Title
                          Row(
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                color: categoryColor,
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '오늘의 경제 명언',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: themeController.textPrimaryColor,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Quote text
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: categoryColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              '"$quoteText"',
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.5,
                                fontWeight: FontWeight.w500,
                                color: themeController.textPrimaryColor,
                                letterSpacing: 0.2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),

                          if (author != null && author.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              '- $author',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: categoryColor,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],

                          const SizedBox(height: 20),

                          // Collection badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  categoryColor.withOpacity(0.2),
                                  categoryColor.withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: categoryColor.withOpacity(0.3),
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.workspace_premium,
                                  color: categoryColor,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '명언 카드를 수집했어요!',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: categoryColor,
                                  ),
                                ),
                              ],
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
        ],
      ),
    );
  }
}
