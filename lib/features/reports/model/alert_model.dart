class AlertModel {
  final String id;
  final String title;
  final String message;
  final String severity; // 'Info', 'Warning', 'Danger'
  final DateTime createdAt;

  AlertModel({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    required this.createdAt,
  });

  AlertModel copyWith({
    String? id,
    String? title,
    String? message,
    String? severity,
    DateTime? createdAt,
  }) {
    return AlertModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      severity: severity ?? this.severity,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'priority': severity == 'Danger' ? 'high' : (severity == 'Warning' ? 'normal' : 'low'),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    final String priority = json['priority'] as String? ?? json['severity'] as String? ?? 'normal';
    String mappedSeverity = 'Warning';
    if (priority.toLowerCase() == 'high') {
      mappedSeverity = 'Danger';
    } else if (priority.toLowerCase() == 'low') {
      mappedSeverity = 'Info';
    } else {
      mappedSeverity = 'Warning';
    }

    return AlertModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Safety Alert',
      message: json['message'] as String? ?? '',
      severity: mappedSeverity,
      createdAt: DateTime.parse(json['created_at'] as String? ?? DateTime.now().toIso8601String()),
    );
  }
}
