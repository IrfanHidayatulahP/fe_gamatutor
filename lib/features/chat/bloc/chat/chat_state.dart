
import 'package:equatable/equatable.dart';

import '../../data/chat_message_model.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class MessagesLoaded extends ChatState {
  final List<ChatMessageModel> messages;
  final String otherUserId;
  final int total;
  final bool hasMore;

  const MessagesLoaded({
    required this.messages,
    required this.otherUserId,
    required this.total,
    required this.hasMore,
  });

  @override
  List<Object?> get props => [messages, otherUserId, total, hasMore];
}

class ConversationsLoaded extends ChatState {
  final List<ChatMessageModel> conversations; // Last message per conversation
  final int total;

  const ConversationsLoaded({required this.conversations, required this.total});

  @override
  List<Object?> get props => [conversations, total];
}

class MessageSent extends ChatState {
  final ChatMessageModel message;

  const MessageSent({required this.message});

  @override
  List<Object?> get props => [message];
}

class MessageUpdated extends ChatState {
  final ChatMessageModel message;

  const MessageUpdated({required this.message});

  @override
  List<Object?> get props => [message];
}

class MessageDeleted extends ChatState {
  final String chatId;

  const MessageDeleted({required this.chatId});

  @override
  List<Object?> get props => [chatId];
}

class ChatError extends ChatState {
  final String message;

  const ChatError({required this.message});

  @override
  List<Object?> get props => [message];
}