import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

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
}

enum VisionFailure {
  noInternet,
  timeout,
  noLandmarkDetected,
  lowConfidence,
  apiError,
  billingDisabled,
  imageReadError,
}

class VisionException implements Exception {
  final VisionFailure failure;
  final String message;
  const VisionException(this.failure, this.message);
  @override
  String toString() => 'VisionException(${failure.name}): $message';
}

class GoogleVisionService {
  static const _hardcodedKey = 'AIzaSyCGiWjnDXrix3ZsMWgCvOfXFSaykWYzgVE';
  static const _envKey = String.fromEnvironment('VISION_API_KEY', defaultValue: '');
  static String get apiKey => _hardcodedKey.isNotEmpty ? _hardcodedKey : _envKey;

  static const _endpoint = 'https://vision.googleapis.com/v1/images:annotate';
  static const _confidenceThreshold = 0.55;
  static const _timeoutSeconds = 15;

  /// Sends image bytes to Google Cloud Vision Landmark Detection and returns
  /// the highest-confidence landmark. This is the single source of truth —
  /// there is NO local guessing/substitution. If the API cannot confidently
  /// identify a landmark, an honest [VisionException] is thrown so the UI can
  /// tell the user exactly what happened.
  static Future<DetectedLandmark?> detectLandmark(Uint8List bytes) async {
    if (apiKey.isEmpty) {
      throw const VisionException(VisionFailure.apiError,
          'No Vision API key configured.');
    }

    final http.Response response;
    try {
      final base64Image = base64Encode(bytes);
      response = await http
          .post(
            Uri.parse('$_endpoint?key=$apiKey'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'requests': [
                {
                  'image': {'content': base64Image},
                  'features': [
                    {'type': 'LANDMARK_DETECTION', 'maxResults': 5}
                  ]
                }
              ]
            }),
          )
          .timeout(const Duration(seconds: _timeoutSeconds));
    } on http.ClientException {
      throw const VisionException(
          VisionFailure.noInternet, 'No internet connection.');
    } catch (e) {
      throw VisionException(VisionFailure.timeout, 'Network error: $e');
    }

    if (response.statusCode != 200) {
      // Surface the real reason. 403 with "billing" is the most common setup
      // problem — make it explicit instead of hiding it behind a fake result.
      final body = response.body;
      debugPrint('[Vision] HTTP ${response.statusCode}: $body');
      if (response.statusCode == 403 && body.toLowerCase().contains('billing')) {
        throw const VisionException(VisionFailure.billingDisabled,
            'Billing is not enabled on the Google Cloud project.');
      }
      throw VisionException(VisionFailure.apiError,
          'Vision API returned HTTP ${response.statusCode}.');
    }

    final data = jsonDecode(response.body);
    final responses = data['responses'] as List?;
    final annotations =
        (responses != null && responses.isNotEmpty)
            ? responses[0]['landmarkAnnotations'] as List?
            : null;

    if (annotations == null || annotations.isEmpty) {
      throw const VisionException(VisionFailure.noLandmarkDetected,
          'No landmark detected in the image.');
    }

    // Pick the highest-confidence landmark.
    final best = annotations.reduce(
        (a, b) => (a['score'] ?? 0) > (b['score'] ?? 0) ? a : b);
    final confidence = (best['score'] as num?)?.toDouble() ?? 0.0;
    if (confidence < _confidenceThreshold) {
      throw const VisionException(VisionFailure.lowConfidence,
          'Landmark recognised with low confidence.');
    }

    final locations = best['locations'] as List?;
    double? lat, lng;
    if (locations != null && locations.isNotEmpty) {
      final ll = locations[0]['latLng'];
      lat = (ll?['latitude'] as num?)?.toDouble();
      lng = (ll?['longitude'] as num?)?.toDouble();
    }

    return DetectedLandmark(
      name: best['description'] as String,
      confidence: confidence,
      latitude: lat,
      longitude: lng,
    );
  }

  static String messageForFailure(VisionFailure failure) {
    switch (failure) {
      case VisionFailure.noInternet:
        return 'No internet connection. Check your network and try again.';
      case VisionFailure.timeout:
        return 'Scan timed out. Check your connection and try again.';
      case VisionFailure.noLandmarkDetected:
        return 'No monument detected. Point the camera directly at a landmark.';
      case VisionFailure.lowConfidence:
        return 'Monument not recognised clearly. Try a closer or clearer shot.';
      case VisionFailure.apiError:
        return 'Recognition service unavailable. Please try again later.';
      case VisionFailure.billingDisabled:
        return 'Recognition service is not active. Enable billing on the '
            'Google Cloud project to turn on monument recognition.';
      case VisionFailure.imageReadError:
        return 'Could not process the image. Try again.';
    }
  }
}
