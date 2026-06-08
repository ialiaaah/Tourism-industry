import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/ar_models.dart';
import '../../services/monument_data_service.dart';
import '../../services/game_progress_service.dart';
import '../../services/audio_narration_service.dart';
import 'treasure_hunt_screen.dart';

class ARExperienceScreen extends StatefulWidget {
  final MonumentInfo monument;

  const ARExperienceScreen({super.key, required this.monument});

  @override
  State<ARExperienceScreen> createState() => _ARExperienceScreenState();
}

class _ARExperienceScreenState extends State<ARExperienceScreen>
    with TickerProviderStateMixin {
  late AnimationController _guideCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _radarCtrl;
  late AudioNarrationService _audioService;

  ARHotspot? _selectedHotspot;
  bool _showTimeline = false;
  double _parallaxOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _guideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _radarCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _audioService = AudioNarrationService();
  }

  @override
  void dispose() {
    _guideCtrl.dispose();
    _pulseCtrl.dispose();
    _radarCtrl.dispose();
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = Provider.of<GameProgressService>(context);
    final unlockedList = progress.unlockedHotspots[widget.monument.id] ?? [];
    final currentText = widget.monument.overview;

    return Scaffold(
      backgroundColor: const Color(0xFF070B19),
      body: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _parallaxOffset = (_parallaxOffset + details.delta.dx * 0.05)
                .clamp(-30.0, 30.0);
          });
        },
        child: Stack(
          children: [
            // ── Background image with Parallax ───────────────────────────────
            Positioned.fill(
              left: -30 + _parallaxOffset,
              right: -30 - _parallaxOffset,
              child: Opacity(
                opacity: 0.65,
                child: Image.asset(
                  widget.monument.assetImage,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: const Color(0xFF0F1A30),
                    child: Center(
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: Colors.white24,
                        size: 64,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Deep overlay gradient ────────────────────────────────────────
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Color(0xBB070B19),
                      Color(0xFF070B19),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.0, 0.6, 1.0],
                  ),
                ),
              ),
            ),

            // ── Holographic Radar Scan Line ──────────────────────────────────
            AnimatedBuilder(
              animation: _radarCtrl,
              builder: (context, child) {
                return Positioned(
                  top: MediaQuery.of(context).size.height * _radarCtrl.value,
                  left: 0,
                  right: 0,
                  height: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4CD87A).withOpacity(0.5),
                          blurRadius: 15,
                          spreadRadius: 4,
                        )
                      ],
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          const Color(0xFF4CD87A).withOpacity(0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            // ── Compass & Calibration UI ──────────────────────────────────────
            Positioned(
              top: 50,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.explore_outlined, color: Color(0xFF4CD87A), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'HD AR CALIBRATED',
                      style: GoogleFonts.spaceMono(
                        color: const Color(0xFF4CD87A),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Main UI Content ──────────────────────────────────────────────
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(context),
                  Expanded(
                    child: Stack(
                      children: [
                        // ── Hotspots ─────────────────────────────────────────
                        ...widget.monument.arHotspots.map((hs) {
                          final isUnlocked = unlockedList.contains(hs.id);
                          return _buildHotspotMarker(hs, isUnlocked, progress);
                        }),

                        // ── AR Guide Character ───────────────────────────────
                        _buildARGuide(),

                        // ── Selected Hotspot glassmorphic panel ──────────────
                        if (_selectedHotspot != null)
                          _buildSelectedHotspotPanel(unlockedList.contains(_selectedHotspot!.id)),
                      ],
                    ),
                  ),
                  _buildBottomControls(progress),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Column(
            children: [
              Text(
                widget.monument.name.toUpperCase(),
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                widget.monument.era,
                style: GoogleFonts.outfit(
                  color: const Color(0xFFDFAF58),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(width: 48), // Balancing spacer
        ],
      ),
    );
  }

  Widget _buildHotspotMarker(ARHotspot hs, bool isUnlocked, GameProgressService progress) {
    return Positioned(
      left: MediaQuery.of(context).size.width * hs.position.dx - 24,
      top: MediaQuery.of(context).size.height * 0.55 * hs.position.dy,
      child: AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (context, child) {
          final scale = 1.0 + (_pulseCtrl.value * 0.25);
          final opacity = 0.5 + ((1.0 - _pulseCtrl.value) * 0.5);

          return GestureDetector(
            onTap: () async {
              setState(() {
                _selectedHotspot = hs;
              });
              if (!isUnlocked) {
                final success = await progress.unlockHotspot(widget.monument.id, hs.id);
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF4CD87A),
                      behavior: SnackBarBehavior.floating,
                      content: Row(
                        children: [
                          const Icon(Icons.workspace_premium, color: Colors.white),
                          const SizedBox(width: 10),
                          Text(
                            'New Hotspot Unlocked! +20 Points',
                            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              }
            },
            child: SizedBox(
              width: 60,
              height: 60,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer glowing ring
                  Container(
                    width: 44 * scale,
                    height: 44 * scale,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.transparent,
                      border: Border.all(
                        color: isUnlocked ? const Color(0xFF4CD87A).withOpacity(opacity) : const Color(0xFF2196F3).withOpacity(opacity),
                        width: 2.0,
                      ),
                    ),
                  ),
                  // Inner solid button
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: isUnlocked
                            ? [const Color(0xFF4CD87A), const Color(0xFF1E88E5)]
                            : [const Color(0xFF2196F3), const Color(0xFF0D47A1)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isUnlocked ? const Color(0xFF4CD87A).withOpacity(0.6) : const Color(0xFF2196F3).withOpacity(0.6),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      hs.icon,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildARGuide() {
    return AnimatedBuilder(
      animation: _guideCtrl,
      builder: (context, child) {
        final bobbing = math.sin(_guideCtrl.value * math.pi * 2) * 8;
        return Positioned(
          left: 20,
          bottom: 120 + bobbing,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                constraints: const BoxConstraints(maxWidth: 220),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xDC111C36),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  border: Border.all(color: const Color(0xFFDFAF58).withOpacity(0.5), width: 1.5),
                ),
                child: Text(
                  _selectedHotspot != null
                      ? 'Incredible discovery! Let\'s read about ${_selectedHotspot!.title}.'
                      : 'Hi, I\'m Cleo! Tap the floating holographic nodes to unlock deep history facts.',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFDFAF58), width: 2),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                      ),
                    ),
                    child: const Center(
                      child: Text('🐱', style: TextStyle(fontSize: 24)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CLEO',
                        style: GoogleFonts.spaceMono(
                          color: const Color(0xFFDFAF58),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'AR Guide Bot',
                        style: GoogleFonts.outfit(
                          color: Colors.white70,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSelectedHotspotPanel(bool isUnlocked) {
    final hs = _selectedHotspot!;
    return Positioned(
      left: 20,
      right: 20,
      top: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xED122040),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
          boxShadow: const [
            BoxShadow(color: Colors.black54, blurRadius: 15, spreadRadius: 2),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(hs.icon, color: const Color(0xFFDFAF58), size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hs.title,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                  onPressed: () => setState(() => _selectedHotspot = null),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              hs.description,
              style: GoogleFonts.outfit(
                color: Colors.white70,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls(GameProgressService progress) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF0D1424),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Timeline Expanded view ─────────────────────────────────────────
          if (_showTimeline) ...[
            Text(
              'HISTORICAL TIMELINE',
              style: GoogleFonts.spaceMono(
                color: const Color(0xFFDFAF58),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: widget.monument.timeline.length,
                separatorBuilder: (context, index) => Container(
                  width: 24,
                  alignment: Alignment.center,
                  child: Container(height: 2, color: Colors.white12),
                ),
                itemBuilder: (context, index) {
                  final event = widget.monument.timeline[index];
                  return Container(
                    width: 160,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF162544),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.year,
                          style: GoogleFonts.spaceMono(
                            color: const Color(0xFF4CD87A),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          event.title,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Expanded(
                          child: Text(
                            event.description,
                            style: GoogleFonts.outfit(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],

          Row(
            children: [
              // Audio narration play/stop button
              AnimatedBuilder(
                animation: _audioService,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: _audioService.isPlaying
                          ? const LinearGradient(colors: [Color(0xFFEF5350), Color(0xFFD32F2F)])
                          : const LinearGradient(colors: [Color(0xFF4CD87A), Color(0xFF2E7D32)]),
                    ),
                    child: IconButton(
                      icon: Icon(
                        _audioService.isPlaying ? Icons.stop_rounded : Icons.volume_up_rounded,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        _audioService.speak(widget.monument.audioNarrationText);
                      },
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              // Timeline expand button
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3154),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: Icon(_showTimeline ? Icons.keyboard_arrow_down : Icons.timeline),
                  label: Text(
                    _showTimeline ? 'Close Timeline' : 'Chronology Ribbon',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  onPressed: () => setState(() => _showTimeline = !_showTimeline),
                ),
              ),
              const SizedBox(width: 12),
              // Start Treasure Hunt button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDFAF58),
                  foregroundColor: const Color(0xFF070B19),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                ),
                icon: const Icon(Icons.military_tech_rounded),
                label: Text(
                  'Treasure Hunt',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TreasureHuntScreen(monument: widget.monument),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
