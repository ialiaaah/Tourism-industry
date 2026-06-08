import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ar_models.dart';
import 'monument_data_service.dart';

class GameProgressService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  int _totalPoints = 0;
  List<String> _scannedMonuments = [];
  List<String> _completedMissions = [];
  Map<String, List<String>> _unlockedHotspots = {}; // monumentId -> list of hotspotIds
  List<Badge> _badges = [];
  List<DigitalArtifact> _collectedArtifacts = [];
  int _currentStreak = 0;
  DateTime? _lastActiveDate;

  int get totalPoints => _totalPoints;
  List<String> get scannedMonuments => _scannedMonuments;
  List<String> get completedMissions => _completedMissions;
  Map<String, List<String>> get unlockedHotspots => _unlockedHotspots;
  List<Badge> get badges => _badges;
  List<DigitalArtifact> get collectedArtifacts => _collectedArtifacts;
  int get currentStreak => _currentStreak;

  String? get _uid => _auth.currentUser?.uid;

  GameProgressService() {
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        loadProgress();
      } else {
        _resetLocalState();
      }
    });
  }

  void _resetLocalState() {
    _totalPoints = 0;
    _scannedMonuments = [];
    _completedMissions = [];
    _unlockedHotspots = {};
    _badges = [];
    _collectedArtifacts = [];
    _currentStreak = 0;
    _lastActiveDate = null;
    notifyListeners();
  }

  // Load user progress from Firestore and local cache
  Future<void> loadProgress() async {
    final userId = _uid;
    if (userId == null) return;

    try {
      // 1. Try to load from local SharedPreferences first (for instant load)
      final prefs = await SharedPreferences.getInstance();
      _totalPoints = prefs.getInt('progress_points_$userId') ?? 0;
      _scannedMonuments = prefs.getStringList('progress_scanned_$userId') ?? [];
      _completedMissions = prefs.getStringList('progress_missions_$userId') ?? [];
      _currentStreak = prefs.getInt('progress_streak_$userId') ?? 0;
      
      final savedStreakDate = prefs.getString('progress_streak_date_$userId');
      if (savedStreakDate != null) {
        _lastActiveDate = DateTime.parse(savedStreakDate);
      }

      // Load unlocked hotspots
      final hotspotKeys = prefs.getStringList('progress_hotspots_keys_$userId') ?? [];
      for (final monumentId in hotspotKeys) {
        _unlockedHotspots[monumentId] = prefs.getStringList('progress_hotspots_${userId}_$monumentId') ?? [];
      }

      // Check and update streak on load
      _updateStreakLogic();

      notifyListeners();

      // 2. Load from Firestore
      final doc = await _db.collection('users').doc(userId).collection('gameProgress').doc('main').get();
      if (doc.exists) {
        final data = doc.data()!;
        _totalPoints = data['totalPoints'] ?? 0;
        _scannedMonuments = List<String>.from(data['scannedMonuments'] ?? []);
        _completedMissions = List<String>.from(data['completedMissions'] ?? []);
        _currentStreak = data['currentStreak'] ?? 0;
        if (data['lastActiveDate'] != null) {
          _lastActiveDate = (data['lastActiveDate'] as Timestamp).toDate();
        }

        // Unlocked hotspots
        if (data['unlockedHotspots'] != null) {
          final hsMap = data['unlockedHotspots'] as Map<String, dynamic>;
          _unlockedHotspots = hsMap.map((key, value) => MapEntry(key, List<String>.from(value)));
        }

        // Badges
        final badgeSnap = await _db.collection('users').doc(userId).collection('badges').get();
        _badges = badgeSnap.docs.map((d) => Badge.fromJson(d.data())).toList();

        // Artifacts
        final artSnap = await _db.collection('users').doc(userId).collection('artifacts').get();
        _collectedArtifacts = artSnap.docs.map((d) => DigitalArtifact.fromJson(d.data())).toList();

        // Save back to prefs for offline access
        await _saveToPrefs(userId);
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading progress from Firestore: $e');
    }
  }

  Future<void> _saveToPrefs(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('progress_points_$userId', _totalPoints);
      await prefs.setStringList('progress_scanned_$userId', _scannedMonuments);
      await prefs.setStringList('progress_missions_$userId', _completedMissions);
      await prefs.setInt('progress_streak_$userId', _currentStreak);
      if (_lastActiveDate != null) {
        await prefs.setString('progress_streak_date_$userId', _lastActiveDate!.toIso8601String());
      }

      await prefs.setStringList('progress_hotspots_keys_$userId', _unlockedHotspots.keys.toList());
      for (final monumentId in _unlockedHotspots.keys) {
        await prefs.setStringList('progress_hotspots_${userId}_$monumentId', _unlockedHotspots[monumentId]!);
      }
    } catch (e) {
      debugPrint('Error saving to SharedPreferences: $e');
    }
  }

  // Update Firestore sync
  Future<void> _syncToFirestore() async {
    final userId = _uid;
    if (userId == null) return;

    try {
      await _saveToPrefs(userId);

      await _db.collection('users').doc(userId).collection('gameProgress').doc('main').set({
        'totalPoints': _totalPoints,
        'scannedMonuments': _scannedMonuments,
        'completedMissions': _completedMissions,
        'unlockedHotspots': _unlockedHotspots,
        'currentStreak': _currentStreak,
        'lastActiveDate': _lastActiveDate != null ? Timestamp.fromDate(_lastActiveDate!) : null,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error syncing progress to Firestore: $e');
    }
  }

  void _updateStreakLogic() {
    final now = DateTime.now();
    if (_lastActiveDate == null) {
      _currentStreak = 1;
      _lastActiveDate = now;
    } else {
      final diff = now.difference(_lastActiveDate!).inDays;
      if (diff == 1) {
        _currentStreak++;
        _lastActiveDate = now;
      } else if (diff > 1) {
        _currentStreak = 1;
        _lastActiveDate = now;
      }
    }
  }

  // Award Points
  Future<void> awardPoints(int points, String reason) async {
    _totalPoints += points;
    _updateStreakLogic();
    notifyListeners();
    await _syncToFirestore();
  }

  // Scan Monument
  Future<void> scanMonument(String monumentId) async {
    if (!_scannedMonuments.contains(monumentId)) {
      _scannedMonuments.add(monumentId);
      await awardPoints(100, 'Scanned new monument: $monumentId');
      await checkAndAwardBadges();
    }
  }

  // Unlock Hotspot
  Future<bool> unlockHotspot(String monumentId, String hotspotId) async {
    if (_unlockedHotspots[monumentId] == null) {
      _unlockedHotspots[monumentId] = [];
    }

    if (!_unlockedHotspots[monumentId]!.contains(hotspotId)) {
      _unlockedHotspots[monumentId]!.add(hotspotId);
      await awardPoints(20, 'Discovered hotspot $hotspotId');
      await checkAndAwardBadges();
      notifyListeners();
      return true; // Newly unlocked
    }
    return false; // Already unlocked
  }

  // Complete Mission
  Future<void> completeMission(TreasureHuntMission mission) async {
    if (!_completedMissions.contains(mission.id)) {
      _completedMissions.add(mission.id);
      await awardPoints(mission.rewardPoints, 'Completed mission: ${mission.title}');

      // Award artifact if defined
      if (mission.artifactReward.isNotEmpty) {
        await _awardArtifact(mission.id, mission.artifactReward, mission.monumentId);
      }

      await checkAndAwardBadges();
      notifyListeners();
    }
  }

  Future<void> _awardArtifact(String missionId, String name, String monumentId) async {
    final userId = _uid;
    final artifactId = 'art_${missionId}_${DateTime.now().millisecondsSinceEpoch}';
    final rarity = missionId.hashCode % 4 == 0
        ? ArtifactRarity.legendary
        : (missionId.hashCode % 3 == 0 ? ArtifactRarity.epic : ArtifactRarity.rare);

    final emojis = ['🏺', '👑', '📜', '⚔️', '🪙', '💍', '🧿', '⚜️'];
    final emoji = emojis[missionId.hashCode % emojis.length];

    final artifact = DigitalArtifact(
      id: artifactId,
      name: name,
      description: 'A legendary souvenir discovered during the exploration of monument $monumentId.',
      monumentId: monumentId,
      rarity: rarity,
      emoji: emoji,
      earnedDate: DateTime.now(),
    );

    _collectedArtifacts.add(artifact);

    if (userId != null) {
      try {
        await _db.collection('users').doc(userId).collection('artifacts').doc(artifactId).set(artifact.toJson());
      } catch (e) {
        debugPrint('Error saving artifact to Firestore: $e');
      }
    }
  }

  // Check and Award Badges
  Future<void> checkAndAwardBadges() async {
    final userId = _uid;
    final earnedIds = _badges.map((b) => b.id).toList();

    // Check conditions for badges
    final List<Badge> newBadges = [];

    // Badge 1: First Scan
    if (!earnedIds.contains('first_scan') && _scannedMonuments.isNotEmpty) {
      newBadges.add(Badge(
        id: 'first_scan',
        name: 'First Explorer Step',
        description: 'Scanned your first ancient monument!',
        iconName: 'explore',
        rarity: BadgeRarity.bronze,
        earnedDate: DateTime.now(),
      ));
    }

    // Badge 2: Scan 5 monuments
    if (!earnedIds.contains('monument_master') && _scannedMonuments.length >= 5) {
      newBadges.add(Badge(
        id: 'monument_master',
        name: 'Heritage Chronicler',
        description: 'Scanned 5 unique monuments.',
        iconName: 'menu_book',
        rarity: BadgeRarity.silver,
        earnedDate: DateTime.now(),
      ));
    }

    // Badge 3: Master Explorer (Complete 5 Hotspots)
    int totalHotspotsUnlocked = _unlockedHotspots.values.fold(0, (sum, list) => sum + list.length);
    if (!earnedIds.contains('hotspot_explorer') && totalHotspotsUnlocked >= 5) {
      newBadges.add(Badge(
        id: 'hotspot_explorer',
        name: 'Detail Detective',
        description: 'Discovered 5 deep AR monument hotspots.',
        iconName: 'location_searching',
        rarity: BadgeRarity.silver,
        earnedDate: DateTime.now(),
      ));
    }

    // Badge 4: Treasure Hunter (Complete 3 missions)
    if (!earnedIds.contains('treasure_hunter') && _completedMissions.length >= 3) {
      newBadges.add(Badge(
        id: 'treasure_hunter',
        name: 'Tomb Raider',
        description: 'Solved 3 monument treasure hunt missions.',
        iconName: 'military_tech',
        rarity: BadgeRarity.gold,
        earnedDate: DateTime.now(),
      ));
    }

    // Badge 5: High Points (1000 points)
    if (!earnedIds.contains('point_king') && _totalPoints >= 1000) {
      newBadges.add(Badge(
        id: 'point_king',
        name: 'CulturaX Legend',
        description: 'Earned over 1,000 adventure points!',
        iconName: 'workspace_premium',
        rarity: BadgeRarity.legendary,
        earnedDate: DateTime.now(),
      ));
    }

    if (newBadges.isNotEmpty) {
      _badges.addAll(newBadges);
      notifyListeners();

      if (userId != null) {
        try {
          for (final badge in newBadges) {
            await _db.collection('users').doc(userId).collection('badges').doc(badge.id).set(badge.toJson());
          }
        } catch (e) {
          debugPrint('Error saving badges to Firestore: $e');
        }
      }
    }
  }

  // Get Monument Hotspot / Mission Completion progress
  double getMonumentProgress(String monumentId) {
    final monument = MonumentDataService.monuments.firstWhere((m) => m.id == monumentId, orElse: () => null as dynamic);
    if (monument == null) return 0.0;

    int totalHotspots = monument.arHotspots.length;
    int totalMissions = monument.treasureHuntMissions.length;
    
    if (totalHotspots + totalMissions == 0) return 1.0;

    int unlocked = (_unlockedHotspots[monumentId]?.length ?? 0);
    int completedM = monument.treasureHuntMissions.where((m) => _completedMissions.contains(m.id)).length;

    return (unlocked + completedM) / (totalHotspots + totalMissions);
  }
}
