// Import statements
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

// 숫자만 허용하고 천단위 콤마를 자동으로 추가하는 TextInputFormatter
class ThousandsFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat('#,###');

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {

    // 빈 값이면 그대로 반환
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // 커서 위치 저장
    int selectionIndex = newValue.selection.end;

    // 콤마 제거
    String value = newValue.text.replaceAll(',', '');

    // 숫자가 아닌 문자가 있는지 확인
    if (!RegExp(r'^\d*$').hasMatch(value)) {
      // 숫자가 아닌 문자가 입력되면 이전 값을 유지
      return oldValue;
    }

    // 숫자가 너무 크면(16자리 이상) 이전 값 유지
    if (value.length > 16) {
      return oldValue;
    }

    // 콤마를 포함한 이전 문자열의 길이
    int oldValueCommaCount = oldValue.text.length - oldValue.text.replaceAll(',', '').length;

    // 포맷팅 적용 (천단위 콤마)
    String newText = value.isEmpty ? '' : _formatter.format(int.parse(value));

    // 새 콤마 개수 계산
    int newValueCommaCount = newText.length - value.length;

    // 커서 위치 조정 (콤마가 추가되었을 경우 커서 위치 조정)
    selectionIndex += (newValueCommaCount - oldValueCommaCount);

    // 커서가 문자열 범위를 벗어나지 않도록 조정
    if (selectionIndex > newText.length) {
      selectionIndex = newText.length;
    } else if (selectionIndex < 0) {
      selectionIndex = 0;
    }

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}

// 경고 메시지 표시 함수
void showNumberFormatAlert(BuildContext context) {
  // 키보드가 열려 있으면 닫기
  FocusManager.instance.primaryFocus?.unfocus();

  // 짧은 경고 메시지 표시
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.white),
          SizedBox(width: 10),
          Text('숫자만 입력 가능합니다'),
        ],
      ),
      backgroundColor: Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: EdgeInsets.all(10),
    ),
  );
}

// 금액 입력 TextField 예제 (사용법)
TextField buildAmountTextField(
    TextEditingController controller,
    BuildContext context,
    Function(String) onChanged,
    ) {
  return TextField(
    controller: controller,
    keyboardType: TextInputType.numberWithOptions(decimal: false),
    inputFormatters: [
      FilteringTextInputFormatter.allow(RegExp(r'[0-9,]')),
      ThousandsFormatter(),
    ],
    onChanged: (value) {
      // 숫자가 아닌 문자가 입력된 경우 경고
      if (value.isNotEmpty && !RegExp(r'^[0-9,]+$').hasMatch(value)) {
        showNumberFormatAlert(context);
      }

      // 콤마 제거 후 값 전달
      final plainValue = value.replaceAll(',', '');
      onChanged(plainValue);
    },
    decoration: InputDecoration(
      hintText: '금액 입력',
      filled: true,
      fillColor: Colors.grey[50],
      prefixIcon: const Icon(Icons.attach_money, color: Colors.green),
      prefixText: '₩ ',
      prefixStyle: const TextStyle(color: Colors.black87, fontSize: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.green.shade700, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
  );
}