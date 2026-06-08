import 'dart:math' as math;
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../models/ar_models.dart';
import '../../services/monument_data_service.dart';
import '../../services/game_progress_service.dart';
import '../../theme/app_theme.dart';

/// Narrative treasure hunt — 5 historical riddles about the Great Sphinx.
class TreasureHuntScreen extends StatefulWidget {
  final MonumentInfo monument;
  const TreasureHuntScreen({super.key, required this.monument});

  @override
  State<TreasureHuntScreen> createState() => _TreasureHuntScreenState();
}

class _TreasureHuntScreenState extends State<TreasureHuntScreen>
    with TickerProviderStateMixin {
  late final List<_QuestStage> _stages;
  int _current = 0;
  bool _intro = true;           // show intro screen first
  bool _answered = false;       // user has picked an answer
  int? _selected;               // index of picked answer
  int _totalXP = 0;
  int _correctCount = 0;

  late AnimationController _cardCtrl;
  late Animation<double> _cardAnim;
  late AnimationController _correctCtrl;
  late Animation<double> _correctAnim;
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;
  late ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _stages = _buildStages();

    _cardCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _cardAnim = CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOut);
    _cardCtrl.forward();

    _correctCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _correctAnim =
        CurvedAnimation(parent: _correctCtrl, curve: Curves.elasticOut);

    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _shakeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: -6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: 0.0), weight: 1),
    ]).animate(_shakeCtrl);

    _confetti = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _cardCtrl.dispose();
    _correctCtrl.dispose();
    _shakeCtrl.dispose();
    _confetti.dispose();
    super.dispose();
  }

  // ── Quest stages ──────────────────────────────────────────────────────────

  List<_QuestStage> _buildStages() => [
        _QuestStage(
          stageNumber: 1,
          chapterTitle: 'The First Light',
          story:
              'The sun rises over the Giza Plateau as you stand before the'
              ' Great Sphinx for the first time. Its worn limestone face'
              ' gazes ahead with an eternal calm. An ancient parchment in'
              ' your satchel holds the first riddle…',
          riddle:
              'I have faced the same direction for 4,500 years — watching the'
              ' solar disc emerge each dawn and tracking the equinoxes.'
              '\n\n Which cardinal direction do I eternally face?',
          options: ['North', 'East', 'South', 'West'],
          correctIndex: 1,
          explanation:
              'The Sphinx faces true east. On both the spring and autumn'
              ' equinoxes, the sun rises directly in line with its gaze,'
              ' a solar alignment intentional in ancient Egyptian cosmology.',
          icon: Icons.wb_sunny_rounded,
          color: Color(0xFFDFAF58),
          xp: 50,
        ),
        _QuestStage(
          stageNumber: 2,
          chapterTitle: 'The Dream Stele',
          story:
              'You notice a tall stone tablet nestled between the great paws.'
              ' Its hieroglyphs tell a story of destiny, royalty, and a'
              ' divine promise made to a sleeping prince.',
          riddle:
              'A young Egyptian prince fell asleep in the shadow of my head'
              ' during a hunting trip. In his dream I promised him the throne'
              ' of Egypt if he would clear the sand burying my body.'
              '\n\n Who was this prince, who later erected this very stele?',
          options: [
            'Ramesses II',
            'Tutankhamun',
            'Thutmose IV',
            'Akhenaten'
          ],
          correctIndex: 2,
          explanation:
              'Thutmose IV (c. 1400 BCE) erected the Dream Stele to legitimise'
              ' his claim to the throne. The inscription is one of the oldest'
              ' references to the Sphinx as a living deity — "Horemakhet"'
              ' (Horus on the Horizon).',
          icon: Icons.bedtime_rounded,
          color: Color(0xFF9C27B0),
          xp: 50,
        ),
        _QuestStage(
          stageNumber: 3,
          chapterTitle: 'The Vanished Feature',
          story:
              'Your field notebook records accounts from medieval Arab'
              ' travellers who described the Sphinx very differently from'
              ' its appearance today. Something remarkable is missing — and'
              ' Napoleon\'s cannons had nothing to do with it.',
          riddle:
              'Contrary to popular myth, my iconic missing feature was'
              ' already gone centuries before Napoleon arrived in Egypt.'
              ' The Arab historian al-Maqrizi wrote in the 14th century'
              ' that a religious fanatic damaged it in 1378.'
              '\n\n What famous feature is missing from my face?',
          options: ['The left ear', 'The royal beard', 'The nose', 'The eyes'],
          correctIndex: 2,
          explanation:
              'The nose of the Sphinx was deliberately damaged, likely by'
              ' Muhammad Sa\'im al-Dahr in 1378 CE. A fragment of the actual'
              ' beard is now in the British Museum — confirming it once existed.',
          icon: Icons.face_rounded,
          color: Color(0xFFD4581E),
          xp: 50,
        ),
        _QuestStage(
          stageNumber: 4,
          chapterTitle: 'The Lion\'s Measure',
          story:
              'Walking around the great leonine form, you are overwhelmed'
              ' by its sheer scale. It was carved from a single natural'
              ' limestone knoll — the quarry workers simply removed the'
              ' surrounding stone, leaving this colossus behind.',
          riddle:
              'I am the world\'s largest monolithic statue — carved from'
              ' a single continuous mass of bedrock.'
              ' Modern laser surveys have precisely measured my full length'
              ' from my extended front paws to my tail.'
              '\n\n How long am I from paw to tail?',
          options: ['53 metres', '63 metres', '73 metres', '83 metres'],
          correctIndex: 2,
          explanation:
              'The Sphinx is 73.5 metres long and 20.3 metres tall — roughly'
              ' the length of a Boeing 737. It was carved in situ, meaning'
              ' the sculptors never moved the stone; they sculpted the'
              ' plateau itself.',
          icon: Icons.straighten_rounded,
          color: Color(0xFF4CD87A),
          xp: 75,
        ),
        _QuestStage(
          stageNumber: 5,
          chapterTitle: 'The Ancient Controversy',
          story:
              'As the golden hour paints the plateau amber, you pull out'
              ' the final riddle. This one delves into one of archaeology\'s'
              ' greatest controversies — the true age of the Sphinx'
              ' and what the weathering on its walls might reveal.',
          riddle:
              'Geologist Robert Schoch studied the Sphinx enclosure walls'
              ' in the 1990s and made a startling claim: the erosion'
              ' patterns were not caused by windblown sand — they suggested'
              ' the Sphinx is far older than mainstream Egyptology accepts.'
              '\n\n What type of erosion did Schoch cite as evidence?',
          options: [
            'Wind erosion',
            'Desert sand abrasion',
            'Water / rainfall erosion',
            'Earthquake fracturing'
          ],
          correctIndex: 2,
          explanation:
              'Schoch identified deep vertical weathering channels consistent'
              ' with prolonged heavy rainfall — arguing the Sphinx was'
              ' built before 7000 BCE when North Africa had a wetter climate.'
              ' The debate remains unsettled, making the Sphinx one of'
              ' archaeology\'s most exciting mysteries.',
          icon: Icons.water_drop_rounded,
          color: Color(0xFF00BCD4),
          xp: 75,
        ),
      ];

  // ── Interaction ───────────────────────────────────────────────────────────

  void _pickAnswer(int index) {
    if (_answered) return;
    final correct = _stages[_current].correctIndex;
    HapticFeedback.lightImpact();
    setState(() {
      _answered = true;
      _selected = index;
    });
    if (index == correct) {
      _totalXP += _stages[_current].xp;
      _correctCount++;
      _correctCtrl.forward(from: 0);
      HapticFeedback.heavyImpact();
    } else {
      _shakeCtrl.forward(from: 0);
      HapticFeedback.mediumImpact();
    }
  }

  void _nextStage() {
    if (_current < _stages.length - 1) {
      setState(() {
        _current++;
        _answered = false;
        _selected = null;
      });
      _cardCtrl.forward(from: 0);
      _correctCtrl.reset();
    } else {
      _finish();
    }
  }

  void _finish() {
    final progress = Provider.of<GameProgressService>(context, listen: false);
    for (int i = 0; i < _correctCount; i++) {
      // Award XP proportionally to correct answers
    }
    progress.completeMission(TreasureHuntMission(
      id: 'sphinx_quest_complete',
      monumentId: widget.monument.id,
      title: 'Sphinx Quest Complete',
      clue: 'Complete all 5 Sphinx riddles',
      hint: 'Answer historical questions about the Great Sphinx',
      correctHotspotId: 'sphinx_hotspot_1',
      rewardPoints: _totalXP,
      badgeReward: 'Sphinx Explorer',
      artifactReward: 'Guardian of Giza',
    ));
    _confetti.play();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => _QuestCompletionScreen(
          monument: widget.monument,
          xpEarned: _totalXP,
          correctCount: _correctCount,
          totalCount: _stages.length,
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_intro) return _buildIntroScreen();
    return _buildQuestScreen();
  }

  // ── Intro screen ──────────────────────────────────────────────────────────

  Widget _buildIntroScreen() {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Opacity(
              opacity: 0.25,
              child: Image.asset(
                widget.monument.assetImage,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: AppColors.bg),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.bg.withValues(alpha: 0.6),
                    AppColors.bg,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0, 0.55],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  // Back
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: AppColors.cream, size: 18),
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(colors: [
                        Color(0xFF4A2A06),
                        Color(0xFF2E1A04),
                      ]),
                      border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.6),
                          width: 2),
                    ),
                    child: const Icon(Icons.explore_rounded,
                        color: AppColors.gold, size: 36),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'The Sphinx\nScholar Quest',
                    style: GoogleFonts.playfairDisplay(
                        color: AppColors.cream,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        height: 1.15),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'The year is 1925. You are a young archaeologist who'
                      ' has just arrived at the Giza Plateau. An ancient'
                      ' parchment in your satchel holds five riddles that'
                      ' will unlock the deepest secrets of the Great Sphinx.\n\n'
                      'Answer correctly to earn XP and unlock the'
                      ' Sphinx Scholar badge.\n\nAre you ready to begin?',
                      style:
                          AppTextStyles.body.copyWith(height: 1.65),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // XP preview
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _xpBadge('5 Riddles', Icons.quiz_rounded, AppColors.gold),
                      const SizedBox(width: 12),
                      _xpBadge('300 XP', Icons.star_rounded, AppColors.terra),
                      const SizedBox(width: 12),
                      _xpBadge('1 Badge', Icons.workspace_premium_rounded,
                          const Color(0xFF9C27B0)),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => setState(() => _intro = false),
                      icon: const Icon(Icons.play_arrow_rounded, size: 20),
                      label: const Text('Begin Quest'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.bg,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        textStyle: GoogleFonts.inter(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _xpBadge(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(label,
              style: AppTextStyles.labelSmall.copyWith(color: color)),
        ],
      ),
    );
  }

  // ── Quest screen ──────────────────────────────────────────────────────────

  Widget _buildQuestScreen() {
    final stage = _stages[_current];
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // Subtle background
          Positioned.fill(
            child: Opacity(
              opacity: 0.12,
              child: Image.asset(widget.monument.assetImage,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: AppColors.bg)),
            ),
          ),
          Positioned.fill(
            child: Container(color: AppColors.bg.withValues(alpha: 0.85)),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _cardAnim,
              child: Column(
                children: [
                  _buildQuestTopBar(stage),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStoryCard(stage),
                          const SizedBox(height: 16),
                          _buildRiddleCard(stage),
                          const SizedBox(height: 16),
                          _buildOptions(stage),
                          if (_answered) ...[
                            const SizedBox(height: 16),
                            _buildFeedbackCard(stage),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestTopBar(_QuestStage stage) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.close_rounded,
                color: AppColors.muted, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stage ${_current + 1} of ${_stages.length}  ·  ${stage.chapterTitle}',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.gold),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (_current + 1) / _stages.length,
                    backgroundColor: AppColors.border,
                    color: stage.color,
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded,
                    color: AppColors.gold, size: 13),
                const SizedBox(width: 4),
                Text('$_totalXP XP',
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.gold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryCard(_QuestStage stage) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: stage.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: stage.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(stage.icon, color: stage.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stage.chapterTitle,
                    style: AppTextStyles.label
                        .copyWith(color: stage.color)),
                const SizedBox(height: 6),
                Text(stage.story,
                    style:
                        AppTextStyles.body.copyWith(height: 1.6)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiddleCard(_QuestStage stage) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            stage.color.withValues(alpha: 0.12),
            AppColors.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: stage.color.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.menu_book_rounded,
                  color: AppColors.gold, size: 16),
              const SizedBox(width: 8),
              Text('The Riddle',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.gold)),
            ],
          ),
          const SizedBox(height: 12),
          Text(stage.riddle,
              style: GoogleFonts.playfairDisplay(
                  color: AppColors.cream,
                  fontSize: 15,
                  height: 1.7)),
        ],
      ),
    );
  }

  Widget _buildOptions(_QuestStage stage) {
    return AnimatedBuilder(
      animation: _shakeAnim,
      builder: (_, child) => Transform.translate(
        offset: Offset(_shakeAnim.value, 0),
        child: child,
      ),
      child: Column(
        children: List.generate(stage.options.length, (i) {
          final isCorrect = i == stage.correctIndex;
          final isSelected = i == _selected;

          Color bgColor = AppColors.surface;
          Color borderColor = AppColors.border;
          Color textColor = AppColors.sand;
          Widget? trailing;

          if (_answered) {
            if (isCorrect) {
              bgColor = AppColors.success.withValues(alpha: 0.12);
              borderColor = AppColors.success;
              textColor = AppColors.success;
              trailing = const Icon(Icons.check_circle_rounded,
                  color: AppColors.success, size: 20);
            } else if (isSelected) {
              bgColor = AppColors.error.withValues(alpha: 0.1);
              borderColor = AppColors.error;
              textColor = AppColors.error;
              trailing = const Icon(Icons.cancel_rounded,
                  color: AppColors.error, size: 20);
            }
          }

          return GestureDetector(
            onTap: () => _pickAnswer(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: borderColor.withValues(alpha: 0.6)),
                      color: _answered && isCorrect
                          ? AppColors.success.withValues(alpha: 0.15)
                          : AppColors.bg.withValues(alpha: 0.4),
                    ),
                    child: Center(
                      child: Text(
                        String.fromCharCode(65 + i), // A, B, C, D
                        style: AppTextStyles.label.copyWith(
                            color: textColor, fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(stage.options[i],
                        style: AppTextStyles.body
                            .copyWith(color: textColor)),
                  ),
                  if (trailing != null) trailing,
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildFeedbackCard(_QuestStage stage) {
    final isCorrect = _selected == stage.correctIndex;
    final color = isCorrect ? AppColors.success : AppColors.error;
    final icon = isCorrect
        ? Icons.emoji_events_rounded
        : Icons.lightbulb_rounded;
    final title = isCorrect
        ? 'Correct! You uncovered a hidden detail.'
        : 'Not quite — but here\'s what history tells us…';

    return ScaleTransition(
      scale: _correctAnim.value > 0
          ? _correctAnim
          : const AlwaysStoppedAnimation(1.0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(title,
                        style: AppTextStyles.label
                            .copyWith(color: color))),
                if (isCorrect)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('+${stage.xp} XP',
                        style: AppTextStyles.badge
                            .copyWith(color: AppColors.gold)),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(stage.explanation,
                style: AppTextStyles.body.copyWith(height: 1.6)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _nextStage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.bg,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  _current < _stages.length - 1
                      ? 'Next Stage  →'
                      : 'Complete Quest  🏆',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Data model ────────────────────────────────────────────────────────────────

class _QuestStage {
  final int stageNumber;
  final String chapterTitle;
  final String story;
  final String riddle;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final IconData icon;
  final Color color;
  final int xp;

  const _QuestStage({
    required this.stageNumber,
    required this.chapterTitle,
    required this.story,
    required this.riddle,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    required this.icon,
    required this.color,
    required this.xp,
  });
}

// ── Completion screen ─────────────────────────────────────────────────────────

class _QuestCompletionScreen extends StatefulWidget {
  final MonumentInfo monument;
  final int xpEarned;
  final int correctCount;
  final int totalCount;

  const _QuestCompletionScreen({
    required this.monument,
    required this.xpEarned,
    required this.correctCount,
    required this.totalCount,
  });

  @override
  State<_QuestCompletionScreen> createState() =>
      _QuestCompletionScreenState();
}

class _QuestCompletionScreenState
    extends State<_QuestCompletionScreen>
    with TickerProviderStateMixin {
  late ConfettiController _confetti;
  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _confetti =
        ConfettiController(duration: const Duration(seconds: 5))..play();
    _scaleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _scaleAnim =
        CurvedAnimation(parent: _scaleCtrl, curve: Curves.elasticOut);
    _scaleCtrl.forward();
  }

  @override
  void dispose() {
    _confetti.dispose();
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pct =
        (widget.correctCount / widget.totalCount * 100).round();
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          ConfettiWidget(
            confettiController: _confetti,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              AppColors.gold,
              AppColors.terra,
              AppColors.success,
              Colors.white,
              Color(0xFF9C27B0),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Badge
                  ScaleTransition(
                    scale: _scaleAnim,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(colors: [
                          Color(0xFF5A3A0A),
                          Color(0xFF2E1A04),
                        ]),
                        border: Border.all(
                            color: AppColors.gold, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withValues(alpha: 0.4),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                          Icons.workspace_premium_rounded,
                          color: AppColors.gold,
                          size: 56),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Quest Complete!',
                    style: GoogleFonts.playfairDisplay(
                        color: AppColors.gold,
                        fontSize: 32,
                        fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You unlocked the Sphinx Scholar badge.',
                    style: AppTextStyles.body,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  // Stats row
                  Row(
                    children: [
                      _StatCard(
                          label: 'XP Earned',
                          value: '+${widget.xpEarned}',
                          icon: Icons.star_rounded,
                          color: AppColors.gold),
                      const SizedBox(width: 12),
                      _StatCard(
                          label: 'Accuracy',
                          value: '$pct%',
                          icon: Icons.check_circle_rounded,
                          color: AppColors.success),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Badge card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color:
                              AppColors.gold.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF9C27B0)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                              Icons.workspace_premium_rounded,
                              color: Color(0xFF9C27B0),
                              size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text('Sphinx Scholar',
                                  style: AppTextStyles.h3
                                      .copyWith(
                                          color: AppColors.cream)),
                              const SizedBox(height: 4),
                              Text(
                                  'Unlocked for completing the Sphinx Scholar Quest.',
                                  style: AppTextStyles.bodySmall),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context)
                          ..pop()
                          ..pop()
                          ..pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.bg,
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text('Back to Home',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(value,
                style: GoogleFonts.playfairDisplay(
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label,
                style:
                    AppTextStyles.bodySmall.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}
