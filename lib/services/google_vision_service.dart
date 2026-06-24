import 'package:flutter/foundation.dart';
import 'local_recognition_service.dart';

/// Monument recognition facade.
///
/// NOTE: Despite the historical name, recognition now runs FULLY ON-DEVICE via
/// [LocalRecognitionService] — there is no network call, no API key, and no
/// Google Cloud billing requirement. The public surface (DetectedLandmark /
/// VisionException / detectLandmark / messageForFailure) is kept identical so
/// the rest of the app is unchanged.
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
  /// Identify the monument in [bytes] using the on-device recognizer.
  /// Throws a [VisionException] when nothing is confidently recognised so the
  /// UI can show an honest message (same contract as before).
  static Future<DetectedLandmark?> detectLandmark(Uint8List bytes) async {
    final LocalMatch? match;
    try {
      match = await LocalRecognitionService.recognize(bytes);
    } catch (e) {
      throw VisionException(
          VisionFailure.imageReadError, 'Could not process the image: $e');
    }

    if (match == null) {
      throw const VisionException(VisionFailure.noLandmarkDetected,
          'No supported monument recognised in the image.');
    }

    return DetectedLandmark(name: match.name, confidence: match.confidence);
  }

  static String messageForFailure(VisionFailure failure) {
    switch (failure) {
      case VisionFailure.noInternet:
        return 'No internet connection. Check your network and try again.';
      case VisionFailure.timeout:
        return 'Scan timed out. Try again.';
      case VisionFailure.noLandmarkDetected:
        return 'No monument recognised. Point the camera at the Sphinx or the '
            'Pyramid of Khafre and try again.';
      case VisionFailure.lowConfidence:
        return 'Monument not recognised clearly. Try a closer or clearer shot.';
      case VisionFailure.apiError:
        return 'Recognition error. Please try again.';
      case VisionFailure.billingDisabled:
        return 'Recognition service is not active.';
      case VisionFailure.imageReadError:
        return 'Could not process the image. Try again.';
    }
  }
}
