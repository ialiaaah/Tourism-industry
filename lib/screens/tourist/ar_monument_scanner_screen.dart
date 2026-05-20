import 'dart:async';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/google_vision_service.dart';
import '../../services/monument_data_service.dart';
import 'detected_monument_sheet.dart';
import 'monument_info_sheet.dart';
import 'web_cam/cam_interface.dart';

class ARMonumentScannerScreen extends StatefulWidget {
  const ARMonumentScannerScreen({super.key});
  @override
  State<ARMonumentScannerScreen> createState() => _ARMonumentScannerScreenState();
}

class _ARMonumentScannerScreenState extends State<ARMonumentScannerScreen>
    with TickerProviderStateMixin {
  static const _gold  = Color(0xFFDFAF58);
  static const _dark  = Color(0xFF0D1420);
  static const _green = Color(0xFF4CD87A);
  static const _red   = Color(0xFFEF5350);

  // ── Web camera ──────────────────────────────────────────────────────────────
  final WebCamController _webCam = WebCamController();
  bool _webCamInitializing = false;

  // ── Camera ─────────────────────────────────────────────────────────────────
  CameraController? _cam;
  bool _camReady  = false;
  String? _camErr;

  // ── Scan state ─────────────────────────────────────────────────────────────
  bool _scanning     = false;
  bool _autoScan     = false;
  bool _apiKeyMissing = false;
  MonumentInfo? _detected;
  String _statusMsg  = 'Point at a monument and tap Scan';
  bool _isError      = false;
  Timer? _autoTimer;

  // ── Animations ─────────────────────────────────────────────────────────────
  late AnimationController _bracketCtrl;
  late AnimationController _scanLineCtrl;
  late Animation<double>   _scanLineAnim;
  late AnimationController _pulseCtrl;
  late Animation<double>   _pulseAnim;

  @override
  void initState() {
    super.initState();
    _bracketCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _scanLineCtrl = AnimationController(vsync: this,
        duration: const Duration(seconds: 2))..repeat();
    _scanLineAnim = Tween<double>(begin: 0, end: 1).animate(_scanLineCtrl);
    _pulseCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 800))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _initCamera();
    // Check API key immediately so user sees the warning right away
    _apiKeyMissing = GoogleVisionService.apiKey.isEmpty;
    if (_apiKeyMissing) {
      debugPrint('⚠️  VISION_API_KEY is not set. '
          'Run: flutter run --dart-define=VISION_API_KEY=YOUR_KEY');
    }
    // On web, mark camera as "ready" immediately (we use image_picker instead)
    if (kIsWeb) {
      setState(() {
        _camReady = true;
        _statusMsg = 'Tap the button to take a photo of a monument';
      });
    }
  }

  Future<void> _initCamera() async {
    // On web, use getUserMedia live camera instead of the camera package
    if (kIsWeb) {
      setState(() {
        _webCamInitializing = true;
        _statusMsg = 'Starting camera...';
      });
      try {
        await _webCam.initialize();
        if (mounted) {
          setState(() {
            _webCamInitializing = false;
            _camReady = _webCam.isReady;
            _statusMsg = _webCam.isReady
                ? 'Tap \u25ce to scan a monument'
                : (_webCam.errorMessage ?? 'Camera unavailable');
            _isError = !_webCam.isReady;
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
        setState(() => _camErr = 'No camera found on this device.');
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
    _autoTimer?.cancel();
    _cam?.dispose();
    if (kIsWeb) _webCam.dispose();
    _bracketCtrl.dispose();
    _scanLineCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Auto-scan ───────────────────────────────────────────────────────────────
  void _toggleAutoScan() {
    setState(() {
      _autoScan = !_autoScan;
      _detected = null;
      _isError  = false;
      _statusMsg = _autoScan
          ? 'Auto-scanning every 5 s...'
          : 'Point at a monument and tap Scan';
    });
    if (_autoScan) {
      _autoTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (!_scanning && _autoScan) {
          // On web use the live-frame capture; on native use the camera package
          if (kIsWeb) {
            _scanWebLiveFrame();
          } else {
            _capture();
          }
        }
      });
    } else {
      _autoTimer?.cancel();
    }
  }

  // ── Core capture & recognition ──────────────────────────────────────────────
  Future<void> _capture() async {
    // On web, delegate to the live-frame path
    if (kIsWeb) { _scanWebLiveFrame(); return; }
    if (_scanning || !_camReady || _cam == null) return;
    setState(() {
      _scanning  = true;
      _isError   = false;
      _statusMsg = 'Sending to Google Vision...';
      _detected  = null;
    });
    HapticFeedback.lightImpact();

    try {
      // 1. Capture image from camera
      final xfile = await _cam!.takePicture();

      // 2. Read bytes via XFile — avoids iOS sandbox path issues
      final bytes = await xfile.readAsBytes();

      // 3. Send to Google Cloud Vision
      final landmark = await GoogleVisionService.detectLandmark(bytes);

      if (landmark == null) {
        setState(() {
          _scanning  = false;
          _statusMsg = 'No landmark detected. Try another angle.';
          _isError   = true;
        });
        return;
      }

      // 4. Match to local database
      final monument = MonumentDataService.findByDetectedName(landmark.name);

      if (!mounted) return;

      if (monument != null) {
        // ✅ Match found — show rich info sheet
        HapticFeedback.heavyImpact();
        setState(() {
          _scanning  = false;
          _detected  = monument;
          _isError   = false;
          _statusMsg = '✓ ${monument.name} '
              '(${(landmark.confidence * 100).toStringAsFixed(0)}%)';
        });
        // Wait so user can see AR lock on
        await Future.delayed(const Duration(milliseconds: 500));
        // We no longer auto-open _showInfo, the user taps the AR card
      } else {
        // ✅ Vision found something — show detected sheet even if not in our DB
        HapticFeedback.mediumImpact();
        setState(() {
          _scanning  = false;
          _isError   = false;
          _statusMsg = '✓ ${landmark.name} detected '
              '(${(landmark.confidence * 100).toStringAsFixed(0)}% confidence)';
        });
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) _showDetected(landmark);
      }
    } on VisionException catch (e) {
      debugPrint('🔴 VisionException [${e.failure.name}]: ${e.message}');
      if (!mounted) return;
      setState(() {
        _scanning  = false;
        _isError   = true;
        _statusMsg = e.message;
      });
    } on CameraException catch (e) {
      debugPrint('🔴 CameraException [${e.code}]: ${e.description}');
      if (!mounted) return;
      setState(() {
        _scanning  = false;
        _isError   = true;
        _statusMsg = 'Camera error: ${e.description ?? e.code}';
      });
    } catch (e, stack) {
      debugPrint('🔴 Unexpected scan error: $e');
      debugPrint(stack.toString());
      if (!mounted) return;
      setState(() {
        _scanning  = false;
        _isError   = true;
        _statusMsg = e.toString().length > 120
            ? '${e.toString().substring(0, 120)}…'
            : e.toString();
      });
    }
  }

  Future<void> _pickImage() async {
    if (_scanning) return;
    setState(() {
      _scanning  = true;
      _isError   = false;
      _statusMsg = 'Selecting image...';
      _detected  = null;
    });

    try {
      final picker = ImagePicker();
      final xfile = await picker.pickImage(source: ImageSource.gallery);
      
      if (xfile == null) {
        setState(() {
          _scanning = false;
          _statusMsg = 'Point at a monument and tap Scan';
        });
        return;
      }

      setState(() => _statusMsg = 'Sending to Google Vision...');
      final bytes = await xfile.readAsBytes();
      final landmark = await GoogleVisionService.detectLandmark(bytes);

      if (landmark == null) {
        setState(() {
          _scanning  = false;
          _statusMsg = 'No landmark detected. Try another photo.';
          _isError   = true;
        });
        return;
      }

      final monument = MonumentDataService.findByDetectedName(landmark.name);

      if (!mounted) return;

      if (monument != null) {
        HapticFeedback.heavyImpact();
        setState(() {
          _scanning  = false;
          _detected  = monument;
          _isError   = false;
          _statusMsg = '✓ ${monument.name} '
              '(${(landmark.confidence * 100).toStringAsFixed(0)}%)';
        });
        // Wait so user can see AR lock on
        await Future.delayed(const Duration(milliseconds: 500));
        // User taps AR card to show info
      } else {
        // Show the detected sheet even for monuments not in our DB
        HapticFeedback.mediumImpact();
        setState(() {
          _scanning  = false;
          _isError   = false;
          _statusMsg = '✓ ${landmark.name} detected '
              '(${(landmark.confidence * 100).toStringAsFixed(0)}% confidence)';
        });
        await Future.delayed(const Duration(milliseconds: 350));
        if (mounted) _showDetected(landmark);
      }
    } on VisionException catch (e) {
      if (!mounted) return;
      setState(() {
        _scanning  = false;
        _isError   = true;
        _statusMsg = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _scanning  = false;
        _isError   = true;
        _statusMsg = 'Error: $e';
      });
    }
  }

  void _showInfo(MonumentInfo m) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => MonumentInfoSheet(monument: m),
      );

  void _showDetected(DetectedLandmark landmark) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => DetectedMonumentSheet(landmark: landmark),
      );

  void _openBrowse() => showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF1A1208),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (_) => _BrowseSheet(
            monuments: MonumentDataService.monuments,
            onTap: (m) { Navigator.pop(context); _showInfo(m); }),
      );

  // ── Scan from live web camera frame ──────────────────────────────────────────
  Future<void> _scanWebLiveFrame() async {
    if (_scanning) return;
    setState(() {
      _scanning  = true;
      _isError   = false;
      _statusMsg = 'Capturing frame...';
      _detected  = null;
    });

    try {
      final bytes = await _webCam.capture();
      if (bytes == null) {
        setState(() {
          _scanning  = false;
          _statusMsg = 'Could not capture frame. Try again.';
          _isError   = true;
        });
        return;
      }
      setState(() => _statusMsg = 'Sending to Google Vision...');
      final landmark = await GoogleVisionService.detectLandmark(bytes);
      if (landmark == null) {
        setState(() {
          _scanning  = false;
          _statusMsg = 'No monument detected. Aim at a landmark and try again.';
          _isError   = true;
        });
        return;
      }
      final monument = MonumentDataService.findByDetectedName(landmark.name);
      if (!mounted) return;
      if (monument != null) {
        HapticFeedback.heavyImpact();
        setState(() {
          _scanning  = false;
          _detected  = monument;
          _isError   = false;
          _statusMsg = '✓ ${monument.name} '
              '(${(landmark.confidence * 100).toStringAsFixed(0)}%)';
        });
        // Wait so user can see AR lock on
        await Future.delayed(const Duration(milliseconds: 500));
        // User taps AR card to show info
      } else {
        // Show detected sheet even for unknown monuments
        HapticFeedback.mediumImpact();
        setState(() {
          _scanning  = false;
          _isError   = false;
          _statusMsg = '✓ ${landmark.name} detected '
              '(${(landmark.confidence * 100).toStringAsFixed(0)}% confidence)';
        });
        await Future.delayed(const Duration(milliseconds: 350));
        if (mounted) _showDetected(landmark);
      }
    } on VisionException catch (e) {
      if (!mounted) return;
      setState(() {
        _scanning  = false;
        _isError   = true;
        _statusMsg = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _scanning  = false;
        _isError   = true;
        _statusMsg = 'Error: $e';
      });
    }
  }

  // ── Web camera scan (opens phone camera via browser) ─────────────────────────
  Future<void> _scanWithCamera() async {

    if (_scanning) return;
    setState(() {
      _scanning  = true;
      _isError   = false;
      _statusMsg = 'Opening camera...';
      _detected  = null;
    });
    try {
      final picker = ImagePicker();
      final xfile = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 85,
      );
      if (xfile == null) {
        setState(() {
          _scanning  = false;
          _statusMsg = 'Tap the button to take a photo of a monument';
        });
        return;
      }
      setState(() => _statusMsg = 'Sending to Google Vision...');
      final bytes = await xfile.readAsBytes();
      final landmark = await GoogleVisionService.detectLandmark(bytes);
      if (landmark == null) {
        setState(() {
          _scanning  = false;
          _statusMsg = 'No landmark detected. Try another angle.';
          _isError   = true;
        });
        return;
      }
      final monument = MonumentDataService.findByDetectedName(landmark.name);
      if (!mounted) return;
      if (monument != null) {
        HapticFeedback.heavyImpact();
        setState(() {
          _scanning  = false;
          _detected  = monument;
          _isError   = false;
          _statusMsg = '✓ ${monument.name} '
              '(${(landmark.confidence * 100).toStringAsFixed(0)}%)';
        });
        // Wait so user can see AR lock on
        await Future.delayed(const Duration(milliseconds: 500));
        // User taps AR card to show info
      } else {
        // Show detected sheet even for unknown monuments
        HapticFeedback.mediumImpact();
        setState(() {
          _scanning  = false;
          _isError   = false;
          _statusMsg = '✓ ${landmark.name} detected '
              '(${(landmark.confidence * 100).toStringAsFixed(0)}% confidence)';
        });
        await Future.delayed(const Duration(milliseconds: 350));
        if (mounted) _showDetected(landmark);
      }
    } on VisionException catch (e) {
      if (!mounted) return;
      setState(() {
        _scanning  = false;
        _isError   = true;
        _statusMsg = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _scanning  = false;
        _isError   = true;
        _statusMsg = 'Error: $e';
      });
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _dark,
      body: Stack(fit: StackFit.expand, children: [
        _cameraLayer(),
        _arOverlay(),
        _topBar(),
        _bottomBar(),
      ]),
    );
  }

  // ── Camera layer ─────────────────────────────────────────────────────────────
  Widget _cameraLayer() {
    // ── Web: live getUserMedia stream ──
    if (kIsWeb) {
      if (_webCamInitializing) {
        return Container(
          color: _dark,
          child: const Center(child: CircularProgressIndicator(color: _gold)),
        );
      }
      if (!_webCam.isReady) {
        return Container(
          color: _dark,
          child: Center(child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.no_photography_rounded, color: Colors.white38, size: 64),
              const SizedBox(height: 16),
              Text(
                _webCam.errorMessage ??
                    'Camera unavailable.\nAllow camera access and reload.\n\nNote: Mobile browsers require HTTPS for camera access. To test on mobile via local network, either use the "Upload" button instead or deploy to Firebase Hosting.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.white54, fontSize: 14, height: 1.5),
              ),
            ]),
          )),
        );
      }
      // Live camera feed fills the screen
      return buildCamView(_webCam);
    }
    if (_camErr != null) {
      return Container(
        color: _dark,
        child: Center(child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.no_photography_rounded,
                color: Colors.white38, size: 64),
            const SizedBox(height: 16),
            Text(_camErr!, textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    color: Colors.white54, fontSize: 14, height: 1.5)),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: _gold, foregroundColor: _dark),
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ]),
        )),
      );
    }
    if (!_camReady || _cam == null) {
      return const Center(
          child: CircularProgressIndicator(color: _gold));
    }
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width:  _cam!.value.previewSize!.height,
          height: _cam!.value.previewSize!.width,
          child:  CameraPreview(_cam!),
        ),
      ),
    );
  }

  // ── AR overlay ────────────────────────────────────────────────────────────────
  Widget _arOverlay() {
    final h = MediaQuery.of(context).size.height;
    return Stack(fit: StackFit.expand, children: [
        // Vignette
        IgnorePointer(
          child: Container(decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center, radius: 0.9,
              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.55)],
            ),
          )),
        ),
        // Scan line (only while scanning)
        if (_scanning) AnimatedBuilder(
          animation: _scanLineAnim,
          builder: (_, __) => Positioned(
            top: _scanLineAnim.value * h - 1,
            left: 0, right: 0,
            child: Container(height: 2, decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.transparent,
                _gold.withValues(alpha: 0.9),
                Colors.transparent,
              ]),
            )),
          ),
        ),
        // Corner brackets
        Center(child: _ScanBrackets(controller: _bracketCtrl, scanning: _scanning)),
        // Floating AR Card
        if (_detected != null) _arHoverCard(),
        // Status pill
        Positioned(
          bottom: 175, left: 28, right: 28,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _statusPill(),
          ),
        ),
        // LIVE badge
        if (_autoScan) Positioned(
          top: 110, right: 20,
          child: AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, __) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: _pulseAnim.value * 0.85),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 6, height: 6,
                    decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle)),
                const SizedBox(width: 5),
                Text('LIVE', style: GoogleFonts.inter(
                    color: Colors.white, fontSize: 10,
                    fontWeight: FontWeight.bold)),
              ]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusPill() {
    final borderColor = _isError
        ? _red.withValues(alpha: 0.7)
        : _detected != null
            ? _green
            : _gold.withValues(alpha: 0.7);
    return Container(
      key: ValueKey(_statusMsg),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: borderColor),
      ),
      child: Row(mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_scanning)
            const SizedBox(width: 14, height: 14,
                child: CircularProgressIndicator(
                    color: _gold, strokeWidth: 2))
          else
            Icon(
              _isError
                  ? Icons.error_outline_rounded
                  : _detected != null
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
              color: _isError ? _red : _detected != null ? _green : _gold,
              size: 15,
            ),
          const SizedBox(width: 8),
          Flexible(child: Text(_statusMsg,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.white,
                  fontSize: 12, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  // ── Floating AR Card ──────────────────────────────────────────────────────────
  Widget _arHoverCard() {
    final m = _detected!;
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.20,
      left: 30,
      right: 30,
      child: AnimatedBuilder(
        animation: _pulseAnim,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 10 * math.sin(_pulseAnim.value * math.pi * 2)),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.elasticOut,
              builder: (context, val, child) {
                return Transform.scale(
                  scale: val,
                  child: Opacity(
                    opacity: val.clamp(0.0, 1.0),
                    child: child,
                  ),
                );
              },
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _showInfo(m);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: _gold.withValues(alpha: 0.6), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: _gold.withValues(alpha: 0.4 * _pulseAnim.value),
                        blurRadius: 40,
                        spreadRadius: 8,
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Scanning reticle header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(Icons.filter_center_focus, color: _gold, size: 16),
                          Text(
                            'AR TARGET ACQUIRED',
                            style: GoogleFonts.inter(
                              color: _gold,
                              fontSize: 10,
                              letterSpacing: 2.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Icon(Icons.filter_center_focus, color: _gold, size: 16),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Monument Name & Emoji
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(m.emoji, style: const TextStyle(fontSize: 32)),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              m.name,
                              style: GoogleFonts.playfairDisplay(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                shadows: [Shadow(color: _gold, blurRadius: 10)],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Animated connecting line pointing down
                      Container(
                        width: 2,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_gold, Colors.transparent],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Action Button
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                        decoration: BoxDecoration(
                          color: _gold.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _gold),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'TAP TO EXPLORE',
                              style: GoogleFonts.inter(
                                color: _gold,
                                fontSize: 12,
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.touch_app, color: _gold, size: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Top bar ──────────────────────────────────────────────────────────────────
  Widget _topBar() {
    return Positioned(top: 0, left: 0, right: 0,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(gradient: LinearGradient(
            colors: [Colors.black.withValues(alpha: 0.75), Colors.transparent],
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
          )),
          child: Row(children: [
            _iconBtn(Icons.arrow_back_ios_new_rounded,
                () => Navigator.pop(context)),
            const SizedBox(width: 12),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Monument Scanner',
                  style: GoogleFonts.playfairDisplay(
                      color: _gold, fontSize: 17, fontWeight: FontWeight.bold)),
              Text('Powered by Google Cloud Vision',
                  style: GoogleFonts.inter(
                      color: Colors.white38, fontSize: 10)),
            ])),
            if (!kIsWeb && _camReady && _cam != null) _iconBtn(
              _cam?.value.flashMode == FlashMode.torch
                  ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              () async {
                final next = _cam!.value.flashMode == FlashMode.torch
                    ? FlashMode.off : FlashMode.torch;
                await _cam!.setFlashMode(next);
                setState(() {});
              },
              color: _cam?.value.flashMode == FlashMode.torch
                  ? _gold : Colors.white54,
            ),
          ]),
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap,
      {Color color = Colors.white}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: Colors.black38, shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 18),
        ),
      );

  // ── Bottom bar ────────────────────────────────────────────────────────────────
  Widget _bottomBar() {
    return Positioned(bottom: 0, left: 0, right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 44),
        decoration: BoxDecoration(gradient: LinearGradient(
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.88)],
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
        )),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(
            _autoScan
                ? 'Scanning automatically every 5 seconds'
                : 'Tap the button to scan a monument',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
          ),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            // Gallery Upload
            _BottomBtn(
              icon: Icons.photo_library_rounded,
              label: 'Upload',
              color: Colors.white70,
              onTap: _pickImage,
            ),
            // Auto toggle
            _BottomBtn(
              icon: _autoScan
                  ? Icons.pause_rounded : Icons.play_arrow_rounded,
              label: _autoScan ? 'Stop' : 'Auto',
              color: _autoScan ? Colors.redAccent : Colors.white70,
              onTap: _toggleAutoScan,
            ),
            // Main shutter — on web captures live frame, on native uses camera package
            GestureDetector(
              onTap: _scanning ? null : (kIsWeb ? _scanWebLiveFrame : (_camReady ? _capture : null)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 72, height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _scanning ? Colors.white24 : _gold,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: _scanning ? [] : [
                    BoxShadow(color: _gold.withValues(alpha: 0.5),
                        blurRadius: 20, spreadRadius: 4),
                  ],
                ),
                child: _scanning
                    ? const Center(child: SizedBox(width: 28, height: 28,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5)))
                    : const Icon(Icons.center_focus_strong_rounded,
                        color: Color(0xFF1E1308), size: 30),
              ),
            ),
            // Info / Browse
            _BottomBtn(
              icon: _detected != null
                  ? Icons.info_outline_rounded : Icons.grid_view_rounded,
              label: _detected != null ? 'Info' : 'Browse',
              color: _detected != null ? _green : Colors.white70,
              onTap: _detected != null
                  ? () => _showInfo(_detected!) : _openBrowse,
            ),
          ]),
        ]),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _BottomBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _BottomBtn({required this.icon, required this.label,
      required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 50, height: 50,
        decoration: BoxDecoration(color: Colors.black38,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white12)),
        child: Icon(icon, color: color, size: 22),
      ),
      const SizedBox(height: 4),
      Text(label, style: GoogleFonts.inter(
          color: Colors.white38, fontSize: 10)),
    ]),
  );
}

class _ScanBrackets extends StatelessWidget {
  final AnimationController controller;
  final bool scanning;
  const _ScanBrackets({required this.controller, required this.scanning});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (_, __) => SizedBox(width: 200, height: 200,
      child: CustomPaint(painter: _BracketPainter(
        color: const Color(0xFFDFAF58).withValues(
            alpha: scanning
                ? 0.5 + controller.value * 0.5
                : 0.75),
      )),
    ),
  );
}

class _BracketPainter extends CustomPainter {
  final Color color;
  const _BracketPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color..strokeWidth = 2.5
        ..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    const l = 30.0;
    final w = size.width; final h = size.height;
    canvas.drawLine(Offset(0, l), Offset.zero, p);
    canvas.drawLine(Offset.zero, Offset(l, 0), p);
    canvas.drawLine(Offset(w - l, 0), Offset(w, 0), p);
    canvas.drawLine(Offset(w, 0), Offset(w, l), p);
    canvas.drawLine(Offset(0, h - l), Offset(0, h), p);
    canvas.drawLine(Offset(0, h), Offset(l, h), p);
    canvas.drawLine(Offset(w - l, h), Offset(w, h), p);
    canvas.drawLine(Offset(w, h), Offset(w, h - l), p);
  }
  @override
  bool shouldRepaint(_BracketPainter old) => old.color != color;
}

class _BrowseSheet extends StatelessWidget {
  final List<MonumentInfo> monuments;
  final void Function(MonumentInfo) onTap;
  const _BrowseSheet({required this.monuments, required this.onTap});
  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
    const SizedBox(height: 12),
    Container(width: 40, height: 4,
        decoration: BoxDecoration(color: Colors.white24,
            borderRadius: BorderRadius.circular(2))),
    const SizedBox(height: 16),
    Text('Monument Library', style: GoogleFonts.playfairDisplay(
        color: const Color(0xFFDFAF58), fontSize: 18,
        fontWeight: FontWeight.bold)),
    const SizedBox(height: 12),
    SizedBox(height: 190, child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: monuments.length,
      separatorBuilder: (_, __) => const SizedBox(width: 10),
      itemBuilder: (_, i) {
        final m = monuments[i];
        return GestureDetector(
          onTap: () => onTap(m),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(m.assetImage, width: 100, height: 130,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 100, height: 130, color: const Color(0xFF2E1E0C),
                    child: const Icon(Icons.account_balance_rounded,
                        color: Color(0xFFDFAF58), size: 36),
                  )),
            ),
            const SizedBox(height: 6),
            SizedBox(width: 100, child: Text(m.name, maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 10))),
          ]),
        );
      },
    )),
    const SizedBox(height: 20),
  ]);
}
