import 'package:equatable/equatable.dart';

import '../data/board_model.dart';
import '../data/column_model.dart';

abstract class BoardState extends Equatable {
  const BoardState();

  @override
  List<Object?> get props => [];
}

class BoardInitial extends BoardState {}

class BoardLoading extends BoardState {}

class BoardLoaded extends BoardState {
  final BoardResponse board;
  final ColumnsResponse columns;
  final BoardCard? selectedCard;

  const BoardLoaded({
    required this.board,
    required this.columns,
    this.selectedCard,
  });

  BoardLoaded copyWith({
    BoardResponse? board,
    ColumnsResponse? columns,
    BoardCard? selectedCard,
  }) {
    return BoardLoaded(
      board: board ?? this.board,
      columns: columns ?? this.columns,
      selectedCard: selectedCard ?? this.selectedCard,
    );
  }

  @override
  List<Object?> get props => [board, columns, selectedCard];
}

class BoardError extends BoardState {
  final String message;

  const BoardError({required this.message});

  @override
  List<Object?> get props => [message];
}