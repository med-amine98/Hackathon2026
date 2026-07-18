// lib/presentation/bloc/conseil/conseil_bloc.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ai_insurance_advisor/services/ai/ai_service.dart';
import 'package:ai_insurance_advisor/models/user_model.dart';
import 'package:ai_insurance_advisor/models/vehicle_model.dart';

part 'conseil_event.dart';
part 'conseil_state.dart';

class ConseilBloc extends Bloc<ConseilEvent, ConseilState> {
  ConseilBloc() : super(const ConseilInitial()) {
    on<LoadConseilDataEvent>(_onLoadData);
  }

  Future<void> _onLoadData(
    LoadConseilDataEvent event,
    Emitter<ConseilState> emit,
  ) async {
    emit(const ConseilLoading());
    try {
      final user = await _getUser();
      final vehicle = await _getVehicle();

      final advice = await AIService.getPersonalizedAdvice(
        user: user,
        vehicle: vehicle,
      );

      final riskScore = _calculateRisk(user, vehicle);
      final riskAnalysis = _getRiskAnalysis(riskScore);
      final garanties = _getGaranties(user, vehicle);

      emit(ConseilLoaded(
        user: user,
        vehicle: vehicle,
        riskScore: riskScore,
        riskAnalysis: riskAnalysis,
        garanties: garanties,
        iaAdvice: advice,
      ));
    } catch (e) {
      _emitFallbackData(emit);
    }
  }

  void _emitFallbackData(Emitter<ConseilState> emit) {
    final user = UserModel(
      id: '1',
      firstName: 'Test',
      lastName: 'User',
      email: 'test@email.com',
      phone: '12345678',
      age: 30,
      city: 'Tunis',
      drivingLicense: 'TUN123456',
      experienceYears: 5,
    );

    final vehicle = VehicleModel(
      id: '1',
      make: 'Toyota',
      model: 'Corolla',
      year: 2020,
      licensePlate: '123 TUN 456',
      annualKm: 15000,
      usage: 'quotidiennement',
      parkingType: 'garage',
    );

    emit(ConseilLoaded(
      user: user,
      vehicle: vehicle,
      riskScore: 35,
      riskAnalysis: 'Risque modéré - Conduite régulière en zone urbaine',
      garanties: [
        {
          'icon': Icons.shield,
          'title': 'Protection vol',
          'description': 'Couverture complète en cas de vol',
          'color': Colors.blue,
          'recommended': true,
        },
        {
          'icon': Icons.handshake,
          'title': 'Protection juridique',
          'description': 'Assistance et protection en cas de litige',
          'color': Colors.green,
          'recommended': true,
        },
      ],
      iaAdvice: 'Recommandation: Optez pour une protection vol et une assistance 24/7 adaptée à votre utilisation quotidienne.',
    ));
  }

  Future<UserModel> _getUser() async {
    return UserModel(
      id: '1',
      firstName: 'Test',
      lastName: 'User',
      email: 'test@email.com',
      phone: '12345678',
      age: 30,
      city: 'Tunis',
      drivingLicense: 'TUN123456',
      experienceYears: 5,
    );
  }

  Future<VehicleModel> _getVehicle() async {
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

  int _calculateRisk(UserModel user, VehicleModel vehicle) {
    int score = 0;
    if (user.age < 25) score += 20;
    if (user.experienceYears < 3) score += 15;
    if (vehicle.annualKm > 20000) score += 15;
    if (vehicle.usage == 'quotidiennement') score += 10;
    if (user.city == 'Tunis' || user.city == 'Sfax') score += 10;
    return score;
  }

  String _getRiskAnalysis(int score) {
    if (score > 60) return 'Risque élevé - Conduite à risque important';
    if (score > 30) return 'Risque modéré - Conduite standard';
    return 'Risque faible - Excellent profil';
  }

  List<Map<String, dynamic>> _getGaranties(
    UserModel user,
    VehicleModel vehicle,
  ) {
    final garanties = [
      {
        'icon': Icons.shield,
        'title': 'Protection vol',
        'description': 'Couverture complète en cas de vol',
        'color': Colors.blue,
        'recommended': true,
      },
      {
        'icon': Icons.handshake,
        'title': 'Protection juridique',
        'description': 'Assistance et protection en cas de litige',
        'color': Colors.green,
        'recommended': true,
      },
    ];

    if (user.age < 25) {
      garanties.add({
        'icon': Icons.people,
        'title': 'Protection conducteur',
        'description': 'Couverture spécifique jeune conducteur',
        'color': Colors.orange,
        'recommended': true,
      });
    }

    if (vehicle.annualKm > 20000) {
      garanties.add({
        'icon': Icons.construction,
        'title': 'Assistance dépannage',
        'description': 'Dépannage et remorquage illimité',
        'color': Colors.purple,
        'recommended': true,
      });
    }

    return garanties;
  }
}