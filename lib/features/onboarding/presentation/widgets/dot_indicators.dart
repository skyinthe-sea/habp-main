import 'package:flutter/material.dart';
import 'package:habp/core/constants/app_colors.dart';

class DotIndicators extends StatelessWidget {
  final int currentIndex;
  final int pageCount;

  const DotIndicators({
    Key? key,
    required this.currentIndex,
    required this.pageCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        pageCount,
            (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: currentIndex == index ? 12 : 8,
          width: currentIndex == index ? 12 : 8,
          decoration: BoxDecoration(
            color: currentIndex == index
                ? AppColors.grey
                : AppColors.white,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }
}