// Basic widget test that compiles with the TourismApp class

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tourism_prototype/main.dart';
import 'package:tourism_prototype/services/auth_service.dart';
import 'package:tourism_prototype/services/firestore_service.dart';
import 'package:tourism_prototype/services/game_progress_service.dart';

class FakeAuthService extends ChangeNotifier implements AuthService {
  @override
  bool get isLoggedIn => false;

  @override
  bool get isLoading => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeFirestoreService extends ChangeNotifier implements FirestoreService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeGameProgressService extends ChangeNotifier implements GameProgressService {
  @override
  int get totalPoints => 0;

  @override
  List<String> get scannedMonuments => const [];

  @override
  List<String> get completedMissions => const [];

  @override
  Map<String, List<String>> get unlockedHotspots => const {};

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('App compiles and runs without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthService>.value(value: FakeAuthService()),
          ChangeNotifierProvider<FirestoreService>.value(value: FakeFirestoreService()),
          ChangeNotifierProvider<GameProgressService>.value(value: FakeGameProgressService()),
        ],
        child: const TourismApp(firebaseReady: false),
      ),
    );
    // Verify that the app widget builds successfully
    expect(find.byType(TourismApp), findsOneWidget);
  });
}
