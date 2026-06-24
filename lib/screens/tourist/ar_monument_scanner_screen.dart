import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../services/google_vision_service.dart';
import '../../services/monument_data_service.dart';
import '../../services/game_progress_service.dart';
import '../../theme/app_theme.dart';
import 'ar_experience_screen.dart';
import 'sphinx_ar_screen.dart';
import 'khafre_pyramid_ar_screen.dart';
import 'treasure_hunt_screen.dart';
import 'web_cam/cam_interface.dart';

/// Heritage Scanner — uses Google Vision landmark detection to recognise
/// monuments and routes to the appropriate AR / Treasure Hunt experience.
class ARMonumentScannerScreen extends StatefulWidget {
  const ARMonumentScannerScreen({super.key});
  @override
  State<ARMonumentScannerScreen> createState() =>
      _ARMonumentScannerScreenState();
}

enum _ScanState { idle, scanning, success, failure }

class _ARMonumentScannerScreenState extends State<ARMonumentScannerScreen>
    with TickerProviderStateMixin {
  // Web camera
  final WebCamController _webCam = WebCamController();
  bool _webCamInitializing = false;

  // Native camera
  CameraController? _cam;
  bool _camReady = false;
  String? _camErr;

  // Scan state
  _ScanState _state = _ScanState.idle;
  DetectedLandmark? _result;
  MonumentInfo? _monument;
  Uint8List? _lastCapturedBytes;
  String _failureMessage = 'No monument detected. Try a different angle or image.';

  // Animations
  late AnimationController _bracketCtrl;
  late AnimationController _scanLineCtrl;
  late Animation<double> _scanLineAnim;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  late AnimationController _successCtrl;
  late Animation<double> _successAnim;

  @override
  void initState() {
    super.initState();
    _bracketCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _scanLineCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
    _scanLineAnim =
        Tween<double>(begin: 0, end: 1).animate(_scanLineCtrl);
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.5, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _successCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _successAnim =
        CurvedAnimation(parent: _successCtrl, curve: Curves.elasticOut);
    _initCamera();
  }

  Future<void> _initCamera() async {
    if (kIsWeb) {
      setState(() => _webCamInitializing = true);
      try {
        await _webCam.initialize();
        if (mounted) {
          setState(() {
            _webCamInitializing = false;
            _camReady = _webCam.isReady;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _webCamInitializing = false;
            _camErr = e.toString();
          });
        }
      }
      return;
    }
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _camErr = 'No camera found.');
        return;
      }
      final back = cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
          orElse: () => cameras.first);
      _cam = CameraController(back, ResolutionPreset.high,
          enableAudio: false, imageFormatGroup: ImageFormatGroup.jpeg);
      await _cam!.initialize();
      if (mounted) setState(() => _camReady = true);
    } on CameraException catch (e) {
      if (mounted) setState(() => _camErr = e.description ?? 'Camera error.');
    } catch (e) {
      if (mounted) setState(() => _camErr = e.toString());
    }
  }

  @override
  void dispose() {
    _cam?.dispose();
    if (kIsWeb) _webCam.dispose();
    _bracketCtrl.dispose();
    _scanLineCtrl.dispose();
    _pulseCtrl.dispose();
    _successCtrl.dispose();
    super.dispose();
  }

  // ── Core scan ─────────────────────────────────────────────────────────────

  Future<void> _scan(Uint8List bytes) async {
    setState(() {
      _state = _ScanState.scanning;
      _result = null;
      _monument = null;
      _lastCapturedBytes = bytes;
    });
    HapticFeedback.lightImpact();

    try {
      final detected = await GoogleVisionService.detectLandmark(bytes);
      if (!mounted) return;

      if (detected != null) {
        // Try to find a matching monument in the database
        final monument = MonumentDataService.findByDetectedName(detected.name);

        HapticFeedback.heavyImpact();
        _successCtrl.forward(from: 0);

        // Award points if we have a matching monument
        if (monument != null) {
          await Provider.of<GameProgressService>(context, listen: false)
              .scanMonument(monument.id);
        } else if (detected.name.toLowerCase().contains('sphinx')) {
          // Sphinx detected but not found by name lookup — use fallback
          final sphinx = MonumentDataService.findByDetectedName('The Great Sphinx');
          if (sphinx != null && mounted) {
            await Provider.of<GameProgressService>(context, listen: false)
                .scanMonument(sphinx.id);
          }
        }

        setState(() {
          _state = _ScanState.success;
          _result = detected;
          _monument = monument ?? MonumentDataService.findByDetectedName('The Great Sphinx');
        });
      } else {
        HapticFeedback.mediumImpact();
        setState(() {
          _state = _ScanState.failure;
          _failureMessage =
              'No monument recognised. Ensure the landmark is clearly visible and try again.';
        });
      }
    } on VisionException catch (e) {
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() {
        _state = _ScanState.failure;
        _failureMessage = GoogleVisionService.messageForFailure(e.failure);
      });
    } catch (e) {
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() {
        _state = _ScanState.failure;
        _failureMessage = 'An unexpected error occurred. Please try again.';
      });
    }
  }

  Future<void> _capture() async {
    if (_state == _ScanState.scanning) return;
    if (kIsWeb) {
      await _scanWebFrame();
      return;
    }
    if (!_camReady || _cam == null) return;
    try {
      final xfile = await _cam!.takePicture();
      final bytes = await xfile.readAsBytes();
      await _scan(bytes);
    } on CameraException catch (e) {
      if (mounted) {
        setState(() {
          _state = _ScanState.failure;
          _failureMessage = 'Camera error: ${e.description ?? e.code}';
        });
      }
    }
  }

  Future<void> _pickImage() async {
    if (_state == _ScanState.scanning) return;
    try {
      final xfile =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (xfile == null) return;
      final bytes = await xfile.readAsBytes();
      await _scan(bytes);
    } catch (e) {
      if (mounted) {
        setState(() {
          _state = _ScanState.failure;
          _failureMessage = 'Could not read image.';
        });
      }
    }
  }

  Future<void> _scanWebFrame() async {
    if (_state == _ScanState.scanning) return;
    try {
      final bytes = await _webCam.capture();
      if (bytes == null) return;
      await _scan(bytes);
    } catch (e) {
      if (mounted) {
        setState(() {
          _state = _ScanState.failure;
          _failureMessage = 'Could not capture frame.';
        });
      }
    }
  }

  void _reset() {
    setState(() {
      _state = _ScanState.idle;
      _result = null;
      _monument = null;
    });
    _successCtrl.reset();
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  void _openARExperience() {
    final detected = _result;
    if (detected == null) return;

    final monument = _monument ?? MonumentDataService.findByDetectedName('The Great Sphinx');
    if (monument == null) return;

    final Widget screen = _resolveARScreen(monument);
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  Widget _resolveARScreen(MonumentInfo monument) {
    switch (monument.id) {
      case 'khafre_pyramid':
        return KhafrePyramidARScreen(monument: monument);
      default:
        return SphinxARScreen(monument: monument);
    }
  }

  void _openTreasureHunt() {
    final monument = _monument ?? MonumentDataService.findByDetectedName('The Great Sphinx');
    if (monument == null) return;
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => TreasureHuntScreen(monument: monument)));
  }

  void _openARHotspots() {
    final monument = _monument ?? MonumentDataService.findByDetectedName('The Great Sphinx');
    if (monument == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ARExperienceScreen(
          monument: monument,
          capturedImage: _lastCapturedBytes,
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scanDark,
      body: Stack(
        children: [
          // Camera preview
          if (!kIsWeb && _camReady && _cam != null)
            Positioned.fill(child: CameraPreview(_cam!))
          else if (kIsWeb && _webCam.isReady)
            Positioned.fill(child: buildCamView(_webCam))
          else
            Positioned.fill(child: _buildNoCameraPlaceholder()),

          // Gradient overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.65),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.85),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0, 0.2, 0.7, 1],
                ),
              ),
            ),
          ),

          // Scan frame (idle / scanning)
          if (_state == _ScanState.idle || _state == _ScanState.scanning)
            _buildScanFrame(),

          // Top bar + bottom controls
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                const Spacer(),
                _buildBottomPanel(),
              ],
            ),
          ),

          // Overlay panels
          if (_state == _ScanState.scanning) _buildScanningOverlay(),
          if (_state == _ScanState.success && _result != null)
            _buildSuccessOverlay(_result!),
          if (_state == _ScanState.failure)
            _buildFailureOverlay(_failureMessage),
        ],
      ),
    );
  }

  // ── Sub-widgets ───────────────────────────────────────────────────────────

  Widget _buildNoCameraPlaceholder() {
    return Container(
      color: AppColors.scanDark,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.camera_enhance_outlined,
                color: AppColors.gold.withValues(alpha: 0.3), size: 80),
            const SizedBox(height: 16),
            Text(
              _camErr ??
                  (_webCamInitializing
                      ? 'Starting camera...'
                      : 'Camera unavailable'),
              style: AppTextStyles.body.copyWith(color: AppColors.muted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _PickButton(onTap: _pickImage),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _CircleIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => Navigator.pop(context),
          ),
          const Spacer(),
          Column(
            children: [
              Text('Heritage Scanner',
                  style: AppTextStyles.h3.copyWith(color: AppColors.cream)),
              Text('Monument Recognition',
                  style:
                      AppTextStyles.labelSmall.copyWith(color: AppColors.gold)),
            ],
          ),
          const Spacer(),
          _CircleIconButton(
            icon: Icons.photo_library_outlined,
            onTap: _pickImage,
          ),
        ],
      ),
    );
  }

  Widget _buildScanFrame() {
    return Center(
      child: AnimatedBuilder(
        animation: Listenable.merge([_bracketCtrl, _scanLineAnim]),
        builder: (_, __) => SizedBox(
          width: 260,
          height: 260,
          child: CustomPaint(
            painter: _ScanFramePainter(
              bracketOffset: _bracketCtrl.value * 4,
              scanY: _state == _ScanState.scanning ? _scanLineAnim.value : -1,
              color: AppColors.gold.withValues(
                  alpha: _state == _ScanState.scanning ? 1.0 : 0.7),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 36),
      child: Column(
        children: [
          // Instruction card
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Text('Scan a Monument',
                    style: AppTextStyles.h3
                        .copyWith(color: AppColors.gold),
                    textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Text(
                  'Point your camera at any heritage landmark to identify it and unlock the AR experience.',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.sand),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Scan button
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, __) => GestureDetector(
              onTap: _state == _ScanState.scanning ? null : _capture,
              child: Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.gold,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold
                          .withValues(alpha: _pulseAnim.value * 0.45),
                      blurRadius: 22 * _pulseAnim.value,
                      spreadRadius: 4 * _pulseAnim.value,
                    ),
                  ],
                ),
                child: const Icon(Icons.camera_enhance_rounded,
                    color: AppColors.bg, size: 34),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanningOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.5),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.4)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation(AppColors.gold),
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 18),
                Text('Analysing image…',
                    style: AppTextStyles.h3
                        .copyWith(color: AppColors.gold)),
                const SizedBox(height: 8),
                Text(
                  'Identifying monument via Google Vision',
                  style: AppTextStyles.body,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessOverlay(DetectedLandmark result) {
    final monumentId = _monument?.id ?? '';
    final isSphinx   = monumentId == 'sphinx' || result.name.toLowerCase().contains('sphinx');
    final isPyramid  = monumentId == 'khafre_pyramid';
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.72),
        child: Center(
          child: ScaleTransition(
            scale: _successAnim,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.6),
                    width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.15),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.success.withValues(alpha: 0.12),
                      border: Border.all(
                          color: AppColors.success, width: 2),
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: AppColors.success, size: 36),
                  ),
                  const SizedBox(height: 16),
                  Text(result.name,
                      style: AppTextStyles.h2
                          .copyWith(color: AppColors.gold),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text('Monument identified! Your heritage discovery is ready.',
                      style: AppTextStyles.body,
                      textAlign: TextAlign.center),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color:
                          AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.success
                              .withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      '${(result.confidence * 100).toStringAsFixed(0)}% confidence',
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.success),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _openARExperience,
                      icon: const Icon(Icons.explore_rounded, size: 18),
                      label: Text(isSphinx
                          ? 'Explore Sphinx in AR'
                          : isPyramid
                              ? 'Explore Pyramid in AR'
                              : 'Explore AR Experience'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.bg,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _openARHotspots,
                      icon: const Icon(Icons.my_location_rounded, size: 18),
                      label: const Text('AR Hotspot Experience'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF4FC3F7),
                        side: const BorderSide(
                            color: Color(0xFF4FC3F7), width: 1.5),
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _openTreasureHunt,
                      icon: const Icon(Icons.map_rounded, size: 18),
                      label: const Text('Start Treasure Hunt'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.terra,
                        side: const BorderSide(
                            color: AppColors.terra, width: 1.5),
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: _reset,
                    child: Text('Scan Again',
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.muted)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFailureOverlay(String message) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.72),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: AppColors.terra.withValues(alpha: 0.4)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.terra.withValues(alpha: 0.1),
                    border: Border.all(
                        color: AppColors.terra.withValues(alpha: 0.5)),
                  ),
                  child: const Icon(Icons.search_off_rounded,
                      color: AppColors.terra, size: 36),
                ),
                const SizedBox(height: 16),
                Text('Monument Not Recognised',
                    style: AppTextStyles.h2
                        .copyWith(color: AppColors.cream),
                    textAlign: TextAlign.center),
                const SizedBox(height: 10),
                Text(
                  message,
                  style: AppTextStyles.body,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _reset,
                    icon:
                        const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Try Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.bg,
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.muted,
                      side:
                          const BorderSide(color: AppColors.border),
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('Back to Home',
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.muted)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Small helpers ─────────────────────────────────────────────────────────────

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: 0.5),
            border: Border.all(color: Colors.white12),
          ),
          child: Icon(icon, color: AppColors.cream, size: 18),
        ),
      );
}

class _PickButton extends StatelessWidget {
  final VoidCallback onTap;
  const _PickButton({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.photo_library_outlined,
                  color: AppColors.gold, size: 18),
              const SizedBox(width: 8),
              Text('Pick from Gallery',
                  style: AppTextStyles.label
                      .copyWith(color: AppColors.gold)),
            ],
          ),
        ),
      );
}

// ── Scan frame painter ────────────────────────────────────────────────────────

class _ScanFramePainter extends CustomPainter {
  final double bracketOffset;
  final double scanY;
  final Color color;

  const _ScanFramePainter(
      {required this.bracketOffset,
      required this.scanY,
      required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const r = 8.0;
    final len = 30.0 + bracketOffset;

    // Top-left
    canvas.drawLine(Offset(r, r), Offset(r + len, r), p);
    canvas.drawLine(Offset(r, r), Offset(r, r + len), p);
    // Top-right
    canvas.drawLine(
        Offset(size.width - r - len, r), Offset(size.width - r, r), p);
    canvas.drawLine(
        Offset(size.width - r, r), Offset(size.width - r, r + len), p);
    // Bottom-left
    canvas.drawLine(Offset(r, size.height - r - len),
        Offset(r, size.height - r), p);
    canvas.drawLine(Offset(r, size.height - r),
        Offset(r + len, size.height - r), p);
    // Bottom-right
    canvas.drawLine(Offset(size.width - r - len, size.height - r),
        Offset(size.width - r, size.height - r), p);
    canvas.drawLine(Offset(size.width - r, size.height - r - len),
        Offset(size.width - r, size.height - r), p);

    // Scan line
    if (scanY >= 0) {
      final y = size.height * scanY;
      final scanPaint = Paint()
        ..shader = LinearGradient(colors: [
          Colors.transparent,
          color.withValues(alpha: 0.8),
          color,
          color.withValues(alpha: 0.8),
          Colors.transparent,
        ]).createShader(Rect.fromLTWH(0, y - 1, size.width, 2))
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), scanPaint);
    }
  }

  @override
  bool shouldRepaint(_ScanFramePainter old) =>
      old.bracketOffset != bracketOffset || old.scanY != scanY;
}
