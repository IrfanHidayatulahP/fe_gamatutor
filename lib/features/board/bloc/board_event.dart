import 'package:equatable/equatable.dart';

import '../data/board_model.dart';

abstract class BoardEvent extends Equatable {
  const BoardEvent();

  @override
  List<Object?> get props => [];
}

class LoadBoard extends BoardEvent {
  final String? column;
  final int limit;
  final int offset;

  const LoadBoard({
    this.column,
    this.limit = 100,
    this.offset = 0,
  });

  @override
  List<Object?> get props => [column, limit, offset];
}

class LoadColumns extends BoardEvent {}

class RefreshBoard extends BoardEvent {}

class SelectCard extends BoardEvent {
  final BoardCard? card;

  const SelectCard({this.card});

  @override
  List<Object?> get props => [card];
}