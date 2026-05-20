import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'screens/heritage_home_screen.dart';
import 'screens/landing_screen.dart';

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
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0B1E35),
          primary: const Color(0xFF0B1E35),
          secondary: const Color(0xFFCBA153),
          tertiary: const Color(0xFFB41E2D),
          surface: const Color(0xFFF9F6F0),
        ),
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
        appBarTheme: AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: const Color(0xFF0B1E35),
          foregroundColor: const Color(0xFFCBA153),
          titleTextStyle: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFCBA153),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFCBA153),
            foregroundColor: const Color(0xFF0B1E35),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF0B1E35),
            side: const BorderSide(color: Color(0xFF0B1E35), width: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white, elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        ),
      ),
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
