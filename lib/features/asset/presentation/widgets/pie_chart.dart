import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class CustomPieChart extends StatelessWidget {
  final Map<String, double> data;
  final double totalValue;

  const CustomPieChart({
    Key? key,
    required this.data,
    required this.totalValue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty || totalValue <= 0) {
      return Container();
    }

    return CustomPaint(
      size: const Size(120, 120),
      painter: PieChartPainter(data: data, totalValue: totalValue),
    );
  }
}

class PieChartPainter extends CustomPainter {
  final Map<String, double> data;
  final double totalValue;

  PieChartPainter({
    required this.data,
    required this.totalValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;

    // 파이 차트의 색상 리스트
    final List<Color> colors = [
      AppColors.cate1,
      AppColors.cate2,
      AppColors.cate3,
      AppColors.cate4,
      AppColors.cate5,
      AppColors.cate6,
      AppColors.cate7,
      AppColors.cate8,
      AppColors.cate9,
      AppColors.cate10,
    ];

    double startAngle = -pi / 2; // -90도에서 시작

    int colorIndex = 0;
    data.forEach((category, value) {
      final sweepAngle = (value / totalValue) * 2 * pi;

      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = colors[colorIndex % colors.length];

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      startAngle += sweepAngle;
      colorIndex++;
    });

    // 내부 흰색 원 (도넛 모양을 만들기 위함)
    final innerCirclePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white;

    canvas.drawCircle(
      center,
      radius * 0.6, // 내부 원의 크기
      innerCirclePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}