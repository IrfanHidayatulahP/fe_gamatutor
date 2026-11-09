import 'package:equatable/equatable.dart';

import '../../../../core/models/user_model.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserModel user;
  final String accessToken;

  const AuthAuthenticated({required this.user, required this.accessToken});

  @override
  List<Object?> get props => [user, accessToken];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object?> get props => [message];
}

class AuthTokenRefreshed extends AuthState {
  final String newToken;

  const AuthTokenRefreshed({required this.newToken});

  @override
  List<Object?> get props => [newToken];
}