import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/google_vision_service.dart';

/// Shown when Google Vision identifies a landmark that isn't in our local DB.
/// Displays the Vision result in a beautiful, animated sheet.
class DetectedMonumentSheet extends StatefulWidget {
  final DetectedLandmark landmark;

  const DetectedMonumentSheet({super.key, required this.landmark});

  @override
  State<DetectedMonumentSheet> createState() => _DetectedMonumentSheetState();
}

class _DetectedMonumentSheetState extends State<DetectedMonumentSheet>
    with TickerProviderStateMixin {
  static const _gold = Color(0xFFDFAF58);
  static const _darkBg = Color(0xFF0D1420);
  static const _cardBg = Color(0xFF162233);
  static const _accentBlue = Color(0xFF4FC3F7);

  late AnimationController _revealCtrl;
  late Animation<double> _revealAnim;

  late AnimationController _shimmerCtrl;
  late Animation<double> _shimmerAnim;

  late AnimationController _radarCtrl;

  // Confidence ring animation
  late AnimationController _confCtrl;
  late Animation<double> _confAnim;

  @override
  void initState() {
    super.initState();

    _revealCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _revealAnim =
        CurvedAnimation(parent: _revealCtrl, curve: Curves.easeOutCubic);
    _revealCtrl.forward();

    _shimmerCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat();
    _shimmerAnim = Tween<double>(begin: -1.0, end: 2.0).animate(
        CurvedAnimation(parent: _shimmerCtrl, curve: Curves.linear));

    _radarCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat();

    _confCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _confAnim = Tween<double>(begin: 0, end: widget.landmark.confidence)
        .animate(CurvedAnimation(parent: _confCtrl, curve: Curves.easeOut));
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _confCtrl.forward();
    });
  }

  @override
  void dispose() {
    _revealCtrl.dispose();
    _shimmerCtrl.dispose();
    _radarCtrl.dispose();
    _confCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.80,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, sc) => FadeTransition(
        opacity: _revealAnim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.15),
            end: Offset.zero,
          ).animate(_revealAnim),
          child: Container(
            decoration: const BoxDecoration(
              color: _darkBg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: ListView(
              controller: sc,
              padding: EdgeInsets.zero,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),

                // ── Radar hero ──
                _buildRadarHero(),

                const SizedBox(height: 20),

                // ── Name ──
                _buildNameSection(),

                const SizedBox(height: 16),

                // ── Confidence ring ──
                _buildConfidenceSection(),

                const SizedBox(height: 16),

                // ── GPS location ──
                if (widget.landmark.latitude != null &&
                    widget.landmark.longitude != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildGpsCard(),
                  ),

                const SizedBox(height: 16),

                // ── Vision API badge ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildApiCard(),
                ),

                const SizedBox(height: 16),

                // ── Not in DB notice ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildNotInDbCard(),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Radar hero ──────────────────────────────────────────────────────────────

  Widget _buildRadarHero() {
    return Container(
      height: 220,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF0A1628), Color(0xFF0D2040)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: _gold.withValues(alpha: 0.25), width: 1.5),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Radar rings
          ...List.generate(3, (i) {
            final radius = 40.0 + i * 30.0;
            return Container(
              width: radius * 2,
              height: radius * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: _accentBlue.withValues(alpha: 0.12 + i * 0.06),
                    width: 1),
              ),
            );
          }),

          // Rotating radar sweep
          AnimatedBuilder(
            animation: _radarCtrl,
            builder: (_, __) => Transform.rotate(
              angle: _radarCtrl.value * 2 * math.pi,
              child: SizedBox(
                width: 200,
                height: 200,
                child: CustomPaint(
                  painter: _RadarPainter(color: _accentBlue),
                ),
              ),
            ),
          ),

          // Shimmer "✓ Scanned" badge on top-right
          Positioned(
            top: 12,
            right: 12,
            child: AnimatedBuilder(
              animation: _shimmerAnim,
              builder: (_, child) => ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: const [_gold, Colors.white, _gold],
                  stops: [
                    (_shimmerAnim.value - 0.3).clamp(0.0, 1.0),
                    _shimmerAnim.value.clamp(0.0, 1.0),
                    (_shimmerAnim.value + 0.3).clamp(0.0, 1.0),
                  ],
                ).createShader(bounds),
                child: child,
              ),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _gold.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_rounded,
                        color: _gold, size: 13),
                    const SizedBox(width: 4),
                    Text('Scanned',
                        style: GoogleFonts.inter(
                            color: _gold,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),

          // Center icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _accentBlue.withValues(alpha: 0.25),
                  _accentBlue.withValues(alpha: 0.05),
                ],
              ),
              border:
                  Border.all(color: _accentBlue.withValues(alpha: 0.5), width: 1.5),
            ),
            child: const Icon(Icons.account_balance_rounded,
                color: _accentBlue, size: 28),
          ),

          // Bottom label
          Positioned(
            bottom: 14,
            child: Text(
              'LANDMARK DETECTED',
              style: GoogleFonts.inter(
                  color: _accentBlue.withValues(alpha: 0.7),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0),
            ),
          ),
        ],
      ),
    );
  }

  // ── Name section ────────────────────────────────────────────────────────────

  Widget _buildNameSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DETECTED MONUMENT',
              style: GoogleFonts.inter(
                  color: _accentBlue.withValues(alpha: 0.8),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.8)),
          const SizedBox(height: 6),
          Text(
            widget.landmark.name,
            style: GoogleFonts.playfairDisplay(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 60,
            height: 3,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [_gold, Color(0xFFE8C97A)]),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  // ── Confidence section ──────────────────────────────────────────────────────

  Widget _buildConfidenceSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _gold.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            // Ring chart
            AnimatedBuilder(
              animation: _confAnim,
              builder: (_, __) => SizedBox(
                width: 72,
                height: 72,
                child: CustomPaint(
                  painter: _ConfRingPainter(
                    value: _confAnim.value,
                    gold: _gold,
                  ),
                  child: Center(
                    child: Text(
                      '${(_confAnim.value * 100).toStringAsFixed(0)}%',
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Vision Confidence',
                      style: GoogleFonts.inter(
                          color: _gold,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    _confidenceLabel(widget.landmark.confidence),
                    style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                        height: 1.4),
                  ),
                  const SizedBox(height: 8),
                  // Mini progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: AnimatedBuilder(
                      animation: _confAnim,
                      builder: (_, __) => LinearProgressIndicator(
                        value: _confAnim.value,
                        backgroundColor: Colors.white12,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _confidenceColor(widget.landmark.confidence),
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── GPS card ────────────────────────────────────────────────────────────────

  Widget _buildGpsCard() {
    final lat = widget.landmark.latitude!;
    final lng = widget.landmark.longitude!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.location_on_rounded,
                color: Colors.greenAccent, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('GPS Coordinates',
                    style: GoogleFonts.inter(
                        color: Colors.white38,
                        fontSize: 10,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  '${lat.toStringAsFixed(5)}° N, ${lng.toStringAsFixed(5)}° E',
                  style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFeatures: [const FontFeature.tabularFigures()]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── API source card ─────────────────────────────────────────────────────────

  Widget _buildApiCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _accentBlue.withValues(alpha: 0.08),
            _accentBlue.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _accentBlue.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _accentBlue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.cloud_done_rounded,
                color: _accentBlue, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Powered by Google Cloud Vision',
                    style: GoogleFonts.inter(
                        color: _accentBlue,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(
                    'Landmark Detection API · Live scan result',
                    style: GoogleFonts.inter(
                        color: Colors.white38, fontSize: 10)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: Colors.greenAccent.withValues(alpha: 0.3)),
            ),
            child: Text('LIVE',
                style: GoogleFonts.inter(
                    color: Colors.greenAccent,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1)),
          ),
        ],
      ),
    );
  }

  // ── Not-in-DB notice ────────────────────────────────────────────────────────

  Widget _buildNotInDbCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _gold.withValues(alpha: 0.08),
            _gold.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _gold.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: _gold, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Not Yet in Our Database',
                    style: GoogleFonts.inter(
                        color: _gold,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(
                  'Google Vision successfully identified this landmark. '
                  'We\'re continuously expanding our Egyptian heritage database — '
                  'this monument will be added soon!',
                  style: GoogleFonts.inter(
                      color: Colors.white54, fontSize: 12, height: 1.55),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  String _confidenceLabel(double confidence) {
    if (confidence >= 0.90) return 'Excellent match — very high certainty';
    if (confidence >= 0.75) return 'Strong match — high certainty';
    if (confidence >= 0.60) return 'Good match — moderate certainty';
    return 'Possible match — consider rescanning';
  }

  Color _confidenceColor(double confidence) {
    if (confidence >= 0.80) return Colors.greenAccent;
    if (confidence >= 0.65) return _gold;
    return Colors.orangeAccent;
  }
}

// ── Radar sweep painter ──────────────────────────────────────────────────────

class _RadarPainter extends CustomPainter {
  final Color color;
  const _RadarPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()..style = PaintingStyle.fill;

    final gradient = SweepGradient(
      colors: [color.withValues(alpha: 0.0), color.withValues(alpha: 0.25)],
      stops: const [0.0, 1.0],
    );
    paint.shader =
        gradient.createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_RadarPainter old) => old.color != color;
}

// ── Confidence ring painter ──────────────────────────────────────────────────

class _ConfRingPainter extends CustomPainter {
  final double value;
  final Color gold;
  const _ConfRingPainter({required this.value, required this.gold});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 5;

    // Background ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white12
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6,
    );

    // Foreground arc
    final color =
        value >= 0.80 ? Colors.greenAccent : value >= 0.65 ? gold : Colors.orangeAccent;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * value,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ConfRingPainter old) =>
      old.value != value || old.gold != gold;
}
