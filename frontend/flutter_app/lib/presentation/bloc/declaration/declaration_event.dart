// lib/presentation/bloc/declaration/declaration_event.dart

part of 'declaration_bloc.dart';

abstract class DeclarationEvent extends Equatable {
  const DeclarationEvent();
  
  @override
  List<Object?> get props => [];
}

class LoadDeclarationDataEvent extends DeclarationEvent {
  const LoadDeclarationDataEvent();
}

class UpdateDeclarationEvent extends DeclarationEvent {
  final String key;
  final dynamic value;
  
  const UpdateDeclarationEvent(this.key, this.value);
  
  @override
  List<Object?> get props => [key, value];
}

class SubmitDeclarationEvent extends DeclarationEvent {
  final String date;
  final String time;
  final String location;
  final String description;
  final String vehicleName;
  final String driverName;
  final List<String>? images;
  
  const SubmitDeclarationEvent({
    required this.date,
    required this.time,
    required this.location,
    required this.description,
    required this.vehicleName,
    required this.driverName,
    this.images,
  });
  
  @override
  List<Object?> get props => [
    date, time, location, description, vehicleName, driverName, images
  ];
}

class ResetDeclarationEvent extends DeclarationEvent {
  const ResetDeclarationEvent();
}