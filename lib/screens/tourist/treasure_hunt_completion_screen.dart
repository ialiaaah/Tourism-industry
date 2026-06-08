import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import '../../services/monument_data_service.dart';

class TreasureHuntCompletionScreen extends StatefulWidget {
  final MonumentInfo monument;

  const TreasureHuntCompletionScreen({super.key, required this.monument});

  @override
  State<TreasureHuntCompletionScreen> createState() =>
      _TreasureHuntCompletionScreenState();
}

class _TreasureHuntCompletionScreenState
    extends State<TreasureHuntCompletionScreen> {
  late ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 4));
    _confetti.play();
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B19),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // ── Confetti effect ────────────────────────────────────────────────
          ConfettiWidget(
            confettiController: _confetti,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              Color(0xFFDFAF58),
              Color(0xFF4CD87A),
              Colors.amber,
              Colors.white,
            ],
          ),

          // ── Centered content ───────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),

                  // Trophy/Success Icon
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFDFAF58).withOpacity(0.1),
                        border: Border.all(color: const Color(0xFFDFAF58), width: 3),
                      ),
                      child: const Icon(
                        Icons.military_tech_rounded,
                        color: Color(0xFFDFAF58),
                        size: 64,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'CONGRATULATIONS!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.spaceMono(
                      color: const Color(0xFFDFAF58),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Quest Completed Successfully',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'You have completed all treasure hunt missions for ${widget.monument.name} and proved your historical knowledge!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 36),

                  // ── Rewards Card ───────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF121F3D),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'YOUR REWARDS',
                          style: GoogleFonts.spaceMono(
                            color: Colors.white54,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildRewardItem('XP POINTS', '+250', Icons.workspace_premium),
                            _buildRewardItem('ARTIFACT', 'Ancient Sigil', Icons.auto_stories),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Back to scan CTA
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDFAF58),
                      foregroundColor: const Color(0xFF070B19),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Back to Monument AR',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFDFAF58), size: 28),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.spaceMono(
            color: Colors.white30,
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}
