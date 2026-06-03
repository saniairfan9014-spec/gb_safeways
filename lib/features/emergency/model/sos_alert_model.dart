class SosAlertModel {
  final String id;
  final String userId;
  final String emergencyType;
  final String? description;
  final double latitude;
  final double longitude;
  final String status; // 'active' | 'resolved'
  final DateTime createdAt;
  final DateTime? resolvedAt;

  // Joined user fields (loaded for admin dashboard, optional otherwise)
  final String? userName;
  final String? userEmail;
  final String? userAvatar;

  SosAlertModel({
    required this.id,
    required this.userId,
    required this.emergencyType,
    this.description,
    required this.latitude,
    required this.longitude,
    this.status = 'active',
    required this.createdAt,
    this.resolvedAt,
    this.userName,
    this.userEmail,
    this.userAvatar,
  });

  SosAlertModel copyWith({
    String? id,
    String? userId,
    String? emergencyType,
    String? description,
    double? latitude,
    double? longitude,
    String? status,
    DateTime? createdAt,
    DateTime? resolvedAt,
    String? userName,
    String? userEmail,
    String? userAvatar,
  }) {
    return SosAlertModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      emergencyType: emergencyType ?? this.emergencyType,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userAvatar: userAvatar ?? this.userAvatar,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'user_id': userId,
      'emergency_type': emergencyType,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
    if (id.isNotEmpty && !id.startsWith('temp-')) {
      map['id'] = id;
    }
    if (resolvedAt != null) {
      map['resolved_at'] = resolvedAt!.toUtc().toIso8601String();
    }
    return map;
  }

  factory SosAlertModel.fromJson(Map<String, dynamic> json) {
    // Supabase returns joined table metadata under a 'users' key
    final userData = json['users'] as Map<String, dynamic>?;

    return SosAlertModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      emergencyType: json['emergency_type'] as String? ?? 'Other',
      description: json['description'] as String?,
      latitude: (json['latitude'] as num? ?? 35.9208).toDouble(),
      longitude: (json['longitude'] as num? ?? 74.3089).toDouble(),
      status: json['status'] as String? ?? 'active',
      createdAt: DateTime.parse(json['created_at'] as String? ?? DateTime.now().toIso8601String()),
      resolvedAt: json['resolved_at'] != null ? DateTime.parse(json['resolved_at'] as String) : null,
      userName: userData?['full_name'] as String? ?? json['user_name'] as String?,
      userEmail: userData?['email'] as String? ?? json['user_email'] as String?,
      userAvatar: userData?['avatar_url'] as String? ?? json['user_avatar'] as String?,
    );
  }
}
