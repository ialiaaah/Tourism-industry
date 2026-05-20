// ignore: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

const _kViewType = 'tourismx-live-camera';

class WebCamController {
  // Shared static video element so the platform view factory is only registered once
  static html.VideoElement? _sharedVideo;
  static bool _factoryRegistered = false;

  html.MediaStream? _stream;
  bool _isReady = false;
  String? _errorMessage;

  bool get isReady => _isReady;
  String? get errorMessage => _errorMessage;

  static void _ensureFactory() {
    if (_factoryRegistered) return;
    _sharedVideo = html.VideoElement()
      ..autoplay = true
      ..muted = true
      ..setAttribute('playsinline', 'true')
      ..style.cssText =
          'width:100%;height:100%;object-fit:cover;background:#000;display:block;';
    ui_web.platformViewRegistry.registerViewFactory(
      _kViewType,
      (_) => _sharedVideo!,
    );
    _factoryRegistered = true;
  }

  Future<void> initialize() async {
    _ensureFactory();
    try {
      final mediaDevices = html.window.navigator.mediaDevices;
      if (mediaDevices == null) {
        throw Exception('Media devices not found. This usually happens when the site is not served over HTTPS.');
      }
      _stream = await mediaDevices.getUserMedia({
        'video': {
          'facingMode': {'ideal': 'environment'},
          'width': {'ideal': 1920},
          'height': {'ideal': 1080},
        },
        'audio': false,
      });
      _sharedVideo!.srcObject = _stream;
      await _sharedVideo!.play();
      _isReady = true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isReady = false;
    }
  }

  /// Captures the current camera frame and returns JPEG bytes.
  Future<Uint8List?> capture() async {
    final video = _sharedVideo;
    if (video == null || !_isReady) return null;
    final w = video.videoWidth;
    final h = video.videoHeight;
    if (w == 0 || h == 0) return null;

    final canvas = html.CanvasElement(width: w, height: h);
    canvas.context2D.drawImage(video, 0, 0);
    final dataUrl = canvas.toDataUrl('image/jpeg', 0.85);
    // dataUrl = "data:image/jpeg;base64,/9j/..."
    final base64 = dataUrl.split(',').last;
    return base64Decode(base64);
  }

  void dispose() {
    final tracks = _stream?.getTracks() ?? [];
    for (final track in tracks) {
      track.stop();
    }
    _sharedVideo?.srcObject = null;
    _stream = null;
    _isReady = false;
  }
}

Widget buildCamView(WebCamController ctrl) {
  return const HtmlElementView(viewType: _kViewType);
}
