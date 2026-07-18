// lib/presentation/bloc/profile/profile_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ai_insurance_advisor/data/repositories/profile_repository.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository _profileRepository;

  ProfileBloc(this._profileRepository) : super(const ProfileInitial()) {
    on<LoadProfileEvent>(_onLoadProfile);
    on<UpdateProfileEvent>(_onUpdateProfile);
  }

  Future<void> _onLoadProfile(
    LoadProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());
    try {
      final data = await _profileRepository.getProfile();
      
      // ✅ Structurer les données pour le dashboard
      final profile = _mapProfileData(data);
      emit(ProfileLoaded(profile));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> _onUpdateProfile(
    UpdateProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());
    try {
      final data = await _profileRepository.updateProfile(event.profileData);
      final profile = _mapProfileData(data);
      emit(ProfileLoaded(profile));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  /// ✅ Mapper les données du backend vers un format structuré
  Map<String, dynamic> _mapProfileData(Map<String, dynamic> data) {
    return {
      // Infos personnelles
      'id': data['id'],
      'email': data['email'] ?? 'Non renseigné',
      'first_name': data['first_name'] ?? 'Utilisateur',
      'last_name': data['last_name'] ?? '',
      'phone': data['phone'],
      'age': data['age'],
      'city': data['city'] ?? 'Tunis',
      'occupation': data['occupation'] ?? 'Non renseigné',
      
      // Véhicule
      'vehicle_make': data['vehicle_make'] ?? 'Non renseigné',
      'vehicle_model': data['vehicle_model'] ?? 'Non renseigné',
      'vehicle_year': data['vehicle_year'],
      'vehicle_usage': data['vehicle_usage'] ?? 'quotidiennement',
      'annual_km': data['annual_km'] ?? 0,
      
      // Assurance
      'insurance_status': data['insurance_status'] ?? 'active',
      'monthly_premium': data['monthly_premium'] ?? 0.0,
      'coverage_amount': data['coverage_amount'] ?? 0.0,
      
      // Score de risque
      'risk_score': data['risk_score'] ?? 0.0,
      'risk_level': data['risk_level'] ?? 'Moyen',
      'risk_factors': data['risk_factors'] ?? [],
      
      // Statistiques
      'vehicles_count': data['vehicles_count'] ?? 1,
      'contracts_count': data['contracts_count'] ?? 2,
      'alerts_count': data['alerts_count'] ?? 5,
      
      // Dates
      'created_at': data['created_at'],
      'updated_at': data['updated_at'],
    };
  }
}