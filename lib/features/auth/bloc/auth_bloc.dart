import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/messaging/fcm_service.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/websocket_manager.dart';
import '../../../../core/storage/token_storage.dart';
import '../../chat/bloc/chat/chat_bloc.dart';
import '../../calls/bloc/call/call_bloc.dart';
import '../../calls/bloc/group_call/group_call_bloc.dart';
import '../../friendship/bloc/friendship_bloc.dart';
import '../../notification/bloc/notification_bloc.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;
  final FCMService _fcmService;
  final WebSocketManager _wsManager;
  final ChatBloc _chatBloc;
  final CallBloc _callBloc;
  final GroupCallBloc _groupCallBloc;
  final FriendshipBloc _friendshipBloc;
  final NotificationBloc _notificationBloc;

  AuthBloc({
    ApiClient? apiClient,
    TokenStorage? tokenStorage,
    FCMService? fcmService,
    WebSocketManager? wsManager,
    ChatBloc? chatBloc,
    CallBloc? callBloc,
    GroupCallBloc? groupCallBloc,
    FriendshipBloc? friendshipBloc,
    NotificationBloc? notificationBloc,
  }) : _apiClient = apiClient ?? sl<ApiClient>(),
       _tokenStorage = tokenStorage ?? sl<TokenStorage>(),
       _fcmService = fcmService ?? sl<FCMService>(),
       _wsManager = wsManager ?? sl<WebSocketManager>(),
       _chatBloc = chatBloc ?? sl<ChatBloc>(),
       _callBloc = callBloc ?? sl<CallBloc>(),
       _groupCallBloc = groupCallBloc ?? sl<GroupCallBloc>(),
       _friendshipBloc = friendshipBloc ?? sl<FriendshipBloc>(),
       _notificationBloc = notificationBloc ?? sl<NotificationBloc>(),
       super(AuthInitial()) {
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthGetMeRequested>(_onGetMeRequested);
    on<AuthRefreshTokenRequested>(_onRefreshTokenRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthCheckStatusRequested>(_onCheckStatusRequested);
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'email': event.email, 'password': event.password},
      );

      if (response.statusCode == 200 && response.data != null) {
        final authResponse = AuthResponse.fromJson(response.data!);
        await _tokenStorage.saveAccessToken(authResponse.tokens.accessToken);
        if (authResponse.tokens.refreshToken != null) {
          await _tokenStorage.saveRefreshToken(
            authResponse.tokens.refreshToken!,
          );
        }
        emit(
          AuthAuthenticated(
            user: authResponse.user,
            accessToken: authResponse.tokens.accessToken,
          ),
        );

        // Connect WebSocket and set current user ID for real-time messaging
        await _wsManager.connect();
        _chatBloc.setCurrentUserId(authResponse.user.userId);
        _callBloc.setCurrentUserId(authResponse.user.userId);
        _friendshipBloc.setCurrentUserId(authResponse.user.userId);
        _groupCallBloc.setCurrentUserId(authResponse.user.userId);
        _notificationBloc.setCurrentUserId(authResponse.user.userId);

        // Register FCM token after successful login
        await _fcmService.registerTokenIfLoggedIn();
      } else {
        emit(AuthError(message: response.data?['message'] ?? 'Login failed'));
      }
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/auth/register',
        data: {
          'email': event.email,
          'password': event.password,
          'firstName': event.firstName,
          'lastName': event.lastName,
          if (event.username != null) 'username': event.username,
        },
      );

      if (response.statusCode == 201 && response.data != null) {
        final authResponse = AuthResponse.fromJson(response.data!);
        await _tokenStorage.saveAccessToken(authResponse.tokens.accessToken);
        if (authResponse.tokens.refreshToken != null) {
          await _tokenStorage.saveRefreshToken(
            authResponse.tokens.refreshToken!,
          );
        }
        emit(
          AuthAuthenticated(
            user: authResponse.user,
            accessToken: authResponse.tokens.accessToken,
          ),
        );

        // Connect WebSocket and set current user ID for real-time messaging
        await _wsManager.connect();
        _chatBloc.setCurrentUserId(authResponse.user.userId);
        _callBloc.setCurrentUserId(authResponse.user.userId);
        _friendshipBloc.setCurrentUserId(authResponse.user.userId);
        _groupCallBloc.setCurrentUserId(authResponse.user.userId);
        _notificationBloc.setCurrentUserId(authResponse.user.userId);

        // Register FCM token after successful registration
        await _fcmService.registerTokenIfLoggedIn();
      } else {
        emit(
          AuthError(
            message: response.data?['message'] ?? 'Registration failed',
          ),
        );
      }
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onGetMeRequested(
    AuthGetMeRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>('/auth/me');

      if (response.statusCode == 200 && response.data != null) {
        // ─── FIX: UNWRAP 'user' KEY ───
        final rawData = response.data!;
        final Map<String, dynamic> userJson =
            (rawData['user'] as Map<String, dynamic>?) ?? rawData;
        final user = UserModel.fromJson(userJson);

        final token = await _tokenStorage.getAccessToken();
        if (token != null) {
          emit(AuthAuthenticated(user: user, accessToken: token));

          await _wsManager.connect();
          _chatBloc.setCurrentUserId(user.userId);
          _callBloc.setCurrentUserId(user.userId);
          _friendshipBloc.setCurrentUserId(user.userId);
          _groupCallBloc.setCurrentUserId(user.userId);
          _notificationBloc.setCurrentUserId(user.userId);

          await _fcmService.registerTokenIfLoggedIn();
        }
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onRefreshTokenRequested(
    AuthRefreshTokenRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/auth/refresh',
      );

      if (response.statusCode == 200 && response.data != null) {
        final authResponse = AuthResponse.fromJson(response.data!);
        await _tokenStorage.saveAccessToken(authResponse.tokens.accessToken);
        emit(AuthTokenRefreshed(newToken: authResponse.tokens.accessToken));
      } else {
        await _tokenStorage.clear();
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      await _tokenStorage.clear();
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _apiClient.post('/auth/logout');
      // Unregister FCM token on logout
      await _fcmService.unregisterToken();
      // Disconnect WebSocket and clear user IDs
      await _wsManager.disconnect();
      _chatBloc.setCurrentUserId('');
      _callBloc.setCurrentUserId('');
      _friendshipBloc.setCurrentUserId('');
      _groupCallBloc.setCurrentUserId('');
      _notificationBloc.setCurrentUserId('');
    } catch (_) {
      // Ignore logout API errors
      await _wsManager.disconnect();
      _chatBloc.setCurrentUserId('');
      _callBloc.setCurrentUserId('');
      _friendshipBloc.setCurrentUserId('');
      _groupCallBloc.setCurrentUserId('');
      _notificationBloc.setCurrentUserId('');
    } finally {
      await _tokenStorage.clear();
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onCheckStatusRequested(
    AuthCheckStatusRequested event,
    Emitter<AuthState> emit,
  ) async {
    final hasToken = await _tokenStorage.hasValidToken();
    if (hasToken) {
      add(AuthGetMeRequested());
    } else {
      emit(AuthUnauthenticated());
    }
  }
}
