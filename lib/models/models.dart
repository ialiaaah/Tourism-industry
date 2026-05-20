import 'package:flutter/foundation.dart';

// ---------- User & Auth ----------

enum UserRole { tourist, guide }

class AppUser {
  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final DateTime createdAt;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
  });

  /// Alias for name — keeps compatibility with displayName references.
  String? get displayName => name.isNotEmpty ? name : null;

  /// First name only, safe.
  String get firstName {
    final parts = name.trim().split(' ');
    return parts.isNotEmpty ? parts.first : 'User';
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'name': name,
        'email': email,
        'role': role.name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      uid: json['uid'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] == 'guide' ? UserRole.guide : UserRole.tourist,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctOptionIndex;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctOptionIndex,
  });

  Map<String, dynamic> toJson() => {
        'question': question,
        'options': options,
        'correctOptionIndex': correctOptionIndex,
      };

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      question: json['question'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      correctOptionIndex: json['correctOptionIndex'] ?? 0,
    );
  }
}

class Stop {
  final String id;
  final String name;
  final String description;
  final String imagePath; // Dummy image path or placeholder
  final String? arSnippet;
  final QuizQuestion? quiz;

  Stop({
    required this.id,
    required this.name,
    required this.description,
    required this.imagePath,
    this.arSnippet,
    this.quiz,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'imagePath': imagePath,
        'arSnippet': arSnippet,
        'quiz': quiz?.toJson(),
      };

  factory Stop.fromJson(Map<String, dynamic> json) {
    return Stop(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      imagePath: json['imagePath'] ?? '',
      arSnippet: json['arSnippet'],
      quiz: json['quiz'] != null ? QuizQuestion.fromJson(json['quiz']) : null,
    );
  }
}

class Tour {
  final String id;
  final String title;
  final String description;
  final String accessCode;
  final List<Stop> stops;

  Tour({
    required this.id,
    required this.title,
    required this.description,
    required this.accessCode,
    required this.stops,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'accessCode': accessCode,
        'stops': stops.map((s) => s.toJson()).toList(),
      };

  factory Tour.fromJson(Map<String, dynamic> json) {
    return Tour(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      accessCode: json['accessCode'] ?? '',
      stops: (json['stops'] as List<dynamic>?)?.map((s) => Stop.fromJson(s)).toList() ?? [],
    );
  }
}

class Stamp {
  final String stopId;
  final String stopName;
  final DateTime dateEarned;

  Stamp({
    required this.stopId,
    required this.stopName,
    required this.dateEarned,
  });

  Map<String, dynamic> toJson() => {
        'stopId': stopId,
        'stopName': stopName,
        'dateEarned': dateEarned.toIso8601String(),
      };

  factory Stamp.fromJson(Map<String, dynamic> json) {
    return Stamp(
      stopId: json['stopId'] ?? '',
      stopName: json['stopName'] ?? '',
      dateEarned: DateTime.parse(json['dateEarned']),
    );
  }
}

class TouristQuestion {
  final String tourId;
  final String stopId;
  final String questionText;
  final DateTime timestamp;

  TouristQuestion({
    required this.tourId,
    required this.stopId,
    required this.questionText,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'tourId': tourId,
        'stopId': stopId,
        'questionText': questionText,
        'timestamp': timestamp.toIso8601String(),
      };

  factory TouristQuestion.fromJson(Map<String, dynamic> json) {
    return TouristQuestion(
      tourId: json['tourId'] ?? '',
      stopId: json['stopId'] ?? '',
      questionText: json['questionText'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
