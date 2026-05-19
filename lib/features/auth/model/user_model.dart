class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String avatarUrl;
  final int contributionsCount;
  final String badge;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.avatarUrl,
    this.contributionsCount = 0,
    this.badge = "Basecamp Guide",
    required this.createdAt,
  });

  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? avatarUrl,
    int? contributionsCount,
    String? badge,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      contributionsCount: contributionsCount ?? this.contributionsCount,
      badge: badge ?? this.badge,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'contributions_count': contributionsCount,
      'badge': badge,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      avatarUrl: json['avatar_url'] as String,
      contributionsCount: json['contributions_count'] as int? ?? 0,
      badge: json['badge'] as String? ?? "Basecamp Guide",
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
