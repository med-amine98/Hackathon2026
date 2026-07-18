// lib/presentation/bloc/traffic/traffic_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ai_insurance_advisor/services/traffic_service.dart';

part 'traffic_event.dart';
part 'traffic_state.dart';

class TrafficBloc extends Bloc<TrafficEvent, TrafficState> {
  TrafficBloc() : super(const TrafficInitial()) {
    on<LoadTrafficEvent>(_onLoadTraffic);
    on<RefreshTrafficEvent>(_onRefreshTraffic);
  }

  Future<void> _onLoadTraffic(
    LoadTrafficEvent event,
    Emitter<TrafficState> emit,
  ) async {
    emit(const TrafficLoading());
    try {
      final data = await TrafficService.getTrafficIncidents(
        lat: event.lat,
        lon: event.lon,
        radius: event.radius ?? 5000,
      );
      
      emit(TrafficLoaded(
        isCongested: data['isCongested'] as bool? ?? false,
        location: 'Tunis',
        totalDelay: data['totalDelay'] as int? ?? 0,
        incidentCount: data['incidentCount'] as int? ?? 0,
        trafficLevel: data['trafficLevel'] as String? ?? 'Fluide',
        incidents: (data['incidents'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [],
        lastUpdate: data['lastUpdate'] as String? ?? DateTime.now().toIso8601String(),
      ));
    } catch (e) {
      print('❌ TrafficBloc error: $e');
      emit(TrafficError(e.toString()));
    }
  }

  Future<void> _onRefreshTraffic(
    RefreshTrafficEvent event,
    Emitter<TrafficState> emit,
  ) async {
    add(LoadTrafficEvent(
      lat: event.lat,
      lon: event.lon,
      radius: event.radius,
    ));
  }
}