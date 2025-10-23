import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import '../../../../core/controllers/theme_controller.dart';

/// Custom TickerProvider for standalone animations
class _CustomTickerProvider extends TickerProvider {
  Ticker? _ticker;

  @override
  Ticker createTicker(TickerCallback onTick) {
    _ticker = Ticker(onTick);
    return _ticker!;
  }

  void dispose() {
    _ticker?.dispose();
  }
}

/// Service to handle the save animation from dialog to calendar marker
class SaveAnimationService {
  /// Animates the dialog shrinking to center and triggers calendar marker pulse
  ///
  /// [context] - The build context
  /// [dialogKey] - GlobalKey of the dialog widget
  /// [targetDate] - The date on the calendar to animate to (for marker identification)
  /// [amount] - The transaction amount
  /// [categoryType] - Type of transaction (INCOME, EXPENSE, FINANCE)
  /// [onComplete] - Callback when animation completes
  static Future<void> animateToCalendar({
    required BuildContext context,
    required GlobalKey dialogKey,
    required DateTime targetDate,
    required double amount,
    required String categoryType,
    required VoidCallback onComplete,
  }) async {
    // Get screen size
    final screenSize = MediaQuery.of(context).size;

    // Target position: center of screen
    final centerX = screenSize.width / 2;
    final centerY = screenSize.height / 2;

    // Create a custom ticker provider for the animation
    final tickerProvider = _CustomTickerProvider();

    // Animation controller for dialog shrink to point (300ms - very fast)
    final animationController = AnimationController(
      vsync: tickerProvider,
      duration: const Duration(milliseconds: 300),
    );

    // Scale animation: 1.0 -> 0.0 (shrink to point)
    final scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: Curves.easeInCubic, // Fast acceleration
    ));

    // Opacity animation: fade out at the end
    final opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
    ));

    // Get ThemeController for dialog colors
    final ThemeController themeController = Get.find<ThemeController>();

    // Get overlay
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => AnimatedBuilder(
        animation: animationController,
        builder: (context, child) {
          final scale = scaleAnimation.value;
          final opacity = opacityAnimation.value;

          // Dialog shrinks to center as a circle/point
          final size = screenSize.width * scale; // Start from dialog width, shrink to 0

          return Positioned(
            left: centerX - size / 2,
            top: centerY - size / 2,
            child: IgnorePointer(
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: themeController.surfaceColor,
                    shape: BoxShape.circle, // Always circular for smooth shrink
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2 * scale),
                        blurRadius: 20 * scale,
                        spreadRadius: 5 * scale,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );

    // Insert overlay
    overlay.insert(overlayEntry);

    // Start shrink animation
    await animationController.forward();

    // Cleanup overlay
    overlayEntry.remove();
    animationController.dispose();
    tickerProvider.dispose();

    // Complete callback
    onComplete();
  }

  /// Trigger a pulse animation on the calendar marker for the target date
  ///
  /// This makes the calendar marker briefly scale: 0.5 → 1.5 → 1.0
  static void triggerMarkerPulse({
    required DateTime targetDate,
  }) {
    // Emit event through GetX or EventBus to trigger marker pulse
    // The calendar controller will listen for this event
    Get.find<SaveAnimationController>().triggerPulse(targetDate);
  }
}

/// Controller to manage marker pulse animations
class SaveAnimationController extends GetxController {
  // Observable map to track pulse state for each date
  final RxMap<String, bool> pulseStates = <String, bool>{}.obs;

  /// Trigger pulse animation for a specific date
  void triggerPulse(DateTime date) {
    final dateKey = _getDateKey(date);
    pulseStates[dateKey] = true;

    // Reset after animation completes
    Future.delayed(const Duration(milliseconds: 400), () {
      pulseStates[dateKey] = false;
    });
  }

  /// Check if a date should be pulsing
  bool isPulsing(DateTime date) {
    return pulseStates[_getDateKey(date)] ?? false;
  }

  /// Generate a unique key for a date
  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }
}
