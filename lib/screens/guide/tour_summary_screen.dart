import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

class TourSummaryScreen extends StatelessWidget {
  final String title;
  final String accessCode;
  final int stopsCount;

  const TourSummaryScreen({
    Key? key,
    required this.title,
    required this.accessCode,
    required this.stopsCount,
  }) : super(key: key);

  // ── Palette ────────────────────────────────────────────────────────────────
  static const _bg      = Color(0xFF1E1308);
  static const _card    = Color(0xFF2E1E0C);
  static const _cardAlt = Color(0xFF3A2410);
  static const _gold    = Color(0xFFDFAF58);
  static const _terra   = Color(0xFFD4581E);
  static const _cream   = Color(0xFFF5EDD8);
  static const _sand    = Color(0xFFE0C896);
  static const _muted   = Color(0xFF8A7560);

  void _copyCode(BuildContext context) {
    Clipboard.setData(ClipboardData(text: accessCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _cardAlt,
        content: Row(children: [
          const Icon(Icons.check_circle_rounded, color: _gold, size: 18),
          const SizedBox(width: 8),
          Text('Access code copied to clipboard!',
              style: GoogleFonts.inter(color: _cream)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _card,
        foregroundColor: _cream,
        elevation: 0,
        title: Text('Tour Ready',
            style: GoogleFonts.playfairDisplay(
                color: _gold, fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.home_rounded),
          tooltip: 'Back to home',
          onPressed: () =>
              Navigator.popUntil(context, (route) => route.isFirst),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Success icon ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _gold.withValues(alpha: 0.12),
                border: Border.all(color: _gold.withValues(alpha: 0.5), width: 2),
              ),
              child: const Icon(Icons.check_rounded, color: _gold, size: 56),
            ),
            const SizedBox(height: 22),

            Text('Tour Created Successfully!',
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                    color: _cream, fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              '$title  •  $stopsCount stops',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: _muted, fontSize: 14),
            ),

            const SizedBox(height: 36),

            // ── Access code card ──────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _gold.withValues(alpha: 0.4)),
              ),
              child: Column(
                children: [
                  Text('Tourist Access Code',
                      style: GoogleFonts.inter(
                          color: _sand,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2)),
                  const SizedBox(height: 12),

                  // Code + copy
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        accessCode,
                        style: GoogleFonts.spaceMono(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: _cream,
                          letterSpacing: 6,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded,
                            color: _gold, size: 22),
                        tooltip: 'Copy code',
                        onPressed: () => _copyCode(context),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // QR code on white background
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: QrImageView(
                      data: accessCode,
                      version: QrVersions.auto,
                      size: 190,
                    ),
                  ),

                  const SizedBox(height: 14),

                  Text('Share this code or QR with your tourists.',
                      textAlign: TextAlign.center,
                      style:
                          GoogleFonts.inter(color: _muted, fontSize: 12)),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── Info chips ────────────────────────────────────────────────────
            Row(
              children: [
                _InfoChip(
                    icon: Icons.tour_rounded,
                    label: '$stopsCount Stops'),
                const SizedBox(width: 10),
                _InfoChip(
                    icon: Icons.qr_code_rounded,
                    label: 'QR Ready'),
                const SizedBox(width: 10),
                _InfoChip(
                    icon: Icons.cloud_done_rounded,
                    label: 'Saved'),
              ],
            ),

            const SizedBox(height: 36),

            // ── Back home button ──────────────────────────────────────────────
            ElevatedButton.icon(
              icon: const Icon(Icons.home_rounded),
              label: Text('Back to Home',
                  style: GoogleFonts.inter(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _terra,
                foregroundColor: _cream,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              onPressed: () =>
                  Navigator.popUntil(context, (route) => route.isFirst),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  static const _card    = Color(0xFF2E1E0C);
  static const _cardAlt = Color(0xFF3A2410);
  static const _gold    = Color(0xFFDFAF58);
  static const _sand    = Color(0xFFE0C896);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _gold.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: _gold, size: 20),
            const SizedBox(height: 4),
            Text(label,
                style: GoogleFonts.inter(
                    color: _sand,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
