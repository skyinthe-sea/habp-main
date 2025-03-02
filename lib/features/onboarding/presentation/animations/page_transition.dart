import 'package:flutter/material.dart';

// 정갈한 페이지 전환 애니메이션
class JapaneseStylePageTransition extends PageRouteBuilder {
  final Widget page;

  JapaneseStylePageTransition({required this.page})
      : super(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = 0.0;
      const end = 1.0;
      const curve = Curves.easeInOutQuart;

      var fadeAnimation = Tween(
        begin: begin,
        end: end,
      ).animate(
        CurvedAnimation(
          parent: animation,
          curve: curve,
        ),
      );

      return FadeTransition(
        opacity: fadeAnimation,
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 800),
  );
}

// 컨텐츠 애니메이션을 위한 위젯
class ContentAnimation extends StatelessWidget {
  final Widget child;
  final bool isVisible;

  const ContentAnimation({
    Key? key,
    required this.child,
    this.isVisible = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutQuart,
      child: AnimatedScale(
        scale: isVisible ? 1.0 : 0.95,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutQuart,
        child: child,
      ),
    );
  }
}

// 페이지 인디케이터 애니메이션
class DotAnimation extends StatelessWidget {
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;

  const DotAnimation({
    Key? key,
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: isActive ? 12 : 8,
      width: isActive ? 12 : 8,
      decoration: BoxDecoration(
        color: isActive ? activeColor : inactiveColor,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}