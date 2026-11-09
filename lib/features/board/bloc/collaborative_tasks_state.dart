import 'package:equatable/equatable.dart';

import '../data/collaborative_task_model.dart';

abstract class CollaborativeTasksState extends Equatable {
  const CollaborativeTasksState();

  @override
  List<Object?> get props => [];
}

class CollaborativeTasksInitial extends CollaborativeTasksState {}

class CollaborativeTasksLoading extends CollaborativeTasksState {}

class CollaborativeTasksLoaded extends CollaborativeTasksState {
  final List<CollaborativeTaskModel> tasks;

  const CollaborativeTasksLoaded(this.tasks);

  @override
  List<Object?> get props => [tasks];
}

class CollaborativeTasksError extends CollaborativeTasksState {
  final String message;

  const CollaborativeTasksError(this.message);

  @override
  List<Object?> get props => [message];
}