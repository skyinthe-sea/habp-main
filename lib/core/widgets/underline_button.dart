import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class UnderlineButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final double width;

  const UnderlineButton({
    Key? key,
    required this.text,
    required this.onTap,
    this.width = double.infinity,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 16,
              fontFamily: 'YourCustomFont', // 여기에 실제 폰트 이름을 넣어주세요
            ),
          ),
          Stack(
            children: [
              Container(
                width: width,
                height: 1,
                color: AppColors.white,
              ),
              Positioned(
                right: 0,
                top: -4,
                child: CustomPaint(
                  size: const Size(8, 8),
                  painter: TrianglePainter(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.white
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}