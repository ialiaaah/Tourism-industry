import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class AudioNarrationService extends ChangeNotifier {
  late FlutterTts _tts;
  bool _isPlaying = false;
  String? _currentText;
  bool _ready = false;

  bool get isPlaying => _isPlaying;
  String? get currentText => _currentText;

  AudioNarrationService() {
    _initTts();
  }

  Future<void> _initTts() async {
    _tts = FlutterTts();

    // ── iOS-specific: activate the audio session so TTS actually makes sound ──
    if (Platform.isIOS) {
      await _tts.setSharedInstance(true);
      await _tts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
          IosTextToSpeechAudioCategoryOptions.mixWithOthers,
          IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
        ],
        IosTextToSpeechAudioMode.defaultMode,
      );
    }

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

    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    await _tts.awaitSpeakCompletion(true);

    _ready = true;
  }

  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    if (!_ready) await Future.delayed(const Duration(milliseconds: 300));

    if (_isPlaying) {
      await _tts.stop();
      _isPlaying = false;
      _currentText = null;
      notifyListeners();
      // If same text tapped again — toggle off
      if (_currentText == text) return;
    }

    _currentText = text;
    notifyListeners();
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
    _isPlaying = false;
    _currentText = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }
}
