import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/network/websocket_manager.dart';
import '../../../../../core/utils/constants.dart';
import '../repository/friendship_repository.dart';
import '../../card_collab/bloc/card_collab_bloc.dart';
import '../../card_collab/bloc/card_collab_event.dart';
import 'friendship_event.dart';
import 'friendship_state.dart';

class FriendshipBloc extends Bloc<FriendshipEvent, FriendshipState> {
  final FriendshipRepository _repository;
  final WebSocketManager _wsManager;
  StreamSubscription? _wsSubscription;
  String? _currentUserId;

  FriendshipBloc({
    FriendshipRepository? repository,
    WebSocketManager? wsManager,
  })  : _repository = repository ?? sl<FriendshipRepository>(),
        _wsManager = wsManager ?? sl<WebSocketManager>(),
        super(FriendshipInitial()) {
    on<LoadFriends>(_onLoadFriends);
    on<LoadPendingRequests>(_onLoadPendingRequests);
    on<LoadTeamFriends>(_onLoadTeamFriends);
    on<SendFriendRequest>(_onSendFriendRequest);
    on<AcceptFriendRequest>(_onAcceptFriendRequest);
    on<RejectFriendRequest>(_onRejectFriendRequest);
    on<BlockFriend>(_onBlockFriend);
    on<UnblockFriend>(_onUnblockFriend);
    on<RemoveFriend>(_onRemoveFriend);
    on<SearchUsers>(_onSearchUsers);
    on<InviteFriendToCollaboration>(_onInviteFriendToCollaboration);
    on<FriendshipRealtimeEvent>(_onRealtimeEvent);
    on<AuthStateCleared>(_onAuthStateCleared);

    _setupWebSocketListeners();
  }

  void setCurrentUserId(String userId) {
    _currentUserId = userId;
    // Auto-load friends when userId is set
    if (!isClosed) {
      add(const LoadFriends());
      add(const LoadPendingRequests());
    }
  }

  void _setupWebSocketListeners() {
    _wsManager.on(WebSocketEvents.friendRequestReceived, _handleFriendRequestReceived);
    _wsManager.on(WebSocketEvents.friendRequestAccepted, _handleFriendRequestAccepted);
    _wsManager.on(WebSocketEvents.friendRequestRejected, _handleFriendRequestRejected);
    _wsManager.on(WebSocketEvents.friendBlocked, _handleFriendBlocked);
    _wsManager.on(WebSocketEvents.friendUnblocked, _handleFriendUnblocked);
    _wsManager.on(WebSocketEvents.friendRemoved, _handleFriendRemoved);
    _wsManager.on(WebSocketEvents.friendStatusChanged, _handleFriendStatusChanged);
  }

  void _handleFriendRequestReceived(Map<String, dynamic> data) {
    add(FriendshipRealtimeEvent(data: data));
  }

  void _handleFriendRequestAccepted(Map<String, dynamic> data) {
    add(FriendshipRealtimeEvent(data: data));
  }

  void _handleFriendRequestRejected(Map<String, dynamic> data) {
    add(FriendshipRealtimeEvent(data: data));
  }

  void _handleFriendBlocked(Map<String, dynamic> data) {
    add(FriendshipRealtimeEvent(data: data));
  }

  void _handleFriendUnblocked(Map<String, dynamic> data) {
    add(FriendshipRealtimeEvent(data: data));
  }

  void _handleFriendRemoved(Map<String, dynamic> data) {
    add(FriendshipRealtimeEvent(data: data));
  }

  void _handleFriendStatusChanged(Map<String, dynamic> data) {
    add(FriendshipRealtimeEvent(data: data));
  }

  Future<void> _onLoadFriends(
    LoadFriends event,
    Emitter<FriendshipState> emit,
  ) async {
    if (_currentUserId == null) {
      emit(const FriendshipError(message: 'User not authenticated'));
      return;
    }
    emit(FriendshipLoading());
    try {
      final response = await _repository.getFriends(
        userId: _currentUserId!,
        limit: event.limit,
        offset: event.offset,
      );
      emit(FriendsLoaded(
        friends: response.friendships,
        total: response.total,
        hasMore: response.friendships.length < response.total,
      ));
    } catch (e) {
      emit(FriendshipError(message: e.toString()));
    }
  }

  Future<void> _onLoadPendingRequests(
    LoadPendingRequests event,
    Emitter<FriendshipState> emit,
  ) async {
    if (_currentUserId == null) {
      emit(const FriendshipError(message: 'User not authenticated'));
      return;
    }
    emit(FriendshipLoading());
    try {
      final response = await _repository.getPendingRequests(
        userId: _currentUserId!,
        limit: event.limit,
        offset: event.offset,
      );

      emit(PendingRequestsLoaded(
        incomingRequests: response.incomingRequests,
        outgoingRequests: response.outgoingRequests,
        total: response.total,
      ));
    } catch (e) {
      emit(FriendshipError(message: e.toString()));
    }
  }

  Future<void> _onSendFriendRequest(
    SendFriendRequest event,
    Emitter<FriendshipState> emit,
  ) async {
    try {
      final friendship = await _repository.sendFriendRequest(event.friendId);
      if (friendship != null) {
        emit(FriendActionSuccess(
          action: 'send_request',
          friendship: friendship,
          message: 'Friend request sent',
        ));
        // Reload pending requests
        add(LoadPendingRequests());
      } else {
        emit(const FriendshipError(message: 'Failed to send friend request'));
      }
    } catch (e) {
      // Handle duplicate friend request gracefully
      final errorMessage = e.toString();
      if (errorMessage.contains('Friend request already exists') ||
          errorMessage.contains('400')) {
        emit(const FriendActionSuccess(
          action: 'send_request',
          friendship: null,
          message: 'Friend request already sent',
        ));
        add(LoadPendingRequests());
      } else {
        emit(FriendshipError(message: errorMessage));
      }
    }
  }

  Future<void> _onAcceptFriendRequest(
    AcceptFriendRequest event,
    Emitter<FriendshipState> emit,
  ) async {
    try {
      final friendship = await _repository.acceptFriendRequest(event.fsId);
      if (friendship != null) {
        emit(FriendActionSuccess(
          action: 'accept',
          friendship: friendship,
          message: 'Friend request accepted',
        ));
        add(LoadFriends());
        add(LoadPendingRequests());
      } else {
        emit(const FriendshipError(message: 'Failed to accept friend request'));
      }
    } catch (e) {
      emit(FriendshipError(message: e.toString()));
    }
  }

  Future<void> _onRejectFriendRequest(
    RejectFriendRequest event,
    Emitter<FriendshipState> emit,
  ) async {
    try {
      final friendship = await _repository.rejectFriendRequest(event.fsId);
      if (friendship != null) {
        emit(FriendActionSuccess(
          action: 'reject',
          friendship: friendship,
          message: 'Friend request rejected',
        ));
        add(LoadPendingRequests());
      } else {
        emit(const FriendshipError(message: 'Failed to reject friend request'));
      }
    } catch (e) {
      emit(FriendshipError(message: e.toString()));
    }
  }

  Future<void> _onBlockFriend(
    BlockFriend event,
    Emitter<FriendshipState> emit,
  ) async {
    try {
      final friendship = await _repository.blockFriend(event.fsId);
      if (friendship != null) {
        emit(FriendActionSuccess(
          action: 'block',
          friendship: friendship,
          message: 'User blocked',
        ));
        add(LoadFriends());
      } else {
        emit(const FriendshipError(message: 'Failed to block user'));
      }
    } catch (e) {
      emit(FriendshipError(message: e.toString()));
    }
  }

  Future<void> _onUnblockFriend(
    UnblockFriend event,
    Emitter<FriendshipState> emit,
  ) async {
    try {
      final friendship = await _repository.unblockFriend(event.fsId);
      if (friendship != null) {
        emit(FriendActionSuccess(
          action: 'unblock',
          friendship: friendship,
          message: 'User unblocked',
        ));
        add(LoadFriends());
      } else {
        emit(const FriendshipError(message: 'Failed to unblock user'));
      }
    } catch (e) {
      emit(FriendshipError(message: e.toString()));
    }
  }

  Future<void> _onRemoveFriend(
    RemoveFriend event,
    Emitter<FriendshipState> emit,
  ) async {
    try {
      final success = await _repository.removeFriendship(event.fsId);
      if (success) {
        emit(const FriendActionSuccess(
          action: 'remove',
          friendship: null,
          message: 'Friend removed',
        ));
        add(LoadFriends());
      } else {
        emit(const FriendshipError(message: 'Failed to remove friend'));
      }
    } catch (e) {
      emit(FriendshipError(message: e.toString()));
    }
  }

  Future<void> _onSearchUsers(
    SearchUsers event,
    Emitter<FriendshipState> emit,
  ) async {
    if (event.email.isEmpty) {
      emit(const UsersSearchResult(users: []));
      return;
    }

    try {
      final users = await _repository.searchUsers(event.email);
      emit(UsersSearchResult(users: users));
    } catch (e) {
      emit(FriendshipError(message: e.toString()));
    }
  }

  Future<void> _onRealtimeEvent(
    FriendshipRealtimeEvent event,
    Emitter<FriendshipState> emit,
  ) async {
    // Handle real-time events - reload data
    final eventType = event.data['event'] ?? event.data['type'];
    switch (eventType) {
      case WebSocketEvents.friendRequestReceived:
      case WebSocketEvents.friendRequestAccepted:
      case WebSocketEvents.friendRequestRejected:
        add(LoadPendingRequests());
        add(LoadFriends());
        break;
      case WebSocketEvents.friendBlocked:
      case WebSocketEvents.friendUnblocked:
      case WebSocketEvents.friendRemoved:
        add(LoadFriends());
        break;
      case WebSocketEvents.friendStatusChanged:
        // Update specific friend status in current list
        break;
    }
  }

  Future<void> _onLoadTeamFriends(
    LoadTeamFriends event,
    Emitter<FriendshipState> emit,
  ) async {
    if (_currentUserId == null) {
      emit(const FriendshipError(message: 'User not authenticated'));
      return;
    }
    emit(FriendshipLoading());
    try {
      final response = await _repository.getTeamFriends(
        userId: _currentUserId!,
        limit: event.limit,
        offset: event.offset,
      );

      emit(TeamFriendsLoaded(
        friends: response.friendships,
        total: response.total,
        hasMore: response.friendships.length < response.total,
      ));
    } catch (e) {
      emit(FriendshipError(message: e.toString()));
    }
  }

  Future<void> _onInviteFriendToCollaboration(
    InviteFriendToCollaboration event,
    Emitter<FriendshipState> emit,
  ) async {
    try {
      // Delegate to CardCollabBloc to actually add the collaborator
      sl<CardCollabBloc>().add(
        AddCollaborator(
          cardId: event.cardId,
          userId: event.friendId,
          role: 'member',
        ),
      );
      emit(FriendActionSuccess(
        action: 'invite_collab',
        friendship: null,
        message: 'Undangan kolaborasi dikirim',
      ));
    } catch (e) {
      emit(FriendshipError(message: e.toString()));
    }
  }

  Future<void> _onAuthStateCleared(
    AuthStateCleared event,
    Emitter<FriendshipState> emit,
  ) async {
    emit(FriendshipInitial());
  }

  @override
  Future<void> close() {
    _wsSubscription?.cancel();
    return super.close();
  }
}