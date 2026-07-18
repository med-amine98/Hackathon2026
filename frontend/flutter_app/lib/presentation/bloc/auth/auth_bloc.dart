// lib/presentation/bloc/auth/auth_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ai_insurance_advisor/data/repositories/auth_repository.dart';
import 'package:ai_insurance_advisor/data/models/user.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc(this._authRepository) : super(const AuthInitial()) {
    on<AuthCheckRequestedEvent>(_onAuthCheckRequested);
    on<LoginSubmittedEvent>(_onLoginSubmitted);
    on<RegisterSubmittedEvent>(_onRegisterSubmitted);
    on<LogoutRequestedEvent>(_onLogoutRequested);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequestedEvent event,
    Emitter<AuthState> emit,
  ) async {
    final isLoggedIn = await _authRepository.isLoggedIn;
    if (isLoggedIn) {
      try {
        // ✅ Essayer de récupérer l'utilisateur stocké
        final storedUser = await _authRepository.getStoredUser();
        if (storedUser != null) {
          emit(AuthAuthenticated(storedUser));
          return;
        }
        
        // Fallback: récupérer depuis l'API
        final user = await _authRepository.getCurrentUser();
        emit(AuthAuthenticated(user));
      } catch (e) {
        emit(const AuthUnauthenticated());
      }
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onLoginSubmitted(
    LoginSubmittedEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _authRepository.login(
        event.email,
        event.password,
      );
      print('✅ User logged in: ${user.fullName}');
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError('Identifiants incorrects. Vérifiez votre email et mot de passe.'));
    }
  }

  Future<void> _onRegisterSubmitted(
    RegisterSubmittedEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _authRepository.register(
        email: event.email,
        password: event.password,
        firstName: event.firstName,
        lastName: event.lastName,
        phone: event.phone,
      );
      print('✅ User registered: ${user.fullName}');
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError('Inscription échouée. Cet email est peut-être déjà utilisé.'));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequestedEvent event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.logout();
    emit(const AuthUnauthenticated());
  }
}