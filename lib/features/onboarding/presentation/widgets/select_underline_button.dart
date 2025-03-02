// lib/features/onboarding/widgets/select_underline_button.dart

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'blinking_line.dart';

class SelectUnderlineButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final double width;
  final double fontSize;
  final Color textColor;
  final bool showDropIcon;

  const SelectUnderlineButton({
    Key? key,
    required this.text,
    required this.onTap,
    this.width = 100,
    this.fontSize = 24,
    this.textColor = AppColors.primary,
    this.showDropIcon = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                text,
                style: TextStyle(
                  color: textColor,
                  fontSize: fontSize,
                  fontFamily: 'hakFont',
                ),
              ),
              if (showDropIcon) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_drop_down,
                  color: textColor,
                  size: fontSize,
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          BlinkingLine(
            width: width,
            color: textColor,
            height: 2,
          ),
        ],
      ),
    );
  }
}

// 커스텀 셀렉트 메뉴를 표시하는 함수
Future<T?> showCustomSelectMenu<T>({
  required BuildContext context,
  required List<T> items,
  required String Function(T) itemText,
  required Offset position,
  double maxHeight = 200,
  Color backgroundColor = AppColors.primary,
  Color textColor = Colors.white,
}) async {
  final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
  final size = overlay.size;

  // 메뉴가 화면 밖으로 나가지 않도록 위치 조정
  final double menuWidth = 150;
  final double menuX = position.dx;
  final double menuY = position.dy;

  // 오른쪽에 공간이 부족한 경우 왼쪽으로 이동
  final adjustedX = menuX + menuWidth > size.width
      ? size.width - menuWidth - 10
      : menuX;

  // 실제 표시될 아이템 수에 따라 높이 계산
  final itemHeight = 48.0;
  final double calculatedHeight = items.length * itemHeight;
  final double menuHeight = calculatedHeight > maxHeight
      ? maxHeight
      : calculatedHeight;

  // 아래쪽에 공간이 부족한 경우 위쪽으로 이동
  final adjustedY = menuY + menuHeight > size.height
      ? menuY - menuHeight
      : menuY;

  return await showDialog<T>(
    context: context,
    barrierColor: Colors.transparent,
    builder: (BuildContext context) {
      return Stack(
        children: [
          Positioned(
            left: adjustedX,
            top: adjustedY,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              color: backgroundColor,
              child: Container(
                width: menuWidth,
                constraints: BoxConstraints(
                  maxHeight: maxHeight,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: items.length,
                  padding: EdgeInsets.zero,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return InkWell(
                      onTap: () {
                        Navigator.of(context).pop(item);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          border: index < items.length - 1
                              ? Border(
                            bottom: BorderSide(
                              color: textColor.withOpacity(0.2),
                              width: 1,
                            ),
                          )
                              : null,
                        ),
                        child: Text(
                          itemText(item),
                          style: TextStyle(
                            color: textColor,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}