// lib/features/quick_add/presentation/widgets/quick_add_button.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/controllers/theme_controller.dart';
import '../controllers/quick_add_controller.dart';
import '../dialogs/category_type_dialog.dart';
import '../dialogs/category_selection_dialog.dart';

enum SwipeDirection {
  none,
  left,    // 수입
  right,   // 지출  
  up,      // 저축
  down,    // 기타
}

/// QuickAdd button widget that replaces the FloatingActionButton in MainPage
/// Handles swipe gestures and shows different dialogs based on swipe direction
class QuickAddButton extends StatefulWidget {
  const QuickAddButton({Key? key}) : super(key: key);

  @override
  State<QuickAddButton> createState() => _QuickAddButtonState();
}

class _QuickAddButtonState extends State<QuickAddButton>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late AnimationController _hintAnimationController;
  late Animation<Offset> _hintSlideAnimation;
  
  SwipeDirection _currentDirection = SwipeDirection.none;
  bool _isPanning = false;
  Offset? _panStartPosition;
  Timer? _hintTimer;

  @override
  void initState() {
    super.initState();
    
    // 스케일 애니메이션 (스와이프 시)
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    // 힌트 애니메이션 (빠른 미세 흔들림)
    _hintAnimationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _hintSlideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.08, 0),
    ).animate(CurvedAnimation(
      parent: _hintAnimationController,
      curve: Curves.linear,
    ));
    
    // 10초마다 힌트 애니메이션 시작
    _startHintTimer();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _hintAnimationController.dispose();
    _hintTimer?.cancel();
    super.dispose();
  }
  
  void _startHintTimer() {
    _hintTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (!_isPanning && mounted) {
        _playHintAnimation();
      }
    });
  }
  
  void _playHintAnimation() async {
    // 빠른 좌우 흔들림 효과 (2회)
    for (int i = 0; i < 2; i++) {
      // 오른쪽으로 미세하게 이동
      await _hintAnimationController.forward();
      // 왼쪽으로 미세하게 이동
      await _hintAnimationController.reverse();
    }
    // 중앙에서 완전 정지
    _hintAnimationController.reset();
  }

  @override
  Widget build(BuildContext context) {
    // Initialize the controller if not already done
    final controller = Get.put(QuickAddController());
    final ThemeController themeController = Get.find<ThemeController>();

    return AnimatedBuilder(
      animation: Listenable.merge([_scaleAnimation, _hintSlideAnimation]),
      builder: (context, child) {
        return SlideTransition(
          position: _hintSlideAnimation,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: GestureDetector(
            onPanStart: (details) {
              setState(() {
                _isPanning = true;
                _currentDirection = SwipeDirection.none;
                _panStartPosition = details.globalPosition;
              });
              _animationController.forward();
            },
            onPanUpdate: (details) {
              if (_panStartPosition == null) return;
              
              final dx = details.globalPosition.dx - _panStartPosition!.dx;
              final dy = details.globalPosition.dy - _panStartPosition!.dy;
              final threshold = 20.0;

              SwipeDirection newDirection = SwipeDirection.none;
              
              if (dx.abs() > dy.abs() && dx.abs() > threshold) {
                // 수평 스와이프 (절대 거리 기준)
                if (dx > 0) {
                  newDirection = SwipeDirection.right;
                } else {
                  newDirection = SwipeDirection.left;
                }
              } else if (dy.abs() > dx.abs() && dy.abs() > threshold) {
                // 수직 스와이프 (절대 거리 기준)  
                if (dy > 0) {
                  newDirection = SwipeDirection.down;
                } else {
                  newDirection = SwipeDirection.up;
                }
              }

              if (newDirection != _currentDirection) {
                setState(() {
                  _currentDirection = newDirection;
                });
              }
            },
            onPanEnd: (details) {
              setState(() {
                _isPanning = false;
              });
              _animationController.reverse();

              // 스와이프 방향에 따라 다른 다이얼로그 표시
              if (_currentDirection != SwipeDirection.none) {
                _showDialogForDirection(_currentDirection);
              } else {
                // 기본 탭 동작
                _showCategoryTypeDialog(context);
              }
              
              setState(() {
                _currentDirection = SwipeDirection.none;
                _panStartPosition = null;
              });
            },
            onTap: () {
              if (!_isPanning) {
                _showCategoryTypeDialog(context);
              }
            },
            child: Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                gradient: _getGradientForDirection(_currentDirection),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _getColorForDirection(_currentDirection).withOpacity(0.4),
                    spreadRadius: 1,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(_getIconForDirection(_currentDirection), 
                          color: Colors.white, size: 28),
                onPressed: null, // GestureDetector가 처리
              ),
            ),
          ),
        ),
      );
      },
    );
  }

  /// 스와이프 방향에 따른 그라데이션 색상 반환
  LinearGradient _getGradientForDirection(SwipeDirection direction) {
    switch (direction) {
      case SwipeDirection.left: // 수입 - 연두색
        return const LinearGradient(
          colors: [Color(0xFF8BC34A), Color(0xFF66BB6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case SwipeDirection.right: // 지출 - 빨간색
        return const LinearGradient(
          colors: [Color(0xFFEF5350), Color(0xFFE53935)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case SwipeDirection.up: // 재테크 - 푸른색
        return const LinearGradient(
          colors: [Color(0xFF42A5F5), Color(0xFF2196F3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case SwipeDirection.down: // 감사 인사 - 따뜻한 핑크색
        return const LinearGradient(
          colors: [Color(0xFFF06292), Color(0xFFE91E63)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default: // 기본 - 테마 색상
        final themeController = Get.find<ThemeController>();
        final primaryColor = themeController.primaryColor;
        final darkerPrimary = Color.lerp(primaryColor, Colors.black, 0.1) ?? primaryColor;
        return LinearGradient(
          colors: [primaryColor, darkerPrimary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  /// 스와이프 방향에 따른 기본 색상 반환
  Color _getColorForDirection(SwipeDirection direction) {
    switch (direction) {
      case SwipeDirection.left: // 수입 - 연두색
        return const Color(0xFF66BB6A);
      case SwipeDirection.right: // 지출 - 빨간색
        return const Color(0xFFE53935);
      case SwipeDirection.up: // 재테크 - 푸른색
        return const Color(0xFF2196F3);
      case SwipeDirection.down: // 감사 인사 - 따뜻한 핑크색
        return const Color(0xFFE91E63);
      default: // 기본 - 테마 색상
        final themeController = Get.find<ThemeController>();
        return themeController.primaryColor;
    }
  }

  /// 스와이프 방향에 따른 아이콘 반환
  IconData _getIconForDirection(SwipeDirection direction) {
    switch (direction) {
      case SwipeDirection.left: // 수입
        return Icons.trending_up;
      case SwipeDirection.right: // 지출
        return Icons.trending_down;
      case SwipeDirection.up: // 저축
        return Icons.savings;
      case SwipeDirection.down: // 감사 인사
        return Icons.favorite;
      default:
        return Icons.add;
    }
  }

  /// 스와이프 방향에 따라 직접 카테고리 선택 다이얼로그 표시
  void _showDialogForDirection(SwipeDirection direction) {
    final controller = Get.put(QuickAddController());
    String categoryType = '';

    switch (direction) {
      case SwipeDirection.left: // 수입
        categoryType = 'INCOME';
        break;
      case SwipeDirection.right: // 지출
        categoryType = 'EXPENSE';
        break;
      case SwipeDirection.up: // 재테크
        categoryType = 'FINANCE';
        break;
      case SwipeDirection.down: // 감사 인사 이스터에그
        _showThankYouDialog();
        return;
      default:
        return;
    }

    // 트랜잭션 리셋 및 카테고리 타입 설정
    controller.resetTransaction();
    controller.setCategoryType(categoryType);

    // 카테고리 선택 다이얼로그 표시
    showGeneralDialog(
      context: context,
      pageBuilder: (_, __, ___) => const CategorySelectionDialog(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(
          parent: animation,
          curve: Curves.elasticOut,
        );

        return ScaleTransition(
          scale: curve,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.5),
    );
  }

  /// 감사 인사 이스터에그 다이얼로그 (아래 스와이프)
  void _showThankYouDialog() {
    Color accentColor = _getColorForDirection(SwipeDirection.down);

    showGeneralDialog(
      context: context,
      pageBuilder: (_, __, ___) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 800),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.scale(
              scale: 0.8 + (0.2 * value),
              child: Opacity(
                opacity: value,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Get.find<ThemeController>().cardColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 하트 아이콘 애니메이션
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 1200),
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, heartValue, child) {
                          return Transform.scale(
                            scale: 1.0 + (0.2 * (1 - (heartValue - 0.5).abs() * 2)),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: accentColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.favorite,
                                color: accentColor,
                                size: 48,
                              ),
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // 제목
                      Text(
                        '앱을 사용해 주셔서 감사합니다!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Get.find<ThemeController>().textPrimaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // 메시지
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Get.find<ThemeController>().isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '처음이라 많이 부족하지만\n지속적으로 업데이트하면서\n더욱 사용하기 편한 앱이 되겠습니다.\n\n여러분의 소중한 의견과 관심에\n진심으로 감사드립니다! 💖',
                          style: TextStyle(
                            fontSize: 16,
                            color: Get.find<ThemeController>().textSecondaryColor,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // 확인 버튼
                      Container(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            '감사합니다! ❤️',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.5),
    );
  }

  /// Shows usage guide dialog for new swipe functionality
  void _showCategoryTypeDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      pageBuilder: (_, __, ___) => _buildUsageGuideDialog(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );

        return ScaleTransition(
          scale: curve,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.6),
    );
  }

  /// Builds the usage guide dialog with animations
  Widget _buildUsageGuideDialog() {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Get.find<ThemeController>().cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '💳 빠른 거래 추가',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Get.find<ThemeController>().textPrimaryColor,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 24),
                  onPressed: () => Navigator.of(context).pop(),
                  color: Get.find<ThemeController>().textSecondaryColor,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Subtitle
            Text(
              '버튼을 스와이프해서 빠르게 거래를 추가하세요!',
              style: TextStyle(
                fontSize: 16,
                color: Get.find<ThemeController>().textSecondaryColor,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Swipe directions with animated indicators
            _buildSwipeGuideItem(
              direction: '⬅️ 왼쪽 스와이프',
              action: '수입 추가',
              color: const Color(0xFF66BB6A),
              icon: Icons.trending_up,
              delay: 0,
            ),

            const SizedBox(height: 16),

            _buildSwipeGuideItem(
              direction: '➡️ 오른쪽 스와이프',
              action: '지출 추가',
              color: const Color(0xFFE53935),
              icon: Icons.trending_down,
              delay: 200,
            ),

            const SizedBox(height: 16),

            _buildSwipeGuideItem(
              direction: '⬆️ 위쪽 스와이프',
              action: '재테크 추가',
              color: const Color(0xFF2196F3),
              icon: Icons.savings,
              delay: 400,
            ),

            const SizedBox(height: 24),

            // Animated demonstration button
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 1200),
              tween: Tween(begin: -10.0, end: 10.0),
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(value, 0),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Get.find<ThemeController>().primaryColor, 
                          Color.lerp(Get.find<ThemeController>().primaryColor, Colors.black, 0.1) ?? Get.find<ThemeController>().primaryColor
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Get.find<ThemeController>().primaryColor.withOpacity(0.4),
                          spreadRadius: 2,
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            Text(
              '지금 시도해보세요!',
              style: TextStyle(
                fontSize: 14,
                color: Get.find<ThemeController>().textSecondaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 24),

            // Got it button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Get.find<ThemeController>().primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  '알겠습니다!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds individual swipe guide item with animation
  Widget _buildSwipeGuideItem({
    required String direction,
    required String action,
    required Color color,
    required IconData icon,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: color.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          direction,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          action,
                          style: TextStyle(
                            fontSize: 13,
                            color: Get.find<ThemeController>().textSecondaryColor,
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
      },
    );
  }
}