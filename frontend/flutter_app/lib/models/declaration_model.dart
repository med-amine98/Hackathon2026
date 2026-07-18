// lib/models/declaration_model.dart

class DeclarationModel {
  final String id;
  final String date;
  final String time;
  final String location;
  final String description;
  final String vehicleName;
  final String driverName;
  final String status;
  final DateTime createdAt;
  final List<String> images;
  final Map<String, dynamic>? analysis;

  DeclarationModel({
    required this.id,
    required this.date,
    required this.time,
    required this.location,
    required this.description,
    required this.vehicleName,
    required this.driverName,
    required this.status,
    required this.createdAt,
    this.images = const [],
    this.analysis,
  });

  factory DeclarationModel.fromJson(Map<String, dynamic> json) {
    return DeclarationModel(
      id: json['id'] as String? ?? '',
      date: json['date'] as String? ?? '',
      time: json['time'] as String? ?? '',
      location: json['location'] as String? ?? '',
      description: json['description'] as String? ?? '',
      vehicleName: json['vehicle_name'] as String? ?? '',
      driverName: json['driver_name'] as String? ?? '',
      status: json['status'] as String? ?? 'en_attente',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      images: (json['images'] as List<dynamic>?)?.cast<String>() ?? [],
      analysis: json['analysis'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'time': time,
      'location': location,
      'description': description,
      'vehicle_name': vehicleName,
      'driver_name': driverName,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'images': images,
      'analysis': analysis,
    };
  }
}