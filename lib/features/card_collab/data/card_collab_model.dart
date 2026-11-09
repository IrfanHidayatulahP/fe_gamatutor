import 'package:equatable/equatable.dart';

import '../../../../core/models/user_model.dart';

class CardCollaborationModel extends Equatable {
  final String collabId;
  final String cardId;
  final String userId;
  final String role;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UserModel? user;
  final CardModel? card;

  const CardCollaborationModel({
    required this.collabId,
    required this.cardId,
    required this.userId,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
    this.user,
    this.card,
  });

  factory CardCollaborationModel.fromJson(Map<String, dynamic> json) {
    return CardCollaborationModel(
      collabId: json['collabId'] ?? json['id'] ?? '',
      cardId: json['cardId'] ?? '',
      userId: json['userId'] ?? '',
      role: json['role'] ?? 'member',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
      card: json['card'] != null ? CardModel.fromJson(json['card']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'collabId': collabId,
      'cardId': cardId,
      'userId': userId,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'user': user?.toJson(),
      'card': card?.toJson(),
    };
  }

  bool get isOwner => role == 'owner';
  bool get isMember => role == 'member';

  @override
  List<Object?> get props => [collabId, cardId, userId, role, createdAt, updatedAt, user, card];
}

class CardModel extends Equatable {
  final String cardId;
  final String userId;
  final String title;
  final String learningId;
  final String? description;
  final String? courseName;
  final String? difficulty;
  final String? priority;
  final String? deadline;
  final String? url;
  final DateTime? startTime;
  final DateTime? endTime;
  final bool deleted;
  final DateTime createdAt;

  const CardModel({
    required this.cardId,
    required this.userId,
    required this.title,
    required this.learningId,
    this.description,
    this.courseName,
    this.difficulty,
    this.priority,
    this.deadline,
    this.url,
    this.startTime,
    this.endTime,
    required this.deleted,
    required this.createdAt,
  });

  factory CardModel.fromJson(Map<String, dynamic> json) {
    return CardModel(
      cardId: json['cardId'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      title: json['title'] ?? '',
      learningId: json['learningId'] ?? '',
      description: json['description'],
      courseName: json['courseName'],
      difficulty: json['difficulty'],
      priority: json['priority'],
      deadline: json['deadline'],
      url: json['url'],
      startTime: json['startTime'] != null ? DateTime.parse(json['startTime']) : null,
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      deleted: json['deleted'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cardId': cardId,
      'userId': userId,
      'title': title,
      'learningId': learningId,
      'description': description,
      'courseName': courseName,
      'difficulty': difficulty,
      'priority': priority,
      'deadline': deadline,
      'url': url,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'deleted': deleted,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [cardId, userId, title, learningId, description, courseName, difficulty, priority, deadline, url, startTime, endTime, deleted, createdAt];
}

class CardCollabListResponse extends Equatable {
  final List<CardCollaborationModel> collaborations;
  final int total;

  const CardCollabListResponse({required this.collaborations, required this.total});

  factory CardCollabListResponse.fromJson(Map<String, dynamic> json) {
    final list = json['collaborations'] ?? json['data'] ?? json['cardListCollabs'] ?? [];
    return CardCollabListResponse(
      collaborations: (list as List).map((e) => CardCollaborationModel.fromJson(e)).toList(),
      total: json['total'] ?? list.length,
    );
  }

  @override
  List<Object?> get props => [collaborations, total];
}