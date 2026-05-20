import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/isect_data_service.dart';

class EditionsScreen extends StatelessWidget {
  const EditionsScreen({super.key});

  static const _navy = Color(0xFF0B1E35);
  static const _gold = Color(0xFFCBA153);
  static const _cardBg = Color(0xFF132038);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navy,
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        title: Text('Conference Editions', style: GoogleFonts.playfairDisplay(color: _gold, fontSize: 20, fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: ISECTDataService.editions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 20),
        itemBuilder: (_, i) => _EditionCard(edition: ISECTDataService.editions[i]),
      ),
    );
  }
}

class _EditionCard extends StatelessWidget {
  final ISECTEdition edition;
  const _EditionCard({required this.edition});

  @override
  Widget build(BuildContext context) {
    final isPast = edition.status == EditionStatus.past;
    final isUpcoming = edition.status == EditionStatus.upcoming;
    final c = edition.accentColor;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF132038),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withValues(alpha: isUpcoming ? 0.6 : 0.2), width: isUpcoming ? 1.5 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header band
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [c.withValues(alpha: 0.25), c.withValues(alpha: 0.05)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Text(edition.flag, style: const TextStyle(fontSize: 36)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ISECT ${edition.year}',
                          style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      Text('${edition.city}, ${edition.country}',
                          style: GoogleFonts.inter(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(edition.dates, style: GoogleFonts.inter(color: c, fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isPast ? Colors.white12 : isUpcoming ? c.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isPast ? Colors.white24 : isUpcoming ? c.withValues(alpha: 0.5) : Colors.white24),
                  ),
                  child: Text(
                    isPast ? 'PAST' : isUpcoming ? 'UPCOMING' : 'ANNOUNCED',
                    style: GoogleFonts.inter(
                        color: isPast ? Colors.white38 : isUpcoming ? c : Colors.white38,
                        fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                ),
              ],
            ),
          ),
          // Details
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Venue
                Row(children: [
                  const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFFCBA153)),
                  const SizedBox(width: 6),
                  Expanded(child: Text(edition.venue, style: GoogleFonts.inter(color: Colors.white70, fontSize: 12))),
                ]),
                const SizedBox(height: 14),
                // Theme
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.withValues(alpha: 0.15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('THEME', style: GoogleFonts.inter(color: c, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      const SizedBox(height: 6),
                      Text(edition.theme,
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontStyle: FontStyle.italic, height: 1.4)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(edition.description,
                    style: GoogleFonts.inter(color: Colors.white60, fontSize: 13, height: 1.55)),
                if (edition.attendees != null || edition.sessionCount != null) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (edition.attendees != null) _Stat('${edition.attendees}', 'Delegates', c),
                      if (edition.attendees != null && edition.sessionCount != null)
                        const SizedBox(width: 12),
                      if (edition.sessionCount != null) _Stat('${edition.sessionCount}', 'Sessions', c),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _Stat(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(value, style: GoogleFonts.playfairDisplay(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label, style: GoogleFonts.inter(color: Colors.white54, fontSize: 10)),
        ],
      ),
    );
  }
}
