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
  final List<DeclarationModel> declarations;
  
  const DeclarationLoaded(this.declarations);

  @override
  List<Object?> get props => [declarations];
}

class DeclarationError extends DeclarationState {
  final String message;
  
  const DeclarationError(this.message);

  @override
  List<Object?> get props => [message];
}