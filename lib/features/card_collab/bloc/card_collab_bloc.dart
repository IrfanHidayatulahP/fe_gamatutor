import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/network/websocket_manager.dart';
import '../../../../../core/utils/constants.dart';
import '../repository/card_collab_repository.dart';
import 'card_collab_event.dart';
import 'card_collab_state.dart';

class CardCollabBloc extends Bloc<CardCollabEvent, CardCollabState> {
  final CardCollabRepository _repository;
  final WebSocketManager _wsManager;
  StreamSubscription? _wsSubscription;

  CardCollabBloc({
    CardCollabRepository? repository,
    WebSocketManager? wsManager,
  })  : _repository = repository ?? sl<CardCollabRepository>(),
        _wsManager = wsManager ?? sl<WebSocketManager>(),
        super(CardCollabInitial()) {
    on<AddCollaborator>(_onAddCollaborator);
    on<RemoveCollaborator>(_onRemoveCollaborator);
    on<UpdateCollaboratorRole>(_onUpdateCollaboratorRole);
    on<LoadCardCollaborators>(_onLoadCardCollaborators);
    on<LoadUserCollaborations>(_onLoadUserCollaborations);
    on<LoadCollaborationDetails>(_onLoadCollaborationDetails);
    on<CardCollabRealtimeEvent>(_onRealtimeEvent);

    _setupWebSocketListeners();
  }

  void _setupWebSocketListeners() {
    _wsManager.on(WebSocketEvents.collaborationInvite, _handleCollaborationInvite);
    _wsManager.on(WebSocketEvents.collaborationUpdated, _handleCollaborationUpdated);
    _wsManager.on(WebSocketEvents.cardUpdatedByCollaborator, _handleCardUpdatedByCollaborator);
  }

  void _handleCollaborationInvite(Map<String, dynamic> data) {
    add(CardCollabRealtimeEvent(data: data));
  }

  void _handleCollaborationUpdated(Map<String, dynamic> data) {
    add(CardCollabRealtimeEvent(data: data));
  }

  void _handleCardUpdatedByCollaborator(Map<String, dynamic> data) {
    add(CardCollabRealtimeEvent(data: data));
  }

  Future<void> _onAddCollaborator(
    AddCollaborator event,
    Emitter<CardCollabState> emit,
  ) async {
    emit(CardCollabLoading());
    try {
      final collaboration = await _repository.addCollaborator(
        cardId: event.cardId,
        userId: event.userId,
        role: event.role,
      );
      if (collaboration != null) {
        emit(CollaborationActionSuccess(
          action: 'add',
          collaboration: collaboration,
          message: 'Collaborator added',
        ));
        add(LoadCardCollaborators(cardId: event.cardId));
      } else {
        emit(const CardCollabError(message: 'Failed to add collaborator'));
      }
    } catch (e) {
      emit(CardCollabError(message: e.toString()));
    }
  }

  Future<void> _onRemoveCollaborator(
    RemoveCollaborator event,
    Emitter<CardCollabState> emit,
  ) async {
    try {
      final success = await _repository.removeCollaborator(event.collabId);
      if (success) {
        emit(const CollaborationActionSuccess(
          action: 'remove',
          collaboration: null,
          message: 'Collaborator removed',
        ));
      } else {
        emit(const CardCollabError(message: 'Failed to remove collaborator'));
      }
    } catch (e) {
      emit(CardCollabError(message: e.toString()));
    }
  }

  Future<void> _onUpdateCollaboratorRole(
    UpdateCollaboratorRole event,
    Emitter<CardCollabState> emit,
  ) async {
    try {
      final collaboration = await _repository.updateCollaboratorRole(
        collabId: event.collabId,
        role: event.role,
      );
      if (collaboration != null) {
        emit(CollaborationActionSuccess(
          action: 'update_role',
          collaboration: collaboration,
          message: 'Role updated',
        ));
      } else {
        emit(const CardCollabError(message: 'Failed to update role'));
      }
    } catch (e) {
      emit(CardCollabError(message: e.toString()));
    }
  }

  Future<void> _onLoadCardCollaborators(
    LoadCardCollaborators event,
    Emitter<CardCollabState> emit,
  ) async {
    emit(CardCollabLoading());
    try {
      final response = await _repository.getCardCollaborators(event.cardId);
      emit(CollaboratorsLoaded(
        collaborators: response.collaborations,
        total: response.total,
      ));
    } catch (e) {
      emit(CardCollabError(message: e.toString()));
    }
  }

  Future<void> _onLoadUserCollaborations(
    LoadUserCollaborations event,
    Emitter<CardCollabState> emit,
  ) async {
    emit(CardCollabLoading());
    try {
      final response = await _repository.getUserCollaborations(
        limit: event.limit,
        offset: event.offset,
      );
      emit(UserCollaborationsLoaded(
        collaborations: response.collaborations,
        total: response.total,
        hasMore: response.collaborations.length < response.total,
      ));
    } catch (e) {
      emit(CardCollabError(message: e.toString()));
    }
  }

  Future<void> _onLoadCollaborationDetails(
    LoadCollaborationDetails event,
    Emitter<CardCollabState> emit,
  ) async {
    emit(CardCollabLoading());
    try {
      final collaboration = await _repository.getCollaborationById(event.collabId);
      if (collaboration != null) {
        emit(CollaborationDetailsLoaded(collaboration: collaboration));
      } else {
        emit(const CardCollabError(message: 'Collaboration not found'));
      }
    } catch (e) {
      emit(CardCollabError(message: e.toString()));
    }
  }

  Future<void> _onRealtimeEvent(
    CardCollabRealtimeEvent event,
    Emitter<CardCollabState> emit,
  ) async {
    // Handle real-time collaboration events
    final eventType = event.data['event'] ?? event.data['type'];
    // Could reload relevant data based on event type
    // ignore: unused_local_variable
    final _ = eventType;
  }

  @override
  Future<void> close() {
    _wsSubscription?.cancel();
    return super.close();
  }
}