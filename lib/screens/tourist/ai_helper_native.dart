import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

/// IDs → (display label, number of reference images in assets)
const _kMonuments = <String, (String, int)>{
  'akhenaten': ('Akhenaten', 8),
  'bent_pyramid': ('Bent pyramid for senefru', 8),
  'colossal_ramesses_ii': ('Colossal Statue of Ramesses II', 8),
  'colossi_memnon': ('Colossoi of Memnon', 8),
  'goddess_isis': ('Goddess Isis with her child', 8),
  'hatshepsut': ('Hatshepsut', 8),
  'khafre_pyramid': ('Khafre Pyramid', 8),
  'thutmose_iii': ('King Thutmose III', 8),
  'tutankhamun_mask': ('Mask of Tutankhamun', 8),
  'nefertiti': ('Nefertiti', 8),
  'pyramid_djoser': ('Pyramid of Djoser', 8),
  'ramesseum': ('Ramessum', 8),
  'statue_zoser': ('Statue of King Zoser', 8),
  'tutankhamun_ankhesenamun': ('Statue of Tutankhamun with Ankhesenamun', 8),
  'temple_isis_philae': ('Temple of Isis in Philae', 8),
  'temple_kom_ombo': ('Temple of Kom Ombo', 8),
  'great_temple_ramesses': ('The Great Temple of Ramesses II', 8),
  'amenhotep_tiye': ('Amenhotep III and Tiye', 8),
  'bust_ramesses_ii': ('Bust of Ramesses II', 8),
  'head_amenhotep_iii': ('Head Statue of Amenhotep III', 8),
  'menkaure_pyramid': ('Menkaure Pyramid', 8),
  'sphinx': ('Sphinx', 8),
};

class AIHelper {
  /// Averaged histogram per class (192 values: 64 bins × R,G,B channels).
  final Map<String, List<double>> _classHistograms = {};
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    try {
      for (final entry in _kMonuments.entries) {
        final id = entry.key;
        final count = entry.value.$2;
        final accum = List<double>.filled(192, 0);
        int loaded = 0;

        for (int i = 0; i < count; i++) {
          try {
            final path = 'assets/monuments/${id}_ref$i.jpg';
            final bytes = await rootBundle.load(path);
            final h = await compute(_histogramFromBytes, bytes.buffer.asUint8List());
            if (h.length == 192) {
              for (int j = 0; j < 192; j++) {
                accum[j] += h[j];
              }
              loaded++;
            }
          } catch (_) {}
        }

        if (loaded > 0) {
          _classHistograms[id] =
              accum.map((v) => v / loaded).toList(growable: false);
        }
      }
      _initialized = true;
      debugPrint('✅ AIHelper: averaged histograms for ${_classHistograms.length} classes');
    } catch (e) {
      debugPrint('AIHelper init error: $e');
    }
  }

  Future<String?> analyzeImage(XFile? imageFile, String stopName) async {
    if (imageFile == null) {
      return stopName.isNotEmpty ? _nameMatch(stopName) : null;
    }

    try {
      final bytes = await imageFile.readAsBytes();
      final query = await compute(_histogramFromBytes, bytes);

      if (query.isEmpty || _classHistograms.isEmpty) {
        return stopName.isNotEmpty ? _nameMatch(stopName) : null;
      }

      String? bestId;
      double bestScore = -1;
      for (final ref in _classHistograms.entries) {
        final score = _intersection(query, ref.value);
        if (score > bestScore) {
          bestScore = score;
          bestId = ref.key;
        }
      }

      debugPrint('Best: $bestId  score=${bestScore.toStringAsFixed(4)}');
      if (bestId != null) return _kMonuments[bestId]!.$1;
    } catch (e) {
      debugPrint('analyzeImage error: $e');
    }
    return stopName.isNotEmpty ? _nameMatch(stopName) : null;
  }

  void dispose() {}

  String? _nameMatch(String name) {
    final low = name.toLowerCase();
    for (final e in _kMonuments.entries) {
      if (e.value.$1.toLowerCase() == low) return e.value.$1;
      if (low.contains(e.key.replaceAll('_', ' '))) return e.value.$1;
    }
    return null;
  }

  double _intersection(List<double> a, List<double> b) {
    double s = 0;
    for (int i = 0; i < a.length; i++) s += min(a[i], b[i]);
    return s;
  }
}

// Top-level for compute()
List<double> _histogramFromBytes(Uint8List bytes) {
  const bins = 64;
  final r = List<double>.filled(bins, 0);
  final g = List<double>.filled(bins, 0);
  final b = List<double>.filled(bins, 0);

  final decoded = img.decodeImage(bytes);
  if (decoded == null) return [];
  final resized = img.copyResize(decoded, width: 64, height: 64);

  int count = 0;
  for (int y = 0; y < resized.height; y++) {
    for (int x = 0; x < resized.width; x++) {
      final p = resized.getPixel(x, y);
      r[(p.r.toInt() * bins ~/ 256).clamp(0, bins - 1)]++;
      g[(p.g.toInt() * bins ~/ 256).clamp(0, bins - 1)]++;
      b[(p.b.toInt() * bins ~/ 256).clamp(0, bins - 1)]++;
      count++;
    }
  }

  final result = <double>[];
  for (int i = 0; i < bins; i++) result.add(count > 0 ? r[i] / (count * 3) : 0);
  for (int i = 0; i < bins; i++) result.add(count > 0 ? g[i] / (count * 3) : 0);
  for (int i = 0; i < bins; i++) result.add(count > 0 ? b[i] / (count * 3) : 0);
  return result;
}
