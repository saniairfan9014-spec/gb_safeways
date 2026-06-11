class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String avatarUrl;
  final String phoneNumber;
  final int contributionsCount;
  final String badge;
  final String role;
  final DateTime createdAt;
  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? avatarUrl,
    String? phoneNumber,
    int? contributionsCount,
    String? badge,
    String? role,
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
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.avatarUrl,
    required this.phoneNumber,
    required this.createdAt,
    this.contributionsCount = 0,
    this.badge = "Basecamp Guide",
    this.role = "user",
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'].toString(),
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? json['name'] ?? '',
      avatarUrl: json['avatar_url'] ?? json['avatar'] ?? '',
      phoneNumber: json['phone_number'] ?? json['phone'] ?? '',
      role: json['role'] ?? 'user',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'avatar_url': avatarUrl,
      'role': role,
      'created_at': createdAt.toIso8601String(),
    };
  }
}