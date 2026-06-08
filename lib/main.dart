import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/game_progress_service.dart';
import 'screens/heritage_home_screen.dart';
import 'screens/landing_screen.dart';
import 'theme/app_theme.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool firebaseReady = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseReady = true;
    debugPrint('✅ Firebase initialized successfully');
  } catch (e) {
    debugPrint('Firebase init failed: $e');
  }

  final authService = AuthService();
  final firestoreService = FirestoreService();

  // Try auto-login (if session is persisted from a previous visit)
  if (firebaseReady) {
    try {
      await authService.tryAutoLogin();
      // If already logged in, initialize Firestore data
      if (authService.isLoggedIn) {
        await firestoreService.ensureInitialized();
      }
    } catch (e) {
      debugPrint('Auto-login or Firestore init failed: $e');
      // Continue anyway, user will just be logged out
    }
  }

  // Catch any widget rendering errors and show them instead of a white screen
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: Colors.red.shade900,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Something went wrong!', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text(details.exceptionAsString(), style: const TextStyle(color: Colors.yellow, fontSize: 14)),
                const SizedBox(height: 10),
                Text(details.stack.toString(), style: const TextStyle(color: Colors.white54, fontSize: 10)),
              ],
            ),
          ),
        ),
      ),
    );
  };

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authService),
        ChangeNotifierProvider.value(value: firestoreService),
        ChangeNotifierProvider(create: (_) => GameProgressService()),
      ],
      child: TourismApp(firebaseReady: firebaseReady),
    ),

  );
}

class TourismApp extends StatelessWidget {
  final bool firebaseReady;
  const TourismApp({Key? key, required this.firebaseReady}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CulturaX',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: Consumer<AuthService>(
        builder: (context, auth, _) {
          if (auth.isLoggedIn) {
            return const HeritageHomeScreen();
          }
          return const LandingScreen();
        },
      ),
    );
  }
}
