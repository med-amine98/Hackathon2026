part of 'car_health_bloc.dart';

abstract class CarHealthEvent extends Equatable {
  const CarHealthEvent();
  
  @override
  List<Object?> get props => [];
}

class LoadCarHealthDataEvent extends CarHealthEvent {
  const LoadCarHealthDataEvent();
}

class RefreshCarHealthEvent extends CarHealthEvent {
  const RefreshCarHealthEvent();
}

class UpdateCarHealthEvent extends CarHealthEvent {
  final String key;
  final dynamic value;
  
  const UpdateCarHealthEvent(this.key, this.value);
  
  @override
  List<Object?> get props => [key, value];
}