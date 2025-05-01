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

  // Enhanced dial control system variables
  bool _isFlashing = false; // for visual feedback
  int _consecutiveSlowMovements = 0; // for precision mode detection
  int _lastAmount = 0; // to track amount changes
  bool _isPrecisionMode = false; // current precision mode state
  List<double> _recentSpeedValues = []; // to track recent movement patterns
  double _speedFactor = 1.0; // Current speed factor for visualization

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

    // Initialize last amount
    _lastAmount = 0;
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

  /// Updates the amount based on angle change with enhanced precision and usability
  void _updateAmountFromAngleChange(double angleChange) {
    // Calculate rotation speed with improved timing precision
    final now = DateTime.now().millisecondsSinceEpoch;
    final timeDelta = now - _lastUpdateTime;

    if (timeDelta > 0) {
      // 속도 계산을 더 정밀하게 조정 (40은 기본 감도 계수)
      _rotationSpeed = angleChange / timeDelta * 40;

      // 스마트 감도 보정: 느린 움직임에서는 감도를 더 높임 (미세 조정 용이)
      if (_rotationSpeed.abs() < 0.5) {
        _rotationSpeed *= 1.2; // 느린 움직임 감도 향상
      }
    }
    _lastUpdateTime = now;

    // 최근 속도 기록 업데이트
    _recentSpeedValues.add(_rotationSpeed.abs());
    if (_recentSpeedValues.length > 10) {
      _recentSpeedValues.removeAt(0);
    }

    // 연속된 느린 움직임 감지
    if (_rotationSpeed.abs() < 1.0) {
      _consecutiveSlowMovements++;
    } else {
      _consecutiveSlowMovements = 0;
    }

    // 정밀 모드 상태 업데이트
    _isPrecisionMode = _isInPrecisionMode();

    // 누적 각도 변화량 갱신
    _cumulativeAngleChange += angleChange;

    // 정밀도 모드 결정 (사용자의 움직임 패턴 인식)
    bool precisionMode = _isPrecisionMode;

    // 임계값 동적 조정 (정밀 모드일 때 더 작은 임계값 사용)
    final double angleThreshold = precisionMode ? 3.0 : 6.0;

    // 금액 변경 계산
    int amountChange = 0;

    if (_cumulativeAngleChange.abs() >= angleThreshold) {
      // 누적 각도의 방향에 따라 금액 변경
      final int direction = _cumulativeAngleChange > 0 ? 1 : -1;

      // 기본 변화량 설정 - 정밀 모드에서는 더 작은 단위
      amountChange = direction * (precisionMode ? 1 : 10);

      // 회전 속도 구간 분할 및 최적화
      _speedFactor = _calculateSpeedFactor(precisionMode);

      // 속도 배율 적용
      amountChange = (amountChange * _speedFactor).round();

      // 현재 금액에 스마트 스냅 적용 (사용자가 자주 사용하는 금액 경계에 스냅)
      final String currentText = _amountController.text.isEmpty ? '0' : _amountController.text;
      final int currentAmount = int.tryParse(currentText.replaceAll(',', '')) ?? 0;
      int newAmount = currentAmount + amountChange;

      // 스마트 스냅 적용 (천원, 만원, 십만원 등 자주 사용하는 경계에 근접하면 스냅)
      newAmount = _applySmartSnapping(newAmount, amountChange);

      // 음수 방지
      newAmount = math.max(0, newAmount);

      // 금액이 변경된 경우에만 UI 업데이트
      if (newAmount != currentAmount) {
        final formatted = _formatAmount(newAmount.toString());
        _amountController.text = formatted;

        // 향상된 햅틱 피드백 시스템
        _provideHapticFeedback(currentAmount, newAmount, amountChange.abs());

        // 중요 경계 통과 시 추가 시각적 피드백 (번쩍임 효과)
        if (_isSignificantAmountChange(currentAmount, newAmount)) {
          _flashAmountField();
        }

        // 마지막 금액 업데이트
        _lastAmount = newAmount;
      }

      // 누적 각도 초기화 (임계값의 나머지만 보존)
      _cumulativeAngleChange = _cumulativeAngleChange % angleThreshold;
    }

    // 상태 업데이트
    setState(() {});
  }

  /// 정밀 모드 여부 판단 (사용자의 움직임 패턴 분석)
  bool _isInPrecisionMode() {
    // 지난 5개의 각도 변화를 기반으로 정밀 모드 여부 결정
    // 사용자가 매우 느리고 신중하게 움직이는 경우 정밀 모드로 간주
    return _rotationSpeed.abs() < 1.0 && _consecutiveSlowMovements >= 3;
  }

  /// 속도 기반 배율 계수 계산 (정밀도에 따라 다른 속도 계수 적용)
  double _calculateSpeedFactor(bool precisionMode) {
    double speedFactor = 1.0;

    if (precisionMode) {
      // 정밀 모드일 때는 더 세밀한 속도 구간 분할
      if (_rotationSpeed.abs() <= 0.5) {
        speedFactor = 10; // 1원 단위
      } else if (_rotationSpeed.abs() <= 1.0) {
        speedFactor = 50; // 5원 단위
      } else if (_rotationSpeed.abs() <= 2.0) {
        speedFactor = 100; // 10원 단위
      } else if (_rotationSpeed.abs() <= 3.0) {
        speedFactor = 500; // 50원 단위
      } else {
        speedFactor = 1000; // 100원 단위
      }
    } else {
      // 일반 모드일 때는 더 넓은 구간 분할
      if (_rotationSpeed.abs() <= 1.0) {
        speedFactor = 1; // 10원 단위 (기본값 * 1)
      } else if (_rotationSpeed.abs() <= 2.0) {
        speedFactor = 5; // 50원 단위
      } else if (_rotationSpeed.abs() <= 3.5) {
        speedFactor = 10; // 100원 단위
      } else if (_rotationSpeed.abs() <= 5.0) {
        speedFactor = 50; // 500원 단위
      } else if (_rotationSpeed.abs() <= 7.0) {
        speedFactor = 100; // 1,000원 단위
      } else if (_rotationSpeed.abs() <= 10.0) {
        speedFactor = 500; // 5,000원 단위
      } else if (_rotationSpeed.abs() <= 13.0) {
        speedFactor = 1000; // 10,000원 단위
      } else if (_rotationSpeed.abs() <= 16.0) {
        speedFactor = 5000; // 50,000원 단위
      } else {
        speedFactor = 10000; // 100,000원 단위
      }
    }

    return speedFactor;
  }

  /// 스마트 스냅 기능 (자주 사용하는 금액 경계에 근접하면 그 값으로 스냅)
  int _applySmartSnapping(int amount, int change) {
    // 금액 스냅 경계들 (자주 사용하는 금액들)
    List<int> snapThresholds = [
      1000, 5000, 10000, 50000, 100000, 500000, 1000000
    ];

    // 스냅 적용 거리 (이 범위 내에 있으면 스냅)
    int snapDistance = change.abs() * 2; // 변화량의 2배까지 스냅 허용

    // 최소 스냅 거리 설정
    snapDistance = math.max(snapDistance, 50); // 최소 50원

    // 최대 스냅 거리 설정 (너무 멀리 스냅되지 않도록)
    snapDistance = math.min(snapDistance, 300); // 최대 300원

    // 각 스냅 경계 확인
    for (int threshold in snapThresholds) {
      // 현재 금액이 스냅 경계 근처인지 확인
      if ((amount - threshold).abs() <= snapDistance) {
        // 사용자의 의도 방향 고려 (증가 중인지 감소 중인지)
        if ((change > 0 && amount > threshold) ||
            (change < 0 && amount < threshold) ||
            (amount - threshold).abs() < (snapDistance ~/ 2)) {
          return threshold; // 스냅 적용
        }
      }
    }

    return amount; // 스냅 미적용
  }

  /// 중요한 금액 경계 통과 감지 (시각적 피드백 제공용)
  bool _isSignificantAmountChange(int oldAmount, int newAmount) {
    // 주요 경계 정의
    List<int> significantThresholds = [1000, 10000, 50000, 100000, 500000, 1000000];

    // 경계 통과 여부 확인
    for (int threshold in significantThresholds) {
      // 금액이 경계를 넘었는지 확인 (상향 또는 하향)
      if ((oldAmount < threshold && newAmount >= threshold) ||
          (oldAmount >= threshold && newAmount < threshold)) {
        return true;
      }
    }

    return false;
  }

  /// 향상된 햅틱 피드백 제공
  void _provideHapticFeedback(int oldAmount, int newAmount, int changeAmount) {
    // 기본 변화 피드백
    if (changeAmount >= 10000) {
      HapticFeedback.heavyImpact(); // 강한 진동
    } else if (changeAmount >= 1000) {
      HapticFeedback.mediumImpact(); // 중간 진동
    } else if (changeAmount >= 100) {
      HapticFeedback.lightImpact(); // 약한 진동
    } else {
      HapticFeedback.selectionClick(); // 가장 약한 클릭감
    }

    // 중요 금액 경계 도달 시 추가 피드백
    if (_isSignificantAmountChange(oldAmount, newAmount)) {
      // 약간의 지연 후 추가 햅틱 피드백 (이중 진동 효과)
      Future.delayed(const Duration(milliseconds: 100), () {
        HapticFeedback.mediumImpact();
      });
    }
  }

  /// 금액 필드 번쩍임 효과 (시각적 피드백)
  void _flashAmountField() {
    setState(() {
      _isFlashing = true;
    });

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _isFlashing = false;
        });
      }
    });
  }

  /// Enhanced dial mode indicator widget
  Widget _buildDialModeIndicator() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: _isPrecisionMode
            ? AppColors.primary.withOpacity(0.2)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Center(
        child: Text(
          _isPrecisionMode ? '정밀 모드' : '일반 모드',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: _isPrecisionMode ? AppColors.primary : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  /// Enhanced amount field with visual feedback
  Widget _buildEnhancedAmountField() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isFlashing
              ? AppColors.primary
              : _amountFocusNode.hasFocus
              ? AppColors.primary
              : Colors.grey.shade300,
          width: _isFlashing ? 2.0 : 1.0,
        ),
        color: _isFlashing ? AppColors.primary.withOpacity(0.05) : Colors.white,
      ),
      child: TextField(
        controller: _amountController,
        focusNode: _amountFocusNode,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.end,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: _isFlashing ? AppColors.primary : Colors.black,
        ),
        decoration: InputDecoration(
          hintText: '0',
          suffixText: '원',
          border: InputBorder.none,
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
    );
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

                // Enhanced amount field
                _buildEnhancedAmountField(),

                // Hint text for amount input
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4, right: 4),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '설명란 옆 원형 다이얼을 돌려 금액을 세밀하게 조정할 수 있습니다',
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
              ],
            ),

            const SizedBox(height: 16),

            // Description input field with circular dial positioned on the right
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Description input field - takes most of the width
                    Expanded(
                      child: TextField(
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
                    ),

                    const SizedBox(width: 12),

                    // Circular Dial - now positioned to the right of description field
                    Column(
                      children: [
                        Container(
                          key: _sliderKey,
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withOpacity(0.1),
                            border: Border.all(
                              color: _isPrecisionMode
                                  ? AppColors.primary
                                  : AppColors.primary.withOpacity(0.7),
                              width: _isPrecisionMode ? 2.5 : 2.0,
                            ),
                          ),
                          child: GestureDetector(
                            onPanStart: (details) {
                              _startAngle = _calculateAngle(details.globalPosition);
                              _currentAngle = _startAngle;
                              _lastUpdateTime = DateTime.now().millisecondsSinceEpoch;
                              _cumulativeAngleChange = 0.0; // 새로운 제스처 시작 시 누적 각도 초기화
                              // 다이얼 조작 시작 시 햅틱 피드백 제공
                              HapticFeedback.selectionClick();
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
                              // 다이얼 조작 종료 시 다시 한번 햅틱 피드백
                              HapticFeedback.lightImpact();
                            },
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // 회전하는 다이얼
                                Transform.rotate(
                                  angle: _rotationAngle * math.pi / 180, // 각도를 라디안으로 변환
                                  child: CustomPaint(
                                    painter: EnhancedRotatingDialPainter(
                                      AppColors.primary,
                                      isPrecisionMode: _isPrecisionMode,
                                      speedFactor: math.min(_speedFactor / 10000, 1.0),
                                    ),
                                    size: const Size(70, 70),
                                  ),
                                ),

                                // 고정된 배경 다이얼 (눈금)
                                CustomPaint(
                                  painter: DialPainter(),
                                  size: const Size(70, 70),
                                ),

                                // Center text
                                const Text(
                                  '금액설정',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),

                                // Indicator arrow (fixed)
                                Positioned(
                                  top: 8,
                                  child: Container(
                                    width: 8,
                                    height: 8,
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

                        // Mode indicator below the dial
                        const SizedBox(height: 4),
                        _buildDialModeIndicator(),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Save button - improved styling and positioning
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 8),
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
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  minimumSize: const Size(double.infinity, 52), // 더 큰 버튼 크기
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor:
                  AppColors.primary.withOpacity(0.3),
                  elevation: 0, // 그림자 제거
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
                    fontSize: 17, // 글자 크기 증가
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )),
            ),

            const SizedBox(height: 8), // 하단 여백 추가
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

/// Enhanced rotating dial painter with precision mode and speed indicator
class EnhancedRotatingDialPainter extends CustomPainter {
  final Color color;
  final bool isPrecisionMode;
  final double speedFactor;

  EnhancedRotatingDialPainter(this.color, {
    required this.isPrecisionMode,
    required this.speedFactor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 회전하는 주요 눈금
    final mainTickPaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    // 정밀 모드일 때는 더 많은 눈금 표시
    final tickCount = isPrecisionMode ? 8 : 4;
    for (int i = 0; i < tickCount; i++) {
      final angle = i * (360 / tickCount) * math.pi / 180;
      final outerPoint = Offset(
        center.dx + (radius - 3) * math.cos(angle),
        center.dy + (radius - 3) * math.sin(angle),
      );
      final innerPoint = Offset(
        center.dx + (radius - (isPrecisionMode ? 12 : 15)) * math.cos(angle),
        center.dy + (radius - (isPrecisionMode ? 12 : 15)) * math.sin(angle),
      );

      canvas.drawLine(innerPoint, outerPoint, mainTickPaint);
    }

    // 속도 인디케이터 그리기
    final speedPaint = Paint()
      ..color = color.withOpacity(0.7)
      ..strokeWidth = 4 * math.max(speedFactor, 0.1) // 속도에 따라 두께 변화
      ..style = PaintingStyle.stroke;

    // 원형 경로 그리기 (회전 경로)
    canvas.drawArc(
      Rect.fromCenter(
        center: center,
        width: radius * 1.2,
        height: radius * 1.2,
      ),
      -math.pi / 2, // 시작 각도 (위쪽)
      math.pi * 2 * speedFactor, // 속도에 따른 호의 길이
      false,
      speedPaint,
    );

    // 정밀 모드일 때 추가 표시
    if (isPrecisionMode) {
      final precisionModePaint = Paint()
        ..color = color.withOpacity(0.3)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(center, radius * 0.3, precisionModePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is EnhancedRotatingDialPainter) {
      return oldDelegate.isPrecisionMode != isPrecisionMode ||
          oldDelegate.speedFactor != speedFactor;
    }
    return true;
  }
}