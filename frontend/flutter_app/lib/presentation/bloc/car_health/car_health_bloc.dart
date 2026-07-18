import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'car_health_event.dart';
part 'car_health_state.dart';

class CarHealthBloc extends Bloc<CarHealthEvent, CarHealthState> {
  CarHealthBloc() : super(const CarHealthInitial()) {
    on<LoadCarHealthDataEvent>(_onLoadData);
    on<RefreshCarHealthEvent>(_onRefreshData);
    on<UpdateCarHealthEvent>(_onUpdateData);
  }

  Future<void> _onLoadData(
    LoadCarHealthDataEvent event,
    Emitter<CarHealthState> emit,
  ) async {
    emit(const CarHealthLoading());
    try {
      // ✅ CORRIGÉ : Type explicite pour Future.delayed
      await Future<void>.delayed(const Duration(seconds: 1));
      
      final data = {
        'water_level': 'Ok',
        'water_status': 'good',
        'oil_level': 'Ok',
        'oil_status': 'good',
        'battery': '12.4V',
        'battery_status': 'good',
        'tire_pressure': '2.4 bar',
        'tire_status': 'good',
        'engine_temp': '85°C',
        'temp_status': 'good',
        'rust_status': 'Aucune trace',
        'last_check': DateTime.now().toString(),
      };
      
      emit(CarHealthLoaded(data));
    } catch (e) {
      emit(CarHealthError(e.toString()));
    }
  }

  Future<void> _onRefreshData(
    RefreshCarHealthEvent event,
    Emitter<CarHealthState> emit,
  ) async {
    add(const LoadCarHealthDataEvent());
  }

  Future<void> _onUpdateData(
    UpdateCarHealthEvent event,
    Emitter<CarHealthState> emit,
  ) async {
    final currentState = state;
    if (currentState is CarHealthLoaded) {
      final newData = Map<String, dynamic>.from(currentState.data);
      newData[event.key] = event.value;
      emit(CarHealthLoaded(newData));
    }
  }
}