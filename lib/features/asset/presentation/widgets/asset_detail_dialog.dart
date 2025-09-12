import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/controllers/theme_controller.dart';
import '../../data/models/asset_category_model.dart';
import '../../domain/entities/asset.dart';
import 'asset_icon_visualizer.dart';
import 'edit_asset_dialog.dart';

class AssetDetailDialog extends StatelessWidget {
  final Asset asset;
  final List<AssetCategoryModel> categories;
  final Function({
  required int assetId,
  int? categoryId,
  String? name,
  double? currentValue,
  double? purchaseValue,
  String? purchaseDate,
  double? interestRate,
  double? loanAmount,
  String? description,
  String? location,
  String? details,
  String? iconType,
  }) onUpdate;
  final VoidCallback onDelete;

  const AssetDetailDialog({
    Key? key,
    required this.asset,
    required this.categories,
    required this.onUpdate,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,###', 'ko_KR');
    final dateFormat = DateFormat('yyyy년 MM월 dd일');

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더 섹션
            Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        asset.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      asset.categoryName,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '현재 가치',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '${currencyFormat.format(asset.currentValue.toInt())}원',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 상세 정보 (스크롤 가능)
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 자산 시각화
                    AssetIconVisualizer(asset: asset),
                    const SizedBox(height: 24),

                    // 자산 상세 정보
                    const Text(
                      '자산 상세 정보',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 구매 가치 (있는 경우)
                    if (asset.purchaseValue != null && asset.purchaseValue! > 0) ...[
                      _buildInfoRow(
                        label: '구매 가치',
                        value: '${currencyFormat.format(asset.purchaseValue!.toInt())}원',
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        label: '수익률',
                        value: _calculateChangePercentage(),
                        valueColor: asset.currentValue >= asset.purchaseValue!
                            ? Colors.green
                            : Colors.red,
                      ),
                      const SizedBox(height: 12),
                    ],

                    // 구매 날짜 (있는 경우)
                    if (asset.purchaseDate != null && asset.purchaseDate!.isNotEmpty) ...[
                      _buildInfoRow(
                        label: '구매일',
                        value: dateFormat.format(DateTime.parse(asset.purchaseDate!)),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // 이자율 (있는 경우)
                    if (asset.interestRate != null && asset.interestRate! > 0) ...[
                      _buildInfoRow(
                        label: '이자율',
                        value: '${asset.interestRate!.toStringAsFixed(2)}%',
                      ),
                      const SizedBox(height: 12),
                    ],

                    // 대출 금액 (있는 경우)
                    if (asset.loanAmount != null && asset.loanAmount! > 0) ...[
                      _buildInfoRow(
                        label: '대출 잔액',
                        value: '${currencyFormat.format(asset.loanAmount!.toInt())}원',
                        valueColor: Colors.red.shade700,
                      ),
                      const SizedBox(height: 12),
                    ],

                    // 위치 (있는 경우)
                    if (asset.location != null && asset.location!.isNotEmpty) ...[
                      _buildInfoRow(
                        label: '위치',
                        value: asset.location!,
                      ),
                      const SizedBox(height: 12),
                    ],

                    // 설명 (있는 경우)
                    if (asset.description != null && asset.description!.isNotEmpty) ...[
                      _buildInfoRow(
                        label: '설명',
                        value: asset.description!,
                      ),
                      const SizedBox(height: 12),
                    ],

                    // 상세 정보 (있는 경우)
                    if (asset.details != null && asset.details!.isNotEmpty) ...[
                      _buildInfoRow(
                        label: '세부 정보',
                        value: asset.details!,
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ),

            // 버튼 섹션
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // 삭제 버튼
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _showDeleteConfirmationDialog(context);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('삭제하기'),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // 수정 버튼
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => EditAssetDialog(
                            asset: asset,
                            categories: categories,
                            onUpdate: onUpdate,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('수정하기'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }

  String _calculateChangePercentage() {
    if (asset.purchaseValue == null || asset.purchaseValue! <= 0) {
      return '0%';
    }

    final change = asset.currentValue - asset.purchaseValue!;
    final percentage = (change / asset.purchaseValue!) * 100;

    return '${percentage >= 0 ? '+' : ''}${percentage.toStringAsFixed(1)}%';
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('자산 삭제'),
        content: Text('정말 "${asset.name}" 자산을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // 확인 다이얼로그 닫기
              Navigator.of(context).pop(); // 상세 다이얼로그 닫기
              onDelete();
              final ThemeController themeController = Get.find<ThemeController>();
            Get.snackbar(
            '삭제 완료',
            '${asset.name} 자산이 삭제되었습니다.',
            backgroundColor: themeController.isDarkMode ? AppColors.darkSuccess : AppColors.success,
                snackPosition: SnackPosition.TOP,
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}