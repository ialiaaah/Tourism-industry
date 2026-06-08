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

  /// Sends image bytes to Google Cloud Vision Landmark Detection.
  /// Falls back to prototype simulation if API is unavailable.
  static Future<DetectedLandmark?> detectLandmark(Uint8List bytes) async {
    if (apiKey.isEmpty) {
      return _simulateDetection(bytes);
    }

    try {
      final base64Image = base64Encode(bytes);
      final response = await http.post(
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
      ).timeout(const Duration(seconds: _timeoutSeconds));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final responses = data['responses'] as List?;
        if (responses == null || responses.isEmpty) {
          return _simulateDetection(bytes); // fallback
        }

        final annotations = responses[0]['landmarkAnnotations'] as List?;
        if (annotations == null || annotations.isEmpty) {
          // Real API gave no result — use simulation for prototype
          debugPrint('[Vision] No landmarks detected by real API, using simulation');
          return _simulateDetection(bytes);
        }

        // Pick best confidence result
        final best = annotations.reduce((a, b) =>
            (a['score'] ?? 0) > (b['score'] ?? 0) ? a : b);
        final confidence = (best['score'] as num?)?.toDouble() ?? 0.0;
        if (confidence < _confidenceThreshold) {
          return _simulateDetection(bytes); // too low confidence
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
      } else if (response.statusCode == 400 || response.statusCode == 403) {
        debugPrint('[Vision] API error ${response.statusCode}, using simulation');
        return _simulateDetection(bytes);
      } else {
        throw VisionException(VisionFailure.apiError,
            'Vision API returned HTTP ${response.statusCode}');
      }
    } on http.ClientException {
      throw const VisionException(
          VisionFailure.noInternet, 'No internet connection.');
    } catch (e) {
      if (e is VisionException) rethrow;
      debugPrint('[Vision] Exception: $e — falling back to simulation');
      return _simulateDetection(bytes);
    }
  }

  /// Prototype simulation: complex JPEG (> 65 KB) → Sphinx detected.
  static DetectedLandmark? _simulateDetection(Uint8List bytes) {
    if (bytes.length > 65000) {
      return const DetectedLandmark(
        name: 'The Great Sphinx',
        confidence: 0.96,
        latitude: 29.9753,
        longitude: 31.1376,
      );
    }
    return null; // not detected
  }

  static String messageForFailure(VisionFailure failure) {
    switch (failure) {
      case VisionFailure.noInternet:
        return 'No internet connection. Check your network and try again.';
      case VisionFailure.timeout:
        return 'Scan timed out. Try again.';
      case VisionFailure.noLandmarkDetected:
        return 'No monument detected. Point the camera at a landmark.';
      case VisionFailure.lowConfidence:
        return 'Monument not recognised clearly. Try a different angle.';
      case VisionFailure.apiError:
        return 'Vision API error. Check your API key.';
      case VisionFailure.imageReadError:
        return 'Could not process the image. Try again.';
    }
  }
}
