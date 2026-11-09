
import 'package:equatable/equatable.dart';

abstract class CardCollabEvent extends Equatable {
  const CardCollabEvent();

  @override
  List<Object?> get props => [];
}

class AddCollaborator extends CardCollabEvent {
  final String cardId;
  final String userId;
  final String role;

  const AddCollaborator({
    required this.cardId,
    required this.userId,
    this.role = 'member',
  });

  @override
  List<Object?> get props => [cardId, userId, role];
}

class RemoveCollaborator extends CardCollabEvent {
  final String collabId;

  const RemoveCollaborator({required this.collabId});

  @override
  List<Object?> get props => [collabId];
}

class UpdateCollaboratorRole extends CardCollabEvent {
  final String collabId;
  final String role;

  const UpdateCollaboratorRole({required this.collabId, required this.role});

  @override
  List<Object?> get props => [collabId, role];
}

class LoadCardCollaborators extends CardCollabEvent {
  final String cardId;

  const LoadCardCollaborators({required this.cardId});

  @override
  List<Object?> get props => [cardId];
}

class LoadUserCollaborations extends CardCollabEvent {
  final int limit;
  final int offset;

  const LoadUserCollaborations({this.limit = 50, this.offset = 0});

  @override
  List<Object?> get props => [limit, offset];
}

class LoadCollaborationDetails extends CardCollabEvent {
  final String collabId;

  const LoadCollaborationDetails({required this.collabId});

  @override
  List<Object?> get props => [collabId];
}

class CardCollabRealtimeEvent extends CardCollabEvent {
  final Map<String, dynamic> data;

  const CardCollabRealtimeEvent({required this.data});

  @override
  List<Object?> get props => [data];
}