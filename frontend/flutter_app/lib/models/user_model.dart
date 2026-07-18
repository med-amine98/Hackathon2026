// lib/models/user_model.dart

class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final int age;
  final String city;
  final String drivingLicense;
  final int experienceYears;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.age,
    required this.city,
    required this.drivingLicense,
    required this.experienceYears,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      age: json['age'] as int? ?? 0,
      city: json['city'] as String? ?? '',
      drivingLicense: json['driving_license'] as String? ?? '',
      experienceYears: json['experience_years'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'age': age,
      'city': city,
      'driving_license': drivingLicense,
      'experience_years': experienceYears,
    };
  }

  String get fullName => '$firstName $lastName';
}