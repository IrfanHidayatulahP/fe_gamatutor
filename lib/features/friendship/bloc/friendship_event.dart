
import 'package:equatable/equatable.dart';

abstract class FriendshipEvent extends Equatable {
  const FriendshipEvent();

  @override
  List<Object?> get props => [];
}

class LoadFriends extends FriendshipEvent {
  final int limit;
  final int offset;

  const LoadFriends({this.limit = 50, this.offset = 0});

  @override
  List<Object?> get props => [limit, offset];
}

class LoadPendingRequests extends FriendshipEvent {
  final int limit;
  final int offset;

  const LoadPendingRequests({this.limit = 50, this.offset = 0});

  @override
  List<Object?> get props => [limit, offset];
}

class SendFriendRequest extends FriendshipEvent {
  final String friendId;

  const SendFriendRequest({required this.friendId});

  @override
  List<Object?> get props => [friendId];
}

class AcceptFriendRequest extends FriendshipEvent {
  final String fsId;

  const AcceptFriendRequest({required this.fsId});

  @override
  List<Object?> get props => [fsId];
}

class RejectFriendRequest extends FriendshipEvent {
  final String fsId;

  const RejectFriendRequest({required this.fsId});

  @override
  List<Object?> get props => [fsId];
}

class BlockFriend extends FriendshipEvent {
  final String fsId;

  const BlockFriend({required this.fsId});

  @override
  List<Object?> get props => [fsId];
}

class UnblockFriend extends FriendshipEvent {
  final String fsId;

  const UnblockFriend({required this.fsId});

  @override
  List<Object?> get props => [fsId];
}

class RemoveFriend extends FriendshipEvent {
  final String fsId;

  const RemoveFriend({required this.fsId});

  @override
  List<Object?> get props => [fsId];
}

class SearchUsers extends FriendshipEvent {
  final String email;

  const SearchUsers({required this.email});

  @override
  List<Object?> get props => [email];
}

class FriendshipRealtimeEvent extends FriendshipEvent {
  final Map<String, dynamic> data;

  const FriendshipRealtimeEvent({required this.data});

  @override
  List<Object?> get props => [data];
}

class LoadTeamFriends extends FriendshipEvent {
  final int limit;
  final int offset;

  const LoadTeamFriends({this.limit = 50, this.offset = 0});

  @override
  List<Object?> get props => [limit, offset];
}

class InviteFriendToCollaboration extends FriendshipEvent {
  final String cardId;
  final String friendId;

  const InviteFriendToCollaboration({
    required this.cardId,
    required this.friendId,
  });

  @override
  List<Object?> get props => [cardId, friendId];
}

class AuthStateCleared extends FriendshipEvent {
  const AuthStateCleared();

  @override
  List<Object?> get props => [];
}