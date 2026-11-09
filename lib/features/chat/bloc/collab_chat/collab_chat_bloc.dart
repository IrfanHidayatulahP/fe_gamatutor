import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/network/websocket_manager.dart';
import '../../../../../core/utils/constants.dart';
import '../../repository/chat_repository.dart';
import 'collab_chat_event.dart';
import 'collab_chat_state.dart';

class CollabChatBloc extends Bloc<CollabChatEvent, CollabChatState> {
  final ChatRepository _repository;  // Reuse chat repository
  final WebSocketManager _wsManager;
  StreamSubscription? _wsSubscription;
  String? _currentCollabId;

  CollabChatBloc({
    ChatRepository? repository,
    WebSocketManager? wsManager,
  })  : _repository = repository ?? sl<ChatRepository>(),
        _wsManager = wsManager ?? sl<WebSocketManager>(),
        super(CollabChatInitial()) {
    on<LoadCollabMessages>(_onLoadCollabMessages);
    on<SendCollabMessage>(_onSendCollabMessage);
    on<EditCollabMessage>(_onEditCollabMessage);
    on<DeleteCollabMessage>(_onDeleteCollabMessage);
    on<ListenCollabMessages>(_onListenCollabMessages);
    on<CollabChatRealtimeEvent>(_onRealtimeEvent);

    _setupWebSocketListeners();
  }

  void setCurrentCollabId(String? collabId) {
    _currentCollabId = collabId;
  }

  void _setupWebSocketListeners() {
    _wsManager.on(WebSocketEvents.collabNewMessage, _handleNewMessage);
    _wsManager.on(WebSocketEvents.mentionInCollab, _handleMentionInCollab);
  }

  void _handleNewMessage(Map<String, dynamic> data) {
    add(CollabChatRealtimeEvent(data: data));
  }

  void _handleMentionInCollab(Map<String, dynamic> data) {
    add(CollabChatRealtimeEvent(data: data));
  }

  Future<void> _onLoadCollabMessages(
    LoadCollabMessages event,
    Emitter<CollabChatState> emit,
  ) async {
    emit(CollabChatLoading());
    try {
      _currentCollabId = event.collabId;
      // Using chat repository but with collab endpoint
      final response = await _repository.getMessagesWithUser(
        userId: event.collabId, // This would need a different method in repository
        limit: event.limit,
        offset: event.offset,
      );
      // Note: This needs a dedicated method for collab chat in repository
      emit(CollabMessagesLoaded(
        messages: response.messages,
        collabId: event.collabId,
        total: response.total,
        hasMore: response.messages.length < response.total,
      ));
    } catch (e) {
      emit(CollabChatError(message: e.toString()));
    }
  }

  Future<void> _onSendCollabMessage(
    SendCollabMessage event,
    Emitter<CollabChatState> emit,
  ) async {
    try {
      // This needs a dedicated method in repository for collab chat
      // For now using sendMessage which uses /chat endpoint
      final message = await _repository.sendMessage(
        friendId: event.collabId, // This is incorrect - needs fix in repository
        message: event.message,
      );
      if (message != null) {
        emit(CollabMessageSent(message: message));
        add(LoadCollabMessages(collabId: event.collabId));
      } else {
        emit(const CollabChatError(message: 'Failed to send message'));
      }
    } catch (e) {
      emit(CollabChatError(message: e.toString()));
    }
  }

  Future<void> _onEditCollabMessage(
    EditCollabMessage event,
    Emitter<CollabChatState> emit,
  ) async {
    try {
      final message = await _repository.updateMessage(
        chatId: event.messageId,
        message: event.message,
      );
      if (message != null) {
        emit(CollabMessageUpdated(message: message));
      } else {
        emit(const CollabChatError(message: 'Failed to edit message'));
      }
    } catch (e) {
      emit(CollabChatError(message: e.toString()));
    }
  }

  Future<void> _onDeleteCollabMessage(
    DeleteCollabMessage event,
    Emitter<CollabChatState> emit,
  ) async {
    try {
      final success = await _repository.deleteMessage(event.messageId);
      if (success) {
        emit(CollabMessageDeleted(messageId: event.messageId));
        if (_currentCollabId != null) {
          add(LoadCollabMessages(collabId: _currentCollabId!));
        }
      } else {
        emit(const CollabChatError(message: 'Failed to delete message'));
      }
    } catch (e) {
      emit(CollabChatError(message: e.toString()));
    }
  }

  Future<void> _onListenCollabMessages(
    ListenCollabMessages event,
    Emitter<CollabChatState> emit,
  ) async {
    _currentCollabId = event.collabId;
    add(LoadCollabMessages(collabId: event.collabId));
  }

  Future<void> _onRealtimeEvent(
    CollabChatRealtimeEvent event,
    Emitter<CollabChatState> emit,
  ) async {
    final eventType = event.data['event'] ?? event.data['type'];
    final data = event.data['data'] ?? event.data;

    switch (eventType) {
      case WebSocketEvents.collabNewMessage:
        if (data['collabId'] == _currentCollabId) {
          add(LoadCollabMessages(collabId: _currentCollabId!));
        }
        break;
      case WebSocketEvents.mentionInCollab:
        // Handle mention notification
        break;
    }
  }

  @override
  Future<void> close() {
    _wsSubscription?.cancel();
    return super.close();
  }
}