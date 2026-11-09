import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/network/websocket_manager.dart';
import '../../../../../core/utils/constants.dart';
import '../../repository/chat_repository.dart';
import '../../data/chat_message_model.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _repository;
  final WebSocketManager _wsManager;
  StreamSubscription? _wsSubscription;
  String? _currentUserId;
  String? _currentChatUserId;

  ChatBloc({
    ChatRepository? repository,
    WebSocketManager? wsManager,
  })  : _repository = repository ?? sl<ChatRepository>(),
        _wsManager = wsManager ?? sl<WebSocketManager>(),
        super(ChatInitial()) {
    on<LoadMessages>(_onLoadMessages);
    on<LoadConversations>(_onLoadConversations);
    on<SendMessage>(_onSendMessage);
    on<EditMessage>(_onEditMessage);
    on<DeleteMessage>(_onDeleteMessage);
    on<MarkAsRead>(_onMarkAsRead);
    on<LoadMoreMessages>(_onLoadMoreMessages);
    on<ChatRealtimeEvent>(_onRealtimeEvent);

    _setupWebSocketListeners();
  }

  void setCurrentUserId(String userId) {
    _currentUserId = userId;
  }

  void setCurrentChatUserId(String? userId) {
    _currentChatUserId = userId;
  }

  void _setupWebSocketListeners() {
    _wsManager.on(WebSocketEvents.newMessage, _handleNewMessage);
    _wsManager.on(WebSocketEvents.messageUpdated, _handleMessageUpdated);
    _wsManager.on(WebSocketEvents.messageDeleted, _handleMessageDeleted);
    _wsManager.on(WebSocketEvents.messageRead, _handleMessageRead);
    _wsManager.on(WebSocketEvents.userTyping, _handleUserTyping);
    _wsManager.on(WebSocketEvents.userStoppedTyping, _handleUserStoppedTyping);
  }

  void _handleNewMessage(Map<String, dynamic> data) {
    add(ChatRealtimeEvent(data: data));
  }

  void _handleMessageUpdated(Map<String, dynamic> data) {
    add(ChatRealtimeEvent(data: data));
  }

  void _handleMessageDeleted(Map<String, dynamic> data) {
    add(ChatRealtimeEvent(data: data));
  }

  void _handleMessageRead(Map<String, dynamic> data) {
    add(ChatRealtimeEvent(data: data));
  }

  void _handleUserTyping(Map<String, dynamic> data) {
    add(ChatRealtimeEvent(data: data));
  }

  void _handleUserStoppedTyping(Map<String, dynamic> data) {
    add(ChatRealtimeEvent(data: data));
  }

  Future<void> _onLoadMessages(
    LoadMessages event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatLoading());
    try {
      _currentChatUserId = event.userId;
      final response = await _repository.getMessagesWithUser(
        userId: event.userId,
        limit: event.limit,
        offset: event.offset,
      );

      // Mark messages as sent by current user
      final messages = response.messages.map((msg) {
        return msg.copyWith(
          senderId: msg.senderId,
          // The isSentByMe will be determined in UI
        );
      }).toList();

      emit(MessagesLoaded(
        messages: messages,
        otherUserId: event.userId,
        total: response.total,
        hasMore: response.messages.length < response.total,
      ));
    } catch (e) {
      emit(ChatError(message: e.toString()));
    }
  }

  Future<void> _onLoadConversations(
    LoadConversations event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatLoading());
    try {
      final response = await _repository.getConversations(
        limit: event.limit,
        offset: event.offset,
      );

      // Group messages by conversation partner (other user)
      // For each conversation, keep only the latest message
      final Map<String, ChatMessageModel> latestPerConversation = {};

      for (final msg in response.messages) {
        final otherUserId = msg.senderId == _currentUserId ? msg.receiverId : msg.senderId;
        if (otherUserId.isEmpty) continue;

        final existing = latestPerConversation[otherUserId];
        if (existing == null || msg.createdAt.isAfter(existing.createdAt)) {
          latestPerConversation[otherUserId] = msg;
        }
      }

      final conversations = latestPerConversation.values.whereType<ChatMessageModel>().toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      emit(ConversationsLoaded(
        conversations: conversations,
        total: conversations.length,
      ));
    } catch (e) {
      emit(ChatError(message: e.toString()));
    }
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<ChatState> emit,
  ) async {
    try {
      final message = await _repository.sendMessage(
        friendId: event.friendId,
        message: event.message,
      );
      if (message != null) {
        emit(MessageSent(message: message));
        // Reload messages to get the updated list
        add(LoadMessages(userId: event.friendId));
      } else {
        emit(const ChatError(message: 'Failed to send message'));
      }
    } catch (e) {
      emit(ChatError(message: e.toString()));
    }
  }

  Future<void> _onEditMessage(
    EditMessage event,
    Emitter<ChatState> emit,
  ) async {
    try {
      final message = await _repository.updateMessage(
        chatId: event.chatId,
        message: event.message,
      );
      if (message != null) {
        emit(MessageUpdated(message: message));
      } else {
        emit(const ChatError(message: 'Failed to edit message'));
      }
    } catch (e) {
      emit(ChatError(message: e.toString()));
    }
  }

  Future<void> _onDeleteMessage(
    DeleteMessage event,
    Emitter<ChatState> emit,
  ) async {
    try {
      final success = await _repository.deleteMessage(event.chatId);
      if (success) {
        emit(MessageDeleted(chatId: event.chatId));
        // Reload current conversation
        if (_currentChatUserId != null) {
          add(LoadMessages(userId: _currentChatUserId!));
        }
      } else {
        emit(const ChatError(message: 'Failed to delete message'));
      }
    } catch (e) {
      emit(ChatError(message: e.toString()));
    }
  }

  Future<void> _onMarkAsRead(
    MarkAsRead event,
    Emitter<ChatState> emit,
  ) async {
    // Mark messages as read via API if needed
    // For now just update local state
  }

  Future<void> _onLoadMoreMessages(
    LoadMoreMessages event,
    Emitter<ChatState> emit,
  ) async {
    if (state is! MessagesLoaded) return;

    final currentState = state as MessagesLoaded;
    try {
      final response = await _repository.getMessagesWithUser(
        userId: event.userId,
        offset: event.offset,
      );

      final allMessages = [...currentState.messages, ...response.messages];
      emit(MessagesLoaded(
        messages: allMessages,
        otherUserId: event.userId,
        total: response.total,
        hasMore: allMessages.length < response.total,
      ));
    } catch (e) {
      emit(ChatError(message: e.toString()));
    }
  }

  Future<void> _onRealtimeEvent(
    ChatRealtimeEvent event,
    Emitter<ChatState> emit,
  ) async {
    final eventType = event.data['event'] ?? event.data['type'];
    final data = event.data['data'] ?? event.data;

    switch (eventType) {
      case WebSocketEvents.newMessage:
        if (data['receiverId'] == _currentUserId ||
            data['senderId'] == _currentUserId) {
          // Reload current conversation
          if (_currentChatUserId != null) {
            add(LoadMessages(userId: _currentChatUserId!));
          }
          // Also reload conversations list
          add(LoadConversations());
        }
        break;
      case WebSocketEvents.messageUpdated:
        // Handle message update
        break;
      case WebSocketEvents.messageDeleted:
        // Handle message deletion
        break;
      case WebSocketEvents.messageRead:
        // Handle read receipt
        break;
    }
  }

  @override
  Future<void> close() {
    _wsSubscription?.cancel();
    return super.close();
  }
}