/// 감정 기반 통계 엔티티
class EmotionStats {
  final String? emotionTag;
  final double totalAmount;
  final int count;

  EmotionStats({
    this.emotionTag,
    required this.totalAmount,
    required this.count,
  });

  /// 전체 금액 대비 비율 계산
  double getPercentage(double totalAmount) {
    if (totalAmount == 0) return 0;
    return (this.totalAmount.abs() / totalAmount) * 100;
  }
}
