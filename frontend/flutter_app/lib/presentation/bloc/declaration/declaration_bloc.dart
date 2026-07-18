// lib/presentation/bloc/declaration/declaration_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ai_insurance_advisor/data/models/declaration_model.dart';
import 'package:ai_insurance_advisor/data/repositories/declaration_repository.dart';

part 'declaration_event.dart';
part 'declaration_state.dart';

class DeclarationBloc extends Bloc<DeclarationEvent, DeclarationState> {
  DeclarationBloc() : super(const DeclarationInitial()) {
    on<LoadDeclarationsEvent>(_onLoadDeclarations);
    on<AddDeclarationEvent>(_onAddDeclaration);
    on<UpdateDeclarationEvent>(_onUpdateDeclaration);
    on<DeleteDeclarationEvent>(_onDeleteDeclaration);
    on<RefreshDeclarationsEvent>(_onRefreshDeclarations);
  }

  Future<void> _onLoadDeclarations(
    LoadDeclarationsEvent event,
    Emitter<DeclarationState> emit,
  ) async {
    emit(const DeclarationLoading());
    try {
      // ✅ CORRECTION : Utiliser await pour récupérer les déclarations
      final currentDeclarations = await DeclarationRepository.getDeclarations();
      
      // Ajouter des données de test si nécessaire
      if (currentDeclarations.isEmpty) {
        DeclarationRepository.addTestDeclarations();
      }
      
      final declarations = await DeclarationRepository.getDeclarations();
      emit(DeclarationLoaded(declarations));
    } catch (e) {
      emit(DeclarationError('Erreur lors du chargement des déclarations: $e'));
    }
  }

  Future<void> _onAddDeclaration(
    AddDeclarationEvent event,
    Emitter<DeclarationState> emit,
  ) async {
    try {
      await DeclarationRepository.addDeclaration(event.declaration);
      final declarations = await DeclarationRepository.getDeclarations();
      emit(DeclarationLoaded(declarations));
    } catch (e) {
      emit(DeclarationError('Erreur lors de l\'ajout de la déclaration: $e'));
    }
  }

  Future<void> _onUpdateDeclaration(
    UpdateDeclarationEvent event,
    Emitter<DeclarationState> emit,
  ) async {
    try {
      await DeclarationRepository.updateDeclarationStatus(
        event.id, 
        event.newStatus
      );
      final declarations = await DeclarationRepository.getDeclarations();
      emit(DeclarationLoaded(declarations));
    } catch (e) {
      emit(DeclarationError('Erreur lors de la mise à jour: $e'));
    }
  }

  Future<void> _onDeleteDeclaration(
    DeleteDeclarationEvent event,
    Emitter<DeclarationState> emit,
  ) async {
    try {
      await DeclarationRepository.deleteDeclaration(event.id);
      final declarations = await DeclarationRepository.getDeclarations();
      emit(DeclarationLoaded(declarations));
    } catch (e) {
      emit(DeclarationError('Erreur lors de la suppression: $e'));
    }
  }

  Future<void> _onRefreshDeclarations(
    RefreshDeclarationsEvent event,
    Emitter<DeclarationState> emit,
  ) async {
    final declarations = await DeclarationRepository.getDeclarations();
    emit(DeclarationLoaded(declarations));
  }
}