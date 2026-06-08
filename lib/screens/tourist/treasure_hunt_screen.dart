import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/ar_models.dart';
import '../../services/monument_data_service.dart';
import '../../services/game_progress_service.dart';
import 'treasure_hunt_completion_screen.dart';

class TreasureHuntScreen extends StatefulWidget {
  final MonumentInfo monument;

  const TreasureHuntScreen({super.key, required this.monument});

  @override
  State<TreasureHuntScreen> createState() => _TreasureHuntScreenState();
}

class _TreasureHuntScreenState extends State<TreasureHuntScreen>
    with TickerProviderStateMixin {
  late AnimationController _compassCtrl;
  late AnimationController _hotspotPulseCtrl;
  int _currentMissionIndex = 0;
  bool _showHint = false;

  @override
  void initState() {
    super.initState();
    _compassCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _hotspotPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _compassCtrl.dispose();
    _hotspotPulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = Provider.of<GameProgressService>(context);
    final missions = widget.monument.treasureHuntMissions;

    if (missions.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF070B19),
        body: Center(
          child: Text(
            'No treasure hunts active for this monument.',
            style: GoogleFonts.outfit(color: Colors.white70),
          ),
        ),
      );
    }

    // Filter down to incomplete ones if possible, or just play through them
    final currentMission = missions[_currentMissionIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF070B19),
      body: Stack(
        children: [
          // ── Camera Feed/Monument background ────────────────────────────────
          Positioned.fill(
            child: Opacity(
              opacity: 0.5,
              child: Image.asset(
                widget.monument.assetImage,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(color: const Color(0xFF0A1128)),
              ),
            ),
          ),

          // Gradient overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.5),
                    const Color(0xAA070B19),
                    const Color(0xFF070B19),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // ── Active Target nodes overlay ────────────────────────────────────
          Positioned.fill(
            child: SafeArea(
              child: Stack(
                children: widget.monument.arHotspots.map((hs) {
                  final isTarget = hs.id == currentMission.correctHotspotId;
                  return _buildInteractiveHotspot(hs, isTarget, progress, currentMission);
                }).toList(),
              ),
            ),
          ),

          // ── Active Mission Clue Card ──────────────────────────────────────
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                _buildClueCard(currentMission),
                const Spacer(),
                _buildBottomPanel(missions.length),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            'TREASURE HUNT ACTIVE',
            style: GoogleFonts.spaceMono(
              color: const Color(0xFFDFAF58),
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildClueCard(TreasureHuntMission mission) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xDD121F3D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDFAF58).withOpacity(0.5), width: 1.5),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 10, spreadRadius: 1),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CLUE #${_currentMissionIndex + 1}: ${mission.title.toUpperCase()}',
                style: GoogleFonts.spaceMono(
                  color: const Color(0xFFDFAF58),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDFAF58).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '+${mission.rewardPoints} XP',
                  style: GoogleFonts.spaceMono(
                    color: const Color(0xFFDFAF58),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            mission.clue,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          if (_showHint) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0x224CD87A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF4CD87A).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline, color: Color(0xFF4CD87A), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      mission.hint,
                      style: GoogleFonts.outfit(
                        color: Colors.white70,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInteractiveHotspot(
      ARHotspot hs, bool isTarget, GameProgressService progress, TreasureHuntMission mission) {
    return Positioned(
      left: MediaQuery.of(context).size.width * hs.position.dx - 24,
      top: MediaQuery.of(context).size.height * 0.45 * hs.position.dy,
      child: AnimatedBuilder(
        animation: _hotspotPulseCtrl,
        builder: (context, child) {
          final scale = 1.0 + (_hotspotPulseCtrl.value * 0.3);
          return GestureDetector(
            onTap: () {
              if (isTarget) {
                _onCorrectAnswer(progress, mission);
              } else {
                _onWrongAnswer();
              }
            },
            child: SizedBox(
              width: 54,
              height: 54,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 38 * scale,
                    height: 38 * scale,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.transparent,
                      border: Border.all(
                        color: const Color(0xFFDFAF58).withOpacity(1.0 - _hotspotPulseCtrl.value),
                        width: 2,
                      ),
                    ),
                  ),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFFDFAF58), Color(0xFF9A7B3C)],
                      ),
                    ),
                    child: const Icon(
                      Icons.stars,
                      color: Color(0xFF070B19),
                      size: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _onCorrectAnswer(GameProgressService progress, TreasureHuntMission mission) {
    progress.completeMission(mission);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF4CD87A),
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 10),
            Text(
              'CORRECT! +${mission.rewardPoints} XP',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );

    if (_currentMissionIndex + 1 < widget.monument.treasureHuntMissions.length) {
      setState(() {
        _currentMissionIndex++;
        _showHint = false;
      });
    } else {
      // Last mission finished! Launch completion screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TreasureHuntCompletionScreen(monument: widget.monument),
        ),
      );
    }
  }

  void _onWrongAnswer() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFFEF5350),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 10),
            Text(
              'Not quite! Keep exploring the other nodes.',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomPanel(int totalMissions) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF0D1424),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'QUEST PROGRESS',
                style: GoogleFonts.spaceMono(
                  color: Colors.white54,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Mission ${_currentMissionIndex + 1} of $totalMissions',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFDFAF58),
              backgroundColor: const Color(0xFFDFAF58).withOpacity(0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            icon: const Icon(Icons.lightbulb_outline, size: 16),
            label: Text(
              _showHint ? 'Hint Active' : 'Reveal Hint',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            onPressed: () {
              setState(() {
                _showHint = true;
              });
            },
          ),
        ],
      ),
    );
  }
}
