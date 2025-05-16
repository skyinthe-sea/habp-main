import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/budget_status.dart';
import '../controllers/expense_controller.dart';
import '../widgets/category_detail_dialog.dart';

class CategoryBudgetGrid extends StatelessWidget {
  final ExpenseController controller;

  const CategoryBudgetGrid({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ExpenseController>(
      init: controller,
      builder: (controller) {
        return Obx(() {
          if (!controller.dataInitialized.value) {
            controller.fetchBudgetStatus();
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          // 빈 상태 처리
          if (controller.budgetStatusList.isEmpty) {
            if (controller.isLoading.value) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            return _buildEmptyState();
          }

          // 그리드 카드 생성
          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2열 그리드
              childAspectRatio: 1, // 정사각형 카드
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.budgetStatusList.length,
            itemBuilder: (context, index) {
              return _buildCategoryCard(context, controller.budgetStatusList[index]);
            },
          );
        });
      },
    );
  }

  // 카테고리 카드 위젯
  Widget _buildCategoryCard(BuildContext context, BudgetStatus budgetStatus) {
    // 통화 포맷팅
    final currencyFormat = NumberFormat('#,###', 'ko_KR');
    final budget = '${currencyFormat.format(budgetStatus.budgetAmount.toInt())}원';
    final spent = '${currencyFormat.format(budgetStatus.spentAmount.abs().toInt())}원';

    // 진행 상태에 따른 색상 결정
    final double progressPercentage = budgetStatus.progressPercentage.abs();
    final Color progressColor = progressPercentage >= 90
        ? Colors.red
        : (progressPercentage >= 70 ? Colors.orange : AppColors.primary);

    // 카테고리별 색상 지정
    final categoryColors = [
      AppColors.primary,
      Color(0xFF9177E0),
      Color(0xFF49E292),
      Color(0xFF4990E2),
      Color(0xFFE2A949),
      Color(0xFFE07777),
      Color(0xFF49C5E2),
      Color(0xFF7CC576),
    ];
    final cardColor = categoryColors[budgetStatus.categoryId % categoryColors.length];

    return InkWell(
      onTap: () {
        // 카테고리 상세 분석 다이얼로그 표시
        showDialog(
          context: context,
          builder: (context) => CategoryDetailDialog(
            budgetStatus: budgetStatus,
            controller: controller,
          ),
        );
      },
      onLongPress: () {
        // 카테고리 수정/삭제 옵션 표시
        _showCategoryOptionsDialog(context, budgetStatus);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: cardColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 카테고리 이름과 아이콘
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: cardColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getCategoryIcon(budgetStatus.categoryName),
                    size: 16,
                    color: cardColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    budgetStatus.categoryName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            // 원형 프로그레스 표시
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 70,
                    height: 70,
                    child: CircularProgressIndicator(
                      value: (progressPercentage / 100).toDouble(), // 명시적으로 double로 변환
                      backgroundColor: Colors.grey.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                      strokeWidth: 8,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${progressPercentage.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: progressColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '사용',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 예산 및 지출 정보
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '예산',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      budget,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '사용',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      spent,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: progressColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 카테고리 옵션 다이얼로그 (수정/삭제)
  void _showCategoryOptionsDialog(BuildContext context, BudgetStatus budgetStatus) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              budgetStatus.categoryName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.edit, color: AppColors.primary),
              title: const Text('예산 수정'),
              onTap: () {
                Navigator.pop(context);
                _showEditCategoryDialog(context, budgetStatus);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('카테고리 삭제'),
              onTap: () {
                Navigator.pop(context);
                _showDeleteCategoryDialog(context, budgetStatus);
              },
            ),
          ],
        ),
      ),
    );
  }

  // 예산 수정 다이얼로그
  void _showEditCategoryDialog(BuildContext context, BudgetStatus budgetStatus) {
    final budgetController = TextEditingController(
      text: budgetStatus.budgetAmount.toInt().toString(),
    );
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          '예산 수정',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: budgetController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: '예산 금액',
            hintText: '예산 금액을 입력하세요',
            suffixText: '원',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(
              '취소',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          StatefulBuilder(
            builder: (context, setDialogState) {
              return TextButton(
                onPressed: isSaving
                    ? null
                    : () async {
                  setDialogState(() {
                    isSaving = true;
                  });

                  // 예산 업데이트
                  final result = await controller.addBudget(
                    categoryId: budgetStatus.categoryId,
                    amount: double.tryParse(budgetController.text) ?? 0,
                  );

                  Navigator.of(context).pop();

                  if (result) {
                    Get.snackbar(
                      '성공',
                      '예산이 수정되었습니다.',
                      snackPosition: SnackPosition.TOP,
                    );
                  } else {
                    Get.snackbar(
                      '오류',
                      '예산 수정에 실패했습니다.',  
                      snackPosition: SnackPosition.TOP,
                    );
                  }
                },
                child: isSaving
                    ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                )
                    : Text(
                  '저장',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // 카테고리 삭제 다이얼로그
  void _showDeleteCategoryDialog(BuildContext context, BudgetStatus budgetStatus) {
    bool isDeleting = false;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          '카테고리 삭제',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '\'${budgetStatus.categoryName}\' 예산 정보를 삭제하시겠습니까?',
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(
              '취소',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          StatefulBuilder(
            builder: (context, setDialogState) {
              return TextButton(
                onPressed: isDeleting
                    ? null
                    : () async {
                  setDialogState(() {
                    isDeleting = true;
                  });

                  // 카테고리 삭제
                  final success = await controller.deleteCategory(budgetStatus.categoryId);

                  Navigator.of(context).pop();

                  // 결과 알림
                  if (success) {
                    Get.snackbar(
                      '성공',
                      '카테고리가 삭제되었습니다.',
                      snackPosition: SnackPosition.TOP,
                    );
                  } else {
                    Get.snackbar(
                      '오류',
                      '카테고리 삭제에 실패했습니다.',
                      snackPosition: SnackPosition.TOP,
                    );
                  }
                },
                child: isDeleting
                    ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                )
                    : Text(
                  '삭제',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // 빈 상태 위젯
  Widget _buildEmptyState() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            '등록된 예산 정보가 없습니다.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '예산을 설정하여 관리해보세요.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  // 카테고리 아이콘 가져오기
  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case '식비':
        return Icons.restaurant;
      case '교통비':
        return Icons.directions_bus;
      case '문화생활':
        return Icons.movie;
      case '쇼핑':
        return Icons.shopping_bag;
      case '통신비':
        return Icons.phone_android;
      case '교육비':
        return Icons.school;
      case '카페':
        return Icons.coffee;
      case '의료비':
        return Icons.medical_services;
      case '주거비':
        return Icons.home;
      case '월세':
        return Icons.home;
      case '보험':
        return Icons.health_and_safety;
      default:
        return Icons.category;
    }
  }
}