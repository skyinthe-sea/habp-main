// lib/features/dashboard/presentation/widgets/category_chart_tabs.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/entities/category_expense.dart';
import '../presentation/dashboard_controller.dart';

class CategoryChartTabs extends StatelessWidget {
  final DashboardController controller;

  const CategoryChartTabs({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '카테고리별 내역',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '터치하여 상세보기',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[400],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '이번 달',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 세 개의 미니 도넛 차트를 가로로 배치
          SizedBox(
            height: 220, // 높이 축소
            child: Row(
              children: [
                // 소득 차트
                Expanded(
                  child: _buildMiniChart(
                    data: controller.categoryIncome,
                    title: '소득',
                    isLoading: controller.isCategoryIncomeLoading.value,
                    emptyMessage: '소득 데이터가 없습니다',
                    baseColor: Colors.green.shade400,
                    type: 'INCOME',
                  ),
                ),

                // 지출 차트
                Expanded(
                  child: _buildMiniChart(
                    data: controller.categoryExpenses,
                    title: '지출',
                    isLoading: controller.isCategoryExpenseLoading.value,
                    emptyMessage: '지출 데이터가 없습니다',
                    baseColor: AppColors.primary,
                    type: 'EXPENSE',
                  ),
                ),

                // 재테크 차트
                Expanded(
                  child: _buildMiniChart(
                    data: controller.categoryFinance,
                    title: '재테크',
                    isLoading: controller.isCategoryFinanceLoading.value,
                    emptyMessage: '재테크 데이터가 없습니다',
                    baseColor: Colors.blue.shade400,
                    type: 'FINANCE',
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildMiniChart({
    required List<CategoryExpense> data,
    required String title,
    required bool isLoading,
    required String emptyMessage,
    required Color baseColor,
    required String type,
  }) {
    if (isLoading) {
      return const Center(child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2)
      ));
    }

    if (data.isEmpty) {
      return _buildEmptyState(emptyMessage);
    }

    // 합계 계산
    double total = 0;
    for (var item in data) {
      total += item.amount;
    }

    // 5% 미만 항목 처리를 위한 데이터 가공
    List<CategoryExpense> mainCategories = [];
    List<CategoryExpense> smallCategories = [];
    double otherAmount = 0;

    for (var item in data) {
      if (item.percentage >= 5) {
        mainCategories.add(item);
      } else {
        smallCategories.add(item);
        otherAmount += item.amount;
      }
    }

    // '기타' 카테고리 추가 (작은 항목들 통합)
    if (smallCategories.isNotEmpty) {
      mainCategories.add(CategoryExpense(
        categoryId: -1,
        categoryName: '기타',
        amount: otherAmount,
        percentage: (otherAmount / total) * 100,
      ));
    }

    // 탭 시 상세 보기 표시
    return GestureDetector(
      onTap: () => _showDetailChart(Get.context!, data, title.replaceAll('소득', '수입'), baseColor, type, total),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // 차트 타이틀 - 더 눈에 띄게 개선
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                decoration: BoxDecoration(
                  color: baseColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                ),
                width: double.infinity,
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: baseColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // 제목과 차트 사이 간격 추가
              const SizedBox(height: 8),

              // 미니 도넛 차트
              SizedBox(
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 1,
                        centerSpaceRadius: 35, // 중앙 공간 축소
                        sections: _createSections(mainCategories, data, baseColor, type),
                        startDegreeOffset: 180,
                      ),
                    ),

                    // 중앙 총액 표시
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatAmount(total),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: baseColor,
                          ),
                        ),
                        Text(
                          '원',
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

              // 간단한 범례 (상위 2개 항목)
              Padding(
                padding: const EdgeInsets.only(top: 2, bottom: 4, left: 4, right: 4),
                child: _buildSimpleLegend(data, baseColor, type),
              ),

              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }

  // 간단한 범례 (상위 2개 항목만 표시)
  Widget _buildSimpleLegend(List<CategoryExpense> data, Color baseColor, String type) {
    if (data.isEmpty) return const SizedBox();

    // 금액 기준 내림차순 정렬 및 상위 2개 항목만 선택
    final sortedData = List<CategoryExpense>.from(data)
      ..sort((a, b) => b.amount.compareTo(a.amount));
    final topItems = sortedData.take(2).toList();

    return Column(
      children: topItems.map((item) {
        Color color;
        if (type == 'EXPENSE') {
          color = AppColors.getCategoryColor(item.categoryId);
        } else if (type == 'INCOME') {
          color = Color.lerp(Colors.lightGreen, Colors.green.shade700, data.indexOf(item) / data.length)!;
        } else {
          color = Color.lerp(Colors.lightBlue, Colors.indigo, data.indexOf(item) / data.length)!;
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  '${item.categoryName} ${item.percentage.toInt()}%',
                  style: const TextStyle(fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // 도넛 차트 섹션 생성
  List<PieChartSectionData> _createSections(
      List<CategoryExpense> mainCategories,
      List<CategoryExpense> allData,
      Color baseColor,
      String type) {
    return mainCategories.map((item) {
      // 색상 결정
      Color color;
      if (type == 'EXPENSE') {
        color = item.categoryId == -1
            ? Colors.grey
            : AppColors.getCategoryColor(item.categoryId);
      } else if (type == 'INCOME') {
        if (item.categoryId == -1) {
          color = Colors.grey;
        } else {
          int index = allData.indexWhere((e) => e.categoryId == item.categoryId);
          color = Color.lerp(Colors.lightGreen, Colors.green.shade700, index / allData.length)!;
        }
      } else {
        if (item.categoryId == -1) {
          color = Colors.grey;
        } else {
          int index = allData.indexWhere((e) => e.categoryId == item.categoryId);
          color = Color.lerp(Colors.lightBlue, Colors.indigo, index / allData.length)!;
        }
      }

      return PieChartSectionData(
        color: color,
        value: item.amount,
        title: '', // 미니 차트에서는 제목 표시 X
        radius: 45, // 반지름 축소
        badgeWidget: null, // 미니 차트에서는 배지 표시 X
      );
    }).toList();
  }

  // 빈 상태 위젯
  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 24, color: Colors.grey.shade300),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // 상세 차트 다이얼로그 표시
  void _showDetailChart(BuildContext context, List<CategoryExpense> data, String title, Color baseColor, String type, double total) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: double.maxFinite,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 다이얼로그 헤더
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$title 상세',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: baseColor,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),

              // 총액 정보
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '총 금액: ${_formatAmount(total)}원',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              // 상세 도넛 차트
              SizedBox(
                height: 300,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 60,
                        sections: _createDetailSections(data, baseColor, type),
                        startDegreeOffset: 180,
                      ),
                    ),

                    // 중앙 텍스트
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: baseColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '카테고리 비율',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 카테고리 목록
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    final item = data[index];
                    // 색상 설정
                    Color color;
                    if (type == 'EXPENSE') {
                      color = AppColors.getCategoryColor(item.categoryId);
                    } else if (type == 'INCOME') {
                      color = Color.lerp(Colors.lightGreen, Colors.green.shade700, index / data.length)!;
                    } else {
                      color = Color.lerp(Colors.lightBlue, Colors.indigo, index / data.length)!;
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.categoryName,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_formatAmount(item.amount)}원',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${item.percentage.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 상세 차트용 섹션 생성
  List<PieChartSectionData> _createDetailSections(List<CategoryExpense> data, Color baseColor, String type) {
    return data.map((item) {
      // 색상 설정
      Color color;
      if (type == 'EXPENSE') {
        color = AppColors.getCategoryColor(item.categoryId);
      } else if (type == 'INCOME') {
        color = Color.lerp(Colors.lightGreen, Colors.green.shade700, data.indexOf(item) / data.length)!;
      } else {
        color = Color.lerp(Colors.lightBlue, Colors.indigo, data.indexOf(item) / data.length)!;
      }

      return PieChartSectionData(
        color: color,
        value: item.amount,
        title: '',
        radius: 60,
        titlePositionPercentageOffset: 0.6,
        badgeWidget: _getBadgeWidget(item.categoryName, item.percentage, color),
        badgePositionPercentageOffset: 1.2,
      );
    }).toList();
  }

  // 배지 위젯 (라벨)
  Widget _getBadgeWidget(String categoryName, double percentage, Color color) {
    // 비율이 매우 낮은 경우 배지 표시 안함
    if (percentage < 3) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$categoryName ',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            TextSpan(
              text: '${percentage.toInt()}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
                shadows: const [
                  Shadow(
                    offset: Offset(1.0, 1.0),
                    blurRadius: 2.0,
                    color: Colors.black,
                  ),
                  Shadow(
                    offset: Offset(-1.0, -1.0),
                    blurRadius: 2.0,
                    color: Colors.black,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 금액 포맷팅
  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 10000).toStringAsFixed(0)}만';
    } else if (amount >= 10000) {
      return '${(amount / 10000).toStringAsFixed(1)}만';
    } else {
      return amount.toStringAsFixed(0);
    }
  }
}