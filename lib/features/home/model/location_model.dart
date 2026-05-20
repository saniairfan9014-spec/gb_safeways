class UserLocationModel {
  final String id; // User ID
  final double latitude;
  final double longitude;
  final DateTime lastUpdated;

  UserLocationModel({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.lastUpdated,
  });

  UserLocationModel copyWith({
    String? id,
    double? latitude,
    double? longitude,
    DateTime? lastUpdated,
  }) {
    return UserLocationModel(
      id: id ?? this.id,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  factory UserLocationModel.fromJson(Map<String, dynamic> json) {
    return UserLocationModel(
      id: json['id'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      lastUpdated: DateTime.parse(json['last_updated'] as String),
    );
  }
}
