
import 'package:equatable/equatable.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class LoadMessages extends ChatEvent {
  final String userId;
  final int limit;
  final int offset;

  const LoadMessages({
    required this.userId,
    this.limit = 50,
    this.offset = 0,
  });

  @override
  List<Object?> get props => [userId, limit, offset];
}

class LoadConversations extends ChatEvent {
  final int limit;
  final int offset;

  const LoadConversations({this.limit = 50, this.offset = 0});

  @override
  List<Object?> get props => [limit, offset];
}

class SendMessage extends ChatEvent {
  final String friendId;
  final String message;

  const SendMessage({required this.friendId, required this.message});

  @override
  List<Object?> get props => [friendId, message];
}

class EditMessage extends ChatEvent {
  final String chatId;
  final String message;

  const EditMessage({required this.chatId, required this.message});

  @override
  List<Object?> get props => [chatId, message];
}

class DeleteMessage extends ChatEvent {
  final String chatId;

  const DeleteMessage({required this.chatId});

  @override
  List<Object?> get props => [chatId];
}

class MarkAsRead extends ChatEvent {
  final String userId;

  const MarkAsRead({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class LoadMoreMessages extends ChatEvent {
  final String userId;
  final int offset;

  const LoadMoreMessages({required this.userId, required this.offset});

  @override
  List<Object?> get props => [userId, offset];
}

class ChatRealtimeEvent extends ChatEvent {
  final Map<String, dynamic> data;

  const ChatRealtimeEvent({required this.data});

  @override
  List<Object?> get props => [data];
}