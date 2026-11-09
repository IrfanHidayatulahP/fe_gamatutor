import 'package:equatable/equatable.dart';

import '../../../../core/models/user_model.dart';

class ChatMessageModel extends Equatable {
  final String chatId;
  final String senderId;
  final String receiverId;
  final String messageChat;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final UserModel? sender;
  final UserModel? receiver;

  const ChatMessageModel({
    required this.chatId,
    required this.senderId,
    required this.receiverId,
    required this.messageChat,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.sender,
    this.receiver,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      chatId: json['chatId'] ?? json['id'] ?? '',
      senderId: json['senderId'] ?? json['userId'] ?? '',
      receiverId: json['receiverId'] ?? json['friendId'] ?? '',
      messageChat: json['messageChat'] ?? json['message'] ?? '',
      status: json['status'] ?? 'delivered',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : (json['timeChat'] != null ? DateTime.parse(json['timeChat']) : DateTime.now()),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      sender: json['sender'] != null
          ? UserModel.fromJson(json['sender'])
          : (json['user'] != null ? UserModel.fromJson(json['user']) : null),
      receiver: json['receiver'] != null
          ? UserModel.fromJson(json['receiver'])
          : (json['recipient'] != null ? UserModel.fromJson(json['recipient']) : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'receiverId': receiverId,
      'messageChat': messageChat,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'sender': sender?.toJson(),
      'receiver': receiver?.toJson(),
    };
  }

  bool get isSentByMe => false; // Will be set by BLOC based on current user
  bool get isRead => status == 'read';
  bool get isDelivered => status == 'delivered' || status == 'read';

  ChatMessageModel copyWith({
    String? chatId,
    String? senderId,
    String? receiverId,
    String? messageChat,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    UserModel? sender,
    UserModel? receiver,
  }) {
    return ChatMessageModel(
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      messageChat: messageChat ?? this.messageChat,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sender: sender ?? this.sender,
      receiver: receiver ?? this.receiver,
    );
  }

  @override
  List<Object?> get props => [chatId, senderId, receiverId, messageChat, status, createdAt, updatedAt, sender, receiver];
}

class ChatListResponse extends Equatable {
  final List<ChatMessageModel> messages;
  final int total;

  const ChatListResponse({required this.messages, required this.total});

  factory ChatListResponse.fromJson(Map<String, dynamic> json) {
    final list = json['messages'] ?? json['data'] ?? json['chat'] ?? json['chats'] ?? [];
    return ChatListResponse(
      messages: (list as List).map((e) => ChatMessageModel.fromJson(e)).toList(),
      total: json['total'] ?? list.length,
    );
  }

  @override
  List<Object?> get props => [messages, total];
}