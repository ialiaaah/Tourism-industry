import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/models.dart';

/// Handles all authentication & user-profile logic.
///
/// Auth modes:
///   1. Email/Password — returns a `User`, then we create/fetch the Firestore profile
///   2. Google Sign-In (v7 API) — returns a `User`, then we create/fetch the Firestore profile
///
/// Firestore document for each user lives at `/users/{uid}`.
class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool _googleInitialized = false;

  AppUser? _currentAppUser;
  bool _isLoading = false;

  AppUser? get currentAppUser => _currentAppUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _auth.currentUser != null && _currentAppUser != null;
  User? get firebaseUser => _auth.currentUser;

  // ─── Bootstrap ────────────────────────────────────────────────
  /// Called once at app start. If a Firebase user already exists
  /// (session persisted), we fetch their Firestore profile.
  Future<void> tryAutoLogin() async {
    final user = _auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    _currentAppUser = await _fetchUserProfile(user.uid);
    _isLoading = false;
    notifyListeners();
  }

  // ─── Email / Password ─────────────────────────────────────────
  Future<AppUser> signUpWithEmail({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      await cred.user!.updateDisplayName(name.trim());

      final appUser = AppUser(
        uid: cred.user!.uid,
        name: name.trim(),
        email: email.trim(),
        role: role,
        createdAt: DateTime.now(),
      );

      await _db.collection('users').doc(appUser.uid).set(appUser.toJson());
      debugPrint('✅ User registered: ${appUser.name} (${appUser.role.name})');

      _currentAppUser = appUser;
      return appUser;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
    UserRole? roleOverride,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      AppUser? profile = await _fetchUserProfile(cred.user!.uid);
      if (profile == null) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'No user profile found. Please register first.',
        );
      }

      if (roleOverride != null && profile.role != roleOverride) {
        profile = AppUser(
          uid: profile.uid,
          name: profile.name,
          email: profile.email,
          role: roleOverride,
          createdAt: profile.createdAt,
        );
        await _db.collection('users').doc(profile.uid).update({'role': roleOverride.name});
        debugPrint('✅ User role updated to: ${profile.role.name}');
      }

      _currentAppUser = profile;
      debugPrint('✅ User signed in: ${profile.name} (${profile.role.name})');
      return profile;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Google Sign-In (v7 API) ──────────────────────────────────
  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    // For Web, Google Sign-In requires the Web Client ID from Firebase Console.
    // Replace 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com' with your actual Web Client ID
    // found in Firebase Console -> Authentication -> Sign-in method -> Google.
    await GoogleSignIn.instance.initialize(
      clientId: '780714473574-rlet71gp38584h4pf2v35liep4nbvr5i.apps.googleusercontent.com',
    );
    _googleInitialized = true;
  }

  /// Returns `null` if the Google flow was cancelled by the user.
  /// If the user has no Firestore profile yet, we create one with the given role.
  Future<AppUser?> signInWithGoogle({UserRole? roleOverride}) async {
    _isLoading = true;
    notifyListeners();

    try {
      User user;

      if (kIsWeb) {
        // On Web, GoogleSignIn().authenticate() is unsupported. 
        // We use FirebaseAuth's signInWithPopup instead, which bypasses the need for `renderButton`
        // and allows us to keep our beautiful custom UI button.
        final googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        
        // This will pop up the standard Google login window
        final userCred = await _auth.signInWithPopup(googleProvider);
        user = userCred.user!;
      } else {
        // Native platforms (iOS / Android)
        await _ensureGoogleInitialized();
        final GoogleSignInAccount account = await GoogleSignIn.instance.authenticate();
        final GoogleSignInAuthentication googleAuth = account.authentication;
        final credential = GoogleAuthProvider.credential(idToken: googleAuth.idToken);
        final userCred = await _auth.signInWithCredential(credential);
        user = userCred.user!;
      }

      // Check if profile exists
      AppUser? profile = await _fetchUserProfile(user.uid);

      if (profile == null) {
        // First-time Google sign-in → create profile
        profile = AppUser(
          uid: user.uid,
          name: user.displayName ?? 'User',
          email: user.email ?? '',
          role: roleOverride ?? UserRole.tourist,
          createdAt: DateTime.now(),
        );
        await _db.collection('users').doc(profile.uid).set(profile.toJson());
        debugPrint(
            '✅ New Google user registered: ${profile.name} (${profile.role.name})');
      } else {
        if (roleOverride != null && profile.role != roleOverride) {
          profile = AppUser(
            uid: profile.uid,
            name: profile.name,
            email: profile.email,
            role: roleOverride,
            createdAt: profile.createdAt,
          );
          await _db.collection('users').doc(profile.uid).update({'role': roleOverride.name});
          debugPrint('✅ Google user role updated to: ${profile.role.name}');
        } else {
          debugPrint(
              '✅ Existing Google user signed in: ${profile.name} (${profile.role.name})');
        }
      }

      _currentAppUser = profile;
      return profile;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        // User cancelled — just return null
        return null;
      }
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Sign Out ─────────────────────────────────────────────────
  Future<void> signOut() async {
    await _auth.signOut();
    try {
      if (_googleInitialized) {
        await GoogleSignIn.instance.signOut();
      }
    } catch (_) {}
    _currentAppUser = null;
    notifyListeners();
    debugPrint('✅ Signed out');
  }

  // ─── Helpers ──────────────────────────────────────────────────
  Future<AppUser?> _fetchUserProfile(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return AppUser.fromJson(doc.data()!);
      }
    } catch (e) {
      debugPrint('⚠️ Error fetching user profile: $e');
    }
    return null;
  }
}
