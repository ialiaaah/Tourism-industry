import 'package:flutter/material.dart';

enum HotspotType {
  history,
  architecture,
  story,
  symbol,
  restoration,
  nearby,
}

class ARHotspot {
  final String id;
  final String title;
  final String description;
  final Offset position; // Relative X, Y coordinates (0.0 to 1.0)
  final HotspotType type;
  final IconData icon;

  const ARHotspot({
    required this.id,
    required this.title,
    required this.description,
    required this.position,
    required this.type,
    required this.icon,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'x': position.dx,
        'y': position.dy,
        'type': type.name,
      };

  factory ARHotspot.fromJson(Map<String, dynamic> json) {
    return ARHotspot(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      position: Offset(
        (json['x'] as num?)?.toDouble() ?? 0.5,
        (json['y'] as num?)?.toDouble() ?? 0.5,
      ),
      type: HotspotType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => HotspotType.history,
      ),
      icon: _getIconForType(json['type'] ?? ''),
    );
  }

  static IconData _getIconForType(String typeStr) {
    switch (typeStr) {
      case 'history':
        return Icons.history_edu;
      case 'architecture':
        return Icons.account_balance;
      case 'story':
        return Icons.auto_stories;
      case 'symbol':
        return Icons.stars;
      case 'restoration':
        return Icons.build;
      case 'nearby':
        return Icons.map;
      default:
        return Icons.info;
    }
  }
}

class TreasureHuntMission {
  final String id;
  final String monumentId;
  final String title;
  final String clue;
  final String hint;
  final String correctHotspotId;
  final int rewardPoints;
  final String badgeReward;
  final String artifactReward;
  final bool completed;

  const TreasureHuntMission({
    required this.id,
    required this.monumentId,
    required this.title,
    required this.clue,
    required this.hint,
    required this.correctHotspotId,
    required this.rewardPoints,
    required this.badgeReward,
    required this.artifactReward,
    this.completed = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'monumentId': monumentId,
        'title': title,
        'clue': clue,
        'hint': hint,
        'correctHotspotId': correctHotspotId,
        'rewardPoints': rewardPoints,
        'badgeReward': badgeReward,
        'artifactReward': artifactReward,
        'completed': completed,
      };

  factory TreasureHuntMission.fromJson(Map<String, dynamic> json) {
    return TreasureHuntMission(
      id: json['id'] ?? '',
      monumentId: json['monumentId'] ?? '',
      title: json['title'] ?? '',
      clue: json['clue'] ?? '',
      hint: json['hint'] ?? '',
      correctHotspotId: json['correctHotspotId'] ?? '',
      rewardPoints: json['rewardPoints'] ?? 50,
      badgeReward: json['badgeReward'] ?? '',
      artifactReward: json['artifactReward'] ?? '',
      completed: json['completed'] ?? false,
    );
  }

  TreasureHuntMission copyWith({bool? completed}) {
    return TreasureHuntMission(
      id: id,
      monumentId: monumentId,
      title: title,
      clue: clue,
      hint: hint,
      correctHotspotId: correctHotspotId,
      rewardPoints: rewardPoints,
      badgeReward: badgeReward,
      artifactReward: artifactReward,
      completed: completed ?? this.completed,
    );
  }
}

class TimelineEvent {
  final String year;
  final String title;
  final String description;

  const TimelineEvent({
    required this.year,
    required this.title,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
        'year': year,
        'title': title,
        'description': description,
      };

  factory TimelineEvent.fromJson(Map<String, dynamic> json) {
    return TimelineEvent(
      year: json['year'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
    );
  }
}

enum BadgeRarity {
  bronze,
  silver,
  gold,
  legendary,
}

class Badge {
  final String id;
  final String name;
  final String description;
  final String iconName;
  final BadgeRarity rarity;
  final DateTime earnedDate;

  const Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
    required this.rarity,
    required this.earnedDate,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'iconName': iconName,
        'rarity': rarity.name,
        'earnedDate': earnedDate.toIso8601String(),
      };

  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      iconName: json['iconName'] ?? 'military_tech',
      rarity: BadgeRarity.values.firstWhere(
        (e) => e.name == json['rarity'],
        orElse: () => BadgeRarity.bronze,
      ),
      earnedDate: json['earnedDate'] != null
          ? DateTime.parse(json['earnedDate'])
          : DateTime.now(),
    );
  }
}

enum ArtifactRarity {
  common,
  rare,
  epic,
  legendary,
}

class DigitalArtifact {
  final String id;
  final String name;
  final String description;
  final String monumentId;
  final ArtifactRarity rarity;
  final String emoji;
  final DateTime earnedDate;

  const DigitalArtifact({
    required this.id,
    required this.name,
    required this.description,
    required this.monumentId,
    required this.rarity,
    required this.emoji,
    required this.earnedDate,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'monumentId': monumentId,
        'rarity': rarity.name,
        'emoji': emoji,
        'earnedDate': earnedDate.toIso8601String(),
      };

  factory DigitalArtifact.fromJson(Map<String, dynamic> json) {
    return DigitalArtifact(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      monumentId: json['monumentId'] ?? '',
      rarity: ArtifactRarity.values.firstWhere(
        (e) => e.name == json['rarity'],
        orElse: () => ArtifactRarity.common,
      ),
      emoji: json['emoji'] ?? '🏺',
      earnedDate: json['earnedDate'] != null
          ? DateTime.parse(json['earnedDate'])
          : DateTime.now(),
    );
  }
}

class LeaderboardEntry {
  final String userId;
  final String displayName;
  final int totalPoints;
  final int badgeCount;

  const LeaderboardEntry({
    required this.userId,
    required this.displayName,
    required this.totalPoints,
    required this.badgeCount,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'displayName': displayName,
        'totalPoints': totalPoints,
        'badgeCount': badgeCount,
      };

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: json['userId'] ?? '',
      displayName: json['displayName'] ?? 'Explorer',
      totalPoints: json['totalPoints'] ?? 0,
      badgeCount: json['badgeCount'] ?? 0,
    );
  }
}
