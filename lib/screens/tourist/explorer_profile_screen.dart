import 'package:flutter/material.dart' hide Badge;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/game_progress_service.dart';
import '../../services/monument_data_service.dart';
import '../../models/ar_models.dart';

class ExplorerProfileScreen extends StatelessWidget {
  const ExplorerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = Provider.of<GameProgressService>(context);

    // Calculate level based on points
    final int points = progress.totalPoints;
    final int level = (points / 200).floor() + 1;
    final int pointsToNext = 200 - (points % 200);
    final double percentToNext = (points % 200) / 200.0;

    String rank = 'Novice Explorer';
    if (level >= 10) rank = 'Ancient Legend';
    else if (level >= 7) rank = 'Master Historian';
    else if (level >= 4) rank = 'Grand Adventurer';
    else if (level >= 2) rank = 'Avid Chronicle-Keeper';

    return Scaffold(
      backgroundColor: const Color(0xFF070B19),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'EXPLORER PROFILE',
          style: GoogleFonts.spaceMono(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),

              // ── Header Profile Card ────────────────────────────────────────
              _buildProfileCard(rank, level, points, percentToNext, pointsToNext, progress.currentStreak),

              const SizedBox(height: 24),

              // ── Statistics Row ─────────────────────────────────────────────
              _buildStatsRow(progress),

              const SizedBox(height: 30),

              // ── Badge Showcase ─────────────────────────────────────────────
              _buildBadgeSection(context, progress.badges),

              const SizedBox(height: 30),

              // ── Digital Artifacts ──────────────────────────────────────────
              _buildArtifactsSection(context, progress.collectedArtifacts),

              const SizedBox(height: 30),

              // ── Scanned Monuments ──────────────────────────────────────────
              _buildScannedMonumentsSection(context, progress),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(
      String rank, int level, int points, double percentToNext, int pointsToNext, int streak) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111C36),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDFAF58).withOpacity(0.3), width: 1.5),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 15, spreadRadius: 2),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFDFAF58), width: 2),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                  ),
                ),
                child: const Center(
                  child: Text('🤠', style: TextStyle(fontSize: 36)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Adventure Level $level',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rank.toUpperCase(),
                      style: GoogleFonts.spaceMono(
                        color: const Color(0xFFDFAF58),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // Streak badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.deepOrange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.deepOrange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department, color: Colors.deepOrange, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '$streak d',
                      style: GoogleFonts.spaceMono(
                        color: Colors.deepOrange,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Experience progress bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$points XP TOTAL',
                style: GoogleFonts.spaceMono(color: Colors.white54, fontSize: 10),
              ),
              Text(
                'Next Level in $pointsToNext XP',
                style: GoogleFonts.spaceMono(color: const Color(0xFF4CD87A), fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percentToNext,
              minHeight: 10,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4CD87A)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(GameProgressService progress) {
    return Row(
      children: [
        _buildStatItem('MONUMENTS', '${progress.scannedMonuments.length}', Icons.location_on),
        const SizedBox(width: 12),
        _buildStatItem('MISSIONS', '${progress.completedMissions.length}', Icons.military_tech),
        const SizedBox(width: 12),
        _buildStatItem('BADGES', '${progress.badges.length}', Icons.workspace_premium),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF10192E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFFDFAF58), size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.spaceMono(
                color: Colors.white30,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeSection(BuildContext context, List<Badge> badges) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('MY BADGES', '${badges.length} EARNED'),
        const SizedBox(height: 12),
        if (badges.isEmpty)
          _buildEmptyPlaceholder('No badges unlocked yet. Keep scanning!')
        else
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: badges.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final badge = badges[index];
                return Container(
                  width: 90,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10192E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _getBorderColorForRarity(badge.rarity)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🏆', style: TextStyle(fontSize: 24)),
                      const SizedBox(height: 4),
                      Text(
                        badge.name,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildArtifactsSection(BuildContext context, List<DigitalArtifact> artifacts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('DIGITAL ARTIFACTS', '${artifacts.length} DISCOVERED'),
        const SizedBox(height: 12),
        if (artifacts.isEmpty)
          _buildEmptyPlaceholder('Solve treasure hunt clues to locate artifacts.')
        else
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: artifacts.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final art = artifacts[index];
                return Container(
                  width: 90,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10192E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        art.emoji,
                        style: const TextStyle(fontSize: 28),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        art.name,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildScannedMonumentsSection(BuildContext context, GameProgressService progress) {
    // Fetch information for scanned monuments
    final scannedList = MonumentDataService.monuments
        .where((m) => progress.scannedMonuments.contains(m.id))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('COLLECTED MONUMENTS', '${scannedList.length} VISITED'),
        const SizedBox(height: 12),
        if (scannedList.isEmpty)
          _buildEmptyPlaceholder('No monuments scanned yet. Use AR to scan!')
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: scannedList.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final monument = scannedList[index];
              final scorePercent = progress.getMonumentProgress(monument.id);

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF10192E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        monument.assetImage,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, e, s) => Container(color: Colors.white10, width: 50, height: 50),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            monument.name,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            monument.location,
                            style: GoogleFonts.outfit(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${(scorePercent * 100).toInt()}% Done',
                          style: GoogleFonts.spaceMono(
                            color: const Color(0xFF4CD87A),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Discovery Rate',
                          style: GoogleFonts.spaceMono(
                            color: Colors.white30,
                            fontSize: 8,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.spaceMono(
            color: const Color(0xFFDFAF58),
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 1.5,
          ),
        ),
        Text(
          subtitle,
          style: GoogleFonts.spaceMono(
            color: Colors.white30,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyPlaceholder(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF10192E).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Center(
        child: Text(
          message,
          style: GoogleFonts.outfit(
            color: Colors.white30,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Color _getBorderColorForRarity(BadgeRarity rarity) {
    switch (rarity) {
      case BadgeRarity.bronze:
        return Colors.brown.withOpacity(0.5);
      case BadgeRarity.silver:
        return Colors.blueGrey.withOpacity(0.5);
      case BadgeRarity.gold:
        return Colors.amber.withOpacity(0.5);
      case BadgeRarity.legendary:
        return Colors.purpleAccent.withOpacity(0.5);
    }
  }
}
