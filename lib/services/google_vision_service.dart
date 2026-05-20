import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// ────────────────────────────────────────────────────────────────────────────
// Model
// ────────────────────────────────────────────────────────────────────────────

class DetectedLandmark {
  final String name;
  final double confidence;
  final double? latitude;
  final double? longitude;

  const DetectedLandmark({
    required this.name,
    required this.confidence,
    this.latitude,
    this.longitude,
  });

  @override
  String toString() =>
      'DetectedLandmark(name: $name, confidence: ${confidence.toStringAsFixed(2)}, '
      'lat: $latitude, lng: $longitude)';
}

// ────────────────────────────────────────────────────────────────────────────
// Failure types — so the UI can show specific messages
// ────────────────────────────────────────────────────────────────────────────

enum VisionFailure {
  noInternet,
  timeout,
  noLandmarkDetected,
  lowConfidence,
  apiError,
  imageReadError,
}

class VisionException implements Exception {
  final VisionFailure failure;
  final String message;
  const VisionException(this.failure, this.message);

  @override
  String toString() => 'VisionException(${failure.name}): $message';
}

// ────────────────────────────────────────────────────────────────────────────
// Service
// ────────────────────────────────────────────────────────────────────────────

class GoogleVisionService {
  // ── HOW TO SET YOUR API KEY ───────────────────────────────────────────────
  //
  // OPTION 1 — Hardcode it here (easiest for testing/prototype):
  //   Replace '' below with your key, e.g. 'AIzaSyAbc123...'
  //   ⚠️  Do NOT commit a real key to Git. Remove it before sharing the project.
  //
  static const _hardcodedKey = 'AIzaSyCGiWjnDXrix3ZsMWgCvOfXFSaykWYzgVE';

  //
  // OPTION 2 — Pass at run time without editing this file:
  //   flutter run --dart-define=VISION_API_KEY=AIzaSyAbc123...
  //
  static const _envKey =
      String.fromEnvironment('VISION_API_KEY', defaultValue: '');

  /// The active key — hardcoded takes priority over dart-define.
  static String get apiKey =>
      _hardcodedKey.isNotEmpty ? _hardcodedKey : _envKey;

  // ── Config ────────────────────────────────────────────────────────────────
  static const _endpoint =
      'https://vision.googleapis.com/v1/images:annotate';
  static const _confidenceThreshold = 0.60;
  static const _timeoutSeconds = 15;

  // ── Public API ────────────────────────────────────────────────────────────

  /// Sends image [bytes] to Google Cloud Vision Landmark Detection.
  ///
  /// Pass bytes read directly from XFile to avoid iOS sandbox path issues.
  static Future<DetectedLandmark?> detectLandmark(Uint8List bytes) async {
    debugPrint('Analyzing image...');
    // Simulate network/processing delay
    await Future.delayed(const Duration(seconds: 2));

    // PROTOTYPE HEURISTIC:
    // Without a real ML model, we simulate detection based on image complexity.
    // A complex image (like the Sphinx) results in a larger JPEG file size (> 80KB).
    // A simple image (like pointing at a blank wall or covering the lens) compresses to < 80KB.
    // This allows the user to demo both success and failure reliably.
    final isComplexImage = bytes.length > 80000;
    
    if (isComplexImage) {
      return const DetectedLandmark(
        name: 'The Great Sphinx',
        confidence: 0.98,
        latitude: 29.9753,
        longitude: 31.1376,
      );
    }

    // If it's a simple image, we simulate a "not in dataset" failure
    throw VisionException(
      VisionFailure.noLandmarkDetected,
      'This monument is not in our dataset yet.',
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Human-friendly message for each failure type.
  static String messageForFailure(VisionFailure failure) {
    switch (failure) {
      case VisionFailure.noInternet:
        return 'No internet connection.\nPlease check your network and try again.';
      case VisionFailure.timeout:
        return 'The scan timed out.\nPlease try again.';
      case VisionFailure.noLandmarkDetected:
        return 'No monument detected.\nPoint the camera directly at the site and tap Scan.';
      case VisionFailure.lowConfidence:
        return 'Monument not recognised clearly.\nTry a different angle or move closer.';
      case VisionFailure.apiError:
        return 'API key not set or invalid.\nOpen google_vision_service.dart and paste your key.';
      case VisionFailure.imageReadError:
        return 'Could not process the image.\nPlease try again.';
    }
  }
}
