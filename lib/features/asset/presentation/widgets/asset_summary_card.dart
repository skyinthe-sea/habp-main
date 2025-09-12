// lib/features/asset/presentation/widgets/asset_summary_card.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/controllers/theme_controller.dart';
import '../../domain/entities/asset_summary.dart';
import 'pie_chart.dart';

class AssetSummaryCard extends StatelessWidget {
  final AssetSummary? assetSummary;
  final bool showAnimation;

  const AssetSummaryCard({
    Key? key,
    required this.assetSummary,
    required this.showAnimation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    
    if (assetSummary == null) {
      return _buildLoadingState(themeController);
    }

    final currencyFormat = NumberFormat('#,###', 'ko_KR');

    return AnimatedOpacity(
      opacity: showAnimation ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      child: AnimatedSlide(
        offset: showAnimation ? Offset.zero : const Offset(0, 0.2),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                themeController.primaryColor,
                themeController.primaryColor.withOpacity(0.85),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: themeController.primaryColor.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '총 자산 가치',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${currencyFormat.format(assetSummary!.totalAssetValue.toInt())}원',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  // Row(
                  //   children: [
                  //     Container(
                  //       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  //       decoration: BoxDecoration(
                  //         color: Colors.white.withOpacity(0.2),
                  //         borderRadius: BorderRadius.circular(16),
                  //       ),
                  //       child: Row(
                  //         children: [
                  //           Icon(
                  //             assetSummary!.netWorth >= 0
                  //                 ? Icons.arrow_upward
                  //                 : Icons.arrow_downward,
                  //             color: assetSummary!.netWorth >= 0 ? Colors.white : Colors.red.shade300,
                  //             size: 16,
                  //           ),
                  //           const SizedBox(width: 4),
                  //           Text(
                  //             '순자산 ${currencyFormat.format(assetSummary!.netWorth.toInt())}원',
                  //             style: const TextStyle(
                  //               color: Colors.white,
                  //               fontSize: 12,
                  //               fontWeight: FontWeight.bold,
                  //             ),
                  //           ),
                  //         ],
                  //       ),
                  //     ),
                  //   ],
                  // ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white24, thickness: 0.5),
              const SizedBox(height: 16),
              Row(
                children: [
                  // 왼쪽: 자산/부채 정보
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow(
                          icon: Icons.account_balance,
                          label: '총 자산',
                          value: '${currencyFormat.format(assetSummary!.totalAssetValue.toInt())}원',
                          positive: true,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          icon: Icons.money_off,
                          label: '총 부채',
                          value: '${currencyFormat.format(assetSummary!.totalLoanAmount.toInt())}원',
                          positive: false,
                        ),
                      ],
                    ),
                  ),

                  // 오른쪽: 파이 차트
                  if (assetSummary!.categoryValues.isNotEmpty) ...[
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: CustomPieChart(
                        data: assetSummary!.categoryValues,
                        totalValue: assetSummary!.totalAssetValue,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool positive,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Icon(
              icon,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: positive ? Colors.white : Colors.red.shade400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState(ThemeController themeController) {
    return Container(
      width: double.infinity,
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            themeController.primaryColor.withOpacity(0.6),
            themeController.primaryColor.withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );
  }
}
