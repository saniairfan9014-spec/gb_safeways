class RoadModel {
  final String id;
  final String name;
  final String status; // 'Open', 'Caution', 'Blocked'
  final String description;
  final String weather; // e.g., 'Clear', 'Heavy Rain', 'Heavy Snow', 'Foggy'
  final double safetyRating; // 1.0 (very dangerous) to 5.0 (perfectly safe)
  final String origin;
  final String destination;
  final int distanceKm;
  final DateTime lastUpdated;

  RoadModel({
    required this.id,
    required this.name,
    required this.status,
    required this.description,
    required this.weather,
    required this.safetyRating,
    required this.origin,
    required this.destination,
    required this.distanceKm,
    required this.lastUpdated,
  });

  RoadModel copyWith({
    String? id,
    String? name,
    String? status,
    String? description,
    String? weather,
    double? safetyRating,
    String? origin,
    String? destination,
    int? distanceKm,
    DateTime? lastUpdated,
  }) {
    return RoadModel(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      description: description ?? this.description,
      weather: weather ?? this.weather,
      safetyRating: safetyRating ?? this.safetyRating,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      distanceKm: distanceKm ?? this.distanceKm,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'status': status,
      'description': description,
      'from_location': origin,
      'to_location': destination,
      'updated_at': lastUpdated.toIso8601String(),
    };
  }

  factory RoadModel.fromJson(Map<String, dynamic> json) {
    return RoadModel(
      id: json['id'] as String,
      name: json['name'] as String,
      status: json['status'] as String? ?? 'open',
      description: json['description'] as String? ?? '',
      weather: json['weather'] as String? ?? 'Clear',
      safetyRating: json['safety_rating'] != null ? (json['safety_rating'] as num).toDouble() : 4.5,
      origin: json['from_location'] as String? ?? json['origin'] as String? ?? 'Origin',
      destination: json['to_location'] as String? ?? json['destination'] as String? ?? 'Destination',
      distanceKm: json['distance_km'] as int? ?? 100,
      lastUpdated: DateTime.parse(json['updated_at'] as String? ?? json['last_updated'] as String? ?? DateTime.now().toIso8601String()),
    );
  }
}
