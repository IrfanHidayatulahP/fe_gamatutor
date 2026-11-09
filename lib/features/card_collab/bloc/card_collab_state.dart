
import 'package:equatable/equatable.dart';

import '../data/card_collab_model.dart';

abstract class CardCollabState extends Equatable {
  const CardCollabState();

  @override
  List<Object?> get props => [];
}

class CardCollabInitial extends CardCollabState {}

class CardCollabLoading extends CardCollabState {}

class CollaboratorsLoaded extends CardCollabState {
  final List<CardCollaborationModel> collaborators;
  final int total;

  const CollaboratorsLoaded({required this.collaborators, required this.total});

  @override
  List<Object?> get props => [collaborators, total];
}

class UserCollaborationsLoaded extends CardCollabState {
  final List<CardCollaborationModel> collaborations;
  final int total;
  final bool hasMore;

  const UserCollaborationsLoaded({
    required this.collaborations,
    required this.total,
    required this.hasMore,
  });

  @override
  List<Object?> get props => [collaborations, total, hasMore];
}

class CollaborationDetailsLoaded extends CardCollabState {
  final CardCollaborationModel collaboration;

  const CollaborationDetailsLoaded({required this.collaboration});

  @override
  List<Object?> get props => [collaboration];
}

class CollaborationActionSuccess extends CardCollabState {
  final String action;
  final CardCollaborationModel? collaboration;
  final String message;

  const CollaborationActionSuccess({
    required this.action,
    this.collaboration,
    required this.message,
  });

  @override
  List<Object?> get props => [action, collaboration, message];
}

class CardCollabError extends CardCollabState {
  final String message;

  const CardCollabError({required this.message});

  @override
  List<Object?> get props => [message];
}