import 'diary_sticker.dart';

/// 월별 다이어리 엔티티
class MonthlyDiary {
  final int? id;
  final int? userId;
  final int year;
  final int month;
  final String? title;
  final String? memo;
  final List<String> images; // 이미지 파일 경로 리스트
  final List<DiarySticker> stickers; // 스티커 리스트
  final String? monthlySummary; // 월간 요약 (수입/지출 등)
  final DateTime createdAt;
  final DateTime updatedAt;

  const MonthlyDiary({
    this.id,
    this.userId,
    required this.year,
    required this.month,
    this.title,
    this.memo,
    this.images = const [],
    this.stickers = const [],
    this.monthlySummary,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 월 표시용 문자열 (예: "2025년 10월")
  String get monthLabel => '$year년 $month월';

  /// 타이틀이 없을 경우 기본 타이틀 반환
  String get displayTitle => title ?? '$monthLabel 다이어리';

  /// 다이어리가 비어있는지 확인
  bool get isEmpty =>
      (title == null || title!.isEmpty) &&
      (memo == null || memo!.isEmpty) &&
      images.isEmpty &&
      stickers.isEmpty;

  MonthlyDiary copyWith({
    int? id,
    int? userId,
    int? year,
    int? month,
    String? title,
    String? memo,
    List<String>? images,
    List<DiarySticker>? stickers,
    String? monthlySummary,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MonthlyDiary(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      year: year ?? this.year,
      month: month ?? this.month,
      title: title ?? this.title,
      memo: memo ?? this.memo,
      images: images ?? this.images,
      stickers: stickers ?? this.stickers,
      monthlySummary: monthlySummary ?? this.monthlySummary,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
