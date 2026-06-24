import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;

/// On-device monument recognition — NO network, NO billing, NO API key.
///
/// How it works:
///   1. Each supported monument has a small set of bundled reference photos.
///   2. Every image (reference or freshly captured) is reduced to a compact
///      perceptual "signature": the picture is downscaled, converted to
///      grayscale, split into a 16x16 grid of average-brightness cells, then
///      mean-subtracted and L2-normalized. That makes it tolerant of overall
///      brightness/contrast and resolution differences.
///   3. A captured photo is compared (cosine similarity) against every
///      reference signature; the monument with the closest reference wins,
///      provided it clears an acceptance threshold.
///
/// Because the SAME Dart code computes both the reference and the query
/// signatures, the pipeline is fully self-consistent and deterministic.
class LocalRecognitionService {
  static const int _grid = 16;          // 16x16 signature grid
  static const int _workSize = 256;     // longest side used for analysis
  // Live-camera shots (especially of a screen) are noisier than the clean
  // reference photos, so the bar to accept a match is intentionally lenient.
  static const double _acceptThreshold = 0.30; // min cosine to accept a match

  /// Curated, visually clean reference images per monument id.
  ///
  /// Deliberately excludes the ambiguous "Sphinx-with-pyramid-behind" frames
  /// (sphinx_ref1/ref4, khafre_pyramid_ref6/ref7) that contain BOTH monuments
  /// and would otherwise blur the two classes together.
  static const Map<String, List<String>> _references = {
    'sphinx': [
      'assets/monuments/sphinx.jpg',
      'assets/monuments/sphinx_ref0.jpg',
      'assets/monuments/sphinx_ref2.jpg',
      'assets/monuments/sphinx_ref3.jpg',
      'assets/monuments/sphinx_ref5.jpg',
      'assets/monuments/sphinx_ref6.jpg',
      'assets/monuments/sphinx_ref7.jpg',
    ],
    'khafre_pyramid': [
      'assets/monuments/khafre_pyramid.jpg',
      'assets/monuments/khafre_pyramid_ref0.jpg',
      'assets/monuments/khafre_pyramid_ref1.jpg',
      'assets/monuments/khafre_pyramid_ref2.jpg',
      'assets/monuments/khafre_pyramid_ref3.jpg',
      'assets/monuments/khafre_pyramid_ref4.jpg',
      'assets/monuments/khafre_pyramid_ref5.jpg',
    ],
  };

  /// Canonical display name per id — fed to
  /// MonumentDataService.findByDetectedName() so routing stays unchanged.
  static const Map<String, String> _canonicalName = {
    'sphinx': 'The Great Sphinx',
    'khafre_pyramid': 'Pyramid of Khafre',
  };

  /// monumentId -> list of reference signatures (lazy-loaded, then cached).
  static Map<String, List<List<double>>>? _refSignatures;

  static Future<void> _ensureLoaded() async {
    if (_refSignatures != null) return;
    final loaded = <String, List<List<double>>>{};
    for (final entry in _references.entries) {
      final sigs = <List<double>>[];
      for (final path in entry.value) {
        try {
          final data = await rootBundle.load(path);
          final sig = signatureFromBytes(data.buffer.asUint8List());
          if (sig != null) sigs.add(sig);
        } catch (e) {
          debugPrint('[LocalRecognition] could not load $path: $e');
        }
      }
      loaded[entry.key] = sigs;
      debugPrint('[LocalRecognition] loaded ${sigs.length}/${entry.value.length} '
          'reference signatures for "${entry.key}"');
    }
    _refSignatures = loaded;
  }

  /// Compute the normalized perceptual signature for raw image bytes.
  /// Returns null if the bytes cannot be decoded.
  static List<double>? signatureFromBytes(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;

    // Respect EXIF orientation, then downscale so analysis cost is bounded
    // and identical for every input regardless of original resolution.
    final oriented = img.bakeOrientation(decoded);
    final scale = _workSize / math.max(oriented.width, oriented.height);
    final tw = (oriented.width * scale).round().clamp(1, _workSize);
    final th = (oriented.height * scale).round().clamp(1, _workSize);
    final image = img.copyResize(oriented,
        width: tw, height: th, interpolation: img.Interpolation.average);

    final w = image.width, h = image.height;
    final cells = List<double>.filled(_grid * _grid, 0);
    for (int cy = 0; cy < _grid; cy++) {
      final y0 = cy * h ~/ _grid;
      final y1 = math.max(y0 + 1, (cy + 1) * h ~/ _grid);
      for (int cx = 0; cx < _grid; cx++) {
        final x0 = cx * w ~/ _grid;
        final x1 = math.max(x0 + 1, (cx + 1) * w ~/ _grid);
        double sum = 0;
        int n = 0;
        for (int yy = y0; yy < y1; yy++) {
          for (int xx = x0; xx < x1; xx++) {
            final p = image.getPixel(xx, yy);
            // ITU-R 601 luma (matches typical grayscale conversion).
            sum += 0.299 * p.r + 0.587 * p.g + 0.114 * p.b;
            n++;
          }
        }
        cells[cy * _grid + cx] = sum / n;
      }
    }

    // Mean-subtract (removes brightness offset) + L2-normalize (removes
    // contrast scaling) -> unit vector comparable via cosine similarity.
    double mean = 0;
    for (final c in cells) {
      mean += c;
    }
    mean /= cells.length;
    double norm = 0;
    for (int i = 0; i < cells.length; i++) {
      cells[i] -= mean;
      norm += cells[i] * cells[i];
    }
    norm = math.sqrt(norm);
    if (norm == 0) norm = 1;
    for (int i = 0; i < cells.length; i++) {
      cells[i] /= norm;
    }
    return cells;
  }

  static double _cosine(List<double> a, List<double> b) {
    double s = 0;
    for (int i = 0; i < a.length; i++) {
      s += a[i] * b[i];
    }
    return s;
  }

  /// Recognize the monument in [bytes]. Returns the best [LocalMatch], or null
  /// if no monument clears the acceptance threshold.
  static Future<LocalMatch?> recognize(Uint8List bytes) async {
    await _ensureLoaded();
    final query = signatureFromBytes(bytes);
    if (query == null) return null;

    // Best cosine per monument (so we can log and compare classes clearly).
    final perClassBest = <String, double>{};
    _refSignatures!.forEach((id, sigs) {
      double best = -2;
      for (final ref in sigs) {
        final c = _cosine(query, ref);
        if (c > best) best = c;
      }
      perClassBest[id] = best;
    });

    String? bestId;
    double bestScore = -2;
    perClassBest.forEach((id, score) {
      if (score > bestScore) {
        bestScore = score;
        bestId = id;
      }
    });

    debugPrint('[LocalRecognition] scores: '
        '${perClassBest.entries.map((e) => '${e.key}=${e.value.toStringAsFixed(3)}').join(', ')} '
        '| best=$bestId (${bestScore.toStringAsFixed(3)}) '
        'threshold=$_acceptThreshold '
        '=> ${(bestId != null && bestScore >= _acceptThreshold) ? "ACCEPT" : "REJECT"}');

    if (bestId == null || bestScore < _acceptThreshold) return null;
    return LocalMatch(
      monumentId: bestId!,
      name: _canonicalName[bestId] ?? bestId!,
      confidence: bestScore.clamp(0.0, 1.0).toDouble(),
    );
  }
}

class LocalMatch {
  final String monumentId;
  final String name;
  final double confidence;
  const LocalMatch({
    required this.monumentId,
    required this.name,
    required this.confidence,
  });
}
