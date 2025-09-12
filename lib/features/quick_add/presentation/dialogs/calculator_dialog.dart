// lib/features/quick_add/presentation/dialogs/calculator_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/controllers/theme_controller.dart';

class CalculatorDialog extends StatefulWidget {
  final int initialValue;

  const CalculatorDialog({
    Key? key,
    this.initialValue = 0,
  }) : super(key: key);

  @override
  State<CalculatorDialog> createState() => _CalculatorDialogState();
}

class _CalculatorDialogState extends State<CalculatorDialog> {
  // 현재 계산기 화면에 표시되는 값
  String _display = '0';

  // 계산 과정을 보여주는 표현식
  String _expression = '';

  // 계산을 위한 값들 (숫자 리스트와 연산자 리스트)
  final List<double> _numbers = [];
  final List<String> _operators = [];

  // 현재 입력 중인 숫자
  String _currentInput = '';

  // 새로운 숫자 입력 시작 여부
  bool _startNew = true;

  // 계산 완료 여부 (= 버튼 누른 후)
  bool _calculationComplete = false;

  // 수평 스크롤 컨트롤러
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // 초기값이 있으면 표시
    if (widget.initialValue > 0) {
      _display = widget.initialValue.toString();
      _currentInput = _display;
      _expression = _display;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // 스크롤을 오른쪽 끝으로 이동
  void _scrollToEnd() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // 숫자 버튼 처리
  void _onNumberPressed(String value) {
    setState(() {
      // 계산 완료 후 새 숫자를 입력하면 모든 것을 리셋
      if (_calculationComplete) {
        _display = value;
        _expression = value;
        _numbers.clear();
        _operators.clear();
        _currentInput = value;
        _startNew = false;
        _calculationComplete = false;
        return;
      }

      // 새로운 숫자 입력 시작이면 화면 초기화
      if (_startNew) {
        _display = value;
        _currentInput = value;

        // 이미 이전 계산이 있을 경우, 표현식에 추가
        if (_numbers.isNotEmpty) {
          _expression = _updateExpression();
        } else {
          _expression = value;
        }

        _startNew = false;
      } else {
        // 0만 있는 경우 교체, 그렇지 않으면 추가
        if (_currentInput == '0') {
          _currentInput = value;
          _display = value;

          // 표현식 업데이트
          if (_numbers.isEmpty) {
            _expression = value;
          } else {
            _expression = _updateExpression();
          }
        } else {
          _currentInput += value;
          _display = _currentInput;

          // 표현식 업데이트
          if (_numbers.isEmpty) {
            _expression = _currentInput;
          } else {
            _expression = _updateExpression();
          }
        }
      }
    });

    _scrollToEnd();

    // 햅틱 피드백 제공
    HapticFeedback.lightImpact();
  }

  // 현재 상태에 기반한 표현식 업데이트
  String _updateExpression() {
    String expr = '';

    // 모든 이전 숫자와 연산자 추가
    for (int i = 0; i < _numbers.length; i++) {
      // 숫자가 정수면 소수점 제거
      if (_numbers[i] == _numbers[i].toInt()) {
        expr += _numbers[i].toInt().toString();
      } else {
        expr += _numbers[i].toString();
      }

      // 연산자가 있으면 추가
      if (i < _operators.length) {
        expr += ' ${_operators[i]} ';
      }
    }

    // 현재 입력 중인 숫자 추가
    expr += _currentInput;

    return expr;
  }

  // 연산자 버튼 처리
  void _onOperationPressed(String operation) {
    // 현재 입력이 없고 숫자도 없으면 무시
    if (_currentInput.isEmpty && _numbers.isEmpty) return;

    // 연산자 버튼 누르면 계산 완료 상태 해제
    _calculationComplete = false;

    setState(() {
      // 현재 입력 중인 숫자가 있으면 numbers 배열에 추가
      if (_currentInput.isNotEmpty) {
        double value = double.tryParse(_currentInput) ?? 0;
        _numbers.add(value);
        _currentInput = '';
      }

      // 여러 숫자가 있고 연산자도 있다면 중간 계산 수행
      if (_numbers.length >= 2 && _operators.length >= 1) {
        // 지금까지의 계산 수행
        double result = _performCalculation();

        // 계산 결과를 첫 번째 숫자로 설정하고 나머지 숫자/연산자 제거
        _numbers.clear();
        _numbers.add(result);
        _operators.clear();

        // 결과 표시 업데이트
        if (result == result.toInt()) {
          _display = result.toInt().toString();
        } else {
          _display = result.toString();
        }
      }

      // 연산자 추가
      _operators.add(operation);
      _startNew = true;

      // 표현식 업데이트
      _expression = _updateExpression();
    });

    _scrollToEnd();

    // 햅틱 피드백 제공
    HapticFeedback.mediumImpact();
  }

  // 현재까지 입력된 숫자와 연산자로 계산 수행
  double _performCalculation() {
    if (_numbers.isEmpty) return 0;

    double result = _numbers[0];

    for (int i = 0; i < _operators.length && i + 1 < _numbers.length; i++) {
      switch (_operators[i]) {
        case '+':
          result += _numbers[i + 1];
          break;
        case '-':
          result -= _numbers[i + 1];
          break;
        case '×':
          result *= _numbers[i + 1];
          break;
        case '÷':
          if (_numbers[i + 1] != 0) {
            result /= _numbers[i + 1];
          } else {
            throw Exception('0으로 나눌 수 없습니다');
          }
          break;
      }
    }

    return result;
  }

  // 계산 결과 처리
  void _calculateResult() {
    // 입력 중인 숫자가 있으면 추가
    if (_currentInput.isNotEmpty) {
      _numbers.add(double.tryParse(_currentInput) ?? 0);
      _currentInput = '';
    }

    // 숫자가 없거나 연산자가 없으면 계산 불가
    if (_numbers.isEmpty || (_numbers.length == 1 && _operators.isEmpty)) {
      return;
    }

    try {
      // 수식 계산 수행
      double result = _performCalculation();

      // 결과가 정수면 소수점 제거
      if (result == result.toInt()) {
        _display = result.toInt().toString();
      } else {
        _display = result.toString();
      }

      // 계산 이후 상태 설정
      _numbers.clear();
      _operators.clear();
      _currentInput = _display;
      _startNew = true;

    } catch (e) {
      // 오류 처리
      _display = '오류';
      _currentInput = '';
      _numbers.clear();
      _operators.clear();
      _startNew = true;
    }
  }

  // C (초기화) 버튼 처리
  void _onClearPressed() {
    setState(() {
      _display = '0';
      _expression = '';
      _currentInput = '';
      _numbers.clear();
      _operators.clear();
      _startNew = true;
      _calculationComplete = false;
    });

    HapticFeedback.mediumImpact();
  }

  // = (계산) 버튼 처리
  void _onEqualsPressed() {
    // 아무 숫자나 연산자가 없으면 무시
    if ((_numbers.isEmpty && _currentInput.isEmpty) ||
        (_numbers.isEmpty && _currentInput.isNotEmpty && _operators.isEmpty) ||
        (_numbers.isNotEmpty && _currentInput.isEmpty && _operators.isEmpty)) {
      return;
    }

    // 현재 표현식 저장
    String currentExpression = _expression;

    // 계산 실행
    _calculateResult();

    // 표현식 업데이트
    setState(() {
      _expression = currentExpression + ' = ' + _display;
      _calculationComplete = true;
    });

    _scrollToEnd();

    HapticFeedback.heavyImpact();
  }

  // 숫자 버튼 생성 헬퍼 메서드
  Widget _buildNumberButton(String number) {
    final ThemeController themeController = Get.find<ThemeController>();
    
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: ElevatedButton(
          onPressed: () => _onNumberPressed(number),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: themeController.cardColor,
            foregroundColor: themeController.textPrimaryColor,
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: themeController.isDarkMode
                    ? Colors.grey.shade600
                    : Colors.grey.shade300,
              ),
            ),
          ),
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  // 연산자 버튼 생성 헬퍼 메서드
  Widget _buildOperationButton(String operation) {
    final ThemeController themeController = Get.find<ThemeController>();
    
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: ElevatedButton(
          onPressed: () => _onOperationPressed(operation),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: themeController.primaryColor.withOpacity(0.2),
            foregroundColor: themeController.primaryColor,
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            operation,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 0,
      backgroundColor: themeController.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 계산기 제목
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: themeController.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '계산기',
                  style: TextStyle(
                    color: themeController.primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // 계산 과정 표시 (가로 스크롤 가능)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: themeController.isDarkMode
                    ? Colors.grey.shade800
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: themeController.isDarkMode
                      ? Colors.grey.shade600
                      : Colors.grey.shade200,
                ),
              ),
              constraints: const BoxConstraints(minHeight: 40),
              child: SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      _expression,
                      style: TextStyle(
                        fontSize: 14,
                        color: themeController.textSecondaryColor,
                      ),
                      textAlign: TextAlign.right,
                    ),
                    // 스크롤 위치 보장을 위한 더미 위젯
                    const SizedBox(width: 4),
                  ],
                ),
              ),
            ),

            // 계산기 디스플레이 (결과값)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: themeController.isDarkMode
                    ? Colors.grey.shade800
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: themeController.isDarkMode
                      ? Colors.grey.shade600
                      : Colors.grey.shade300,
                ),
              ),
              child: Text(
                _display,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: themeController.textPrimaryColor,
                ),
                textAlign: TextAlign.right,
              ),
            ),

            // 숫자 및 연산자 버튼
            Row(
              children: [
                _buildNumberButton('7'),
                _buildNumberButton('8'),
                _buildNumberButton('9'),
                _buildOperationButton('÷'),
              ],
            ),
            Row(
              children: [
                _buildNumberButton('4'),
                _buildNumberButton('5'),
                _buildNumberButton('6'),
                _buildOperationButton('×'),
              ],
            ),
            Row(
              children: [
                _buildNumberButton('1'),
                _buildNumberButton('2'),
                _buildNumberButton('3'),
                _buildOperationButton('-'),
              ],
            ),
            Row(
              children: [
                _buildNumberButton('0'),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: ElevatedButton(
                      onPressed: _onClearPressed,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: themeController.isDarkMode
                            ? Colors.grey.shade700
                            : Colors.grey.shade200,
                        foregroundColor: themeController.textPrimaryColor,
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'C',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: ElevatedButton(
                      onPressed: _onEqualsPressed,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: themeController.isDarkMode
                            ? Colors.grey.shade700
                            : Colors.grey.shade200,
                        foregroundColor: themeController.textPrimaryColor,
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '=',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                _buildOperationButton('+'),
              ],
            ),

            // 확인 및 취소 버튼
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: themeController.isDarkMode
                          ? Colors.grey.shade700
                          : Colors.grey.shade200,
                      foregroundColor: themeController.textPrimaryColor,
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '취소',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // 결과값 반환 ('오류'인 경우 0 반환)
                      if (_display == '오류') {
                        Navigator.of(context).pop(0);
                      } else {
                        // 소수점이 있는 경우 처리
                        double value = double.parse(_display);
                        int result = value.toInt();
                        Navigator.of(context).pop(result);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: themeController.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '입력',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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