// lib/presentation/bloc/traffic/traffic_state.dart

part of 'traffic_bloc.dart';

abstract class TrafficState extends Equatable {
  const TrafficState();
  
  @override
  List<Object?> get props => [];
}

class TrafficInitial extends TrafficState {
  const TrafficInitial();
}

class TrafficLoading extends TrafficState {
  const TrafficLoading();
}

class TrafficLoaded extends TrafficState {
  final bool isCongested;
  final String location;
  final int totalDelay;
  final int incidentCount;
  final String trafficLevel;
  final List<Map<String, dynamic>> incidents;
  final String lastUpdate;

  const TrafficLoaded({
    required this.isCongested,
    required this.location,
    required this.totalDelay,
    required this.incidentCount,
    required this.trafficLevel,
    required this.incidents,
    required this.lastUpdate,
  });

  @override
  List<Object?> get props => [
    isCongested, location, totalDelay, incidentCount, 
    trafficLevel, incidents, lastUpdate
  ];
}

class TrafficError extends TrafficState {
  final String message;

  const TrafficError(this.message);

  @override
  List<Object?> get props => [message];
}