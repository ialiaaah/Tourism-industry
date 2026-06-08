import 'dart:io';
import 'dart:math' as math;
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin/datatypes/hittest_result_types.dart';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/models/ar_anchor.dart';
import 'package:ar_flutter_plugin/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:vector_math/vector_math_64.dart' as vm;
import '../../services/monument_data_service.dart';
import '../../services/game_progress_service.dart';
import '../../services/audio_narration_service.dart';
import '../../theme/app_theme.dart';
import 'treasure_hunt_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Fun facts — emoji + punchy headline + detail + "wow" score (0-5 🔥)
// ─────────────────────────────────────────────────────────────────────────────
class _Fact {
  final String emoji;
  final String headline;
  final String detail;
  final String wowLabel;   // e.g. "MIND-BLOWING"
  final Color accent;
  const _Fact(this.emoji, this.headline, this.detail, this.wowLabel, this.accent);
}

const _kFacts = <_Fact>[
  _Fact('☀️', 'It\'s a solar alarm clock',
      'The Sphinx faces EXACTLY due east. Every spring and autumn equinox, the rising sun lines up perfectly between its paws. Ancient Egyptians didn\'t have phones — they had a 73-metre stone lion.',
      'COSMIC ALIGNMENT', Color(0xFFFFCC00)),
  _Fact('🎨', 'It was once technicolour',
      'Forget bare stone — scientists found red pigment on the right cheek. The Sphinx was painted vivid red, blue and yellow. Imagine that glowing in the desert sun 4,500 years ago.',
      'COLOURFUL PAST', Color(0xFFFF6B6B)),
  _Fact('👃', 'Napoleon didn\'t break its nose',
      'Blame history books, not Bonaparte. A 15th-century scholar documented the nose was already missing 400 years before Napoleon was even born. The real culprit? A religious fanatic in 1378 CE.',
      'MYTH BUSTED', Color(0xFF4CD87A)),
  _Fact('💤', 'A prince made a deal with it',
      'Prince Thutmose IV fell asleep between its paws and dreamed the Sphinx spoke: "Clear the sand off me and I\'ll make you pharaoh." He obeyed — and became Pharaoh. The contract is still carved on the Dream Stele.',
      'DIVINE DEAL', Color(0xFFAA88FF)),
  _Fact('💧', 'It might be 12,000 years old',
      'Geologist Robert Schoch spotted deep water erosion on the Sphinx\'s walls — erosion that only heavy rainfall could cause. Egypt hasn\'t had that much rain since 10,000 BCE. Egyptology has never recovered.',
      'ANCIENT MYSTERY', Color(0xFF00BCD4)),
  _Fact('📏', 'The scale will break your brain',
      '73 metres long. 20 metres tall. Each ear is over 1 metre long. The face alone is 5 metres wide. This was carved out of a single limestone hill — no assembly required.',
      'ABSOLUTELY MASSIVE', Color(0xFFFF9A3C)),
  _Fact('🦁', 'It is half lion, half pharaoh',
      'The body of a lion (strength + power) with the head of a king (wisdom + authority). Together they symbolize the perfect ruler. Some scholars believe the face is Pharaoh Khafre — others aren\'t so sure.',
      'ROYAL HYBRID', Color(0xFFDFAF58)),
  _Fact('🏛️', 'It is the world\'s oldest monolith',
      'Cut from a single rock outcrop, the Sphinx is the largest monolithic sculpture ever made. The builders didn\'t transport blocks — they just carved away everything that wasn\'t the Sphinx.',
      'WORLD RECORD', Color(0xFF66BB6A)),
];

// ─────────────────────────────────────────────────────────────────────────────
class SphinxARScreen extends StatefulWidget {
  final MonumentInfo monument;
  const SphinxARScreen({super.key, required this.monument});
  @override
  State<SphinxARScreen> createState() => _SphinxARScreenState();
}

class _SphinxARScreenState extends State<SphinxARScreen>
    with TickerProviderStateMixin {

  // ── AR state ──────────────────────────────────────────────────────────────
  ARSessionManager?  _sessionMgr;
  ARObjectManager?   _objectMgr;
  ARAnchorManager?   _anchorMgr;
  ARNode?            _sphinxNode;
  ARAnchor?          _sphinxAnchor;
  bool _modelPlaced  = false;
  bool _isPlacing    = false;
  bool _modelReady   = false;   // true once GLB is copied to documents dir
  String _hint       = '✨  Slowly scan a flat surface, then tap to summon the Sphinx!';

  // ── Facts carousel ────────────────────────────────────────────────────────
  int _factIndex   = 0;
  bool _showFacts  = true;
  late PageController _pageCtrl;
  final Set<int> _readFacts = {};

  // ── Fun overlay (shown once after placement) ──────────────────────────────
  bool _showWelcomeBanner = false;

  // ── Audio ─────────────────────────────────────────────────────────────────
  final AudioNarrationService _audio = AudioNarrationService();
  bool _playing = false;

  // ── Animations ────────────────────────────────────────────────────────────
  late AnimationController _pulseCtrl;
  late AnimationController _slideCtrl;
  late Animation<Offset>   _slideAnim;
  late AnimationController _bannerCtrl;
  late Animation<double>   _bannerAnim;
  late AnimationController _factPopCtrl;
  late Animation<double>   _factPopAnim;
  late ConfettiController  _confetti;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController(viewportFraction: 0.90);

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);

    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 1.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.elasticOut));
    _slideCtrl.forward();

    _bannerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _bannerAnim = CurvedAnimation(parent: _bannerCtrl, curve: Curves.elasticOut);

    _factPopCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _factPopAnim = CurvedAnimation(parent: _factPopCtrl, curve: Curves.elasticOut);
    _factPopCtrl.value = 1.0;

    _confetti = ConfettiController(duration: const Duration(seconds: 2));
    _copyGlbToDocuments();
  }

  /// Copy sphinx.glb from Flutter assets → documents directory so
  /// NodeType.fileSystemAppFolderGLB can load it with a full path.
  Future<void> _copyGlbToDocuments() async {
    try {
      final dir  = await getApplicationDocumentsDirectory();
      final dest = File('${dir.path}/sphinx.glb');
      if (!await dest.exists()) {
        final data = await rootBundle.load('assets/models/sphinx.glb');
        await dest.writeAsBytes(data.buffer.asUint8List(), flush: true);
      }
      if (mounted) setState(() => _modelReady = true);
    } catch (e) {
      debugPrint('[SphinxAR] GLB copy failed: $e');
    }
  }

  @override
  void dispose() {
    _sessionMgr?.dispose();
    _pageCtrl.dispose();
    _pulseCtrl.dispose();
    _slideCtrl.dispose();
    _bannerCtrl.dispose();
    _factPopCtrl.dispose();
    _confetti.dispose();
    _audio.dispose();
    super.dispose();
  }

  // ── AR callbacks ──────────────────────────────────────────────────────────
  void _onARViewCreated(ARSessionManager session, ARObjectManager objects,
      ARAnchorManager anchors, ARLocationManager _) {
    _sessionMgr = session;
    _objectMgr  = objects;
    _anchorMgr  = anchors;

    session.onInitialize(
      showFeaturePoints: true,
      showPlanes: true,
      customPlaneTexturePath: null,
      showWorldOrigin: false,
    );
    objects.onInitialize();
    session.onPlaneOrPointTap = _onPlaneTapped;
  }

  Future<void> _onPlaneTapped(List<ARHitTestResult> results) async {
    if (_modelPlaced || _isPlacing || results.isEmpty || !_modelReady) return;

    final hit = results.firstWhere(
      (r) => r.type == ARHitTestResultType.plane,
      orElse: () => results.first,
    );

    setState(() {
      _isPlacing = true;
      _hint = '⏳  Summoning the Great Sphinx…';
    });
    HapticFeedback.mediumImpact();

    final anchor = ARPlaneAnchor(transformation: hit.worldTransform);
    final added  = await _anchorMgr?.addAnchor(anchor);
    if (added != true) {
      setState(() {
        _isPlacing = false;
        _hint = '🔄  Couldn\'t anchor. Tap a flat surface.';
      });
      return;
    }

    // Load from documents directory — GLB was copied there in _copyGlbToDocuments().
    // fileSystemAppFolderGLB uses GLTFSceneSource(path:) which takes a full
    // absolute path and reliably handles binary GLB files.
    final node = ARNode(
      type: NodeType.fileSystemAppFolderGLB,
      uri: 'sphinx.glb',
      scale:    vm.Vector3(0.25, 0.25, 0.25),
      position: vm.Vector3(0.0, 0.0, 0.0),
      rotation: vm.Vector4(0.0, 1.0, 0.0, 0.0),
    );

    final placed = await _objectMgr?.addNode(node, planeAnchor: anchor);
    if (placed == true) {
      _sphinxNode   = node;
      _sphinxAnchor = anchor;
      if (mounted) {
        Provider.of<GameProgressService>(context, listen: false)
            .scanMonument(widget.monument.id);
      }
      setState(() {
        _modelPlaced       = true;
        _isPlacing         = false;
        _hint              = '🦁  The Sphinx is here! Walk around to explore.';
        _showWelcomeBanner = true;
      });
      HapticFeedback.heavyImpact();
      _confetti.play();
      _bannerCtrl.forward();
      // Auto-hide welcome banner after 3 s
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          _bannerCtrl.reverse();
          Future.delayed(const Duration(milliseconds: 700), () {
            if (mounted) setState(() => _showWelcomeBanner = false);
          });
        }
      });
    } else {
      await _anchorMgr?.removeAnchor(anchor);
      setState(() {
        _isPlacing = false;
        _hint = '⚠️  Model failed to load. Check assets/models/sphinx.glb';
      });
    }
  }

  Future<void> _resetModel() async {
    if (_sphinxNode   != null) { await _objectMgr?.removeNode(_sphinxNode!);   _sphinxNode   = null; }
    if (_sphinxAnchor != null) { await _anchorMgr?.removeAnchor(_sphinxAnchor!); _sphinxAnchor = null; }
    setState(() {
      _modelPlaced = false;
      _isPlacing   = false;
      _hint        = '✨  Scan a flat surface, then tap to place the Sphinx again!';
    });
  }

  Future<void> _toggleAudio() async {
    if (_playing) {
      await _audio.stop();
      if (mounted) setState(() => _playing = false);
    } else {
      setState(() => _playing = true);
      await _audio.speak(widget.monument.audioNarrationText);
      if (mounted) setState(() => _playing = false);
    }
  }

  void _onFactChanged(int i) {
    HapticFeedback.selectionClick();
    _factPopCtrl.forward(from: 0);
    setState(() {
      _factIndex = i;
      _readFacts.add(i);
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ① AR camera fills screen
          ARView(
            onARViewCreated: _onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
          ),

          // ② Confetti burst on placement
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirection: math.pi / 2,
              colors: const [
                AppColors.gold, AppColors.terra, Color(0xFF4CD87A),
                Color(0xFFAA88FF), Color(0xFF00BCD4),
              ],
              numberOfParticles: 30,
              emissionFrequency: 0.06,
            ),
          ),

          // ③ Scan ring before placement
          if (!_modelPlaced && !_isPlacing)
            Center(child: _buildScanRing()),

          // ④ Placing spinner
          if (_isPlacing)
            Center(
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: const BoxDecoration(
                    color: Colors.black54, shape: BoxShape.circle),
                child: const CircularProgressIndicator(
                    color: AppColors.gold, strokeWidth: 3),
              ),
            ),

          // ⑤ Placement welcome banner
          if (_showWelcomeBanner)
            Positioned(
              top: 0, left: 0, right: 0,
              child: SafeArea(
                child: ScaleTransition(
                  scale: _bannerAnim,
                  child: _buildWelcomeBanner(),
                ),
              ),
            ),

          // ⑥ Bottom HUD (hint + facts + actions)
          if (!_showWelcomeBanner)
            SafeArea(
              child: Column(
                children: [
                  _buildTopBar(),
                  const Spacer(),
                  SlideTransition(
                    position: _slideAnim,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildHintBadge(),
                        const SizedBox(height: 10),
                        if (_showFacts) _buildFactsCarousel(),
                        const SizedBox(height: 10),
                        _buildActionBar(),
                        const SizedBox(height: 28),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      child: Row(children: [
        _GlassBtn(icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => Navigator.pop(context)),
        const Spacer(),
        Column(children: [
          Text(widget.monument.name,
              style: GoogleFonts.playfairDisplay(
                  color: AppColors.gold, fontSize: 15,
                  fontWeight: FontWeight.bold)),
          Text('🦁 AR Time Machine',
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.sand)),
        ]),
        const Spacer(),
        Row(mainAxisSize: MainAxisSize.min, children: [
          // Fact counter badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
            ),
            child: Text('${_readFacts.length}/${_kFacts.length} facts',
                style: AppTextStyles.labelSmall.copyWith(color: AppColors.gold)),
          ),
          const SizedBox(width: 8),
          _GlassBtn(
            icon: _playing
                ? Icons.pause_circle_rounded
                : Icons.record_voice_over_rounded,
            onTap: _toggleAudio,
          ),
          const SizedBox(width: 6),
          _GlassBtn(
            icon: _showFacts ? Icons.layers_rounded : Icons.layers_clear_rounded,
            onTap: () => setState(() => _showFacts = !_showFacts),
          ),
        ]),
      ]),
    );
  }

  // ── Pulsing scan ring ─────────────────────────────────────────────────────
  Widget _buildScanRing() {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, __) {
        final s = 0.88 + _pulseCtrl.value * 0.14;
        return Transform.scale(
          scale: s,
          child: Stack(alignment: Alignment.center, children: [
            Container(
              width: 200, height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.gold
                        .withValues(alpha: 0.3 + _pulseCtrl.value * 0.3),
                    width: 2),
              ),
            ),
            Container(
              width: 140, height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.15), width: 1),
              ),
            ),
            Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.touch_app_rounded,
                  color: AppColors.gold.withValues(
                      alpha: 0.6 + _pulseCtrl.value * 0.4),
                  size: 40),
              const SizedBox(height: 6),
              Text('Tap to place',
                  style: GoogleFonts.inter(
                      color: AppColors.gold.withValues(
                          alpha: 0.5 + _pulseCtrl.value * 0.5),
                      fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
          ]),
        );
      },
    );
  }

  // ── Hint badge ────────────────────────────────────────────────────────────
  Widget _buildHintBadge() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.70),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: (_modelPlaced ? AppColors.success : AppColors.gold)
                  .withValues(alpha: 0.4)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) => Icon(
              _modelPlaced ? Icons.check_circle_rounded : Icons.auto_awesome_rounded,
              color: _modelPlaced
                  ? AppColors.success
                  : AppColors.gold
                      .withValues(alpha: 0.5 + _pulseCtrl.value * 0.5),
              size: 15,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(_hint,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.cream),
                maxLines: 2),
          ),
        ]),
      ),
    );
  }

  // ── Welcome banner (shown on placement) ──────────────────────────────────
  Widget _buildWelcomeBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3D2A0A), Color(0xFF1E1308)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.2),
              blurRadius: 20,
              spreadRadius: 2),
        ],
      ),
      child: Row(children: [
        const Text('🦁', style: TextStyle(fontSize: 36)),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('The Sphinx has risen!',
                style: GoogleFonts.playfairDisplay(
                    color: AppColors.gold,
                    fontSize: 17,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
                'Carved ~2500 BCE • 73m long • Swipe the cards to uncover its secrets 👇',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.sand, height: 1.4)),
          ]),
        ),
      ]),
    );
  }

  // ── Fun facts carousel ────────────────────────────────────────────────────
  Widget _buildFactsCarousel() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 138,
          child: PageView.builder(
            controller: _pageCtrl,
            itemCount: _kFacts.length,
            onPageChanged: _onFactChanged,
            itemBuilder: (_, i) {
              final f = _kFacts[i];
              final active = i == _factIndex;
              return AnimatedScale(
                scale: active ? 1.0 : 0.94,
                duration: const Duration(milliseconds: 200),
                child: ScaleTransition(
                  scale: active ? _factPopAnim : const AlwaysStoppedAnimation(1.0),
                  child: _FactCard(fact: f, isActive: active,
                      isRead: _readFacts.contains(i)),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        // Dot indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_kFacts.length, (i) {
            final isActive = i == _factIndex;
            final isRead   = _readFacts.contains(i);
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: isRead
                    ? _kFacts[i].accent.withValues(alpha: isActive ? 1.0 : 0.5)
                    : Colors.white24,
              ),
            );
          }),
        ),
      ],
    );
  }

  // ── Action bar ────────────────────────────────────────────────────────────
  Widget _buildActionBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        Expanded(
          flex: 3,
          child: _ActionBtn(
            emoji: '🗺️',
            label: 'Treasure Hunt',
            sublabel: '${_kFacts.length} challenges',
            color: AppColors.terra,
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        TreasureHuntScreen(monument: widget.monument))),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: _modelPlaced
              ? _ActionBtn(
                  emoji: '🔄',
                  label: 'Reset',
                  sublabel: 'Place again',
                  color: AppColors.muted,
                  onTap: _resetModel)
              : _ActionBtn(
                  emoji: '👆',
                  label: 'Tap surface',
                  sublabel: 'to place',
                  color: AppColors.gold,
                  onTap: null),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _FactCard extends StatelessWidget {
  final _Fact fact;
  final bool isActive;
  final bool isRead;
  const _FactCard({required this.fact, required this.isActive, required this.isRead});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withValues(alpha: 0.85),
            fact.accent.withValues(alpha: isActive ? 0.10 : 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: fact.accent.withValues(alpha: isActive ? 0.75 : 0.20),
            width: isActive ? 1.5 : 1.0),
        boxShadow: isActive
            ? [BoxShadow(color: fact.accent.withValues(alpha: 0.18),
                blurRadius: 14, spreadRadius: 1)]
            : [],
      ),
      child: Row(children: [
        // Emoji badge
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            color: fact.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: fact.accent.withValues(alpha: 0.3)),
          ),
          child: Center(
            child: Text(fact.emoji,
                style: const TextStyle(fontSize: 26)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(children: [
                Expanded(
                  child: Text(fact.headline,
                      style: GoogleFonts.inter(
                          color: fact.accent,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          height: 1.2)),
                ),
                if (isRead)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: fact.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('✓',
                        style: TextStyle(color: fact.accent, fontSize: 9)),
                  ),
              ]),
              const SizedBox(height: 5),
              Text(fact.detail,
                  style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.sand.withValues(alpha: 0.85),
                      height: 1.35),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: fact.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: fact.accent.withValues(alpha: 0.25)),
                ),
                child: Text(fact.wowLabel,
                    style: GoogleFonts.inter(
                        color: fact.accent,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8)),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

class _GlassBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlassBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: 0.55),
            border: Border.all(color: Colors.white12),
          ),
          child: Icon(icon, color: AppColors.cream, size: 18),
        ),
      );
}

class _ActionBtn extends StatelessWidget {
  final String emoji;
  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback? onTap;
  const _ActionBtn({
    required this.emoji,
    required this.label,
    required this.sublabel,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: enabled
              ? color.withValues(alpha: 0.15)
              : Colors.black.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: (enabled ? color : AppColors.muted).withValues(alpha: 0.4),
              width: 1.2),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(emoji, style: TextStyle(fontSize: enabled ? 22 : 18)),
          const SizedBox(height: 4),
          Text(label,
              style: GoogleFonts.inter(
                  color: enabled ? color : AppColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
          Text(sublabel,
              style: AppTextStyles.labelSmall.copyWith(
                  color: (enabled ? color : AppColors.muted)
                      .withValues(alpha: 0.6))),
        ]),
      ),
    );
  }
}
