import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/network/api_client.dart';
import '../repository/board_repository.dart';
import 'board_event.dart';
import 'board_state.dart';

class BoardBloc extends Bloc<BoardEvent, BoardState> {
  final BoardRepository _repository;

  BoardBloc({BoardRepository? repository})
      : _repository = repository ?? BoardRepository(apiClient: sl<ApiClient>()),
        super(BoardInitial()) {
    on<LoadBoard>(_onLoadBoard);
    on<LoadColumns>(_onLoadColumns);
    on<RefreshBoard>(_onRefreshBoard);
    on<SelectCard>(_onSelectCard);
  }

  Future<void> _onLoadBoard(
    LoadBoard event,
    Emitter<BoardState> emit,
  ) async {
    emit(BoardLoading());
    try {
      final board = await _repository.getBoard(
        column: event.column,
        limit: event.limit,
        offset: event.offset,
      );
      final columns = await _repository.getColumns();
      emit(BoardLoaded(board: board, columns: columns));
    } catch (e) {
      emit(BoardError(message: e.toString()));
    }
  }

  Future<void> _onLoadColumns(
    LoadColumns event,
    Emitter<BoardState> emit,
  ) async {
    try {
      final columns = await _repository.getColumns();
      if (state is BoardLoaded) {
        final currentState = state as BoardLoaded;
        emit(BoardLoaded(board: currentState.board, columns: columns));
      }
    } catch (e) {
      // Don't overwrite board loaded state with error for columns only
    }
  }

  Future<void> _onRefreshBoard(
    RefreshBoard event,
    Emitter<BoardState> emit,
  ) async {
    // Re-load current board data
    add(LoadBoard());
  }

  Future<void> _onSelectCard(
    SelectCard event,
    Emitter<BoardState> emit,
  ) async {
    if (state is BoardLoaded) {
      final currentState = state as BoardLoaded;
      emit(currentState.copyWith(selectedCard: event.card));
    }
  }
}