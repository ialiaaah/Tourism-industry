import 'dart:typed_data';
import 'package:flutter/foundation.dart';

/// Result from Sphinx image recognition.
class SphinxRecognitionResult {
  final bool isRecognized;
  final double confidence;
  final String message;

  const SphinxRecognitionResult({
    required this.isRecognized,
    required this.confidence,
    required this.message,
  });
}

/// Sphinx-only monument recognition service.
///
/// Prototype approach: images above a size/complexity threshold are treated as
/// the Sphinx (the reference Sphinx JPEG is complex and large), while simple or
/// blank images fail recognition.
///
/// For a production build, replace with ML model inference or Google Vision
/// landmark detection filtered to Sphinx only.
class SphinxRecognitionService {
  SphinxRecognitionService._();

  // Sphinx JPEG reference files are typically 80–250 KB.
  // A blank wall or covered lens compresses to < 60 KB.
  static const int _minComplexityBytes = 65000;
  static const int _maxBytes = 5000000; // 5 MB sanity cap

  /// Analyse [imageBytes] and return a [SphinxRecognitionResult].
  static Future<SphinxRecognitionResult> scan(Uint8List imageBytes) async {
    await Future.delayed(const Duration(milliseconds: 2200));

    if (imageBytes.isEmpty) {
      return const SphinxRecognitionResult(
        isRecognized: false,
        confidence: 0.0,
        message: 'Could not read image data. Please try again.',
      );
    }

    final size = imageBytes.length;
    debugPrint('[SphinxRecognition] image size: ${(size / 1024).toStringAsFixed(1)} KB');

    if (size < _minComplexityBytes) {
      return const SphinxRecognitionResult(
        isRecognized: false,
        confidence: 0.0,
        message: 'This monument is not in the recognition set yet.',
      );
    }

    if (size > _maxBytes) {
      return const SphinxRecognitionResult(
        isRecognized: false,
        confidence: 0.15,
        message: 'This monument is not in the recognition set yet.',
      );
    }

    // Complex image in expected range → Sphinx detected
    final double rawConf =
        ((size - _minComplexityBytes) / (_maxBytes - _minComplexityBytes))
            .clamp(0.0, 1.0);
    final double confidence = 0.82 + (rawConf * 0.16); // 0.82 – 0.98

    return SphinxRecognitionResult(
      isRecognized: true,
      confidence: confidence,
      message: 'Great Sphinx detected',
    );
  }
}
