class PersonalContact {
  final String id;
  final String name;
  final String phone;
  final String category; // e.g. Family, Friend, Doctor, Local Rescue
  final String location;

  PersonalContact({
    required this.id,
    required this.name,
    required this.phone,
    required this.category,
    this.location = 'Unknown Location',
  });

  PersonalContact copyWith({
    String? id,
    String? name,
    String? phone,
    String? category,
    String? location,
  }) {
    return PersonalContact(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      category: category ?? this.category,
      location: location ?? this.location,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'category': category,
      'location': location,
    };
  }

  factory PersonalContact.fromJson(Map<String, dynamic> json) {
    return PersonalContact(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      category: json['category'] as String,
      location: (json['location'] as String?) ?? 'Unknown Location',
    );
  }
}
