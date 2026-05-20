import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/isect_data_service.dart';
import '../isect/editions_screen.dart';
import '../isect/sessions_screen.dart';
import '../isect/speakers_screen.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _navy = Color(0xFF0B1E35);
  static const _gold = Color(0xFFCBA153);
  static const _spainRed = Color(0xFFB41E2D);
  static const _cardBg = Color(0xFF132038);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navy,
      appBar: AppBar(
        backgroundColor: _navy, foregroundColor: Colors.white, elevation: 0,
        title: Text('About CulturaX', style: GoogleFonts.playfairDisplay(color: _gold, fontSize: 20, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Logo block
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF132038), Color(0xFF0B1E35)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _gold.withValues(alpha: 0.25)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.account_balance_rounded, color: Color(0xFFDFAF58), size: 32),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('✕', style: GoogleFonts.inter(color: Colors.white24, fontSize: 20)),
                    ),
                    const Icon(Icons.account_balance_rounded, color: Color(0xFFB41E2D), size: 32),
                  ],
                ),
                const SizedBox(height: 12),
                Text('CulturaX',
                    style: GoogleFonts.playfairDisplay(
                        color: _gold, fontSize: 40, fontWeight: FontWeight.bold, letterSpacing: 3)),
                const SizedBox(height: 4),
                Text('A Smart Cultural Ecosystem Connecting\nHeritage, Tourism, and Global Conferences',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(color: Colors.white54, fontSize: 11, height: 1.5)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _spainRed.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _spainRed.withValues(alpha: 0.3)),
                  ),
                  child: Text('Powered by ISECT',
                      style: GoogleFonts.inter(color: _spainRed, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // About text
          _SectionCard(
            icon: Icons.info_outline_rounded, color: _gold, title: 'About the Conference',
            content: 'ISECT is a prestigious international conference that brings together over 200 top-tier experts, researchers, archaeologists, tourism professionals, and cultural diplomats from Egypt and Spain annually.\n\nThe conference alternates between Egypt and Spain, creating a living bridge between two of the world\'s most celebrated civilizations — Pharaonic Egypt and Andalusian Spain.',
          ),
          const SizedBox(height: 14),

          // Mission
          _SectionCard(
            icon: Icons.flag_rounded, color: _spainRed, title: 'Our Mission',
            content: 'To foster academic excellence, cultural understanding, and sustainable tourism between Egypt and Spain — while protecting and promoting the shared heritage that connects the Mediterranean world.',
          ),
          const SizedBox(height: 14),

          // Timeline
          _SectionCard(
            icon: Icons.timeline_rounded, color: const Color(0xFF4A90D9), title: 'Conference Timeline',
            content: '• 2025 Cairo, Egypt — Inaugural Edition (247 delegates)\n• 2026 Granada, Spain — Second Edition (Registration Open)\n• March 2027 Luxor, Egypt — Third Edition (Announced)',
          ),
          const SizedBox(height: 14),

          // Stats
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _cardBg, borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.bar_chart_rounded, color: _gold, size: 16),
                  const SizedBox(width: 6),
                  Text('CulturaX Platform Highlights', style: GoogleFonts.inter(color: _gold, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                ]),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _StatBadge('247+', 'Delegates', _gold),
                    const SizedBox(width: 10),
                    _StatBadge('32', 'Countries', _spainRed),
                    const SizedBox(width: 10),
                    _StatBadge('34', 'Sessions', const Color(0xFF4A90D9)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Navigate buttons
          Text('Explore via CulturaX', style: GoogleFonts.inter(color: Colors.white54, fontSize: 12, letterSpacing: 0.5)),
          const SizedBox(height: 10),
          _NavButton(icon: Icons.event_rounded, label: 'Conference Editions', color: _gold,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditionsScreen()))),
          const SizedBox(height: 8),
          _NavButton(icon: Icons.calendar_month_rounded, label: 'View Full Schedule', color: _spainRed,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SessionsScreen()))),
          const SizedBox(height: 8),
          _NavButton(icon: Icons.person_rounded, label: 'Meet the Speakers', color: const Color(0xFF4A90D9),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SpeakersScreen()))),
          const SizedBox(height: 24),

          // Footer
          Center(
            child: Text('© 2025–2027 CulturaX · All rights reserved',
                style: GoogleFonts.inter(color: Colors.white24, fontSize: 10)),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String content;
  const _SectionCard({required this.icon, required this.color, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF132038),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(title, style: GoogleFonts.inter(color: color, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.4)),
          ]),
          const SizedBox(height: 10),
          Text(content, style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, height: 1.6)),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatBadge(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(children: [
          Text(value, style: GoogleFonts.playfairDisplay(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
          Text(label, style: GoogleFonts.inter(color: Colors.white38, fontSize: 9)),
        ]),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _NavButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF132038),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 12),
          Text(label, style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
          const Spacer(),
          Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 14),
        ]),
      ),
    );
  }
}
