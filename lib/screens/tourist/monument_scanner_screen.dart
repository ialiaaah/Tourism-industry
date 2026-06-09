import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:io';
import 'dart:typed_data';
import '../../models/models.dart';
import '../../services/monument_data_service.dart';
import 'ar_experience_screen.dart';
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
  // ── Palette ────────────────────────────────────────────────────────────────
  static const _bg      = Color(0xFF1E1308);
  static const _card    = Color(0xFF2E1E0C);
  static const _cardAlt = Color(0xFF3A2410);
  static const _gold    = Color(0xFFDFAF58);
  static const _terra   = Color(0xFFD4581E);
  static const _cream   = Color(0xFFF5EDD8);
  static const _sand    = Color(0xFFE0C896);
  static const _muted   = Color(0xFF8A7560);

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
      if (kIsWeb) {
        final bytes = await photo.readAsBytes();
        setState(() => _webImageBytes = bytes);
      }
      try {
        _inferenceResult =
            await _aiHelper.analyzeImage(photo, widget.stop.name);
      } catch (e) {
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
    _closeLiveCamera();
    setState(() => _isProcessing = true);
    try {
      _inferenceResult =
          await _aiHelper.analyzeImage(null, widget.stop.name);
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
    final identified = _inferenceResult ?? widget.stop.name;
    final monument = MonumentDataService.findByDetectedName(identified) ??
        MonumentDataService.findByDetectedName(widget.stop.name);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        decoration: const BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: _muted.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // ── "Identified" header ──────────────────────────────────────
              Row(children: [
                const Icon(Icons.check_circle_rounded, color: _gold, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Monument Identified!',
                          style: GoogleFonts.playfairDisplay(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _cream)),
                      Text(identified,
                          style: GoogleFonts.inter(
                              fontSize: 13, color: _muted)),
                    ],
                  ),
                ),
              ]),

              const SizedBox(height: 20),

              // ── Historical snippet ────────────────────────────────────────
              if ((widget.stop.arSnippet ?? '').isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _cardAlt,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: _gold.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.history_edu,
                            color: _gold, size: 16),
                        const SizedBox(width: 6),
                        Text('Historical Snippet',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: _sand)),
                      ]),
                      const SizedBox(height: 10),
                      Text(widget.stop.arSnippet!,
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              height: 1.6,
                              color: _cream)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // ── Primary: open full AR experience ─────────────────────────
              if (monument != null) ...[
                ElevatedButton.icon(
                  icon: const Icon(Icons.view_in_ar),
                  label: Text('Open Full AR Experience',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: _terra,
                    foregroundColor: _cream,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              ARExperienceScreen(monument: monument)),
                    );
                  },
                ),
                const SizedBox(height: 10),
              ],

              // ── Secondary: scan another ───────────────────────────────────
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  side: BorderSide(color: _gold.withValues(alpha: 0.6)),
                  foregroundColor: _gold,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Navigator.pop(sheetContext),
                child: Text('Scan Another',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ── Live camera view ──────────────────────────────────────────────────
    if (_isLiveCameraOpen && _cameraController != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: _cream,
          title: Text('Live Camera',
              style: GoogleFonts.inter(color: _cream)),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _closeLiveCamera,
          ),
        ),
        body: Stack(
          children: [
            MobileScanner(
              controller: _cameraController!,
              onDetect: (_) {},
            ),
            // Target info banner
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: _gold.withValues(alpha: 0.4)),
                ),
                child: Row(children: [
                  const Icon(Icons.camera_enhance, color: _gold, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('Point at: ${widget.stop.name}',
                        style: GoogleFonts.inter(
                            color: _cream,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                  ),
                ]),
              ),
            ),
            // Capture button
            Positioned(
              bottom: 48,
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
                      color: _cream,
                      border: Border.all(color: _gold, width: 4),
                    ),
                    child: const Icon(Icons.camera,
                        size: 36, color: _bg),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ── Main scanner screen ───────────────────────────────────────────────
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _card,
        foregroundColor: _cream,
        elevation: 0,
        title: Text('Scan Monument',
            style: GoogleFonts.playfairDisplay(
                color: _gold, fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
      ),
      body: _isProcessing
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: _gold),
                  const SizedBox(height: 20),
                  Text('Scanning monument…',
                      style: GoogleFonts.inter(
                          color: _cream,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text('Identifying historical landmarks…',
                      style: GoogleFonts.inter(
                          color: _muted, fontSize: 12)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Photo preview / placeholder ────────────────────────
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: _photo != null
                        ? (kIsWeb && _webImageBytes != null
                            ? Image.memory(_webImageBytes!,
                                height: 280, fit: BoxFit.cover)
                            : Image.file(File(_photo!.path),
                                height: 280, fit: BoxFit.cover))
                        : Container(
                            height: 280,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_bg, _card],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.camera_enhance,
                                    size: 80, color: _gold),
                                const SizedBox(height: 16),
                                Text(
                                  'Point at the monument\nand capture a photo',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                      color: _muted, fontSize: 15),
                                ),
                              ],
                            ),
                          ),
                  ),
                  const SizedBox(height: 28),

                  // ── Stop name badge ────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: _card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: _gold.withValues(alpha: 0.3)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.location_on_rounded,
                          color: _terra, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Current stop: ${widget.stop.name}',
                          style: GoogleFonts.inter(
                              color: _sand,
                              fontSize: 13,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 24),

                  // ── Open live camera button ────────────────────────────
                  ElevatedButton.icon(
                    icon: const Icon(Icons.videocam_rounded),
                    label: Text('Open Live Camera',
                        style: GoogleFonts.inter(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _terra,
                      foregroundColor: _cream,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: _openLiveCamera,
                  ),
                  const SizedBox(height: 12),

                  // ── Upload from gallery button ─────────────────────────
                  OutlinedButton.icon(
                    icon: const Icon(Icons.photo_library_rounded),
                    label: Text('Upload from Gallery',
                        style: GoogleFonts.inter(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      side: BorderSide(color: _gold.withValues(alpha: 0.6)),
                      foregroundColor: _gold,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => _takePicture(ImageSource.gallery),
                  ),
                ],
              ),
            ),
    );
  }
}
