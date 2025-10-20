// lib/core/constants/emotion_constants.dart

/// 감정 태그 타입
class EmotionTag {
  static const String happy = 'HAPPY';
  static const String neutral = 'NEUTRAL';
  static const String stressed = 'STRESSED';

  /// 모든 감정 태그 리스트
  static const List<String> values = [happy, neutral, stressed];
}

/// 감정 태그 관련 유틸리티
class EmotionTagHelper {
  /// 감정 태그를 이모티콘으로 변환
  static String getEmoji(String? emotionTag) {
    switch (emotionTag) {
      case EmotionTag.happy:
        return '😃';
      case EmotionTag.neutral:
        return '😐';
      case EmotionTag.stressed:
        return '😞';
      default:
        return '';
    }
  }

  /// 감정 태그를 한글 레이블로 변환
  static String getLabel(String? emotionTag) {
    switch (emotionTag) {
      case EmotionTag.happy:
        return '기분 좋음';
      case EmotionTag.neutral:
        return '보통';
      case EmotionTag.stressed:
        return '스트레스';
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
