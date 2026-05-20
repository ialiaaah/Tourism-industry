import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/isect_data_service.dart';

class SessionsScreen extends StatefulWidget {
  const SessionsScreen({super.key});
  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> with SingleTickerProviderStateMixin {
  static const _navy = Color(0xFF0B1E35);
  static const _gold = Color(0xFFCBA153);

  late TabController _tabs;
  final _days = ['Day 1 · June 15', 'Day 2 · June 16', 'Day 3 · June 17'];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _days.length, vsync: this);
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navy,
      appBar: AppBar(
        backgroundColor: _navy, foregroundColor: Colors.white, elevation: 0,
        title: Text('Sessions · ISECT 2026',
            style: GoogleFonts.playfairDisplay(color: _gold, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFF132038), borderRadius: BorderRadius.circular(12)),
            child: TabBar(
              controller: _tabs,
              indicator: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFB41E2D), Color(0xFFCC2233)]),
                  borderRadius: BorderRadius.circular(10)),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white38,
              labelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold),
              tabs: const [Tab(text: 'Day 1'), Tab(text: 'Day 2'), Tab(text: 'Day 3')],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: _days.map((day) {
          final sessions = ISECTDataService.sessions.where((s) => s.day == day).toList();
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sessions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _SessionCard(session: sessions[i]),
          );
        }).toList(),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final ISECTSession session;
  const _SessionCard({required this.session});

  Color get _typeColor {
    return switch (session.type) {
      SessionType.keynote   => const Color(0xFFCBA153),
      SessionType.ceremony  => const Color(0xFF9B59B6),
      SessionType.workshop  => const Color(0xFF3DAA6B),
      SessionType.tour      => const Color(0xFF4A90D9),
      SessionType.panel     => const Color(0xFFE67E22),
      _                     => const Color(0xFF5D7A8C),
    };
  }

  String get _typeLabel {
    return switch (session.type) {
      SessionType.keynote  => 'KEYNOTE',
      SessionType.ceremony => 'CEREMONY',
      SessionType.workshop => 'WORKSHOP',
      SessionType.tour     => 'TOUR',
      SessionType.panel    => 'PANEL',
      _                    => 'SESSION',
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = _typeColor;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF132038),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.withValues(alpha: 0.25)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Colored left bar
            Container(width: 4, decoration: BoxDecoration(color: c, borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)))),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: c.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                          child: Text(_typeLabel, style: GoogleFonts.inter(color: c, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                        ),
                        const SizedBox(width: 8),
                        Text(session.time, style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
                        const Spacer(),
                        const Icon(Icons.room_rounded, size: 12, color: Colors.white24),
                        const SizedBox(width: 3),
                        Text(session.room.length > 16 ? '${session.room.substring(0, 14)}…' : session.room,
                            style: GoogleFonts.inter(color: Colors.white24, fontSize: 10)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(session.title,
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, height: 1.3)),
                    const SizedBox(height: 4),
                    Text(session.speaker, style: GoogleFonts.inter(color: c, fontSize: 11, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Text(session.description,
                        style: GoogleFonts.inter(color: Colors.white54, fontSize: 12, height: 1.4),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
