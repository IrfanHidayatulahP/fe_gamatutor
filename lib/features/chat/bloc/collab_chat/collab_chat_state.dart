
import 'package:equatable/equatable.dart';

import '../../data/chat_message_model.dart';

abstract class CollabChatState extends Equatable {
  const CollabChatState();

  @override
  List<Object?> get props => [];
}

class CollabChatInitial extends CollabChatState {}

class CollabChatLoading extends CollabChatState {}

class CollabMessagesLoaded extends CollabChatState {
  final List<ChatMessageModel> messages;
  final String collabId;
  final int total;
  final bool hasMore;

  const CollabMessagesLoaded({
    required this.messages,
    required this.collabId,
    required this.total,
    required this.hasMore,
  });

  @override
  List<Object?> get props => [messages, collabId, total, hasMore];
}

class CollabMessageSent extends CollabChatState {
  final ChatMessageModel message;

  const CollabMessageSent({required this.message});

  @override
  List<Object?> get props => [message];
}

class CollabMessageUpdated extends CollabChatState {
  final ChatMessageModel message;

  const CollabMessageUpdated({required this.message});

  @override
  List<Object?> get props => [message];
}

class CollabMessageDeleted extends CollabChatState {
  final String messageId;

  const CollabMessageDeleted({required this.messageId});

  @override
  List<Object?> get props => [messageId];
}

class CollabChatError extends CollabChatState {
  final String message;

  const CollabChatError({required this.message});

  @override
  List<Object?> get props => [message];
}