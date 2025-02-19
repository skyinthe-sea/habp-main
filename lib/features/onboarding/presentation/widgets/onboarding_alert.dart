import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/underline_button.dart';

class OnboardingAlert extends StatelessWidget {
  const OnboardingAlert({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          UnderlineButton(
            text: '월급',
            width: 100,
            onTap: () {
              // 월급 종류 선택 알럿 표시
              showDialog(
                context: context,
                builder: (_) => const EmptySelectionAlert(),
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              UnderlineButton(
                text: '매월',
                width: 60,
                onTap: () {
                  // 주기 선택 알럿 표시
                  showDialog(
                    context: context,
                    builder: (_) => const EmptySelectionAlert(),
                  );
                },
              ),
              const SizedBox(width: 8),
              UnderlineButton(
                text: '1일',
                width: 40,
                onTap: () {
                  // 날짜 선택 알럿 표시
                  showDialog(
                    context: context,
                    builder: (_) => const EmptySelectionAlert(),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              _NumberFormatter(),
            ],
            decoration: const InputDecoration(
              suffix: Text('원'),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  // 추가 로직
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('추가'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('완료'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class EmptySelectionAlert extends StatelessWidget {
  const EmptySelectionAlert({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      content: const Text('추후 선택 옵션이 추가될 예정입니다.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('확인'),
        ),
      ],
    );
  }
}

class _NumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final number = int.parse(newValue.text.replaceAll(',', ''));
    final newString = number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    );

    return TextEditingValue(
      text: newString,
      selection: TextSelection.collapsed(offset: newString.length),
    );
  }
}