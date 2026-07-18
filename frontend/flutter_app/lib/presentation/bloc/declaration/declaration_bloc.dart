// lib/presentation/bloc/declaration/declaration_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ai_insurance_advisor/models/declaration_model.dart';
import 'package:ai_insurance_advisor/services/ai/declaration_service.dart';

part 'declaration_event.dart';
part 'declaration_state.dart';

class DeclarationBloc extends Bloc<DeclarationEvent, DeclarationState> {
  DeclarationBloc() : super(const DeclarationInitial()) {
    on<LoadDeclarationDataEvent>(_onLoadData);
    on<UpdateDeclarationEvent>(_onUpdate);
    on<SubmitDeclarationEvent>(_onSubmit);
    on<ResetDeclarationEvent>(_onReset);
  }

  Future<void> _onLoadData(
    LoadDeclarationDataEvent event,
    Emitter<DeclarationState> emit,
  ) async {
    emit(const DeclarationLoading());
    try {
      await Future<void>.delayed(const Duration(seconds: 1));
      emit(const DeclarationLoaded());
    } catch (e) {
      emit(DeclarationError(e.toString()));
    }
  }

  void _onUpdate(
    UpdateDeclarationEvent event,
    Emitter<DeclarationState> emit,
  ) {
    final currentState = state;
    if (currentState is DeclarationLoaded) {
      final updated = Map<String, dynamic>.from(currentState.data);
      updated[event.key] = event.value;
      emit(DeclarationLoaded(data: updated));
    }
  }

  Future<void> _onSubmit(
    SubmitDeclarationEvent event,
    Emitter<DeclarationState> emit,
  ) async {
    emit(const DeclarationLoading());
    try {
      // Créer la déclaration
      final declaration = DeclarationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: event.date,
        time: event.time,
        location: event.location,
        description: event.description,
        vehicleName: event.vehicleName,
        driverName: event.driverName,
        status: 'en_attente',
        createdAt: DateTime.now(),
        images: event.images ?? [],
      );

      // Soumettre avec IA
      final result = await DeclarationService.submitDeclaration(
        declaration: declaration,
      );

      emit(DeclarationSubmitted(data: result.toJson()));
    } catch (e) {
      emit(DeclarationError(e.toString()));
    }
  }

  void _onReset(
    ResetDeclarationEvent event,
    Emitter<DeclarationState> emit,
  ) {
    emit(const DeclarationInitial());
  }
}