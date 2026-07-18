// lib/presentation/bloc/conseil/conseil_event.dart

part of 'conseil_bloc.dart';

abstract class ConseilEvent extends Equatable {
  const ConseilEvent();
  
  @override
  List<Object?> get props => [];
}

class LoadConseilDataEvent extends ConseilEvent {
  const LoadConseilDataEvent();
}