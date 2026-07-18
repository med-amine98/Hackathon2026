part of 'car_health_bloc.dart';

abstract class CarHealthState extends Equatable {
  const CarHealthState();
  
  @override
  List<Object?> get props => [];
}

class CarHealthInitial extends CarHealthState {
  const CarHealthInitial();
}

class CarHealthLoading extends CarHealthState {
  const CarHealthLoading();
}

class CarHealthLoaded extends CarHealthState {
  final Map<String, dynamic> data;
  
  const CarHealthLoaded(this.data);
  
  @override
  List<Object?> get props => [data];
}

class CarHealthError extends CarHealthState {
  final String message;
  
  const CarHealthError(this.message);
  
  @override
  List<Object?> get props => [message];
}