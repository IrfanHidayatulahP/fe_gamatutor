
import 'package:equatable/equatable.dart';

abstract class CollabChatEvent extends Equatable {
  const CollabChatEvent();

  @override
  List<Object?> get props => [];
}

class LoadCollabMessages extends CollabChatEvent {
  final String collabId;
  final int limit;
  final int offset;

  const LoadCollabMessages({
    required this.collabId,
    this.limit = 50,
    this.offset = 0,
  });

  @override
  List<Object?> get props => [collabId, limit, offset];
}

class SendCollabMessage extends CollabChatEvent {
  final String collabId;
  final String message;

  const SendCollabMessage({required this.collabId, required this.message});

  @override
  List<Object?> get props => [collabId, message];
}

class EditCollabMessage extends CollabChatEvent {
  final String messageId;
  final String message;

  const EditCollabMessage({required this.messageId, required this.message});

  @override
  List<Object?> get props => [messageId, message];
}

class DeleteCollabMessage extends CollabChatEvent {
  final String messageId;

  const DeleteCollabMessage({required this.messageId});

  @override
  List<Object?> get props => [messageId];
}

class ListenCollabMessages extends CollabChatEvent {
  final String collabId;

  const ListenCollabMessages({required this.collabId});

  @override
  List<Object?> get props => [collabId];
}

class CollabChatRealtimeEvent extends CollabChatEvent {
  final Map<String, dynamic> data;

  const CollabChatRealtimeEvent({required this.data});

  @override
  List<Object?> get props => [data];
}