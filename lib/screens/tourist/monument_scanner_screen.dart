import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:io';
import 'dart:typed_data';
import '../../models/models.dart';
import 'ai_helper_stub.dart'
    if (dart.library.html) 'ai_helper_web.dart'
    if (dart.library.io) 'ai_helper_native.dart';

class MonumentScannerScreen extends StatefulWidget {
  final Stop stop;

  const MonumentScannerScreen({Key? key, required this.stop}) : super(key: key);

  @override
  State<MonumentScannerScreen> createState() => _MonumentScannerScreenState();
}

class _MonumentScannerScreenState extends State<MonumentScannerScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _photo;
  Uint8List? _webImageBytes;
  bool _isProcessing = false;
  bool _isLiveCameraOpen = false;
  final AIHelper _aiHelper = AIHelper();
  String? _inferenceResult;
  MobileScannerController? _cameraController;

  @override
  void initState() {
    super.initState();
    _aiHelper.init();
  }

  Future<void> _takePicture(ImageSource source) async {
    final XFile? photo = await _picker.pickImage(source: source);
    if (photo != null) {
      setState(() {
        _photo = photo;
        _isProcessing = true;
      });

      // Read bytes for web display
      if (kIsWeb) {
        final bytes = await photo.readAsBytes();
        setState(() => _webImageBytes = bytes);
      }

      try {
        _inferenceResult = await _aiHelper.analyzeImage(photo, widget.stop.name);
      } catch (e) {
        debugPrint('Inference error: $e');
        _inferenceResult = widget.stop.name;
      }

      setState(() => _isProcessing = false);
      _showARSummary();
    }
  }

  void _openLiveCamera() {
    _cameraController = MobileScannerController(
      facing: CameraFacing.back,
      detectionSpeed: DetectionSpeed.normal,
    );
    setState(() => _isLiveCameraOpen = true);
  }

  void _closeLiveCamera() {
    _cameraController?.stop();
    _cameraController?.dispose();
    _cameraController = null;
    setState(() => _isLiveCameraOpen = false);
  }

  Future<void> _captureFromLiveCamera() async {
    // Close live camera and trigger AI analysis with the stop name
    _closeLiveCamera();
    setState(() => _isProcessing = true);

    try {
      _inferenceResult = await _aiHelper.analyzeImage(null, widget.stop.name);
    } catch (e) {
      _inferenceResult = widget.stop.name;
    }

    setState(() => _isProcessing = false);
    _showARSummary();
  }

  @override
  void dispose() {
    _aiHelper.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  void _showARSummary() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Color(0xFFCBA153), size: 28),
                    SizedBox(width: 8),
                    Text(
                      'Scan Complete',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F1B29)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Identified: ${_inferenceResult ?? widget.stop.name}',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Historical Snippet:',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F1B29)),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.stop.arSnippet ?? 'Fascinating details are hidden here...',
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBA153).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFCBA153).withValues(alpha: 0.5)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.record_voice_over, color: Color(0xFFCBA153), size: 32),
                      SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Want to know more? Ask your tour guide for the full story and hidden secrets!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF0F1B29),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Back to Scanner'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Live camera mode
    if (_isLiveCameraOpen && _cameraController != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Live Camera'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _closeLiveCamera,
          ),
        ),
        body: Stack(
          children: [
            MobileScanner(
              controller: _cameraController!,
              onDetect: (_) {}, // We don't need barcode detection here
            ),
            // Overlay with monument info
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Point at: ${widget.stop.name}',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            // Capture button
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _captureFromLiveCamera,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFCBA153), width: 4),
                    ),
                    child: const Icon(Icons.camera, size: 36, color: Color(0xFF0F1B29)),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Scan Monument')),
      body: Center(
        child: _isProcessing
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Color(0xFFCBA153)),
                  const SizedBox(height: 20),
                  const Text('Scanning monument...',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(
                    'Identifying historical landmarks...',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              )
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_photo != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: kIsWeb && _webImageBytes != null
                              ? Image.memory(
                                  _webImageBytes!,
                                  height: 300,
                                  fit: BoxFit.cover,
                                )
                              : Image.file(
                                  File(_photo!.path),
                                  height: 300,
                                  fit: BoxFit.cover,
                                ),
                        )
                      else
                        Container(
                          height: 280,
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0F1B29), Color(0xFF1A2A3A)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_enhance, size: 80, color: Color(0xFFCBA153)),
                                SizedBox(height: 16),
                                Text(
                                  'Take or upload a photo\nof the monument',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white70, fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      // Primary: Open live camera
                      ElevatedButton.icon(
                        icon: const Icon(Icons.videocam),
                        label: const Text('Open Live Camera'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: const Color(0xFF0F1B29),
                          foregroundColor: const Color(0xFFCBA153),
                        ),
                        onPressed: _openLiveCamera,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Upload from Gallery'),
                        style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16)),
                        onPressed: () => _takePicture(ImageSource.gallery),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
