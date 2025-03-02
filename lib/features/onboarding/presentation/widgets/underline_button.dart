import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'blinking_line.dart';

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
              fontSize: 40,
              fontFamily: 'hakFont', // 여기에 실제 폰트 이름을 넣어주세요
            ),
          ),
          Stack(
            children: [
              BlinkingLine(
                width: width,
                color: AppColors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }
}