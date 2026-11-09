class ApiConstants {
  static const String baseUrl = 'http://192.168.1.25:3000/api';
  static const String wsBaseUrl = 'http://192.168.1.25:3000';
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;
  static const int sendTimeout = 30000;
}

class StorageKeys {
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String userData = 'user_data';
  static const String tokenExpiry = 'token_expiry';
}

class WebSocketEvents {
  // Friendship events
  static const String friendRequestReceived = 'friend_request_received';
  static const String friendRequestAccepted = 'friend_request_accepted';
  static const String friendRequestRejected = 'friend_request_rejected';
  static const String friendBlocked = 'friend_blocked';
  static const String friendUnblocked = 'friend_unblocked';
  static const String friendRemoved = 'friend_removed';
  static const String friendStatusChanged = 'friend_status_changed';

  // Chat events
  static const String newMessage = 'new_message';
  static const String messageUpdated = 'message_updated';
  static const String messageDeleted = 'message_deleted';
  static const String messageRead = 'message_read';
  static const String userTyping = 'user_typing';
  static const String userStoppedTyping = 'user_stopped_typing';

  // Call events
  static const String incomingCall = 'incoming_call';
  static const String callAnswered = 'call_answered';
  static const String callRejected = 'call_rejected';
  static const String callEnded = 'call_ended';
  static const String callCancelled = 'call_cancelled';
  static const String callSignaling = 'call_signaling';

  // Group call events
  static const String groupCallInvite = 'group_call_invite';
  static const String groupCallStarting = 'group_call_starting';
  static const String groupCallEnded = 'group_call_ended';
  static const String participantJoined = 'participant_joined';
  static const String participantLeft = 'participant_left';
  static const String participantUpdated = 'participant_updated';

  // Collaboration events
  static const String collaborationInvite = 'collaboration_invite';
  static const String collaborationUpdated = 'collaboration_updated';
  static const String collabNewMessage = 'collab_new_message';
  static const String mentionInCollab = 'mention_in_collab';
  static const String cardUpdatedByCollaborator = 'card_updated_by_collaborator';

  // Notification events
  static const String notificationReceived = 'notification_received';
  static const String notificationRead = 'notification_read';
}

class CallStatus {
  static const String pending = 'pending';
  static const String ringing = 'ringing';
  static const String answered = 'answered';
  static const String rejected = 'rejected';
  static const String ended = 'ended';
  static const String missed = 'missed';
  static const String cancelled = 'cancelled';
}

class CallType {
  static const String audio = 'audio';
  static const String video = 'video';
}

class FriendshipStatus {
  static const String pending = 'pending';
  static const String accepted = 'accepted';
  static const String declined = 'declined';
  static const String blocked = 'blocked';
}

class MessageStatus {
  static const String sent = 'sent';
  static const String delivered = 'delivered';
  static const String read = 'read';
}

class NotificationType {
  static const String push = 'push';
  static const String smartReminder = 'smart_reminder';
  static const String socialPresence = 'social_presence';
  static const String encouragement = 'encouragement';
}

class CollaborationRole {
  static const String owner = 'owner';
  static const String member = 'member';
}