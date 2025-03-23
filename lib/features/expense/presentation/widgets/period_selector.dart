import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/expense_controller.dart';

class PeriodSelector extends StatelessWidget {
  final ExpenseController controller;

  const PeriodSelector({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final current = DateTime.parse('${controller.selectedPeriod.value}-01');
      final month = current.month;
      final year = current.year;
      final monthNames = ['1월', '2월', '3월', '4월', '5월', '6월', '7월', '8월', '9월', '10월', '11월', '12월'];

      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: controller.previousMonth,
          ),
          Text(
            '${year}년 ${monthNames[month - 1]}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: controller.nextMonth,
          ),
        ],
      );
    });
  }
}