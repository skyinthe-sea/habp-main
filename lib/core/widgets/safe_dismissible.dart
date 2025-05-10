// lib/core/widgets/safe_dismissible.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// SafeDismissible은 Flutter의 Dismissible 위젯을 안전하게 래핑하여
/// "A dismissed Dismissible widget is still part of the tree" 에러를 방지합니다.
class SafeDismissible extends StatefulWidget {
  final Key dismissibleKey;
  final Widget child;
  final DismissDirection direction;
  final Widget background;
  final Future<bool?> Function(DismissDirection)? confirmDismiss;
  final void Function(DismissDirection)? onDismissed;
  final double dismissThreshold;
  final Function? onUpdate;

  const SafeDismissible({
    Key? key,
    required this.dismissibleKey,
    required this.child,
    this.direction = DismissDirection.horizontal,
    required this.background,
    this.confirmDismiss,
    this.onDismissed,
    this.dismissThreshold = 0.5,
    this.onUpdate,
  }) : super(key: key);

  @override
  State<SafeDismissible> createState() => _SafeDismissibleState();
}

class _SafeDismissibleState extends State<SafeDismissible> {
  // 삭제 여부를 추적하기 위한 상태
  bool _isDismissed = false;

  @override
  Widget build(BuildContext context) {
    // 이미 삭제된 경우 빈 컨테이너를 반환하여 에러 방지
    if (_isDismissed) {
      return const SizedBox.shrink();
    }

    return Dismissible(
      key: widget.dismissibleKey,
      direction: widget.direction,
      background: widget.background,
      dismissThresholds: {
        widget.direction: widget.dismissThreshold,
      },
      confirmDismiss: widget.confirmDismiss != null 
          ? (direction) async {
              final result = await widget.confirmDismiss!(direction);
              return result;
            }
          : null,
      onDismissed: (direction) {
        // 삭제 상태 즉시 업데이트
        setState(() {
          _isDismissed = true;
        });
        
        // 콜백이 있으면 호출
        if (widget.onDismissed != null) {
          widget.onDismissed!(direction);
        }
      },
      child: widget.child,
    );
  }
}