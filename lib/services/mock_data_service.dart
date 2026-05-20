import 'package:flutter/material.dart';
import 'dart:math';
import '../models/models.dart';

class MockDataService extends ChangeNotifier {
  final List<Tour> _allTours = [];
  Tour? _currentJoinedTour;
  final List<Stamp> _collectedStamps = [];
  final List<TouristQuestion> _submittedQuestions = [];

  MockDataService() {
    _initDummyData();
  }

  // Getters
  List<Tour> get allTours => _allTours;
  Tour? get currentJoinedTour => _currentJoinedTour;
  List<Stamp> get collectedStamps => _collectedStamps;
  List<TouristQuestion> get submittedQuestions => _submittedQuestions;

  void _initDummyData() {
    _allTours.add(
      Tour(
        id: 't1',
        title: 'Giza Necropolis Tour',
        description: 'Explore the ancient wonders of the Egyptian civilization.',
        accessCode: 'EGYPT123',
        stops: [
          Stop(
            id: 's1',
            name: 'Great Pyramid of Giza',
            description: 'The oldest and largest of the three pyramids in the Giza pyramid complex bordering present-day Giza in Greater Cairo, Egypt.',
            imagePath: 'assets/dummy_pyramid.jpg',
            arSnippet: 'Khufu reigned from 2589 to 2566 B.C. The Great Pyramid took approximately 20 years to build and consists of an estimated 2.3 million stone blocks.',
            quiz: QuizQuestion(
              question: 'Who was the Great Pyramid built for?',
              options: ['Khafre', 'Khufu', 'Menkaure', 'Ramses II'],
              correctOptionIndex: 1,
            ),
          ),
          Stop(
            id: 's2',
            name: 'Great Sphinx of Giza',
            description: 'A limestone statue of a reclining sphinx, a mythical creature with the body of a lion and the head of a human.',
            imagePath: 'assets/dummy_sphinx.jpg',
            arSnippet: 'The Sphinx is generally believed to represent pharaoh Khafre. It measures 73 meters (240 ft) long from paw to tail.',
            quiz: QuizQuestion(
              question: 'Which pharaoh is the Sphinx believed to represent?',
              options: ['Khufu', 'Khafre', 'Tutankhamun', 'Akhenaten'],
              correctOptionIndex: 1,
            ),
          ),
        ],
      ),
    );
  }

  // Guide Actions
  String createTour({
    required String title,
    required String description,
    required List<Stop> stops,
  }) {
    final newId = 't_${DateTime.now().millisecondsSinceEpoch}';
    // Generate a random 6-character access code
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    final code = String.fromCharCodes(Iterable.generate(
        6, (_) => chars.codeUnitAt(random.nextInt(chars.length))));

    final newTour = Tour(
      id: newId,
      title: title,
      description: description,
      accessCode: code,
      stops: stops,
    );

    _allTours.add(newTour);
    notifyListeners();
    return code;
  }

  // Tourist Actions
  bool joinTour(String accessCode) {
    try {
      final tour = _allTours.firstWhere(
        (t) => t.accessCode.toUpperCase() == accessCode.toUpperCase()
      );
      _currentJoinedTour = tour;
      notifyListeners();
      return true;
    } catch (e) {
      return false; // Not found
    }
  }

  void leaveTour() {
    _currentJoinedTour = null;
    notifyListeners();
  }

  bool submitQuizAnswer(String stopId, String stopName, int selectedIndex, QuizQuestion quiz) {
    if (quiz.correctOptionIndex == selectedIndex) {
      // Check if already collected
      if (!_collectedStamps.any((stamp) => stamp.stopId == stopId)) {
        _collectedStamps.add(Stamp(
          stopId: stopId,
          stopName: stopName,
          dateEarned: DateTime.now(),
        ));
        notifyListeners();
      }
      return true;
    }
    return false;
  }

  void askQuestion(String stopId, String questionText) {
    if (_currentJoinedTour != null) {
      _submittedQuestions.add(TouristQuestion(
        tourId: _currentJoinedTour!.id,
        stopId: stopId,
        questionText: questionText,
        timestamp: DateTime.now(),
      ));
      notifyListeners();
    }
  }
}
