import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import 'landing_screen.dart';
import 'tourist/ar_monument_scanner_screen.dart';
import 'tourist/join_tour_screen.dart';
import 'tourist/stamp_collection_screen.dart';
import 'tourist/explorer_profile_screen.dart';
import 'guide/create_tour_screen.dart';


class HeritageHomeScreen extends StatelessWidget {
  const HeritageHomeScreen({super.key});

  static const _bg    = Color(0xFF1E1308);
  static const _card  = Color(0xFF2E1E0C);
  static const _gold  = Color(0xFFDFAF58);
  static const _terra = Color(0xFFD4581E);
  static const _cream = Color(0xFFF5EDD8);
  static const _sand  = Color(0xFFE0C896);

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).currentAppUser;
    if (user == null) {
      return Scaffold(
        backgroundColor: _bg,
        body: const Center(child: CircularProgressIndicator(color: Color(0xFFDFAF58))),
      );
    }
    final isGuide = user.role == UserRole.guide;

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // Faint warm pyramid bg
          Positioned.fill(child: CustomPaint(painter: _HeritageBgPainter())),

          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(context, user, isGuide)),
                SliverToBoxAdapter(child: _buildHeroCard(context, isGuide)),
                SliverToBoxAdapter(child: _buildGrid(context, isGuide)),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppUser user, bool isGuide) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          // Logo mark
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _gold.withValues(alpha: 0.4)),
            ),
            child: const CulturaXLogoWidget(size: 32),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CulturaX', style: GoogleFonts.playfairDisplay(
                    color: _gold, fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Welcome, ${user.firstName}',
                    style: GoogleFonts.inter(color: _sand, fontSize: 12),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          // Role badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: (isGuide ? _gold : _terra).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: (isGuide ? _gold : _terra).withValues(alpha: 0.45)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(isGuide ? Icons.tour_rounded : Icons.explore_rounded,
                  size: 12, color: isGuide ? _gold : _terra),
              const SizedBox(width: 5),
              Text(isGuide ? 'Tour Guide' : 'Tourist',
                  style: GoogleFonts.inter(
                      color: isGuide ? _gold : _terra,
                      fontSize: 11, fontWeight: FontWeight.bold)),
            ]),
          ),
          const SizedBox(width: 8),
          // Sign out
          GestureDetector(
            onTap: () async {
              await Provider.of<AuthService>(context, listen: false).signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LandingScreen()),
                    (_) => false);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white12),
              ),
              child: const Icon(Icons.logout_rounded, color: Colors.white38, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context, bool isGuide) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isGuide
                ? [const Color(0xFF3D2A0A), const Color(0xFF2A1C08)]
                : [const Color(0xFF3D1A0A), const Color(0xFF2A1408)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: (isGuide ? _gold : _terra).withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isGuide ? _gold : _terra).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isGuide ? 'GUIDE DASHBOARD' : 'HERITAGE EXPLORER',
                      style: GoogleFonts.inter(
                          color: isGuide ? _gold : _terra,
                          fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isGuide
                        ? 'Create & Manage\nHeritage Routes'
                        : 'Discover Egypt\'s\nAncient Heritage',
                    style: GoogleFonts.playfairDisplay(
                        color: _cream, fontSize: 20, fontWeight: FontWeight.bold, height: 1.2),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isGuide
                        ? 'Build immersive cultural tours for your groups'
                        : 'Scan monuments, join tours, collect heritage stamps',
                    style: GoogleFonts.inter(color: Colors.white54, fontSize: 11, height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => isGuide
                            ? const CreateTourScreen()
                            : const ARMonumentScannerScreen(),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isGuide ? _gold : _terra,
                      foregroundColor: const Color(0xFF1E1308),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: Text(
                      isGuide ? 'Create Route' : 'Scan a Monument',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Icon(
              isGuide ? Icons.map_outlined : Icons.account_balance_outlined,
              size: 72,
              color: (isGuide ? _gold : _terra).withValues(alpha: 0.2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(BuildContext context, bool isGuide) {
    final features = isGuide
        ? [
            _HFeature('Create Heritage Route', Icons.add_location_rounded, _gold,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateTourScreen()))),
            _HFeature('Join a Tour', Icons.qr_code_scanner_rounded, _terra,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const JoinTourScreen()))),
            _HFeature('My Stamps', Icons.military_tech_rounded, _gold,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StampCollectionScreen()))),
            _HFeature('Explorer Profile', Icons.person_rounded, Colors.blueAccent,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExplorerProfileScreen()))),
          ]
        : [
            _HFeature('Heritage Scanner', Icons.camera_enhance_rounded, const Color(0xFF3DAA6B),
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ARMonumentScannerScreen()))),
            _HFeature('Join a Tour', Icons.qr_code_scanner_rounded, _terra,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const JoinTourScreen()))),
            _HFeature('My Stamps', Icons.military_tech_rounded, _gold,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StampCollectionScreen()))),
            _HFeature('Explorer Profile', Icons.person_rounded, Colors.blueAccent,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExplorerProfileScreen()))),
          ];


    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Access', style: GoogleFonts.inter(
              color: _sand, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2, shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12, mainAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: features.map((f) => _buildFeatureTile(f)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureTile(_HFeature f) {
    return GestureDetector(
      onTap: f.onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: f.color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: f.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(f.icon, color: f.color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(f.label,
                  style: GoogleFonts.inter(
                      color: _cream, fontSize: 12, fontWeight: FontWeight.w600, height: 1.3)),
            ),
          ],
        ),
      ),
    );
  }

}

class _HFeature {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _HFeature(this.label, this.icon, this.color, this.onTap);
}

class _HeritageBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFDFAF58).withValues(alpha: 0.03)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, size.height * 0.1)
      ..lineTo(-size.width * 0.2, size.height)
      ..lineTo(size.width * 1.2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
