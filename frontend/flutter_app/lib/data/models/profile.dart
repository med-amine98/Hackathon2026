import 'package:flutter/material.dart';

class UserProfile {
  final int id;
  final int userId;
  final int? age;
  final String? city;
  final String? occupation;
  final String? maritalStatus;
  final String? vehicleMake;
  final String? vehicleModel;
  final int? vehicleYear;
  final String? vehicleUsage;
  final int? annualKm;
  final int? drivingExperienceYears;
  final String? parkingType;
  final double? budgetMonthly;
  final List<String>? preferredCoverage;
  final bool hasPreviousInsurance;
  final String? previousInsurer;
  final double? riskScore;
  final List<String>? riskFactors;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserProfile({
    required this.id,
    required this.userId,
    this.age,
    this.city,
    this.occupation,
    this.maritalStatus,
    this.vehicleMake,
    this.vehicleModel,
    this.vehicleYear,
    this.vehicleUsage,
    this.annualKm,
    this.drivingExperienceYears,
    this.parkingType,
    this.budgetMonthly,
    this.preferredCoverage,
    this.hasPreviousInsurance = false,
    this.previousInsurer,
    this.riskScore,
    this.riskFactors,
    required this.createdAt,
    this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int? ?? 0,
      userId: json['user_id'] as int? ?? 0,
      age: json['age'] as int?,
      city: json['city'] as String?,
      occupation: json['occupation'] as String?,
      maritalStatus: json['marital_status'] as String?,
      vehicleMake: json['vehicle_make'] as String?,
      vehicleModel: json['vehicle_model'] as String?,
      vehicleYear: json['vehicle_year'] as int?,
      vehicleUsage: json['vehicle_usage'] as String?,
      annualKm: json['annual_km'] as int?,
      drivingExperienceYears: json['driving_experience_years'] as int?,
      parkingType: json['parking_type'] as String?,
      budgetMonthly: (json['budget_monthly'] as num?)?.toDouble(),
      preferredCoverage: (json['preferred_coverage'] as List<dynamic>?)?.cast<String>(),
      hasPreviousInsurance: json['has_previous_insurance'] as bool? ?? false,
      previousInsurer: json['previous_insurer'] as String?,
      riskScore: (json['risk_score'] as num?)?.toDouble(),
      riskFactors: (json['risk_factors'] as List<dynamic>?)?.cast<String>(),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'age': age,
      'city': city,
      'occupation': occupation,
      'marital_status': maritalStatus,
      'vehicle_make': vehicleMake,
      'vehicle_model': vehicleModel,
      'vehicle_year': vehicleYear,
      'vehicle_usage': vehicleUsage,
      'annual_km': annualKm,
      'driving_experience_years': drivingExperienceYears,
      'parking_type': parkingType,
      'budget_monthly': budgetMonthly,
      'preferred_coverage': preferredCoverage,
      'has_previous_insurance': hasPreviousInsurance,
      'previous_insurer': previousInsurer,
      'risk_score': riskScore,
      'risk_factors': riskFactors,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  bool get isProfileComplete {
    return age != null &&
           city != null &&
           vehicleMake != null &&
           vehicleModel != null &&
           annualKm != null &&
           budgetMonthly != null;
  }

  String get riskLevel {
    if (riskScore == null) return 'Non évalué';
    if (riskScore! < 30) return 'Faible';
    if (riskScore! < 60) return 'Moyen';
    return 'Élevé';
  }

  Color get riskColor {
    if (riskScore == null) return Colors.grey;
    if (riskScore! < 30) return Colors.green;
    if (riskScore! < 60) return Colors.orange;
    return Colors.red;
  }
}