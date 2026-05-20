// Native stub — camera is handled by the native camera package on iOS/Android.
import 'dart:typed_data';
import 'package:flutter/material.dart';

class WebCamController {
  bool get isReady => false;
  String? get errorMessage => null;
  Future<void> initialize() async {}
  Future<Uint8List?> capture() async => null;
  void dispose() {}
}

Widget buildCamView(WebCamController ctrl) => const SizedBox.shrink();
