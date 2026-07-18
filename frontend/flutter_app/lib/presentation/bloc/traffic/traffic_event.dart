// lib/presentation/bloc/traffic/traffic_event.dart

part of 'traffic_bloc.dart';

abstract class TrafficEvent extends Equatable {
  const TrafficEvent();
  
  @override
  List<Object?> get props => [];
}

class LoadTrafficEvent extends TrafficEvent {
  final double lat;
  final double lon;
  final int? radius;
  
  const LoadTrafficEvent({
    required this.lat,
    required this.lon,
    this.radius,
  });
  
  @override
  List<Object?> get props => [lat, lon, radius];
}

class RefreshTrafficEvent extends TrafficEvent {
  final double lat;
  final double lon;
  final int? radius;
  
  const RefreshTrafficEvent({
    required this.lat,
    required this.lon,
    this.radius,
  });
  
  @override
  List<Object?> get props => [lat, lon, radius];
}