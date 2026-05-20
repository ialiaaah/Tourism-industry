import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/isect_data_service.dart';
import '../models/models.dart';
import 'landing_screen.dart';
import 'isect/editions_screen.dart';
import 'isect/sessions_screen.dart';
import 'isect/speakers_screen.dart';
import 'isect/gallery_screen.dart';
import 'isect/about_screen.dart';
import 'tourist/ar_monument_scanner_screen.dart';
import 'tourist/join_tour_screen.dart';
import 'guide/create_tour_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _navy = Color(0xFF0B1E35);
  static const _gold = Color(0xFFCBA153);
  static const _spainRed = Color(0xFFB41E2D);
  static const _cardBg = Color(0xFF132038);

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final user = auth.currentAppUser;
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final isOrganizer = user.role == UserRole.guide;
    final next = ISECTDataService.nextEdition;

    return Scaffold(
      backgroundColor: _navy,
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────────────────
          SliverToBoxAdapter(child: _Header(user: user, isOrganizer: isOrganizer)),

          // ── Next Edition Hero ────────────────────────────────────────────────
          SliverToBoxAdapter(child: _NextEditionCard(edition: next, context: context)),

          // ── Editions Timeline ────────────────────────────────────────────────
          SliverToBoxAdapter(child: _EditionsStrip(context: context)),

          // ── Features Grid ────────────────────────────────────────────────────
          SliverToBoxAdapter(child: _FeaturesGrid(isOrganizer: isOrganizer, context: context)),

          // ── News ─────────────────────────────────────────────────────────────
          SliverToBoxAdapter(child: _NewsSection()),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

// ── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final dynamic user;
  final bool isOrganizer;
  const _Header({required this.user, required this.isOrganizer});

  static const _gold = Color(0xFFCBA153);
  static const _spainRed = Color(0xFFB41E2D);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF0B1E35), const Color(0xFF132038)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // ISECT wordmark
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.account_balance_rounded, color: Color(0xFFDFAF58), size: 20),
                        const SizedBox(width: 6),
                        Text('✕', style: GoogleFonts.inter(color: Colors.white38, fontSize: 14, fontWeight: FontWeight.w300)),
                        const SizedBox(width: 6),
                        const Icon(Icons.account_balance_rounded, color: Color(0xFFB41E2D), size: 20),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('CulturaX',
                        style: GoogleFonts.playfairDisplay(
                            color: _gold, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 2)),
                    Text('Smart Cultural Ecosystem · Heritage · Tourism · Conferences',
                        style: GoogleFonts.inter(color: Colors.white54, fontSize: 9, height: 1.4)),
                  ],
                ),
              ),
              // Sign out
              GestureDetector(
                onTap: () async {
                  final auth = Provider.of<AuthService>(context, listen: false);
                  await auth.signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LandingScreen()), (_) => false);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: const Icon(Icons.logout_rounded, color: Colors.white54, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Role badge + greeting
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isOrganizer ? _spainRed.withValues(alpha: 0.2) : _gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: isOrganizer ? _spainRed.withValues(alpha: 0.5) : _gold.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(isOrganizer ? Icons.manage_accounts_rounded : Icons.badge_rounded,
                        size: 13, color: isOrganizer ? _spainRed : _gold),
                    const SizedBox(width: 5),
                    Text(isOrganizer ? 'Organizer' : 'Attendee',
                        style: GoogleFonts.inter(
                            color: isOrganizer ? _spainRed : _gold,
                            fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Welcome, ${user.firstName}',
                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Next Edition Card ────────────────────────────────────────────────────────

class _NextEditionCard extends StatelessWidget {
  final ISECTEdition edition;
  final BuildContext context;
  const _NextEditionCard({required this.edition, required this.context});

  static const _spainRed = Color(0xFFB41E2D);
  static const _gold = Color(0xFFCBA153);

  @override
  Widget build(BuildContext ctx) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: GestureDetector(
        onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const EditionsScreen())),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF8B0000), Color(0xFFB41E2D), Color(0xFFCC2233)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: _spainRed.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: Stack(
            children: [
              // Decorative flag stripe
              Positioned(
                right: 0, top: 0, bottom: 0,
                child: ClipRRect(
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(20)),
                  child: SizedBox(
                    width: 80,
                    child: Column(
                      children: [
                        Expanded(child: Container(color: Colors.white.withValues(alpha: 0.08))),
                        Expanded(child: Container(color: _spainRed.withValues(alpha: 0.3))),
                        Expanded(child: Container(color: Colors.white.withValues(alpha: 0.08))),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('NEXT EDITION',
                              style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _gold.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('Registration Open',
                              style: GoogleFonts.inter(color: const Color(0xFF0B1E35), fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text('${edition.flag}  ISECT ${edition.year}',
                        style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('${edition.city}, ${edition.country}',
                        style: GoogleFonts.inter(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 6),
                    Text(edition.dates,
                        style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
                    const SizedBox(height: 12),
                    Text(edition.theme,
                        style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.85), fontSize: 12, fontStyle: FontStyle.italic, height: 1.4),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const SessionsScreen())),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: _spainRed,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          child: Text('View Sessions', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton(
                          onPressed: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const SpeakersScreen())),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text('Speakers', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Editions Strip ───────────────────────────────────────────────────────────

class _EditionsStrip extends StatelessWidget {
  final BuildContext context;
  const _EditionsStrip({required this.context});

  @override
  Widget build(BuildContext ctx) {
    final editions = ISECTDataService.editions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Row(
            children: [
              Text('Conference Editions', style: GoogleFonts.inter(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const EditionsScreen())),
                child: Text('See All', style: GoogleFonts.inter(color: const Color(0xFFCBA153), fontSize: 12)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 130,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: editions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final e = editions[i];
              final isPast = e.status == EditionStatus.past;
              final isUpcoming = e.status == EditionStatus.upcoming;
              return GestureDetector(
                onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const EditionsScreen())),
                child: Container(
                  width: 160,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [e.accentColor.withValues(alpha: 0.2), const Color(0xFF132038)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isUpcoming ? e.accentColor.withValues(alpha: 0.7) : e.accentColor.withValues(alpha: 0.2),
                      width: isUpcoming ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(e.flag, style: const TextStyle(fontSize: 18)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isPast ? Colors.white12 : isUpcoming ? e.accentColor.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isPast ? 'PAST' : isUpcoming ? 'UPCOMING' : 'ANNOUNCED',
                              style: GoogleFonts.inter(
                                color: isPast ? Colors.white38 : isUpcoming ? e.accentColor : Colors.white38,
                                fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('ISECT ${e.year}',
                          style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('${e.city}, ${e.country}',
                          style: GoogleFonts.inter(color: Colors.white54, fontSize: 11)),
                      const Spacer(),
                      if (e.attendees != null)
                        Text('${e.attendees} delegates',
                            style: GoogleFonts.inter(color: e.accentColor, fontSize: 10, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Features Grid ────────────────────────────────────────────────────────────

class _FeaturesGrid extends StatelessWidget {
  final bool isOrganizer;
  final BuildContext context;
  const _FeaturesGrid({required this.isOrganizer, required this.context});

  static const _gold = Color(0xFFCBA153);
  static const _spainRed = Color(0xFFB41E2D);

  @override
  Widget build(BuildContext ctx) {
    final features = [
      _Feature('Sessions', Icons.calendar_month_rounded, _gold,
          () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const SessionsScreen()))),
      _Feature('Speakers', Icons.person_rounded, const Color(0xFF4A90D9),
          () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const SpeakersScreen()))),
      _Feature('Heritage\nScanner', Icons.camera_enhance_rounded, const Color(0xFF3DAA6B),
          () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const ARMonumentScannerScreen()))),
      _Feature('Gallery', Icons.photo_library_rounded, const Color(0xFF9B59B6),
          () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const GalleryScreen()))),
      if (isOrganizer)
        _Feature('Manage\nEdition', Icons.edit_calendar_rounded, _spainRed,
            () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const CreateTourScreen())))
      else
        _Feature('Join Edition', Icons.qr_code_scanner_rounded, _spainRed,
            () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const JoinTourScreen()))),
      _Feature('About\nISECT', Icons.info_outline_rounded, Colors.white38,
          () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const AboutScreen()))),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Explore', style: GoogleFonts.inter(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.95,
            children: features.map((f) => _buildFeatureTile(f)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureTile(_Feature f) {
    return GestureDetector(
      onTap: f.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF132038),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: f.color.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: f.color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(f.icon, color: f.color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(f.label,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.85), fontSize: 11, fontWeight: FontWeight.w600, height: 1.3)),
          ],
        ),
      ),
    );
  }
}

class _Feature {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _Feature(this.label, this.icon, this.color, this.onTap);
}

// ── News Section ─────────────────────────────────────────────────────────────

class _NewsSection extends StatelessWidget {
  static const _gold = Color(0xFFCBA153);
  static const _cardBg = Color(0xFF132038);

  @override
  Widget build(BuildContext context) {
    final news = ISECTDataService.news;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Latest Updates', style: GoogleFonts.inter(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...news.map((item) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.emoji, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.title,
                              style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(item.body,
                              style: GoogleFonts.inter(color: Colors.white54, fontSize: 12, height: 1.4),
                              maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 6),
                          Text(item.date, style: GoogleFonts.inter(color: _gold, fontSize: 10)),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
