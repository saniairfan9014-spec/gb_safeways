class RoadModel {
  final String id;
  final String name;
  final String status;
  final String description;
  final String origin;
  final String destination;
  final double distanceKm;
  final String weather;
  final double safetyRating;
  final String? createdBy;
  final DateTime lastUpdated;

  RoadModel({
    required this.id,
    required this.name,
    required this.status,
    required this.description,
    required this.origin,
    required this.destination,
    required this.distanceKm,
    required this.weather,
    required this.safetyRating,
    this.createdBy,
    required this.lastUpdated,
  });

  factory RoadModel.fromJson(Map<String, dynamic> json) {
    return RoadModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      status: (json['status'] ?? 'open').toString(),
      description: json['description'] ?? '',
      origin: json['from_location'] ?? '',
      destination: json['to_location'] ?? '',
      distanceKm: (json['distance_km'] ?? 0.0).toDouble(),
      weather: json['weather'] ?? 'Clear',
      safetyRating: (json['safety_rating'] ?? 5.0).toDouble(),
      createdBy: json['created_by'],
      lastUpdated: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'status': status,
      'description': description,
      'from_location': origin,
      'to_location': destination,
      'distance_km': distanceKm,
      'weather': weather,
      'safety_rating': safetyRating,
      if (createdBy != null) 'created_by': createdBy,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  RoadModel copyWith({
    String? id,
    String? name,
    String? status,
    String? description,
    String? origin,
    String? destination,
    double? distanceKm,
    String? weather,
    double? safetyRating,
    String? createdBy,
    DateTime? lastUpdated,
  }) {
    return RoadModel(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      description: description ?? this.description,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      distanceKm: distanceKm ?? this.distanceKm,
      weather: weather ?? this.weather,
      safetyRating: safetyRating ?? this.safetyRating,
      createdBy: createdBy ?? this.createdBy,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}