// lib/features/onboarding/presentation/widgets/blinking_text_button.dart

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class BlinkingTextButton extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  final double fontSize;
  final Color textColor;
  final bool showIcon;

  const BlinkingTextButton({
    Key? key,
    required this.text,
    required this.onTap,
    this.fontSize = 40,
    this.textColor = AppColors.white,
    this.showIcon = false,
  }) : super(key: key);

  @override
  State<BlinkingTextButton> createState() => _BlinkingTextButtonState();
}

class _BlinkingTextButtonState extends State<BlinkingTextButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500), // Speed up animation
    );

    _animation = Tween<double>(begin: 1.0, end: 0.1).animate(_controller);
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Call the onTap handler
        widget.onTap();

        // Very important: Stop event propagation to parent widgets
        // This prevents the screen tap from triggering page navigation
      },
      // This ensures the gesture detector consumes the touch event
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Opacity(
            opacity: _animation.value,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.text,
                  style: TextStyle(
                    color: widget.textColor,
                    fontSize: widget.fontSize,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Noto Sans JP',
                  ),
                ),
                if (widget.showIcon) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_drop_down,
                    color: widget.textColor,
                    size: widget.fontSize,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

// DateGrid widget for selecting days
class DateGrid extends StatelessWidget {
  final int selectedDay;
  final Function(int) onDaySelected;

  const DateGrid({
    Key? key,
    required this.selectedDay,
    required this.onDaySelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      height: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          childAspectRatio: 1,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: 31,
        itemBuilder: (context, index) {
          final day = index + 1;
          final isSelected = day == selectedDay;

          // Special label for 31st
          final String label = day == 31 ? "31\n(말일)" : day.toString();

          return GestureDetector(
            onTap: () => onDaySelected(day),
            child: Container(
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontSize: day == 31 ? 10 : 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}