import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../../../../core/constants/app_colors.dart';
import '../../../calendar/presentation/controllers/calendar_controller.dart';
import '../controllers/quick_add_controller.dart';
import 'date_selection_dialog.dart';

/// Final dialog in the quick add flow
/// Allows inputting the transaction amount
class AmountInputDialog extends StatefulWidget {
  const AmountInputDialog({Key? key}) : super(key: key);

  @override
  State<AmountInputDialog> createState() => _AmountInputDialogState();
}

class _AmountInputDialogState extends State<AmountInputDialog>
    with SingleTickerProviderStateMixin {
  // Animation controller for animations
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final FocusNode _amountFocusNode = FocusNode();
  bool _saveEnabled = false;

  // Variables for circular slider
  double _currentAngle = 0.0;
  double _startAngle = 0.0;
  double _rotationSpeed = 0.0;
  int _lastUpdateTime = 0;
  double _cumulativeAngleChange = 0.0; // 누적 각도 변화 추적
  double _rotationAngle = 0.0; // 회전 애니메이션을 위한 각도 값

  // Key for the slider container to get its position
  final GlobalKey _sliderKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    // Start animation after a short delay
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _animationController.forward();
      }
    });

    // Set focus to amount field after a short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        FocusScope.of(context).requestFocus(_amountFocusNode);
      }
    });

    // Listen for changes to enable/disable save button
    _amountController.addListener(_updateSaveButtonState);

    // Initialize with a default amount
    _amountController.text = '0';
  }

  @override
  void dispose() {
    _amountController.removeListener(_updateSaveButtonState);
    _amountController.dispose();
    _descriptionController.dispose();
    _amountFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  /// Updates the enabled state of the save button based on input validity
  void _updateSaveButtonState() {
    final text = _amountController.text.replaceAll(',', '');
    setState(() {
      _saveEnabled = text.isNotEmpty &&
          double.tryParse(text) != null &&
          double.parse(text) > 0;
    });
  }

  /// Formats the amount with comma separators
  String _formatAmount(String text) {
    if (text.isEmpty) return '0';

    final onlyNumbers = text.replaceAll(',', '');
    if (onlyNumbers.isEmpty) return '0';

    final intValue = int.tryParse(onlyNumbers);
    if (intValue == null) return text;

    return NumberFormat('#,###').format(intValue);
  }

  /// Gets the center position of the circular slider
  Offset _getSliderCenter() {
    final RenderBox? renderBox = _sliderKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      return Offset.zero;
    }

    final size = renderBox.size;
    final position = renderBox.localToGlobal(Offset.zero);

    return Offset(
      position.dx + size.width / 2,
      position.dy + size.height / 2,
    );
  }

  /// Calculates the angle between center and position in degrees
  double _calculateAngle(Offset position) {
    final center = _getSliderCenter();

    if (center == Offset.zero) {
      return 0.0;
    }

    // Calculate angle relative to center
    final dx = position.dx - center.dx;
    final dy = position.dy - center.dy;

    // Convert to angle in degrees (0 degrees is at the right, positive angles go clockwise)
    final angleRadians = math.atan2(dy, dx);
    return (angleRadians * 180 / math.pi) + 90; // Add 90 to make top 0 degrees
  }

  /// Updates the amount based on angle change with reduced sensitivity
  void _updateAmountFromAngleChange(double angleChange) {
    // Calculate rotation speed for sensitivity
    final now = DateTime.now().millisecondsSinceEpoch;
    final timeDelta = now - _lastUpdateTime;
    if (timeDelta > 0) {
      _rotationSpeed = angleChange / timeDelta * 100; // Adjust for reasonable values
    }
    _lastUpdateTime = now;

    // 누적 각도 변화량 갱신
    _cumulativeAngleChange += angleChange;

    // 누적된 각도 변화가 임계값을 넘을 때만 금액 변경
    // 임계값 증가 (5도) - 더 큰 회전이 필요하도록 설정
    final double angleThreshold = 5.0;

    // 금액 변경 계산
    int amountChange = 0;

    if (_cumulativeAngleChange.abs() >= angleThreshold) {
      // 누적 각도의 방향에 따라 금액 변경
      final int direction = _cumulativeAngleChange > 0 ? 1 : -1;

      // 기본 변화량 1,000원
      amountChange = direction * 1000;

      // 회전 속도에 따른 배율 적용 (민감도 감소)
      // 속도 영향 계수 감소 및 임계값 증가
      if (_rotationSpeed.abs() > 1.5) {
        // 속도 영향을 완화하기 위해 배율 조정
        amountChange *= (1 + math.min(3, _rotationSpeed.abs() / 2)).round();
      }

      // 누적 각도 초기화 (임계값의 나머지만 보존)
      _cumulativeAngleChange = _cumulativeAngleChange % angleThreshold;

      // 현재 금액에 변화량 적용
      final String currentText = _amountController.text.isEmpty ? '0' : _amountController.text;
      final int currentAmount = int.tryParse(currentText.replaceAll(',', '')) ?? 0;
      int newAmount = currentAmount + amountChange;

      // 음수 방지
      newAmount = math.max(0, newAmount);

      // 금액이 변경된 경우에만 UI 업데이트
      if (newAmount != currentAmount) {
        final formatted = _formatAmount(newAmount.toString());
        _amountController.text = formatted;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<QuickAddController>();

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dialog title and back button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '금액 입력',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_back, size: 20),
                  onPressed: () {
                    // Go back to the previous dialog
                    Navigator.of(context).pop();

                    // Show the date selection dialog again
                    showGeneralDialog(
                      context: context,
                      pageBuilder: (_, __, ___) => const DateSelectionDialog(),
                      transitionBuilder: (context, animation, secondaryAnimation, child) {
                        // 풍선 터지는 효과를 위한 커브 설정
                        final curve = CurvedAnimation(
                          parent: animation,
                          curve: Curves.elasticOut, // 가장 중요한 설정! 풍선 튕김 효과
                        );

                        // 크기 애니메이션을 적용
                        return ScaleTransition(
                          scale: curve, // elasticOut 커브를 적용
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        );
                      },
                      // 매우 빠른 애니메이션을 위해 시간 단축
                      transitionDuration: const Duration(milliseconds: 150),
                      barrierDismissible: true,
                      barrierLabel: '',
                      barrierColor: Colors.black.withOpacity(0.5),
                    );
                  },
                  color: Colors.grey,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Transaction info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        '카테고리:',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Obx(() => Text(
                          controller.transaction.value.categoryName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        )),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text(
                        '날짜:',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Obx(() => Text(
                          DateFormat('yyyy년 MM월 dd일').format(
                              controller.transaction.value.transactionDate),
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        )),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Amount input field
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '금액',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: _amountController,
                  focusNode: _amountFocusNode,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: '0',
                    suffixText: '원',
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  onChanged: (value) {
                    // Format with commas
                    final formatted = _formatAmount(value);
                    if (formatted != value) {
                      _amountController.value = TextEditingValue(
                        text: formatted,
                        selection:
                        TextSelection.collapsed(offset: formatted.length),
                      );
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Description input field (optional)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '설명 (선택사항)',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    hintText: '내용을 입력하세요',
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Hint text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '원형 다이얼을 천천히 돌려 금액을 정밀하게 조정할 수 있습니다',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Save button and circular slider
            Row(
              children: [
                // Save button
                Expanded(
                  child: Obx(() => ElevatedButton(
                    onPressed: !_saveEnabled || controller.isLoading.value
                        ? null
                        : () async {
                      // Parse amount
                      final amount = double.parse(
                          _amountController.text.replaceAll(',', ''));
                      controller.setAmount(amount);

                      // Set description if provided
                      if (_descriptionController.text.isNotEmpty) {
                        controller
                            .setDescription(_descriptionController.text);
                      }

                      // Save transaction
                      final success = await controller.saveTransaction();

                      // Close dialog and show success message if successful
                      if (success) {
                        Navigator.of(context).pop();

                        // Show success snackbar
                        Get.snackbar(
                          '성공',
                          '거래가 추가되었습니다',
                          snackPosition: SnackPosition.TOP,
                          backgroundColor: Colors.green,
                          colorText: Colors.white,
                          margin: const EdgeInsets.all(16),
                          duration: const Duration(seconds: 2),
                        );
                      } else {
                        // Show error message
                        Get.snackbar(
                          '오류',
                          '거래 추가에 실패했습니다',
                          snackPosition: SnackPosition.TOP,
                          backgroundColor: Colors.red,
                          colorText: Colors.white,
                          margin: const EdgeInsets.all(16),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledBackgroundColor:
                      AppColors.primary.withOpacity(0.3),
                    ),
                    child: controller.isLoading.value
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : const Text(
                      '저장하기',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )),
                ),

                const SizedBox(width: 16),

                // Improved Circular Slider
                Container(
                  key: _sliderKey,
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withOpacity(0.1),
                    border: Border.all(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                  child: GestureDetector(
                    onPanStart: (details) {
                      _startAngle = _calculateAngle(details.globalPosition);
                      _currentAngle = _startAngle;
                      _lastUpdateTime = DateTime.now().millisecondsSinceEpoch;
                      _cumulativeAngleChange = 0.0; // 새로운 제스처 시작 시 누적 각도 초기화
                    },
                    onPanUpdate: (details) {
                      final newAngle = _calculateAngle(details.globalPosition);

                      // Calculate the delta with careful handling of the 360-degree wrap-around
                      double angleDelta = newAngle - _currentAngle;

                      // Adjust for wrap-around at 0/360 degrees
                      if (angleDelta > 180) {
                        angleDelta -= 360;
                      } else if (angleDelta < -180) {
                        angleDelta += 360;
                      }

                      // Update current angle for next calculation
                      _currentAngle = newAngle;

                      // 회전 애니메이션을 위한 각도 업데이트
                      setState(() {
                        _rotationAngle += angleDelta;
                      });

                      // Update the amount based on the angle change
                      _updateAmountFromAngleChange(angleDelta);
                    },
                    onPanEnd: (details) {
                      _rotationSpeed = 0;
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // 회전하는 다이얼
                        Transform.rotate(
                          angle: _rotationAngle * math.pi / 180, // 각도를 라디안으로 변환
                          child: CustomPaint(
                            painter: RotatingDialPainter(AppColors.primary),
                            size: const Size(80, 80),
                          ),
                        ),

                        // 고정된 배경 다이얼 (눈금)
                        CustomPaint(
                          painter: DialPainter(),
                          size: const Size(80, 80),
                        ),

                        // Center text
                        const Text(
                          '금액설정',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        // Indicator arrow (fixed)
                        Positioned(
                          top: 10,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for drawing the dial indicators on the circular slider
class DialPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Paint for the tick marks (고정된 눈금)
    final tickPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.3)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Draw tick marks around the circle
    for (int i = 0; i < 36; i++) {
      final angle = i * 10 * math.pi / 180;
      final outerPoint = Offset(
        center.dx + (radius - 5) * math.cos(angle),
        center.dy + (radius - 5) * math.sin(angle),
      );
      final innerPoint = Offset(
        center.dx + (radius - 10) * math.cos(angle),
        center.dy + (radius - 10) * math.sin(angle),
      );

      canvas.drawLine(innerPoint, outerPoint, tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false; // 고정된 배경이므로 다시 그릴 필요 없음
  }
}

/// 회전하는 다이얼을 그리는 CustomPainter
class RotatingDialPainter extends CustomPainter {
  final Color color;

  RotatingDialPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 회전하는 주요 눈금
    final mainTickPaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    // 주요 회전 눈금 (4개)
    for (int i = 0; i < 4; i++) {
      final angle = i * 90 * math.pi / 180;
      final outerPoint = Offset(
        center.dx + (radius - 3) * math.cos(angle),
        center.dy + (radius - 3) * math.sin(angle),
      );
      final innerPoint = Offset(
        center.dx + (radius - 15) * math.cos(angle),
        center.dy + (radius - 15) * math.sin(angle),
      );

      canvas.drawLine(innerPoint, outerPoint, mainTickPaint);
    }

    // 회전 방향 표시기
    final markerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // 위쪽 방향에 더 큰 표시기 추가
    // final markerAngle = 0; // 0도는 12시 방향
    // final markerPoint = Offset(
    //   center.dx + (radius - 20) * math.cos(markerAngle),
    //   center.dy + (radius - 20) * math.sin(markerAngle),
    // );

    // canvas.drawCircle(markerPoint, 4, markerPaint);

    // 원형 경로 그리기 (회전 경로)
    final pathPaint = Paint()
      ..color = color.withOpacity(0.7)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius - 25, pathPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // 회전하는 요소이므로 다시 그려야 함
  }
}