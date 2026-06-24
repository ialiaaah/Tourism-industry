import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/ar_models.dart';
import '../../services/monument_data_service.dart';
import '../../services/game_progress_service.dart';
import '../../services/audio_narration_service.dart';
import '../../theme/app_theme.dart';
import 'treasure_hunt_screen.dart';

// ── Hotspot type → accent color ───────────────────────────────────────────────
const _kHotspotColors = {
  HotspotType.history:      Color(0xFFDFAF58), // gold
  HotspotType.architecture: Color(0xFF4FC3F7), // sky blue
  HotspotType.story:        Color(0xFFCE93D8), // lavender
  HotspotType.symbol:       Color(0xFF80CBC4), // teal
  HotspotType.restoration:  Color(0xFFA5D6A7), // green
  HotspotType.nearby:       Color(0xFFEF9A9A), // rose
};

Color _hotspotColor(HotspotType t) =>
    _kHotspotColors[t] ?? AppColors.gold;

String _hotspotIntro(HotspotType t) {
  switch (t) {
    case HotspotType.history:
      return 'Here\'s a history fact I love! ';
    case HotspotType.architecture:
      return 'Check out this architectural detail! ';
    case HotspotType.story:
      return 'Ooh, there\'s a fascinating story here! ';
    case HotspotType.symbol:
      return 'This symbol holds deep meaning! ';
    case HotspotType.restoration:
      return 'Let me tell you about the restoration work here! ';
    case HotspotType.nearby:
      return 'Something interesting nearby! ';
  }
}

class ARExperienceScreen extends StatefulWidget {
  final MonumentInfo monument;

  /// If provided, this captured image is displayed instead of the static asset.
  final Uint8List? capturedImage;

  const ARExperienceScreen({
    super.key,
    required this.monument,
    this.capturedImage,
  });

  @override
  State<ARExperienceScreen> createState() => _ARExperienceScreenState();
}

class _ARExperienceScreenState extends State<ARExperienceScreen>
    with TickerProviderStateMixin {

  // ── Animation controllers ─────────────────────────────────────────────────
  late AnimationController _pulseCtrl;
  late AnimationController _radarCtrl;
  late AnimationController _cleoCtrl;   // Cleo bob
  late AnimationController _mouthCtrl;  // Cleo speaking indicator
  late AnimationController _panelCtrl;  // hotspot panel slide-in

  // ── State ─────────────────────────────────────────────────────────────────
  ARHotspot? _selectedHotspot;
  bool _showTimeline = false;
  double _parallaxOffset = 0.0;

  // ── Audio ─────────────────────────────────────────────────────────────────
  late AudioNarrationService _audio;
  bool _isSpeaking = false;

  // ── Cleo message state ────────────────────────────────────────────────────
  String _cleoMessage =
      'Hi, I\'m Cleo! 🐱 Tap the glowing markers on the image to explore this monument\'s secrets. I\'ll narrate each one for you!';

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _radarCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _cleoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _mouthCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..repeat(reverse: true);

    _panelCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    _audio = AudioNarrationService();

    // Cleo greets and speaks the monument overview after a short delay
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _cleoSpeak(
        'Welcome to ${widget.monument.name}! I\'m Cleo, your guide. ${widget.monument.overview} Tap the glowing markers to explore more!',
        isIntro: true,
      );
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _radarCtrl.dispose();
    _cleoCtrl.dispose();
    _mouthCtrl.dispose();
    _panelCtrl.dispose();
    _audio.dispose();
    super.dispose();
  }

  // ── Cleo TTS ──────────────────────────────────────────────────────────────
  Future<void> _cleoSpeak(String text, {bool isIntro = false}) async {
    if (!mounted) return;
    setState(() {
      _isSpeaking = true;
      if (isIntro) _cleoMessage = 'Welcome to ${widget.monument.name}! Tap the glowing markers on the image to explore!';
    });
    await _audio.speak(text);
    if (mounted) setState(() => _isSpeaking = false);
  }

  Future<void> _cleoSpeakHotspot(ARHotspot hs) async {
    final intro = _hotspotIntro(hs.type);
    final fullText = '$intro${hs.description}';
    setState(() {
      _cleoMessage = 'Incredible discovery! ${hs.title}: ${hs.description}';
      _isSpeaking = true;
    });
    _panelCtrl.forward(from: 0);
    await _audio.speak(fullText);
    if (mounted) setState(() => _isSpeaking = false);
  }

  Future<void> _toggleCleoVoice() async {
    if (_isSpeaking) {
      await _audio.stop();
      if (mounted) setState(() => _isSpeaking = false);
    } else {
      final text = _selectedHotspot != null
          ? '${_hotspotIntro(_selectedHotspot!.type)}${_selectedHotspot!.description}'
          : 'Welcome to ${widget.monument.name}! ${widget.monument.overview}';
      await _cleoSpeak(text);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final progress = Provider.of<GameProgressService>(context);
    final unlockedList =
        progress.unlockedHotspots[widget.monument.id] ?? [];

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: GestureDetector(
        onPanUpdate: (d) {
          setState(() {
            _parallaxOffset =
                (_parallaxOffset + d.delta.dx * 0.05).clamp(-28.0, 28.0);
          });
        },
        child: Stack(
          children: [
            // ① Background: captured image or asset ─────────────────────────
            Positioned.fill(
              left: -28 + _parallaxOffset,
              right: -28 - _parallaxOffset,
              child: _buildBackground(),
            ),

            // ② Warm gradient vignette ──────────────────────────────────────
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0x551E1308),
                      Color(0xBB1E1308),
                      Color(0xFF1E1308),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),

            // ③ Radar scan line (gold) ──────────────────────────────────────
            AnimatedBuilder(
              animation: _radarCtrl,
              builder: (_, __) => Positioned(
                top: MediaQuery.of(context).size.height * 0.65 *
                    _radarCtrl.value,
                left: 0,
                right: 0,
                height: 3,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppColors.gold.withValues(alpha: 0.55),
                        Colors.transparent,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.3),
                        blurRadius: 12,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ④ Hotspot markers on the image ────────────────────────────────
            SafeArea(
              bottom: false,
              child: Stack(
                children: [
                  ...widget.monument.arHotspots.map((hs) {
                    final isUnlocked = unlockedList.contains(hs.id);
                    return _buildHotspotMarker(hs, isUnlocked, progress);
                  }),
                ],
              ),
            ),

            // ⑤ Selected hotspot panel ──────────────────────────────────────
            if (_selectedHotspot != null)
              _buildSelectedHotspotPanel(
                unlockedList.contains(_selectedHotspot!.id),
              ),

            // ⑥ Main chrome: header + Cleo + bottom controls ────────────────
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(context),
                  const Spacer(),
                  _buildCleoSection(),
                  _buildBottomControls(progress),
                ],
              ),
            ),

            // ⑦ AR CALIBRATED badge ─────────────────────────────────────────
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              right: 16,
              child: _buildCalibrationBadge(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Background ────────────────────────────────────────────────────────────
  Widget _buildBackground() {
    if (widget.capturedImage != null) {
      return Image.memory(
        widget.capturedImage!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _assetBackground(),
      );
    }
    return _assetBackground();
  }

  Widget _assetBackground() => Image.asset(
        widget.monument.assetImage,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: AppColors.surface,
          child: Center(
            child: Text(widget.monument.emoji,
                style: const TextStyle(fontSize: 80)),
          ),
        ),
      );

  // ── Calibration badge ─────────────────────────────────────────────────────
  Widget _buildCalibrationBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) => Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.success.withValues(
                    alpha: 0.5 + _pulseCtrl.value * 0.5),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            widget.capturedImage != null
                ? 'YOUR SCAN · LIVE'
                : 'AR · CALIBRATED',
            style: GoogleFonts.spaceMono(
              color: AppColors.gold,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          _GlassBtn(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () async {
              await _audio.stop();
              if (context.mounted) Navigator.pop(context);
            },
          ),
          const Spacer(),
          Column(
            children: [
              Text(
                widget.monument.name.toUpperCase(),
                style: GoogleFonts.playfairDisplay(
                  color: AppColors.gold,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                widget.monument.era,
                style: GoogleFonts.inter(
                  color: AppColors.sand,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Mute/speak toggle
          _GlassBtn(
            icon: _isSpeaking
                ? Icons.volume_off_rounded
                : Icons.record_voice_over_rounded,
            accent: _isSpeaking ? AppColors.terra : AppColors.gold,
            onTap: _toggleCleoVoice,
          ),
        ],
      ),
    );
  }

  // ── Hotspot marker ────────────────────────────────────────────────────────
  Widget _buildHotspotMarker(
      ARHotspot hs, bool isUnlocked, GameProgressService progress) {
    final accent = _hotspotColor(hs.type);
    final size = MediaQuery.of(context).size;

    return Positioned(
      left: size.width * hs.position.dx - 32,
      top: size.height * 0.58 * hs.position.dy,
      child: AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (context, _) {
          final pulse = 1.0 + _pulseCtrl.value * 0.20;
          final ringOpacity = 0.4 + (1.0 - _pulseCtrl.value) * 0.6;
          final isSelected = _selectedHotspot?.id == hs.id;

          return GestureDetector(
            onTap: () async {
              HapticFeedback.mediumImpact();
              setState(() => _selectedHotspot = hs);
              if (!isUnlocked) {
                final ok =
                    await progress.unlockHotspot(widget.monument.id, hs.id);
                if (ok && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    backgroundColor: accent,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    margin:
                        const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    content: Row(children: [
                      const Icon(Icons.workspace_premium_rounded,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 10),
                      Text('Hotspot Unlocked! +20 pts',
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ]),
                  ));
                }
              }
              // Cleo speaks the hotspot
              _cleoSpeakHotspot(hs);
            },
            child: SizedBox(
              width: 72,
              height: 90,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Label chip
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? accent.withValues(alpha: 0.25)
                          : Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: accent.withValues(
                              alpha: isSelected ? 0.9 : 0.5),
                          width: isSelected ? 1.5 : 1.0),
                    ),
                    child: Text(
                      hs.title,
                      style: GoogleFonts.outfit(
                        color: accent,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 5),
                  // Pin
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer pulse ring
                      Container(
                        width: 52 * pulse,
                        height: 52 * pulse,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                accent.withValues(alpha: ringOpacity),
                            width: isSelected ? 2.5 : 1.6,
                          ),
                        ),
                      ),
                      // Solid core
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: isSelected ? 40 : 32,
                        height: isSelected ? 40 : 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: isUnlocked
                                ? [accent, accent.withValues(alpha: 0.45)]
                                : [
                                    accent.withValues(alpha: 0.45),
                                    accent.withValues(alpha: 0.15)
                                  ],
                          ),
                          border: isUnlocked
                              ? null
                              : Border.all(
                                  color: accent.withValues(alpha: 0.7),
                                  width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withValues(
                                  alpha: isSelected ? 0.85 : 0.45),
                              blurRadius: isSelected ? 20 : 10,
                              spreadRadius: isSelected ? 5 : 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          isUnlocked
                              ? hs.icon
                              : Icons.lock_outline_rounded,
                          color: Colors.white,
                          size: isSelected ? 19 : 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Hotspot info panel ────────────────────────────────────────────────────
  Widget _buildSelectedHotspotPanel(bool isUnlocked) {
    final hs = _selectedHotspot!;
    final accent = _hotspotColor(hs.type);
    final typeName =
        hs.type.name[0].toUpperCase() + hs.type.name.substring(1);

    return Positioned.fill(
      child: GestureDetector(
        onTap: () async {
          await _audio.stop();
          setState(() {
            _selectedHotspot = null;
            _isSpeaking = false;
            _cleoMessage = 'Tap another glowing marker to keep exploring!';
          });
        },
        child: Container(
          color: Colors.black.withValues(alpha: 0.5), // Dim the background
          child: Center(
            child: GestureDetector(
              onTap: () {}, // Prevent tap-to-close when clicking inside the card
              child: TweenAnimationBuilder<double>(
                key: ValueKey(hs.id),
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutBack, // Elastic bounce transition
                builder: (context, v, child) => Transform.scale(
                  scale: 0.85 + v * 0.15,
                  child: Opacity(
                    opacity: v.clamp(0.0, 1.0),
                    child: child,
                  ),
                ),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.98),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: accent.withValues(alpha: 0.6), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.25),
                        blurRadius: 30,
                        spreadRadius: 3,
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.6),
                        blurRadius: 15,
                      ),
                    ],
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Content container
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Header
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: accent.withValues(alpha: 0.15),
                                    border: Border.all(
                                        color: accent.withValues(alpha: 0.5)),
                                  ),
                                  child: Icon(hs.icon, color: accent, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        hs.title,
                                        style: GoogleFonts.playfairDisplay(
                                          color: AppColors.cream,
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Row(
                                        children: [
                                          _Chip(
                                              label: typeName,
                                              color: accent),
                                          const SizedBox(width: 6),
                                          _Chip(
                                            label: isUnlocked ? '✓ Unlocked' : '🔒 Locked',
                                            color: isUnlocked
                                                ? AppColors.success
                                                : AppColors.muted,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            // Divider
                            Container(
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [
                                  Colors.transparent,
                                  accent.withValues(alpha: 0.45),
                                  Colors.transparent,
                                ]),
                              ),
                            ),
                            const SizedBox(height: 14),
                            // Description
                            Text(
                              hs.description,
                              style: GoogleFonts.inter(
                                color: AppColors.sand,
                                fontSize: 13.5,
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Footer
                            Row(
                              children: [
                                // Speaking wave indicator
                                if (_isSpeaking) ...[
                                  AnimatedBuilder(
                                    animation: _mouthCtrl,
                                    builder: (_, __) => Row(
                                      children: List.generate(
                                        4,
                                        (i) => Container(
                                          width: 3,
                                          height: 6.0 +
                                              math.sin(_mouthCtrl.value * math.pi +
                                                      i * 0.8) *
                                                  6,
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 1.5),
                                          decoration: BoxDecoration(
                                            color:
                                                accent.withValues(alpha: 0.85),
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Cleo is speaking…',
                                    style: GoogleFonts.outfit(
                                      color: accent.withValues(alpha: 0.8),
                                      fontSize: 10,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ] else ...[
                                  Icon(Icons.spatial_audio_off_rounded,
                                      color: AppColors.muted, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Tap voice icon to replay',
                                    style: GoogleFonts.outfit(
                                        color: AppColors.muted, fontSize: 10),
                                  ),
                                ],
                                const Spacer(),
                                if (isUnlocked)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: AppColors.gold.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                          color: AppColors.gold.withValues(alpha: 0.35)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.workspace_premium_rounded,
                                            color: AppColors.gold, size: 12),
                                        const SizedBox(width: 4),
                                        Text(
                                          '+20 pts',
                                          style: GoogleFonts.spaceMono(
                                            color: AppColors.gold,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Close button in the top-left corner
                      Positioned(
                        left: -8,
                        top: -8,
                        child: GestureDetector(
                          onTap: () async {
                            await _audio.stop();
                            setState(() {
                              _selectedHotspot = null;
                              _isSpeaking = false;
                              _cleoMessage =
                                  'Tap another glowing marker to keep exploring!';
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceAlt,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: accent.withValues(alpha: 0.6),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              color: accent,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Cleo section ──────────────────────────────────────────────────────────
  Widget _buildCleoSection() {
    return AnimatedBuilder(
      animation: _cleoCtrl,
      builder: (_, __) {
        final bob = math.sin(_cleoCtrl.value * math.pi * 2) * 6;
        return Padding(
          padding: EdgeInsets.only(
              left: 16, right: 16, bottom: 12 + bob),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Cleo avatar
              GestureDetector(
                onTap: _toggleCleoVoice,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [AppColors.surface, AppColors.surfaceAlt],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                          color: _isSpeaking
                              ? AppColors.terra
                              : AppColors.gold,
                          width: _isSpeaking ? 2.5 : 2.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (_isSpeaking
                                    ? AppColors.terra
                                    : AppColors.gold)
                                .withValues(alpha: 0.4),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _isSpeaking ? '😺' : '🐱',
                          style: const TextStyle(fontSize: 26),
                        ),
                      ),
                    ),
                    // Speaking badge
                    if (_isSpeaking)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: AppColors.terra,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppColors.bg, width: 2),
                          ),
                          child: const Icon(Icons.volume_up_rounded,
                              color: Colors.white, size: 9),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Speech bubble
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    border: Border.all(
                      color: (_isSpeaking
                              ? AppColors.terra
                              : AppColors.gold)
                          .withValues(alpha: 0.45),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            'CLEO',
                            style: GoogleFonts.spaceMono(
                              color: AppColors.gold,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isSpeaking ? '• narrating' : '• AR Guide',
                            style: GoogleFonts.inter(
                              color: _isSpeaking
                                  ? AppColors.terra
                                  : AppColors.muted,
                              fontSize: 9,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          if (_isSpeaking) ...[
                            const SizedBox(width: 6),
                            AnimatedBuilder(
                              animation: _mouthCtrl,
                              builder: (_, __) => Row(
                                children: List.generate(
                                  3,
                                  (i) => Container(
                                    width: 3,
                                    height: 3.0 +
                                        math.sin(_mouthCtrl.value *
                                                math.pi +
                                            i) *
                                            3,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 1),
                                    decoration: BoxDecoration(
                                      color: AppColors.terra
                                          .withValues(alpha: 0.8),
                                      borderRadius:
                                          BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _cleoMessage,
                        style: GoogleFonts.inter(
                          color: AppColors.sand,
                          fontSize: 11.5,
                          height: 1.45,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Bottom controls ───────────────────────────────────────────────────────
  Widget _buildBottomControls(GameProgressService progress) {
    final unlockedCount =
        (progress.unlockedHotspots[widget.monument.id] ?? []).length;
    final totalCount = widget.monument.arHotspots.length;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(
              color: AppColors.gold.withValues(alpha: 0.2), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress bar
          Row(
            children: [
              Text(
                '$unlockedCount / $totalCount hotspots explored',
                style: GoogleFonts.inter(
                  color: AppColors.sand,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${((unlockedCount / totalCount.clamp(1, 9999)) * 100).round()}%',
                style: GoogleFonts.spaceMono(
                    color: AppColors.gold,
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: unlockedCount / totalCount.clamp(1, 9999),
              minHeight: 6,
              backgroundColor: AppColors.surfaceAlt,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
            ),
          ),
          const SizedBox(height: 14),

          // Timeline + Treasure Hunt row
          if (_showTimeline) ...[
            Text(
              'HISTORICAL TIMELINE',
              style: GoogleFonts.spaceMono(
                color: AppColors.gold,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 108,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: widget.monument.timeline.length,
                separatorBuilder: (_, __) => Container(
                  width: 20,
                  alignment: Alignment.center,
                  child: Container(height: 2, color: AppColors.divider),
                ),
                itemBuilder: (_, i) {
                  final ev = widget.monument.timeline[i];
                  return Container(
                    width: 155,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.border.withValues(alpha: 0.8)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ev.year,
                            style: GoogleFonts.spaceMono(
                                color: AppColors.gold,
                                fontWeight: FontWeight.bold,
                                fontSize: 11)),
                        const SizedBox(height: 4),
                        Text(ev.title,
                            style: GoogleFonts.outfit(
                                color: AppColors.cream,
                                fontWeight: FontWeight.bold,
                                fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Expanded(
                          child: Text(ev.description,
                              style: GoogleFonts.inter(
                                  color: AppColors.sand, fontSize: 9.5),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],

          Row(
            children: [
              // Timeline toggle
              Expanded(
                child: _BottomBtn(
                  icon: _showTimeline
                      ? Icons.keyboard_arrow_down_rounded
                      : Icons.timeline_rounded,
                  label: _showTimeline ? 'Close' : 'Timeline',
                  color: AppColors.sand,
                  onTap: () =>
                      setState(() => _showTimeline = !_showTimeline),
                ),
              ),
              const SizedBox(width: 10),
              // Treasure Hunt
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: () async {
                    await _audio.stop();
                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TreasureHuntScreen(
                              monument: widget.monument),
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.terra, Color(0xFFE07040)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.terra.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.military_tech_rounded,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Treasure Hunt',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Shared small widgets ──────────────────────────────────────────────────────

class _GlassBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color accent;
  const _GlassBtn({
    required this.icon,
    required this.onTap,
    this.accent = AppColors.gold,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: 0.5),
            border: Border.all(color: accent.withValues(alpha: 0.35)),
          ),
          child: Icon(icon, color: accent, size: 18),
        ),
      );
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(
          label,
          style: GoogleFonts.spaceMono(
            color: color,
            fontSize: 8.5,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.4,
          ),
        ),
      );
}

class _BottomBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _BottomBtn(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(label,
                  style: GoogleFonts.outfit(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 12)),
            ],
          ),
        ),
      );
}
