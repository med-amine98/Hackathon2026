// lib/presentation/bloc/prevention/prevention_state.dart

part of 'prevention_bloc.dart';

abstract class PreventionState {
  const PreventionState();
}

class PreventionInitial extends PreventionState {
  const PreventionInitial();
}

class PreventionLoading extends PreventionState {
  const PreventionLoading();
}

class PreventionLoaded extends PreventionState {
  final Map<String, dynamic> weather;
  final List<Map<String, dynamic>> maintenances;
  final List<Map<String, dynamic>> traffic;
  final List<String> aiAlerts;

  const PreventionLoaded({
    required this.weather,
    required this.maintenances,
    required this.traffic,
    required this.aiAlerts,
  });
}

class PreventionError extends PreventionState {
  final String message;
  
  const PreventionError(this.message);
}