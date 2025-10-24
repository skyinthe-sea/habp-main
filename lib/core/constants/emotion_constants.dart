// lib/core/constants/emotion_constants.dart

/// 감정 태그 타입
class EmotionTag {
  static const String veryHappy = 'VERY_HAPPY';      // 매우 행복
  static const String happy = 'HAPPY';                // 행복
  static const String satisfied = 'SATISFIED';        // 만족
  static const String neutral = 'NEUTRAL';            // 보통
  static const String anxious = 'ANXIOUS';            // 불안
  static const String stressed = 'STRESSED';          // 스트레스
  static const String sad = 'SAD';                    // 슬픔
  static const String angry = 'ANGRY';                // 화남

  /// 모든 감정 태그 리스트 (왼쪽부터 긍정 → 부정 순서)
  static const List<String> values = [
    veryHappy,
    happy,
    satisfied,
    neutral,
    anxious,
    stressed,
    sad,
    angry,
  ];
}

/// 감정 태그 관련 유틸리티
class EmotionTagHelper {
  /// 감정 태그를 이모티콘으로 변환
  static String getEmoji(String? emotionTag) {
    switch (emotionTag) {
      case EmotionTag.veryHappy:
        return '🤩';
      case EmotionTag.happy:
        return '😊';
      case EmotionTag.satisfied:
        return '😌';
      case EmotionTag.neutral:
        return '😐';
      case EmotionTag.anxious:
        return '😰';
      case EmotionTag.stressed:
        return '😫';
      case EmotionTag.sad:
        return '😢';
      case EmotionTag.angry:
        return '😠';
      default:
        return '';
    }
  }

  /// 감정 태그를 한글 레이블로 변환
  static String getLabel(String? emotionTag) {
    switch (emotionTag) {
      case EmotionTag.veryHappy:
        return '최고!';
      case EmotionTag.happy:
        return '행복해요';
      case EmotionTag.satisfied:
        return '만족해요';
      case EmotionTag.neutral:
        return '그냥 그래요';
      case EmotionTag.anxious:
        return '불안해요';
      case EmotionTag.stressed:
        return '스트레스';
      case EmotionTag.sad:
        return '슬퍼요';
      case EmotionTag.angry:
        return '화나요';
      default:
        return '선택 안함';
    }
  }

  /// 감정 태그를 이모티콘과 레이블로 변환
  static String getEmojiWithLabel(String? emotionTag) {
    final emoji = getEmoji(emotionTag);
    final label = getLabel(emotionTag);
    return emoji.isEmpty ? label : '$emoji $label';
  }

  /// 감정 태그의 색상 (통계에 사용)
  static String getColorHex(String? emotionTag) {
    switch (emotionTag) {
      case EmotionTag.happy:
        return '#FFD700'; // 골드
      case EmotionTag.neutral:
        return '#A0A0A0'; // 회색
      case EmotionTag.stressed:
        return '#FF6B6B'; // 레드
      default:
        return '#E0E0E0'; // 연한 회색
    }
  }
}
