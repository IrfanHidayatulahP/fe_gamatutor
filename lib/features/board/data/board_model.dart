import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class BoardResponse extends Equatable {
  final List<BoardCard> planning;
  final List<BoardCard> monitoring;
  final List<BoardCard> controlling;
  final List<BoardCard> reflection;

  const BoardResponse({
    this.planning = const [],
    this.monitoring = const [],
    this.controlling = const [],
    this.reflection = const [],
  });

  factory BoardResponse.fromJson(Map<String, dynamic> json) {
    return BoardResponse(
      planning: _parseCards(json['planning']),
      monitoring: _parseCards(json['monitoring']),
      controlling: _parseCards(json['controlling']),
      reflection: _parseCards(json['reflection']),
    );
  }

  static List<BoardCard> _parseCards(dynamic data) {
    if (data is List) {
      return data.map((e) => BoardCard.fromJson(e)).toList();
    }
    return [];
  }

  List<BoardCard> getCardsForColumn(String columnId) {
    switch (columnId) {
      case 'planning':
        return planning;
      case 'monitoring':
        return monitoring;
      case 'controlling':
        return controlling;
      case 'reflection':
        return reflection;
      default:
        return [];
    }
  }

  int get totalCards => planning.length + monitoring.length + controlling.length + reflection.length;

  @override
  List<Object?> get props => [planning, monitoring, controlling, reflection];
}

class BoardCard extends Equatable {
  final String cardId;
  final String title;
  final String difficulty;
  final String priority;
  final String deadline;
  final CardList? cardList;

  const BoardCard({
    required this.cardId,
    required this.title,
    required this.difficulty,
    required this.priority,
    required this.deadline,
    this.cardList,
  });

  factory BoardCard.fromJson(Map<String, dynamic> json) {
    return BoardCard(
      cardId: json['cardId'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      difficulty: json['difficulty'] ?? 'medium',
      priority: json['priority'] ?? 'medium',
      deadline: json['deadline'] ?? '',
      cardList: json['cardList'] != null ? CardList.fromJson(json['cardList']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cardId': cardId,
      'title': title,
      'difficulty': difficulty,
      'priority': priority,
      'deadline': deadline,
      'cardList': cardList?.toJson(),
    };
  }

  String get difficultyLabel {
    switch (difficulty) {
      case 'easy':
        return 'Mudah';
      case 'medium':
        return 'Sedang';
      case 'hard':
        return 'Sulit';
      case 'expert':
        return 'Ahli';
      default:
        return difficulty;
    }
  }

  String get priorityLabel {
    switch (priority) {
      case 'low':
        return 'Rendah';
      case 'medium':
        return 'Sedang';
      case 'high':
        return 'Tinggi';
      case 'critical':
        return 'Kritis';
      default:
        return priority;
    }
  }

  Color get priorityColor {
    switch (priority) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      case 'critical':
        return Colors.deepOrange;
      default:
        return Colors.grey;
    }
  }

  @override
  List<Object?> get props => [cardId, title, difficulty, priority, deadline, cardList];
}

class CardList extends Equatable {
  final LearningStrat? learningStrat;

  const CardList({this.learningStrat});

  factory CardList.fromJson(Map<String, dynamic> json) {
    return CardList(
      learningStrat: json['learningStrat'] != null ? LearningStrat.fromJson(json['learningStrat']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'learningStrat': learningStrat?.toJson(),
    };
  }

  @override
  List<Object?> get props => [learningStrat];
}

class LearningStrat extends Equatable {
  final String learningStrategy;

  const LearningStrat({required this.learningStrategy});

  factory LearningStrat.fromJson(Map<String, dynamic> json) {
    return LearningStrat(
      learningStrategy: json['learningStrategy'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'learningStrategy': learningStrategy,
    };
  }

  String get strategyLabel {
    switch (learningStrategy) {
      case 'rehearsal':
        return 'Rehearsal';
      case 'organization':
        return 'Organization';
      case 'elaboration':
        return 'Elaboration';
      case 'time management':
        return 'Time Management';
      case 'help seeking':
        return 'Help Seeking';
      case 'metacognitive self regulation':
        return 'Metacognitive Self-Regulation';
      case 'critical thinking':
        return 'Critical Thinking';
      default:
        return learningStrategy;
    }
  }

  String get strategyKeyCode {
    switch (learningStrategy) {
      case 'rehearsal':
        return 'REH';
      case 'organization':
        return 'ORG';
      case 'elaboration':
        return 'ELAB';
      case 'time management':
        return 'TM';
      case 'help seeking':
        return 'HS';
      case 'metacognitive self regulation':
        return 'MSR';
      case 'critical thinking':
        return 'CT';
      default:
        return '';
    }
  }

  @override
  List<Object?> get props => [learningStrategy];
}