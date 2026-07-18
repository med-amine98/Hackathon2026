// lib/presentation/bloc/prevention/prevention_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_insurance_advisor/services/prevention_service.dart';
import 'package:ai_insurance_advisor/models/vehicle_model.dart';
import 'package:ai_insurance_advisor/data/repositories/auth_repository.dart';
import 'package:ai_insurance_advisor/data/repositories/profile_repository.dart';

part 'prevention_event.dart';
part 'prevention_state.dart';

class PreventionBloc extends Bloc<PreventionEvent, PreventionState> {
  final AuthRepository? _authRepository;
  final ProfileRepository? _profileRepository;

  PreventionBloc({
    AuthRepository? authRepository,
    ProfileRepository? profileRepository,
  })  : _authRepository = authRepository,
        _profileRepository = profileRepository,
        super(const PreventionInitial()) {
    on<LoadPreventionDataEvent>(_onLoadData);
    on<RefreshPreventionEvent>(_onRefresh);
  }

  Future<void> _onLoadData(
    LoadPreventionDataEvent event,
    Emitter<PreventionState> emit,
  ) async {
    emit(const PreventionLoading());
    try {
      final vehicle = await _getVehicle();
      const latitude = 36.8065;
      const longitude = 10.1815;

      final weatherData = await PreventionService.getWeatherAlerts(
        latitude: latitude,
        longitude: longitude,
      );

      final trafficData = await PreventionService.getTrafficAlerts(
        latitude: latitude,
        longitude: longitude,
      );

      final aiAlerts = await PreventionService.getAIAlerts(
        vehicle: vehicle,
        weather: weatherData,
        traffic: trafficData,
      );

      final maintenanceAlerts = PreventionService.getMaintenanceAlerts(vehicle);

      emit(PreventionLoaded(
        weather: weatherData,
        maintenances: maintenanceAlerts,
        traffic: trafficData,
        aiAlerts: aiAlerts,
      ));
    } catch (e) {
      print('❌ PreventionBloc error: $e');
      emit(PreventionError('Erreur: ${e.toString()}'));
    }
  }

  Future<void> _onRefresh(
    RefreshPreventionEvent event,
    Emitter<PreventionState> emit,
  ) async {
    add(const LoadPreventionDataEvent());
  }

  Future<VehicleModel> _getVehicle() async {
    try {
      if (_profileRepository != null) {
        final profile = await _profileRepository!.getProfile();
        if (profile.isNotEmpty && profile['vehicle_id'] != null) {
          return VehicleModel(
            id: profile['vehicle_id']?.toString() ?? '1',
            make: profile['vehicle_make'] as String? ?? 'Toyota',
            model: profile['vehicle_model'] as String? ?? 'Corolla',
            year: profile['vehicle_year'] as int? ?? 2020,
            licensePlate: profile['license_plate'] as String? ?? '123 TUN 456',
            annualKm: profile['annual_km'] as int? ?? 15000,
            usage: profile['vehicle_usage'] as String? ?? 'quotidiennement',
            parkingType: profile['parking_type'] as String? ?? 'garage',
          );
        }
      }
      
      if (_authRepository != null) {
        final user = await _authRepository!.getStoredUser();
        if (user != null) {
          return VehicleModel(
            id: '1',
            make: 'Toyota',
            model: 'Corolla',
            year: 2020,
            licensePlate: '123 TUN 456',
            annualKm: 15000,
            usage: 'quotidiennement',
            parkingType: 'garage',
          );
        }
      }
      
      throw Exception('Aucun véhicule trouvé');
    } catch (e) {
      print('❌ Error getting vehicle: $e');
      rethrow;
    }
  }
}