// lib/features/onboarding/domain/models/user.dart

enum MembershipType {
  FREE,
  PREMIUM,
}

class User {
  final int? id;
  final String? email;
  final String? passwordHash;
  final String? name;
  final MembershipType membershipType;
  final DateTime? premiumExpiryDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    this.id,
    this.email,
    this.passwordHash,
    this.name,
    this.membershipType = MembershipType.FREE,
    this.premiumExpiryDate,
    required this.createdAt,
    required this.updatedAt,
  });

  // 객체를 Map으로 변환 (DB 저장용)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'password_hash': passwordHash,
      'name': name,
      'membership_type': membershipType.toString().split('.').last,
      'premium_expiry_date': premiumExpiryDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Map에서 객체로 변환 (DB 조회용)
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      email: map['email'],
      passwordHash: map['password_hash'],
      name: map['name'],
      membershipType: map['membership_type'] == 'PREMIUM'
          ? MembershipType.PREMIUM
          : MembershipType.FREE,
      premiumExpiryDate: map['premium_expiry_date'] != null
          ? DateTime.parse(map['premium_expiry_date'])
          : null,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  // 업데이트된 객체 생성
  User copyWith({
    int? id,
    String? email,
    String? passwordHash,
    String? name,
    MembershipType? membershipType,
    DateTime? premiumExpiryDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      name: name ?? this.name,
      membershipType: membershipType ?? this.membershipType,
      premiumExpiryDate: premiumExpiryDate ?? this.premiumExpiryDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}