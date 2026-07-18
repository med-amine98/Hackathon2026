part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Check persisted token on app startup.
class AuthCheckRequestedEvent extends AuthEvent {
  const AuthCheckRequestedEvent();
}

/// User submits login form.
class LoginSubmittedEvent extends AuthEvent {
  final String email;
  final String password;

  const LoginSubmittedEvent({
    required this.email, 
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

/// User submits registration form.
class RegisterSubmittedEvent extends AuthEvent {
  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final String? phone;

  const RegisterSubmittedEvent({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    this.phone,
  });

  @override
  List<Object?> get props => [email, password, firstName, lastName, phone];
}

/// User logs out.
class LogoutRequestedEvent extends AuthEvent {
  const LogoutRequestedEvent();
}