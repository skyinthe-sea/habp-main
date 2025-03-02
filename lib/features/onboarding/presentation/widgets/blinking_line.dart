import 'package:flutter/material.dart';

class BlinkingLine extends StatefulWidget {
  final double width;
  final Color color;
  final double height;
  final Duration blinkDuration;

  const BlinkingLine({
    Key? key,
    required this.width,
    required this.color,
    this.height = 3.0,
    this.blinkDuration = const Duration(milliseconds: 800),
  }) : super(key: key);

  @override
  State<BlinkingLine> createState() => _BlinkingLineState();
}

class _BlinkingLineState extends State<BlinkingLine> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.blinkDuration,
    );

    _animation = Tween<double>(begin: 1.0, end: 0.0).animate(_controller);

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: widget.width,
        height: widget.height,
        color: widget.color,
      ),
    );
  }
}