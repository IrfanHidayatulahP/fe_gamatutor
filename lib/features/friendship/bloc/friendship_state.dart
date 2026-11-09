
import 'package:equatable/equatable.dart';

import '../data/friendship_model.dart';
import '../../../../../core/models/user_model.dart';

abstract class FriendshipState extends Equatable {
  const FriendshipState();

  @override
  List<Object?> get props => [];
}

class FriendshipInitial extends FriendshipState {}

class FriendshipLoading extends FriendshipState {}

class FriendsLoaded extends FriendshipState {
  final List<FriendshipModel> friends;
  final int total;
  final bool hasMore;

  const FriendsLoaded({
    required this.friends,
    required this.total,
    required this.hasMore,
  });

  @override
  List<Object?> get props => [friends, total, hasMore];
}

class PendingRequestsLoaded extends FriendshipState {
  final List<FriendshipModel> incomingRequests;
  final List<FriendshipModel> outgoingRequests;
  final int total;

  const PendingRequestsLoaded({
    required this.incomingRequests,
    required this.outgoingRequests,
    required this.total,
  });

  @override
  List<Object?> get props => [incomingRequests, outgoingRequests, total];
}

class UsersSearchResult extends FriendshipState {
  final List<UserModel> users;

  const UsersSearchResult({required this.users});

  @override
  List<Object?> get props => [users];
}

class FriendActionSuccess extends FriendshipState {
  final String action;
  final FriendshipModel? friendship;
  final String message;

  const FriendActionSuccess({
    required this.action,
    this.friendship,
    required this.message,
  });

  @override
  List<Object?> get props => [action, friendship, message];
}

class FriendshipError extends FriendshipState {
  final String message;

  const FriendshipError({required this.message});

  @override
  List<Object?> get props => [message];
}

class TeamFriendsLoaded extends FriendshipState {
  final List<FriendshipModel> friends;
  final int total;
  final bool hasMore;

  const TeamFriendsLoaded({
    required this.friends,
    required this.total,
    required this.hasMore,
  });

  @override
  List<Object?> get props => [friends, total, hasMore];
}