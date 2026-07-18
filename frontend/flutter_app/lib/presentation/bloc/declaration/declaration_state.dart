// lib/presentation/bloc/declaration/declaration_state.dart

part of 'declaration_bloc.dart';

abstract class DeclarationState extends Equatable {
  const DeclarationState();
  
  @override
  List<Object?> get props => [];
}

class DeclarationInitial extends DeclarationState {
  const DeclarationInitial();
}

class DeclarationLoading extends DeclarationState {
  const DeclarationLoading();
}

class DeclarationLoaded extends DeclarationState {
  final Map<String, dynamic> data;
  
  const DeclarationLoaded({this.data = const {}});
  
  @override
  List<Object?> get props => [data];
}

class DeclarationSubmitted extends DeclarationState {
  final Map<String, dynamic> data;
  
  const DeclarationSubmitted({required this.data});
  
  @override
  List<Object?> get props => [data];
}

class DeclarationError extends DeclarationState {
  final String message;
  
  const DeclarationError(this.message);
  
  @override
  List<Object?> get props => [message];
}