// lib/data/models/product.dart

class InsuranceProduct {
  final int id;
  final String name;
  final String provider;
  final String category;
  final double coverageAmount;
  final double deductible;
  final double monthlyPremium;
  final List<String> features;
  final Map<String, dynamic>? coverageDetails;
  final int minAge;
  final int maxAge;
  final Map<String, dynamic>? vehicleRequirements;
  final double rating;
  final int reviewsCount;
  final bool isActive;
  final DateTime createdAt;

  InsuranceProduct({
    required this.id,
    required this.name,
    required this.provider,
    required this.category,
    required this.coverageAmount,
    required this.deductible,
    required this.monthlyPremium,
    this.features = const [],
    this.coverageDetails,
    required this.minAge,
    required this.maxAge,
    this.vehicleRequirements,
    required this.rating,
    required this.reviewsCount,
    required this.isActive,
    required this.createdAt,
  });

  factory InsuranceProduct.fromJson(Map<String, dynamic> json) {
    return InsuranceProduct(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      provider: json['provider'] as String? ?? '',
      category: json['category'] as String? ?? 'auto',
      coverageAmount: (json['coverage_amount'] as num?)?.toDouble() ?? 0.0,
      deductible: (json['deductible'] as num?)?.toDouble() ?? 0.0,
      monthlyPremium: (json['monthly_premium'] as num?)?.toDouble() ?? 0.0,
      features: (json['features'] as List<dynamic>?)?.cast<String>() ?? [],
      coverageDetails: json['coverage_details'] as Map<String, dynamic>?,
      minAge: json['min_age'] as int? ?? 18,
      maxAge: json['max_age'] as int? ?? 99,
      vehicleRequirements: json['vehicle_requirements'] as Map<String, dynamic>?,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewsCount: json['reviews_count'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : DateTime.now(),
    );
  }

  String get formattedPremium => '${monthlyPremium.toStringAsFixed(2)} TND';
  String get formattedCoverage => '${(coverageAmount / 1000).toStringAsFixed(0)}K TND';
}