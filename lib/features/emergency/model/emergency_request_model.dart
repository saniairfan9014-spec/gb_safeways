class EmergencyRequestModel {
  final String id;
  final String userId;
  final String userName;
  final String phoneNumber;
  final double latitude;
  final double longitude;
  final String type; // 'rescue' | 'ambulance' | 'police' | 'medical'
  final String message;
  final bool isActive;
  final DateTime createdAt;

  EmergencyRequestModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.phoneNumber,
    required this.latitude,
    required this.longitude,
    this.type = 'rescue',
    this.message = 'Distress satellite signal',
    this.isActive = true,
    required this.createdAt,
  });

  EmergencyRequestModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? phoneNumber,
    double? latitude,
    double? longitude,
    String? type,
    String? message,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return EmergencyRequestModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      type: type ?? this.type,
      message: message ?? this.message,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'message': message,
      'location': 'Lat: ${latitude.toStringAsFixed(4)}, Lng: ${longitude.toStringAsFixed(4)}',
      'latitude': latitude,
      'longitude': longitude,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory EmergencyRequestModel.fromJson(Map<String, dynamic> json) {
    final userData = json['users'] as Map<String, dynamic>?;

    return EmergencyRequestModel(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? '',
      userName: json['user_name'] as String? ?? userData?['name'] as String? ?? 'Traveler',
      phoneNumber: json['phone_number'] as String? ?? userData?['phone'] as String? ?? '+92 355 4567890',
      latitude: (json['latitude'] as num? ?? 35.9208).toDouble(),
      longitude: (json['longitude'] as num? ?? 74.3089).toDouble(),
      type: json['type'] as String? ?? 'rescue',
      message: json['message'] as String? ?? 'Emergency active signal',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String? ?? DateTime.now().toIso8601String()),
    );
  }
}
