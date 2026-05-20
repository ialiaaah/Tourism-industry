import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import '../models/models.dart';

/// Firestore-backed service for all tour data operations.
/// Uses anonymous auth on web so all features work without manual sign-in.
class FirestoreService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Tour? _currentJoinedTour;
  List<Stamp> _collectedStamps = [];
  bool _initialized = false;

  Tour? get currentJoinedTour => _currentJoinedTour;
  List<Stamp> get collectedStamps => _collectedStamps;
  String? get currentUserId => _auth.currentUser?.uid;
  bool get isInitialized => _initialized;

  /// Seed demo tours and load user stamps.
  /// Authentication is handled by AuthService.
  Future<void> ensureInitialized() async {
    if (_initialized) return;

    debugPrint('✅ FirestoreService initializing (user: ${_auth.currentUser?.uid})');

    // Seed demo tours if none exist yet
    await _seedDemoToursIfNeeded();

    // Load user stamps
    await _loadUserStamps();

    _initialized = true;
    notifyListeners();
  }

  /// Seeds the two demo tours into Firestore if the tours collection is empty.
  Future<void> _seedDemoToursIfNeeded() async {
    try {
      final existing = await _db.collection('tours').limit(1).get();
      if (existing.docs.isNotEmpty) {
        debugPrint('📦 Tours already exist in Firestore, skipping seed.');
        return;
      }

      debugPrint('🌱 Seeding demo tours into Firestore...');

      final demoTours = [
        Tour(
          id: 'demo_tour_1',
          title: 'Giza Plateau Experience',
          description: 'A breathtaking journey through the wonders of Giza.',
          accessCode: 'GIZA01',
          stops: [
            Stop(
              id: 'stop_1',
              name: 'Great Pyramid of Giza',
              description:
                  'One of the Seven Wonders of the Ancient World and the oldest and largest of the three pyramids in the Giza Necropolis.',
              imagePath: 'assets/images/pyramid.jpg',
              arSnippet:
                  'Built around 2560 BCE, the Great Pyramid stood as the world\'s tallest man-made structure for over 3,800 years. It contains approximately 2.3 million stone blocks.',
              quiz: QuizQuestion(
                question:
                    'For how many years was the Great Pyramid the tallest man-made structure?',
                options: [
                  '1,000 years',
                  '2,000 years',
                  '3,800 years',
                  '5,000 years'
                ],
                correctOptionIndex: 2,
              ),
            ),
            Stop(
              id: 'stop_2',
              name: 'Great Sphinx of Giza',
              description:
                  'A limestone statue of a reclining sphinx with a human head and a lion\'s body, the largest monolith statue in the world.',
              imagePath: 'assets/images/sphinx.jpg',
              arSnippet:
                  'The Sphinx is believed to have been built during the reign of Pharaoh Khafre (2558–2532 BC). Its face is thought to represent the Pharaoh himself.',
              quiz: QuizQuestion(
                question:
                    'Whose face does the Sphinx is traditionally believed to represent?',
                options: ['Ramesses II', 'Tutankhamun', 'Khafre', 'Khufu'],
                correctOptionIndex: 2,
              ),
            ),
          ],
        ),
        Tour(
          id: 'demo_tour_2',
          title: 'Luxor Temple Tour',
          description: 'Explore the magnificent temples of ancient Thebes.',
          accessCode: 'LUXOR1',
          stops: [
            Stop(
              id: 'stop_3',
              name: 'Karnak Temple',
              description:
                  'The largest ancient religious site in the world, dedicated to the god Amun.',
              imagePath: 'assets/images/karnak.jpg',
              arSnippet:
                  'Karnak was built over a period of 1,500 years by successive pharaohs. It once housed 80,000 priests and servants.',
              quiz: QuizQuestion(
                question: 'To which god is Karnak Temple dedicated?',
                options: ['Ra', 'Osiris', 'Amun', 'Horus'],
                correctOptionIndex: 2,
              ),
            ),
            Stop(
              id: 'stop_4',
              name: 'Valley of the Kings',
              description:
                  'A valley in Egypt where, for a period of nearly 500 years, rock-cut tombs were excavated for pharaohs.',
              imagePath: 'assets/images/valley.jpg',
              arSnippet:
                  'The Valley of the Kings contains 63 known tombs. The most famous discovery here was Tutankhamun\'s tomb in 1922 by Howard Carter.',
              quiz: QuizQuestion(
                question:
                    'In what year was Tutankhamun\'s tomb discovered?',
                options: ['1899', '1911', '1922', '1935'],
                correctOptionIndex: 2,
              ),
            ),
          ],
        ),
      ];

      for (final tour in demoTours) {
        await _db.collection('tours').doc(tour.id).set({
          ...tour.toJson(),
          'guideId': 'system_seed',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      debugPrint('✅ Demo tours seeded successfully');
    } catch (e) {
      debugPrint('⚠️ Error seeding demo tours: $e');
    }
  }

  // ---------- User Stamps ----------

  Future<void> _loadUserStamps() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      final snapshot =
          await _db.collection('users').doc(uid).collection('stamps').get();
      _collectedStamps =
          snapshot.docs.map((d) => Stamp.fromJson(d.data())).toList();
      debugPrint('📦 Loaded ${_collectedStamps.length} existing stamps');
    } catch (e) {
      debugPrint('⚠️ _loadUserStamps error: $e');
    }
  }

  // ---------- Guide Actions ----------

  Future<String> createTour({
    required String title,
    required String description,
    required List<Stop> stops,
  }) async {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    final code = String.fromCharCodes(Iterable.generate(
        6, (_) => chars.codeUnitAt(random.nextInt(chars.length))));

    final uid = _auth.currentUser?.uid ?? 'anonymous';
    final newId = 't_${DateTime.now().millisecondsSinceEpoch}';
    final newTour = Tour(
        id: newId,
        title: title,
        description: description,
        accessCode: code,
        stops: stops);

    await _db.collection('tours').doc(newId).set({
      ...newTour.toJson(),
      'guideId': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    debugPrint('✅ Tour "$title" created with code: $code (stored at tours/$newId)');
    return code;
  }

  // ---------- Tourist Actions ----------

  Future<bool> joinTour(String accessCode) async {
    try {
      final q = await _db
          .collection('tours')
          .where('accessCode', isEqualTo: accessCode.toUpperCase())
          .limit(1)
          .get();

      if (q.docs.isNotEmpty) {
        _currentJoinedTour = Tour.fromJson(q.docs.first.data());
        await _loadUserStamps();
        notifyListeners();
        debugPrint('✅ Joined tour: ${_currentJoinedTour?.title}');
        return true;
      }

      debugPrint('⚠️ No tour found with code: $accessCode');
      return false;
    } catch (e) {
      debugPrint('❌ Error joining tour: $e');
      return false;
    }
  }

  void leaveTour() {
    _currentJoinedTour = null;
    _collectedStamps.clear();
    notifyListeners();
  }

  Future<bool> submitQuizAnswer(
      String stopId, String stopName, int selectedIndex, QuizQuestion quiz) async {
    if (quiz.correctOptionIndex == selectedIndex) {
      if (!_collectedStamps.any((s) => s.stopId == stopId)) {
        final newStamp =
            Stamp(stopId: stopId, stopName: stopName, dateEarned: DateTime.now());

        final uid = _auth.currentUser?.uid;
        if (uid != null) {
          await _db
              .collection('users')
              .doc(uid)
              .collection('stamps')
              .add(newStamp.toJson());
          debugPrint('✅ Stamp saved to Firestore for stop: $stopName');
        }

        _collectedStamps.add(newStamp);
        notifyListeners();
      }
      return true;
    }
    return false;
  }

  Future<void> askQuestion(String stopId, String questionText) async {
    if (_currentJoinedTour == null) return;

    final uid = _auth.currentUser?.uid ?? 'anonymous';
    final question = TouristQuestion(
      tourId: _currentJoinedTour!.id,
      stopId: stopId,
      questionText: questionText,
      timestamp: DateTime.now(),
    );

    await _db.collection('questions').add({
      ...question.toJson(),
      'touristId': uid,
    });
    debugPrint('✅ Question saved to Firestore for stop: $stopId');
  }
}
