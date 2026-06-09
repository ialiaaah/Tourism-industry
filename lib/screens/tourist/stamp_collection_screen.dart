import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';

class StampCollectionScreen extends StatelessWidget {
  const StampCollectionScreen({Key? key}) : super(key: key);

  // ── Palette ─────────────────────────────────────────────────────────────────
  static const _bg      = Color(0xFF1E1308);
  static const _card    = Color(0xFF2E1E0C);
  static const _cardAlt = Color(0xFF3A2410);
  static const _gold    = Color(0xFFDFAF58);
  static const _terra   = Color(0xFFD4581E);
  static const _cream   = Color(0xFFF5EDD8);
  static const _sand    = Color(0xFFE0C896);
  static const _muted   = Color(0xFF8A7560);

  @override
  Widget build(BuildContext context) {
    final service    = context.watch<FirestoreService>();
    final stamps     = service.collectedStamps;
    final totalStops = service.currentJoinedTour?.stops.length ?? 0;
    final isComplete = stamps.isNotEmpty && stamps.length == totalStops;
    final progress   = totalStops > 0 ? stamps.length / totalStops : 0.0;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _card,
        foregroundColor: _cream,
        elevation: 0,
        title: Text('My Stamps',
            style: GoogleFonts.playfairDisplay(
                color: _gold, fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Summary card ───────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isComplete
                      ? _gold.withValues(alpha: 0.7)
                      : _cardAlt,
                  width: isComplete ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  // Trophy / premium icon
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isComplete
                          ? _gold.withValues(alpha: 0.15)
                          : _cardAlt,
                    ),
                    child: Icon(
                      isComplete
                          ? Icons.emoji_events_rounded
                          : Icons.workspace_premium_rounded,
                      size: 52,
                      color: _gold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    '${stamps.length} / $totalStops',
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: _cream),
                  ),
                  Text(
                    'stamps collected',
                    style: GoogleFonts.inter(color: _muted, fontSize: 14),
                  ),

                  const SizedBox(height: 20),

                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: _cardAlt,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          isComplete ? _gold : _terra),
                    ),
                  ),

                  // Completion banner
                  if (isComplete) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: _gold.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: _gold.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.auto_awesome,
                              color: _gold, size: 18),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Congratulations! Tour complete!',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                  color: _gold,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.auto_awesome,
                              color: _gold, size: 18),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Section title ──────────────────────────────────────────────────
            Text('Stamp History',
                style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _cream)),
            const SizedBox(height: 16),

            // ── Stamps grid or empty state ─────────────────────────────────────
            Expanded(
              child: stamps.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.workspace_premium_rounded,
                              size: 64,
                              color: _muted.withValues(alpha: 0.4)),
                          const SizedBox(height: 16),
                          Text(
                            'No stamps yet.\nAnswer quizzes at each stop to earn them!',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                                color: _muted, fontSize: 15, height: 1.6),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 0.95,
                      ),
                      itemCount: stamps.length,
                      itemBuilder: (context, index) {
                        final stamp = stamps[index];
                        return _StampCard(
                          stopName: stamp.stopName,
                          dateEarned: stamp.dateEarned,
                          number: index + 1,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StampCard extends StatelessWidget {
  final String stopName;
  final DateTime dateEarned;
  final int number;

  const _StampCard({
    required this.stopName,
    required this.dateEarned,
    required this.number,
  });

  static const _bg      = Color(0xFF1E1308);
  static const _card    = Color(0xFF2E1E0C);
  static const _cardAlt = Color(0xFF3A2410);
  static const _gold    = Color(0xFFDFAF58);
  static const _cream   = Color(0xFFF5EDD8);
  static const _muted   = Color(0xFF8A7560);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _gold.withValues(alpha: 0.35)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Stamp seal
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _gold.withValues(alpha: 0.12),
                  border: Border.all(
                      color: _gold.withValues(alpha: 0.5), width: 2),
                ),
              ),
              const Icon(Icons.verified_rounded, size: 34, color: _gold),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: _gold),
                  child: Text(
                    '$number',
                    style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: _bg),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            stopName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: _cream),
          ),
          const SizedBox(height: 6),
          Text(
            DateFormat('MMM d, h:mm a').format(dateEarned),
            style: GoogleFonts.inter(fontSize: 11, color: _muted),
          ),
        ],
      ),
    );
  }
}
