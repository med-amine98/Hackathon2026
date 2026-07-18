// lib/presentation/bloc/declaration/declaration_event.dart

part of 'declaration_bloc.dart';

abstract class DeclarationEvent extends Equatable {
  const DeclarationEvent();

  @override
  List<Object?> get props => [];
}

class LoadDeclarationsEvent extends DeclarationEvent {
  const LoadDeclarationsEvent();
}

class AddDeclarationEvent extends DeclarationEvent {
  final DeclarationModel declaration;
  
  const AddDeclarationEvent(this.declaration);

  @override
  List<Object?> get props => [declaration];
}

class UpdateDeclarationEvent extends DeclarationEvent {
  final String id;
  final String newStatus;
  
  const UpdateDeclarationEvent(this.id, this.newStatus);

  @override
  List<Object?> get props => [id, newStatus];
}

class DeleteDeclarationEvent extends DeclarationEvent {
  final String id;
  
  const DeleteDeclarationEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class RefreshDeclarationsEvent extends DeclarationEvent {
  const RefreshDeclarationsEvent();
}