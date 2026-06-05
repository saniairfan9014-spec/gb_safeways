class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String avatarUrl;
  final String phoneNumber;
  final int contributionsCount;
  final String badge;
  final DateTime createdAt;
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

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.avatarUrl,
    required this.phoneNumber,
    required this.createdAt,
    this.contributionsCount = 0,
    this.badge = "Basecamp Guide",
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'].toString(),
      email: json['email'] ?? '',
      fullName: json['name'] ?? '',
      avatarUrl: json['avatar'] ?? '',
      phoneNumber: json['phone'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': fullName,
      'phone': phoneNumber,
      'avatar': avatarUrl,
      'role': 'user',
      'created_at': createdAt.toIso8601String(),
    };
  }
}