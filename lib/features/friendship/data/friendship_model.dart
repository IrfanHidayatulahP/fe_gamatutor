import 'package:equatable/equatable.dart';

import '../../../../core/models/user_model.dart';

class FriendshipModel extends Equatable {
  final String fsId;
  final String userId;
  final String friendId;
  final String status;
  final UserModel? requester;
  final UserModel? friend;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FriendshipModel({
    required this.fsId,
    required this.userId,
    required this.friendId,
    required this.status,
    this.requester,
    this.friend,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FriendshipModel.fromJson(Map<String, dynamic> json) {
    return FriendshipModel(
      fsId: json['fsId'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      friendId: json['friendId'] ?? '',
      status: json['status'] ?? '',
      requester: json['requester'] != null ? UserModel.fromJson(json['requester']) : null,
      friend: json['friend'] != null ? UserModel.fromJson(json['friend']) : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fsId': fsId,
      'userId': userId,
      'friendId': friendId,
      'status': status,
      'requester': requester?.toJson(),
      'friend': friend?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  UserModel? getOtherUser(String currentUserId) {
    // For accepted friendships, both requester and friend are populated
    // Return the user who is NOT the current user
    if (userId == currentUserId) {
      return friend; // Current user sent the request -> friend is the other user
    } else if (friendId == currentUserId) {
      return requester; // Current user received the request -> requester is the other user
    }
    // Fallback for pending requests (only one of requester/friend is populated)
    if (requester == null) {
      return friend;
    }
    return requester;
  }
  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isBlocked => status == 'blocked';
  bool get isDeclined => status == 'declined';

  @override
  List<Object?> get props => [fsId, userId, friendId, status, requester, friend, createdAt, updatedAt];
}

class FriendshipListResponse extends Equatable {
  final List<FriendshipModel> friendships;
  final int total;

  const FriendshipListResponse({required this.friendships, required this.total});

  factory FriendshipListResponse.fromJson(Map<String, dynamic> json) {
    final list = json['friendships'] ?? json['data'] ?? json['users'] ?? [];
    return FriendshipListResponse(
      friendships: (list as List).map((e) => FriendshipModel.fromJson(e)).toList(),
      total: json['total'] ?? list.length,
    );
  }

  @override
  List<Object?> get props => [friendships, total];
}

class PendingRequestsResponse extends Equatable {
  final List<FriendshipModel> incomingRequests;
  final List<FriendshipModel> outgoingRequests;
  final int total;

  const PendingRequestsResponse({
    required this.incomingRequests,
    required this.outgoingRequests,
    required this.total,
  });

  factory PendingRequestsResponse.fromJson(Map<String, dynamic> json) {
    final incoming = (json['incomingRequests'] as List? ?? [])
        .map((e) => FriendshipModel.fromJson(e))
        .toList();
    final outgoing = (json['outgoingRequests'] as List? ?? [])
        .map((e) => FriendshipModel.fromJson(e))
        .toList();
    return PendingRequestsResponse(
      incomingRequests: incoming,
      outgoingRequests: outgoing,
      total: json['total'] ?? (incoming.length + outgoing.length),
    );
  }

  @override
  List<Object?> get props => [incomingRequests, outgoingRequests, total];
}