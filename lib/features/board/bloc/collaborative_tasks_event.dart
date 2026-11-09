import 'package:equatable/equatable.dart';

import '../data/collaborative_task_model.dart';

abstract class CollaborativeTasksEvent extends Equatable {
  const CollaborativeTasksEvent();

  @override
  List<Object?> get props => [];
}

class LoadCollaborativeTasks extends CollaborativeTasksEvent {}

class RefreshCollaborativeTasks extends CollaborativeTasksEvent {}