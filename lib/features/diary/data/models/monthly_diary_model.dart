import 'dart:convert';
import '../../domain/entities/monthly_diary.dart';
import '../../domain/entities/diary_sticker.dart';

/// 월별 다이어리 모델 (DB와 Entity 간 변환)
class MonthlyDiaryModel extends MonthlyDiary {
  const MonthlyDiaryModel({
    super.id,
    super.userId,
    required super.year,
    required super.month,
    super.title,
    super.memo,
    super.images,
    super.stickers,
    super.monthlySummary,
    required super.createdAt,
    required super.updatedAt,
  });

  /// Entity에서 Model로 변환
  factory MonthlyDiaryModel.fromEntity(MonthlyDiary entity) {
    return MonthlyDiaryModel(
      id: entity.id,
      userId: entity.userId,
      year: entity.year,
      month: entity.month,
      title: entity.title,
      memo: entity.memo,
      images: entity.images,
      stickers: entity.stickers,
      monthlySummary: entity.monthlySummary,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Database Map에서 Model로 변환
  factory MonthlyDiaryModel.fromMap(Map<String, dynamic> map) {
    // images JSON 파싱
    List<String> imagesList = [];
    if (map['images'] != null && map['images'] != '') {
      try {
        final imagesParsed = jsonDecode(map['images'] as String);
        imagesList = List<String>.from(imagesParsed);
      } catch (e) {
        imagesList = [];
      }
    }

    // stickers JSON 파싱
    List<DiarySticker> stickersList = [];
    if (map['stickers'] != null && map['stickers'] != '') {
      try {
        final stickersParsed = jsonDecode(map['stickers'] as String);
        stickersList = (stickersParsed as List)
            .map((item) => DiarySticker.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (e) {
        stickersList = [];
      }
    }

    return MonthlyDiaryModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int?,
      year: map['year'] as int,
      month: map['month'] as int,
      title: map['title'] as String?,
      memo: map['memo'] as String?,
      images: imagesList,
      stickers: stickersList,
      monthlySummary: map['monthly_summary'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Model을 Database Map으로 변환
  Map<String, dynamic> toMap() {
    // images를 JSON 문자열로 변환
    final imagesJson = images.isNotEmpty ? jsonEncode(images) : null;

    // stickers를 JSON 문자열로 변환
    final stickersJson = stickers.isNotEmpty
        ? jsonEncode(stickers.map((s) => s.toJson()).toList())
        : null;

    return {
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      'year': year,
      'month': month,
      'title': title,
      'memo': memo,
      'images': imagesJson,
      'stickers': stickersJson,
      'monthly_summary': monthlySummary,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Model을 Entity로 변환
  MonthlyDiary toEntity() {
    return MonthlyDiary(
      id: id,
      userId: userId,
      year: year,
      month: month,
      title: title,
      memo: memo,
      images: images,
      stickers: stickers,
      monthlySummary: monthlySummary,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
