class ReportModel {
  final String id;
  final String userId;
  final String userName;
  final String userAvatar;
  final String roadId;
  final String roadName;
  final String hazardType; // e.g. 'Landslide', 'Avalanche', 'Rockfall'
  final String description;
  final String severity; // 'Low', 'Medium', 'High'
  final double latitude;
  final double longitude;
  final int upvotes;
  final bool isResolved;
  final String status; // 'pending', 'verified', 'rejected'
  final String? imageUrl;
  final DateTime createdAt;

  ReportModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.roadId,
    required this.roadName,
    required this.hazardType,
    required this.description,
    required this.severity,
    required this.latitude,
    required this.longitude,
    this.upvotes = 0,
    this.isResolved = false,
    this.status = 'pending',
    this.imageUrl,
    required this.createdAt,
  });

  ReportModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userAvatar,
    String? roadId,
    String? roadName,
    String? hazardType,
    String? description,
    String? severity,
    double? latitude,
    double? longitude,
    int? upvotes,
    bool? isResolved,
    String? status,
    String? imageUrl,
    DateTime? createdAt,
  }) {
    return ReportModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      roadId: roadId ?? this.roadId,
      roadName: roadName ?? this.roadName,
      hazardType: hazardType ?? this.hazardType,
      description: description ?? this.description,
      severity: severity ?? this.severity,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      upvotes: upvotes ?? this.upvotes,
      isResolved: isResolved ?? this.isResolved,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'user_avatar': userAvatar,
      'road_id': roadId,
      'road_name': roadName,
      'hazard_type': hazardType,
      'description': description,
      'severity': severity,
      'latitude': latitude,
      'longitude': longitude,
      'upvotes': upvotes,
      'is_resolved': isResolved,
      'message': description,
      'image': imageUrl ?? '',
      'location': '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}',
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    final userData = json['users'] as Map<String, dynamic>?;
    final roadData = json['roads'] as Map<String, dynamic>?;

    final parsedStatus = json['status'] as String? ?? 'pending';
    final parsedIsResolved = json['is_resolved'] as bool? ?? (parsedStatus == 'verified' || parsedStatus == 'rejected');

    return ReportModel(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? '',
      userName: json['user_name'] as String? ?? userData?['name'] as String? ?? 'Traveler',
      userAvatar: json['user_avatar'] as String? ?? userData?['avatar'] as String? ?? 'https://ui-avatars.com/api/?name=Traveler&background=0284C7&color=fff&bold=true',
      roadId: json['road_id'] as String? ?? '',
      roadName: json['road_name'] as String? ?? roadData?['name'] as String? ?? 'Road',
      hazardType: json['hazard_type'] as String? ?? 'Hazard',
      description: json['message'] as String? ?? json['description'] as String? ?? '',
      severity: json['severity'] as String? ?? 'Medium',
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : 35.9208,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : 74.3089,
      upvotes: json['upvotes'] as int? ?? 0,
      isResolved: parsedIsResolved,
      status: parsedStatus,
      imageUrl: json['image'] as String? ?? json['image_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String? ?? DateTime.now().toIso8601String()),
    );
  }
}
