import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class AudioNarrationService extends ChangeNotifier {
  late FlutterTts _tts;
  bool _isPlaying = false;
  String? _currentText;

  bool get isPlaying => _isPlaying;
  String? get currentText => _currentText;

  AudioNarrationService() {
    _initTts();
  }

  void _initTts() {
    _tts = FlutterTts();

    _tts.setStartHandler(() {
      _isPlaying = true;
      notifyListeners();
    });

    _tts.setCompletionHandler(() {
      _isPlaying = false;
      _currentText = null;
      notifyListeners();
    });

    _tts.setCancelHandler(() {
      _isPlaying = false;
      _currentText = null;
      notifyListeners();
    });

    _tts.setErrorHandler((msg) {
      _isPlaying = false;
      _currentText = null;
      debugPrint('TTS Error: $msg');
      notifyListeners();
    });

    // Configure default parameters
    _tts.setLanguage('en-US');
    _tts.setSpeechRate(0.5); // Natural rate
    _tts.setVolume(1.0);
    _tts.setPitch(1.0);
  }

  Future<void> speak(String text) async {
    if (text.isEmpty) return;

    if (_isPlaying && _currentText == text) {
      await stop();
      return;
    }

    await stop();
    _currentText = text;
    await _tts.speak(text);
  }

  Future<void> stop() async {
    if (_isPlaying) {
      await _tts.stop();
      _isPlaying = false;
      _currentText = null;
      notifyListeners();
    }
  }

  Future<void> setLanguage(String lang) async {
    await _tts.setLanguage(lang);
  }

  Future<void> setSpeechRate(double rate) async {
    await _tts.setSpeechRate(rate);
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
