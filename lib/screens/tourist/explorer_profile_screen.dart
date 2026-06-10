import 'package:flutter/material.dart' hide Badge;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/game_progress_service.dart';
import '../../services/monument_data_service.dart';
import '../../models/ar_models.dart';

class ExplorerProfileScreen extends StatelessWidget {
  const ExplorerProfileScreen({super.key});

  // ── Palette ────────────────────────────────────────────────────────────────
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
    final progress = Provider.of<GameProgressService>(context);

    final int points       = progress.totalPoints;
    final int level        = (points / 200).floor() + 1;
    final int pointsToNext = 200 - (points % 200);
    final double pct       = (points % 200) / 200.0;

    String rank = 'Novice Explorer';
    if (level >= 10)     rank = 'Ancient Legend';
    else if (level >= 7) rank = 'Master Historian';
    else if (level >= 4) rank = 'Grand Adventurer';
    else if (level >= 2) rank = 'Avid Chronicle-Keeper';

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _card,
        foregroundColor: _cream,
        elevation: 0,
        title: Text(
          'Explorer Profile',
          style: GoogleFonts.playfairDisplay(
            color: _gold,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProfileCard(rank, level, points, pct, pointsToNext, progress.currentStreak),
            const SizedBox(height: 24),
            _buildStatsRow(progress),
            const SizedBox(height: 28),
            _buildBadgeSection(progress.badges),
            const SizedBox(height: 28),
            _buildArtifactsSection(progress.collectedArtifacts),
            const SizedBox(height: 28),
            _buildScannedMonumentsSection(context, progress),
          ],
        ),
      ),
    );
  }

  // ── Profile card ────────────────────────────────────────────────────────────
  Widget _buildProfileCard(String rank, int level, int points,
      double pct, int pointsToNext, int streak) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _gold.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _gold, width: 2),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3A2410), Color(0xFF2E1E0C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Text('🤠', style: TextStyle(fontSize: 36)),
                ),
              ),
              const SizedBox(width: 16),
              // Level + rank
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Adventure Level $level',
                      style: GoogleFonts.playfairDisplay(
                        color: _cream,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rank,
                      style: GoogleFonts.inter(
                        color: _gold,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // Streak badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _terra.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _terra.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_fire_department, color: _terra, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '$streak d',
                      style: GoogleFonts.inter(
                        color: _terra,
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
          // XP progress bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$points XP total',
                style: GoogleFonts.inter(color: _muted, fontSize: 11),
              ),
              Text(
                '$pointsToNext XP to next level',
                style: GoogleFonts.inter(color: _sand, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 10,
              backgroundColor: _cardAlt,
              valueColor: const AlwaysStoppedAnimation<Color>(_gold),
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats row ───────────────────────────────────────────────────────────────
  Widget _buildStatsRow(GameProgressService progress) {
    return Row(
      children: [
        _buildStatItem('Monuments', '${progress.scannedMonuments.length}', Icons.location_on_rounded),
        const SizedBox(width: 10),
        _buildStatItem('Missions',  '${progress.completedMissions.length}', Icons.military_tech_rounded),
        const SizedBox(width: 10),
        _buildStatItem('Badges',    '${progress.badges.length}', Icons.workspace_premium_rounded),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _cardAlt),
        ),
        child: Column(
          children: [
            Icon(icon, color: _gold, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.playfairDisplay(
                color: _cream,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                color: _muted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Badges ──────────────────────────────────────────────────────────────────
  Widget _buildBadgeSection(List<Badge> badges) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('My Badges', '${badges.length} earned'),
        const SizedBox(height: 12),
        badges.isEmpty
            ? _buildEmptyPlaceholder('No badges yet — keep scanning monuments!')
            : SizedBox(
                height: 96,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: badges.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) {
                    final badge = badges[i];
                    return Container(
                      width: 88,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: _rarityColor(badge.rarity).withValues(alpha: 0.6)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🏆', style: TextStyle(fontSize: 26)),
                          const SizedBox(height: 6),
                          Text(
                            badge.name,
                            style: GoogleFonts.inter(
                              color: _cream,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
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

  // ── Artifacts ───────────────────────────────────────────────────────────────
  Widget _buildArtifactsSection(List<DigitalArtifact> artifacts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Digital Artefacts', '${artifacts.length} discovered'),
        const SizedBox(height: 12),
        artifacts.isEmpty
            ? _buildEmptyPlaceholder('Solve treasure hunt clues to collect artefacts.')
            : SizedBox(
                height: 96,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: artifacts.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) {
                    final art = artifacts[i];
                    return Container(
                      width: 88,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _gold.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(art.emoji, style: const TextStyle(fontSize: 28)),
                          const SizedBox(height: 6),
                          Text(
                            art.name,
                            style: GoogleFonts.inter(
                              color: _cream,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
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

  // ── Scanned monuments ───────────────────────────────────────────────────────
  Widget _buildScannedMonumentsSection(
      BuildContext context, GameProgressService progress) {
    final scannedList = MonumentDataService.monuments
        .where((m) => progress.scannedMonuments.contains(m.id))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Visited Monuments', '${scannedList.length} scanned'),
        const SizedBox(height: 12),
        scannedList.isEmpty
            ? _buildEmptyPlaceholder('No monuments scanned yet. Use the Heritage Scanner!')
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: scannedList.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final monument   = scannedList[i];
                  final scorePercent = progress.getMonumentProgress(monument.id);
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _cardAlt),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            monument.assetImage,
                            width: 52,
                            height: 52,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: _cardAlt,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.account_balance,
                                  color: _gold, size: 26),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                monument.name,
                                style: GoogleFonts.playfairDisplay(
                                  color: _cream,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                monument.location,
                                style: GoogleFonts.inter(
                                    color: _muted, fontSize: 11),
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: scorePercent,
                                  minHeight: 6,
                                  backgroundColor: _cardAlt,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(_gold),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${(scorePercent * 100).toInt()}%',
                          style: GoogleFonts.inter(
                            color: _gold,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ],
    );
  }

  // ── Shared helpers ──────────────────────────────────────────────────────────
  Widget _buildSectionHeader(String title, String subtitle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.playfairDisplay(
            color: _cream,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          subtitle,
          style: GoogleFonts.inter(color: _muted, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildEmptyPlaceholder(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardAlt),
      ),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(color: _muted, fontSize: 13),
        ),
      ),
    );
  }

  Color _rarityColor(BadgeRarity rarity) {
    switch (rarity) {
      case BadgeRarity.bronze:    return const Color(0xFFCD7F32);
      case BadgeRarity.silver:    return const Color(0xFFB0C4DE);
      case BadgeRarity.gold:      return _gold;
      case BadgeRarity.legendary: return _terra;
    }
  }
}
