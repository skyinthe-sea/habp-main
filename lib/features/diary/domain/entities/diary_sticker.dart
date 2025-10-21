/// 다이어리 스티커 정보
class DiarySticker {
  final String type; // 스티커 타입 (emoji, icon 등)
  final String value; // 스티커 값 (이모지 문자, 아이콘 이름 등)
  final double x; // x 좌표 (0.0 ~ 1.0, 상대 위치)
  final double y; // y 좌표 (0.0 ~ 1.0, 상대 위치)
  final double size; // 크기 (기본 1.0)
  final double rotation; // 회전 각도 (0 ~ 360)

  const DiarySticker({
    required this.type,
    required this.value,
    required this.x,
    required this.y,
    this.size = 1.0,
    this.rotation = 0.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'value': value,
      'x': x,
      'y': y,
      'size': size,
      'rotation': rotation,
    };
  }

  factory DiarySticker.fromJson(Map<String, dynamic> json) {
    return DiarySticker(
      type: json['type'] as String,
      value: json['value'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      size: json['size'] != null ? (json['size'] as num).toDouble() : 1.0,
      rotation: json['rotation'] != null ? (json['rotation'] as num).toDouble() : 0.0,
    );
  }

  DiarySticker copyWith({
    String? type,
    String? value,
    double? x,
    double? y,
    double? size,
    double? rotation,
  }) {
    return DiarySticker(
      type: type ?? this.type,
      value: value ?? this.value,
      x: x ?? this.x,
      y: y ?? this.y,
      size: size ?? this.size,
      rotation: rotation ?? this.rotation,
    );
  }
}
