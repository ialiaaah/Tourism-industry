import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../models/models.dart';
import '../../services/firestore_service.dart';
import 'stop_details_screen.dart';
import 'stamp_collection_screen.dart';

// ── Palette ─────────────────────────────────────────────────────────────────
const _bg    = Color(0xFF1E1308);
const _card  = Color(0xFF2E1E0C);
const _cardAlt = Color(0xFF3A2410);
const _gold  = Color(0xFFDFAF58);
const _terra = Color(0xFFD4581E);
const _cream = Color(0xFFF5EDD8);
const _sand  = Color(0xFFE0C896);
const _muted = Color(0xFF8A7560);

// ── Public helper used by StopDetailsScreen too ──────────────────────────────
Widget buildStopThumbnail(String imagePath, {double size = 60}) {
  final isBase64  = imagePath.startsWith('data:image');
  final isNetwork = imagePath.startsWith('http://') || imagePath.startsWith('https://');

  if (isBase64) {
    try {
      final base64Str = imagePath.contains(',') ? imagePath.split(',').last : imagePath;
      final bytes = base64Decode(base64Str);
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          bytes,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallbackThumbnail(size),
        ),
      );
    } catch (_) {
      return _fallbackThumbnail(size);
    }
  }

  if (isNetwork) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        imagePath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallbackThumbnail(size),
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : _loadingThumbnail(size),
      ),
    );
  }

  if (imagePath.isNotEmpty) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.asset(
        imagePath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallbackThumbnail(size),
      ),
    );
  }

  return _fallbackThumbnail(size);
}

Widget _fallbackThumbnail(double size) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      gradient: const LinearGradient(
        colors: [_card, _cardAlt],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: const Icon(Icons.account_balance, color: _gold, size: 28),
  );
}

Widget _loadingThumbnail(double size) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      color: _card,
    ),
    child: const Center(
      child: SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: _gold),
      ),
    ),
  );
}

// ── Screen ───────────────────────────────────────────────────────────────────
class TourOverviewScreen extends StatelessWidget {
  const TourOverviewScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final service = context.watch<FirestoreService>();
    final tour = service.currentJoinedTour;

    if (tour == null) {
      return Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _card,
          foregroundColor: _cream,
          title: Text('Tour', style: GoogleFonts.playfairDisplay(color: _gold)),
        ),
        body: Center(
          child: Text('No active tour found.',
              style: GoogleFonts.inter(color: _muted)),
        ),
      );
    }

    final stampsCount = service.collectedStamps.length;
    final totalStops  = tour.stops.length;
    final progress    = totalStops > 0 ? stampsCount / totalStops : 0.0;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _card,
        foregroundColor: _cream,
        elevation: 0,
        title: Text(
          tour.title,
          style: GoogleFonts.playfairDisplay(
              color: _gold, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.workspace_premium, color: _gold),
            tooltip: 'Stamp Collection',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StampCollectionScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: _muted),
            tooltip: 'Leave Tour',
            onPressed: () => _confirmLeave(context, service),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Progress header ───────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            decoration: const BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (tour.description.isNotEmpty) ...[
                  Text(
                    tour.description,
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: _muted),
                  ),
                  const SizedBox(height: 16),
                ],
                Row(
                  children: [
                    const Icon(Icons.workspace_premium, color: _gold, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$stampsCount / $totalStops stops completed',
                            style: GoogleFonts.inter(
                                color: _sand,
                                fontWeight: FontWeight.w600,
                                fontSize: 13),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: _cardAlt,
                              valueColor:
                                  const AlwaysStoppedAnimation<Color>(_gold),
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const StampCollectionScreen()),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _gold.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: _gold.withValues(alpha: 0.6)),
                        ),
                        child: Text(
                          'Stamps',
                          style: GoogleFonts.inter(
                              color: _gold,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Stops list ────────────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount: tour.stops.length,
              itemBuilder: (context, index) {
                final stop = tour.stops[index];
                final earnedStamp =
                    service.collectedStamps.any((s) => s.stopId == stop.id);
                return _StopCard(
                    stop: stop, index: index, earnedStamp: earnedStamp);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLeave(BuildContext context, FirestoreService service) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Leave Tour?',
            style: GoogleFonts.playfairDisplay(color: _cream)),
        content: Text(
          'Your collected stamps will be saved. You can rejoin with the same code.',
          style: GoogleFonts.inter(color: _muted, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                Text('Stay', style: GoogleFonts.inter(color: _gold)),
          ),
          TextButton(
            onPressed: () {
              service.leaveTour();
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            child: Text('Leave',
                style: GoogleFonts.inter(color: _terra)),
          ),
        ],
      ),
    );
  }
}

// ── Stop card ─────────────────────────────────────────────────────────────────
class _StopCard extends StatelessWidget {
  final Stop stop;
  final int index;
  final bool earnedStamp;

  const _StopCard({
    required this.stop,
    required this.index,
    required this.earnedStamp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: earnedStamp
              ? _gold.withValues(alpha: 0.5)
              : _cardAlt,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => StopDetailsScreen(stop: stop)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // ── Stop number badge ────────────────────────────────────────
              Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: earnedStamp ? _gold : _cardAlt,
                ),
                child: Center(
                  child: earnedStamp
                      ? const Icon(Icons.check, color: _bg, size: 16)
                      : Text(
                          '${index + 1}',
                          style: GoogleFonts.inter(
                              color: _sand,
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                        ),
                ),
              ),

              // ── Thumbnail ────────────────────────────────────────────────
              buildStopThumbnail(stop.imagePath, size: 64),
              const SizedBox(width: 14),

              // ── Text info ─────────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stop.name,
                      style: GoogleFonts.playfairDisplay(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _cream),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stop.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style:
                          GoogleFonts.inter(color: _muted, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (stop.quiz != null)
                          _Chip(
                            icon: Icons.quiz,
                            label: 'Quiz',
                            color: _terra,
                          ),
                        if (stop.quiz != null && earnedStamp)
                          const SizedBox(width: 6),
                        if (earnedStamp)
                          _Chip(
                            icon: Icons.workspace_premium,
                            label: 'Stamp earned',
                            color: _gold,
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              Icon(Icons.chevron_right,
                  color: _muted.withValues(alpha: 0.6)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Chip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
