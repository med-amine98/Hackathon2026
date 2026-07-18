// lib/presentation/bloc/profile/profile_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ai_insurance_advisor/data/repositories/profile_repository.dart';
import 'package:ai_insurance_advisor/core/services/risk_prediction_service.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository _profileRepository;
  final RiskPredictionService _riskService = RiskPredictionService();

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
      final profile = await _profileRepository.getProfile();

      final riskScore = _riskService.predictRiskScore(profile);
      final riskLevel = _riskService.getRiskLevel(riskScore);
      final riskFactors = _riskService.getRiskFactors(profile);
      final recommendations = _riskService.getRecommendations(profile);

      final enrichedProfile = {
        ...profile,
        'risk_score': riskScore,
        'risk_level': riskLevel,
        'risk_factors': riskFactors,
        'recommendations': recommendations,
      };

      emit(ProfileLoaded(enrichedProfile));
    } catch (e) {
      emit(ProfileError('Erreur lors du chargement du profil: $e'));
    }
  }

  Future<void> _onUpdateProfile(
    UpdateProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());
    try {
      await _profileRepository.updateProfile(event.profileData);

      final profile = await _profileRepository.getProfile();

      final riskScore = _riskService.predictRiskScore(profile);
      final riskLevel = _riskService.getRiskLevel(riskScore);
      final riskFactors = _riskService.getRiskFactors(profile);
      final recommendations = _riskService.getRecommendations(profile);

      final enrichedProfile = {
        ...profile,
        'risk_score': riskScore,
        'risk_level': riskLevel,
        'risk_factors': riskFactors,
        'recommendations': recommendations,
      };

      emit(ProfileLoaded(enrichedProfile));
    } catch (e) {
      emit(ProfileError('Erreur lors de la mise à jour du profil: $e'));
    }
  }
}