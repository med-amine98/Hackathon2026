// lib/presentation/bloc/conseil/conseil_state.dart

part of 'conseil_bloc.dart';

abstract class ConseilState extends Equatable {
  const ConseilState();
  
  @override
  List<Object?> get props => [];
}

class ConseilInitial extends ConseilState {
  const ConseilInitial();
}

class ConseilLoading extends ConseilState {
  const ConseilLoading();
}

class ConseilLoaded extends ConseilState {
  final UserModel user;
  final VehicleModel vehicle;
  final int riskScore;
  final String riskAnalysis;
  final List<Map<String, dynamic>> garanties;
  final String iaAdvice;

  const ConseilLoaded({
    required this.user,
    required this.vehicle,
    required this.riskScore,
    required this.riskAnalysis,
    required this.garanties,
    required this.iaAdvice,
  });

  @override
  List<Object?> get props => [
    user, vehicle, riskScore, riskAnalysis, garanties, iaAdvice
  ];
}

class ConseilError extends ConseilState {
  final String message;
  
  const ConseilError(this.message);
  
  @override
  List<Object?> get props => [message];
}