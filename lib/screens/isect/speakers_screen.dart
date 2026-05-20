import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/isect_data_service.dart';

class SpeakersScreen extends StatelessWidget {
  const SpeakersScreen({super.key});

  static const _navy = Color(0xFF0B1E35);
  static const _gold = Color(0xFFCBA153);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navy,
      appBar: AppBar(
        backgroundColor: _navy, foregroundColor: Colors.white, elevation: 0,
        title: Text('Speakers · ISECT 2026',
            style: GoogleFonts.playfairDisplay(color: _gold, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Granada banner
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF8B0000), Color(0xFFB41E2D)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Text('🏛️', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ISECT 2026 · Granada, Spain',
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                      Text('${ISECTDataService.speakers.length} Distinguished International Speakers',
                          style: GoogleFonts.inter(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: ISECTDataService.speakers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _SpeakerCard(speaker: ISECTDataService.speakers[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeakerCard extends StatefulWidget {
  final ISECTSpeaker speaker;
  const _SpeakerCard({required this.speaker});
  @override
  State<_SpeakerCard> createState() => _SpeakerCardState();
}

class _SpeakerCardState extends State<_SpeakerCard> {
  bool _expanded = false;
  static const _gold = Color(0xFFCBA153);
  static const _spainRed = Color(0xFFB41E2D);

  @override
  Widget build(BuildContext context) {
    final s = widget.speaker;
    final isEgyptian = s.flag == '🇪🇬';
    final accentColor = isEgyptian ? _gold : _spainRed;

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: const Color(0xFF132038),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accentColor.withValues(alpha: _expanded ? 0.5 : 0.15)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [accentColor.withValues(alpha: 0.3), const Color(0xFF0B1E35)]),
                      border: Border.all(color: accentColor.withValues(alpha: 0.5), width: 1.5),
                    ),
                    child: Center(child: Text(s.emoji, style: const TextStyle(fontSize: 24))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(s.flag, style: const TextStyle(fontSize: 14)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(s.name,
                                  style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(s.title, style: GoogleFonts.inter(color: accentColor, fontSize: 11, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 2),
                        Text(s.institution, style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
                      ],
                    ),
                  ),
                  Icon(_expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      color: Colors.white38, size: 20),
                ],
              ),
            ),
            if (_expanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Divider(color: accentColor.withValues(alpha: 0.2)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(s.specialty,
                          style: GoogleFonts.inter(color: accentColor, fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 10),
                    Text(s.bio,
                        style: GoogleFonts.inter(color: Colors.white60, fontSize: 12, height: 1.55)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
