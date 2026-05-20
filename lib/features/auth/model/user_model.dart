class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String avatarUrl;
  final String phoneNumber;
  final int contributionsCount;
  final String badge;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.avatarUrl,
    this.phoneNumber = "+92 355 4567890",
    this.contributionsCount = 0,
    this.badge = "Basecamp Guide",
    required this.createdAt,
  });

  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? avatarUrl,
    String? phoneNumber,
    int? contributionsCount,
    String? badge,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      contributionsCount: contributionsCount ?? this.contributionsCount,
      badge: badge ?? this.badge,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': fullName,
      'phone': phoneNumber,
      'avatar': avatarUrl,
      'role': 'user',
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String? ?? 'traveler@karakoram.com',
      fullName: json['name'] as String? ?? json['full_name'] as String? ?? 'Karakoram Adventurer',
      avatarUrl: json['avatar'] as String? ?? json['avatar_url'] as String? ?? 'https://ui-avatars.com/api/?name=Traveler&background=0284C7&color=fff&bold=true',
      phoneNumber: json['phone'] as String? ?? json['phone_number'] as String? ?? '+92 355 4567890',
      contributionsCount: json['contributions_count'] as int? ?? 0,
      badge: json['badge'] as String? ?? "Basecamp Guide",
      createdAt: DateTime.parse(json['created_at'] as String? ?? DateTime.now().toIso8601String()),
    );
  }
}
