// lib/models/vehicle_model.dart

class VehicleModel {
  final String id;
  final String make;
  final String model;
  final int year;
  final String licensePlate;
  final int annualKm;
  final String usage;
  final String parkingType;

  VehicleModel({
    required this.id,
    required this.make,
    required this.model,
    required this.year,
    required this.licensePlate,
    required this.annualKm,
    required this.usage,
    required this.parkingType,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'] as String? ?? '',
      make: json['make'] as String? ?? '',
      model: json['model'] as String? ?? '',
      year: json['year'] as int? ?? 0,
      licensePlate: json['license_plate'] as String? ?? '',
      annualKm: json['annual_km'] as int? ?? 0,
      usage: json['usage'] as String? ?? '',
      parkingType: json['parking_type'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'make': make,
      'model': model,
      'year': year,
      'license_plate': licensePlate,
      'annual_km': annualKm,
      'usage': usage,
      'parking_type': parkingType,
    };
  }

  String get fullName => '$make $model ($year)';
}