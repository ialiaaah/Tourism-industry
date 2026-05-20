import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/monument_data_service.dart';

class MonumentInfoSheet extends StatefulWidget {
  final MonumentInfo monument;
  const MonumentInfoSheet({super.key, required this.monument});

  @override
  State<MonumentInfoSheet> createState() => _MonumentInfoSheetState();
}

class _MonumentInfoSheetState extends State<MonumentInfoSheet>
    with TickerProviderStateMixin {
  static const Color _gold = Color(0xFFCBA153);
  static const Color _darkBg = Color(0xFF0D1B2A);
  static const Color _cardBg = Color(0xFF162233);

  late TabController _tabs;
  late AnimationController _revealCtrl;
  late Animation<double> _revealAnim;
  late AnimationController _shimmerCtrl;
  late Animation<double> _shimmerAnim;

  // Fun facts reveal state
  final List<bool> _factRevealed = [];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);

    _revealCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _revealAnim = CurvedAnimation(parent: _revealCtrl, curve: Curves.easeOut);
    _revealCtrl.forward();

    _shimmerCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
    _shimmerAnim = Tween<double>(begin: -1.0, end: 2.0).animate(
        CurvedAnimation(parent: _shimmerCtrl, curve: Curves.linear));

    _factRevealed.addAll(
        List.filled(widget.monument.funFacts.length, false));
  }

  @override
  void dispose() {
    _tabs.dispose();
    _revealCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.monument;
    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      expand: false,
      builder: (context, sc) => FadeTransition(
        opacity: _revealAnim,
        child: SlideTransition(
          position: Tween<Offset>(
                  begin: const Offset(0, 0.1), end: Offset.zero)
              .animate(_revealAnim),
          child: Container(
            decoration: const BoxDecoration(
              color: _darkBg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                // Drag handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2)),
                ),

                // ── Hero image + shimmer badge ──
                _buildHeroImage(m),

                // ── Name / location header ──
                _buildHeader(m),

                const SizedBox(height: 10),

                // ── Tabs ──
                _buildTabBar(),

                const SizedBox(height: 4),

                // ── Tab content ──
                Expanded(
                  child: TabBarView(
                    controller: _tabs,
                    children: [
                      _buildOverview(m, sc),
                      _buildHistory(m, sc),
                      _buildFunFacts(m, sc),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Hero image with shimmer "Identified" badge
  // ────────────────────────────────────────────────────────────────────────────

  Widget _buildHeroImage(MonumentInfo m) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            // Photo
            Image.asset(
              m.assetImage,
              height: 190,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 190,
                color: _cardBg,
                child: Center(
                    child:
                        Text(m.emoji, style: const TextStyle(fontSize: 64))),
              ),
            ),

            // Dark gradient
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.65)
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // Shimmer "✓ Identified" badge
            Positioned(
              top: 10,
              right: 10,
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
                    border: Border.all(color: _gold.withValues(alpha: 0.6)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified_rounded,
                          color: _gold, size: 14),
                      const SizedBox(width: 5),
                      Text('Identified',
                          style: GoogleFonts.inter(
                              color: _gold,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),

            // Era chip at bottom-left
            Positioned(
              bottom: 10,
              left: 10,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(m.era,
                    style: GoogleFonts.inter(
                        color: Colors.white70, fontSize: 10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Header
  // ────────────────────────────────────────────────────────────────────────────

  Widget _buildHeader(MonumentInfo m) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Emoji circle
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _gold.withValues(alpha: 0.15),
              border: Border.all(color: _gold.withValues(alpha: 0.4)),
            ),
            child: Center(
                child: Text(m.emoji,
                    style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.name,
                    style: GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.place_rounded, size: 13, color: _gold),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(m.location,
                          style: GoogleFonts.inter(
                              color: _gold,
                              fontSize: 11,
                              fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Tab bar
  // ────────────────────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
            color: _cardBg, borderRadius: BorderRadius.circular(14)),
        child: TabBar(
          controller: _tabs,
          indicator: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFFCBA153), Color(0xFFE8C97A)]),
            borderRadius: BorderRadius.circular(12),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: _darkBg,
          unselectedLabelColor: Colors.white54,
          labelStyle:
              GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.info_outline_rounded, size: 14),
                SizedBox(width: 4),
                Text('Overview'),
              ]),
            ),
            Tab(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.menu_book_rounded, size: 14),
                SizedBox(width: 4),
                Text('History'),
              ]),
            ),
            Tab(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.emoji_events_rounded, size: 14),
                SizedBox(width: 4),
                Text('Fun Facts'),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Overview tab
  // ────────────────────────────────────────────────────────────────────────────

  Widget _buildOverview(MonumentInfo m, ScrollController sc) {
    return ListView(
      controller: sc,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        _card(
          icon: Icons.auto_stories_rounded,
          title: 'About',
          child: Text(m.overview,
              style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 14,
                  height: 1.65)),
        ),
        const SizedBox(height: 12),
        _infoTile(Icons.place_rounded, 'Location', m.location),
        const SizedBox(height: 8),
        _infoTile(Icons.hourglass_bottom_rounded, 'Era', m.era),
      ],
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // History tab — with a simple timeline
  // ────────────────────────────────────────────────────────────────────────────

  Widget _buildHistory(MonumentInfo m, ScrollController sc) {
    // Split history into ~2 sentences per "era" card for a timeline feel
    final sentences = m.history
        .split('. ')
        .where((s) => s.trim().isNotEmpty)
        .toList();

    return ListView(
      controller: sc,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        for (int i = 0; i < sentences.length; i++)
          _TimelineCard(
            index: i,
            text: sentences[i].endsWith('.')
                ? sentences[i]
                : '${sentences[i]}.',
            isLast: i == sentences.length - 1,
          ),
      ],
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Fun Facts tab — tap-to-reveal cards
  // ────────────────────────────────────────────────────────────────────────────

  Widget _buildFunFacts(MonumentInfo m, ScrollController sc) {
    return ListView(
      controller: sc,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Text('Tap each card to reveal a secret! 🔐',
              style: GoogleFonts.inter(
                  color: Colors.white38,
                  fontSize: 12,
                  fontStyle: FontStyle.italic)),
        ),
        for (int i = 0; i < m.funFacts.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _RevealCard(
              index: i,
              fact: m.funFacts[i],
            ),
          ),
      ],
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Shared widgets
  // ────────────────────────────────────────────────────────────────────────────

  Widget _card(
      {required IconData icon,
      required String title,
      required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _gold.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: _gold, size: 16),
            const SizedBox(width: 7),
            Text(title,
                style: GoogleFonts.inter(
                    color: _gold,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.4)),
          ]),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: _gold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: _gold, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.inter(
                        color: Colors.white38,
                        fontSize: 10,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value,
                    style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Timeline card widget
// ────────────────────────────────────────────────────────────────────────────

class _TimelineCard extends StatelessWidget {
  final int index;
  final String text;
  final bool isLast;

  const _TimelineCard(
      {required this.index, required this.text, required this.isLast});

  static const _gold = Color(0xFFCBA153);
  static const _cardBg = Color(0xFF162233);

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline spine
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                        colors: [_gold, Color(0xFFE8C97A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                  ),
                  child: Center(
                    child: Text('${index + 1}',
                        style: const TextStyle(
                            color: Color(0xFF0D1B2A),
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: _gold.withValues(alpha: 0.25),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Content
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: _gold.withValues(alpha: 0.12)),
              ),
              child: Text(
                text,
                style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                    height: 1.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Tap-to-reveal fun fact card
// ────────────────────────────────────────────────────────────────────────────

class _RevealCard extends StatefulWidget {
  final int index;
  final String fact;
  const _RevealCard({required this.index, required this.fact});

  @override
  State<_RevealCard> createState() => _RevealCardState();
}

class _RevealCardState extends State<_RevealCard>
    with SingleTickerProviderStateMixin {
  bool _revealed = false;
  late AnimationController _ctrl;
  late Animation<double> _flipAnim;

  static const _gold = Color(0xFFCBA153);
  static const _cardBg = Color(0xFF162233);

  static const List<String> _medals = ['🥇', '🥈', '🥉', '🏅'];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _flipAnim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _reveal() {
    if (_revealed) return;
    setState(() => _revealed = true);
    _ctrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    final medal = _medals[widget.index % _medals.length];

    return GestureDetector(
      onTap: _reveal,
      child: AnimatedBuilder(
        animation: _flipAnim,
        builder: (_, __) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _revealed
                  ? _cardBg
                  : _gold.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: _revealed
                      ? _gold.withValues(alpha: 0.2)
                      : _gold.withValues(alpha: 0.4),
                  width: _revealed ? 1 : 1.5),
            ),
            child: _revealed
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(medal,
                          style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FadeTransition(
                          opacity: _flipAnim,
                          child: Text(widget.fact,
                              style: GoogleFonts.inter(
                                  color: Colors.white
                                      .withValues(alpha: 0.88),
                                  fontSize: 14,
                                  height: 1.55)),
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_outline_rounded,
                          color: _gold, size: 20),
                      const SizedBox(width: 10),
                      Text('Secret #${widget.index + 1} — Tap to reveal!',
                          style: GoogleFonts.inter(
                              color: _gold,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
          );
        },
      ),
    );
  }
}
