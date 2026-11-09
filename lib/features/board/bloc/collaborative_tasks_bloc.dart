import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../repository/collaborative_tasks_repository.dart';
import 'collaborative_tasks_event.dart';
import 'collaborative_tasks_state.dart';

class CollaborativeTasksBloc
    extends Bloc<CollaborativeTasksEvent, CollaborativeTasksState> {
  final CollaborativeTasksRepository _repository;

  CollaborativeTasksBloc({required CollaborativeTasksRepository repository})
      : _repository = repository,
        super(CollaborativeTasksInitial()) {
    on<LoadCollaborativeTasks>(_onLoadCollaborativeTasks);
    on<RefreshCollaborativeTasks>(_onRefreshCollaborativeTasks);
  }

  Future<void> _onLoadCollaborativeTasks(
    LoadCollaborativeTasks event,
    Emitter<CollaborativeTasksState> emit,
  ) async {
    emit(CollaborativeTasksLoading());
    try {
      final tasks = await _repository.getCollaborativeTasks();
      emit(CollaborativeTasksLoaded(tasks));
    } catch (e) {
      emit(CollaborativeTasksError(e.toString()));
    }
  }

  Future<void> _onRefreshCollaborativeTasks(
    RefreshCollaborativeTasks event,
    Emitter<CollaborativeTasksState> emit,
  ) async {
    try {
      final tasks = await _repository.getCollaborativeTasks();
      emit(CollaborativeTasksLoaded(tasks));
    } catch (e) {
      emit(CollaborativeTasksError(e.toString()));
    }
  }
}