import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/api_client.dart';
import '../network/websocket_manager.dart';
import '../storage/token_storage.dart';
import '../messaging/fcm_service.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/board/bloc/board_bloc.dart';
import '../../features/board/bloc/collaborative_tasks_bloc.dart';
import '../../features/board/repository/board_repository.dart';
import '../../features/board/repository/collaborative_tasks_repository.dart';
import '../../features/chat/bloc/chat/chat_bloc.dart';
import '../../features/chat/bloc/collab_chat/collab_chat_bloc.dart';
import '../../features/calls/bloc/call/call_bloc.dart';
import '../../features/calls/bloc/group_call/group_call_bloc.dart';
import '../../features/calls/bloc/livekit/call_bloc.dart' as livekit_bloc;
import '../../features/friendship/bloc/friendship_bloc.dart';
import '../../features/notification/bloc/notification_bloc.dart';
import '../../features/card_collab/bloc/card_collab_bloc.dart';
import '../../features/chat/repository/chat_repository.dart';
import '../../features/friendship/repository/friendship_repository.dart';
import '../../features/calls/repository/call_repository.dart';
import '../../features/calls/repository/group_call_repository.dart';
import '../../features/calls/data/webrtc_service.dart';
import '../../features/calls/data/group_call_webrtc_service.dart';
import '../../features/card_collab/repository/card_collab_repository.dart';
import '../../features/notification/repository/notification_repository.dart';
// LiveKit Audio Call (new)
import '../../features/calls/repository/livekit_audio_service.dart' as livekit;
import '../../features/calls/repository/call_livekit_repository.dart';
import '../../features/calls/repository/group_call_livekit_repository.dart';

final GetIt sl = GetIt.instance;

Future<void> initDependencies() async {
  // Core
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);

  sl.registerLazySingleton<TokenStorage>(
    () => TokenStorage(sl<SharedPreferences>()),
  );

  sl.registerLazySingleton<ApiClient>(
    () => ApiClient(sl<TokenStorage>()),
  );

  sl.registerLazySingleton<WebSocketManager>(
    () => WebSocketManager(sl<TokenStorage>()),
  );

  sl.registerLazySingleton<FCMService>(
    () => FCMService(sl<TokenStorage>(), sl<ApiClient>()),
  );

  // WebRTC Services
  sl.registerLazySingleton<WebRTCService>(
    () => WebRTCService(sl<WebSocketManager>()),
  );
  sl.registerLazySingleton<GroupCallWebRTCService>(
    () => GroupCallWebRTCService(sl<WebSocketManager>()),
  );

  // LiveKit Audio Call Services
  sl.registerLazySingleton<livekit.LiveKitAudioService>(
    () => livekit.LiveKitAudioService(),
  );
  sl.registerFactory<CallLiveKitRepository>(
    () => CallLiveKitRepository(apiClient: sl<ApiClient>()),
  );
  sl.registerFactory<GroupCallLiveKitRepository>(
    () => GroupCallLiveKitRepository(apiClient: sl<ApiClient>()),
  );
  sl.registerLazySingleton<livekit_bloc.CallBloc>(
    () => livekit_bloc.CallBloc(
      liveKitService: sl<livekit.LiveKitAudioService>(),
      callRepository: sl<CallLiveKitRepository>(),
      groupCallRepository: sl<GroupCallLiveKitRepository>(),
      wsManager: sl<WebSocketManager>(),
    ),
  );

  // Auth
  sl.registerLazySingleton<AuthBloc>(
    () => AuthBloc(
      apiClient: sl<ApiClient>(),
      tokenStorage: sl<TokenStorage>(),
      fcmService: sl<FCMService>(),
      wsManager: sl<WebSocketManager>(),
      chatBloc: sl<ChatBloc>(),
      callBloc: sl<CallBloc>(),
      groupCallBloc: sl<GroupCallBloc>(),
      friendshipBloc: sl<FriendshipBloc>(),
      notificationBloc: sl<NotificationBloc>(),
    ),
  );

  // Board
  sl.registerLazySingleton<BoardRepository>(
    () => BoardRepository(apiClient: sl<ApiClient>()),
  );
  sl.registerFactory<BoardBloc>(
    () => BoardBloc(repository: sl<BoardRepository>()),
  );

  // Collaborative Tasks
  sl.registerLazySingleton<CollaborativeTasksRepository>(
    () => CollaborativeTasksRepository(apiClient: sl<ApiClient>()),
  );
  sl.registerFactory<CollaborativeTasksBloc>(
    () => CollaborativeTasksBloc(repository: sl<CollaborativeTasksRepository>()),
  );

  // Chat Repositories
  sl.registerLazySingleton<ChatRepository>(
    () => ChatRepository(apiClient: sl<ApiClient>()),
  );
  sl.registerLazySingleton<FriendshipRepository>(
    () => FriendshipRepository(apiClient: sl<ApiClient>()),
  );

  // Calls Repositories (WebRTC)
  sl.registerLazySingleton<CallRepository>(
    () => CallRepository(apiClient: sl<ApiClient>()),
  );
  sl.registerLazySingleton<GroupCallRepository>(
    () => GroupCallRepository(apiClient: sl<ApiClient>()),
  );

  // Card Collab Repository
  sl.registerLazySingleton<CardCollabRepository>(
    () => CardCollabRepository(apiClient: sl<ApiClient>()),
  );

  // Notification Repository
  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepository(apiClient: sl<ApiClient>()),
  );

  // Chat BLOCs
  sl.registerLazySingleton<FriendshipBloc>(
    () => FriendshipBloc(
      repository: sl<FriendshipRepository>(),
      wsManager: sl<WebSocketManager>(),
    ),
  );
  sl.registerLazySingleton<ChatBloc>(
    () => ChatBloc(
      repository: sl<ChatRepository>(),
      wsManager: sl<WebSocketManager>(),
    ),
  );

  // WebRTC Call BLOCs
  sl.registerLazySingleton<CallBloc>(
    () => CallBloc(
      repository: sl<CallRepository>(),
      webRTCService: sl<WebRTCService>(),
      wsManager: sl<WebSocketManager>(),
    ),
  );
  sl.registerLazySingleton<GroupCallBloc>(
    () => GroupCallBloc(
      repository: sl<GroupCallRepository>(),
      webRTCService: sl<GroupCallWebRTCService>(),
      wsManager: sl<WebSocketManager>(),
    ),
  );

  // Card Collab BLOC
  sl.registerLazySingleton<CardCollabBloc>(
    () => CardCollabBloc(
      repository: sl<CardCollabRepository>(),
      wsManager: sl<WebSocketManager>(),
    ),
  );

  // Collab Chat BLOC
  sl.registerLazySingleton<CollabChatBloc>(
    () => CollabChatBloc(
      repository: sl<ChatRepository>(),
      wsManager: sl<WebSocketManager>(),
    ),
  );

  // Notification BLOC
  sl.registerLazySingleton<NotificationBloc>(
    () => NotificationBloc(
      repository: sl<NotificationRepository>(),
      wsManager: sl<WebSocketManager>(),
    ),
  );
}