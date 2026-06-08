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
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:vector_math/vector_math_64.dart' as vm;
import '../../services/monument_data_service.dart';
import '../../services/game_progress_service.dart';
import '../../services/audio_narration_service.dart';
import '../../theme/app_theme.dart';
import 'treasure_hunt_screen.dart';

/// Real ARKit (iOS) / ARCore (Android) experience — places the Great Sphinx
/// 3-D model in the physical world.  Requires assets/models/sphinx.glb.
class SphinxARScreen extends StatefulWidget {
  final MonumentInfo monument;
  const SphinxARScreen({super.key, required this.monument});

  @override
  State<SphinxARScreen> createState() => _SphinxARScreenState();
}

class _SphinxARScreenState extends State<SphinxARScreen>
    with TickerProviderStateMixin {
  // AR managers
  ARSessionManager? _sessionMgr;
  ARObjectManager? _objectMgr;
  ARAnchorManager? _anchorMgr;
  ARNode? _sphinxNode;
  ARAnchor? _sphinxAnchor;
  bool _modelPlaced = false;
  bool _isPlacing = false;
  String _hint = 'Slowly scan a flat surface, then tap to place the Sphinx';
  bool _planeFound = false;

  // Info panel
  int _factIndex = 0;
  bool _showPanel = true;
  late PageController _pageCtrl;

  // Audio
  final AudioNarrationService _audio = AudioNarrationService();
  bool _playing = false;

  // Animations
  late AnimationController _pulseCtrl;
  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;
  late AnimationController _glowCtrl;

  static const List<_Fact> _facts = [
    _Fact(Icons.wb_sunny_rounded,    'Eternal Gaze',      'Faces true east — aligned with the rising sun on both equinoxes every year.',        Color(0xFFDFAF58)),
    _Fact(Icons.height_rounded,      'Colossal Scale',    '73 m long · 20 m tall — the largest monolithic statue ever carved from bedrock.',     Color(0xFF4CD87A)),
    _Fact(Icons.history_edu_rounded, 'The Dream Stele',   'Prince Thutmose IV promised the Sphinx he would clear its buried body; in return the Sphinx promised him the throne of Egypt (c. 1400 BCE).', Color(0xFFD4581E)),
    _Fact(Icons.palette_rounded,     'Lost Colours',      'Originally painted in vivid red, blue and yellow. Traces of red pigment were found on the right cheek.', Color(0xFF9C27B0)),
    _Fact(Icons.water_drop_rounded,  'Age Controversy',   'Geologist Schoch argues water-erosion on its walls dates it before 7000 BCE — making it far older than mainstream Egyptology accepts.', Color(0xFF00BCD4)),
  ];

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController(viewportFraction: 0.88);
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _slideCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
    _slideCtrl.forward();
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _sessionMgr?.dispose();
    _pageCtrl.dispose();
    _pulseCtrl.dispose();
    _slideCtrl.dispose();
    _glowCtrl.dispose();
    _audio.dispose();
    super.dispose();
  }

  // AR callbacks
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
    if (_modelPlaced || _isPlacing || results.isEmpty) return;

    // Prefer a plane hit; fall back to any hit
    final hit = results.firstWhere(
      (r) => r.type == ARHitTestResultType.plane,
      orElse: () => results.first,
    );

    setState(() { _isPlacing = true; _hint = 'Placing the Great Sphinx…'; });
    HapticFeedback.mediumImpact();

    final anchor = ARPlaneAnchor(transformation: hit.worldTransform);
    final added  = await _anchorMgr?.addAnchor(anchor);
    if (added != true) {
      setState(() { _isPlacing = false; _hint = 'Could not anchor. Tap a flat surface.'; });
      return;
    }

    final node = ARNode(
      type: NodeType.localGLTF2,
      uri: 'models/sphinx.glb',           // Flutter asset: assets/models/sphinx.glb
      scale:    vm.Vector3(0.12, 0.12, 0.12),
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
      setState(() { _modelPlaced = true; _isPlacing = false; _hint = 'Sphinx placed! Walk around to explore.'; });
      HapticFeedback.heavyImpact();
    } else {
      await _anchorMgr?.removeAnchor(anchor);
      setState(() { _isPlacing = false; _hint = 'Model not loaded. Add assets/models/sphinx.glb'; });
    }
  }

  Future<void> _resetModel() async {
    if (_sphinxNode != null) { await _objectMgr?.removeNode(_sphinxNode!); _sphinxNode = null; }
    if (_sphinxAnchor != null) { await _anchorMgr?.removeAnchor(_sphinxAnchor!); _sphinxAnchor = null; }
    setState(() { _modelPlaced = false; _isPlacing = false; _hint = 'Slowly scan a flat surface, then tap to place the Sphinx'; });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── AR view fills screen ───────────────────────────────────────
          ARView(
            onARViewCreated: _onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
          ),

          // ── Scan ring (before placement) ───────────────────────────────
          if (!_modelPlaced && !_isPlacing)
            Center(child: _buildScanRing()),

          // ── Placing indicator ──────────────────────────────────────────
          if (_isPlacing)
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const CircularProgressIndicator(color: AppColors.gold, strokeWidth: 3),
              ),
            ),

          // ── Top bar ────────────────────────────────────────────────────
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
                      if (_showPanel) _buildFactCards(),
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

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(children: [
        _GlassBtn(icon: Icons.arrow_back_ios_new_rounded, onTap: () => Navigator.pop(context)),
        const Spacer(),
        Column(children: [
          Text(widget.monument.name,
              style: GoogleFonts.playfairDisplay(color: AppColors.gold, fontSize: 15, fontWeight: FontWeight.bold)),
          Text('AR Experience', style: AppTextStyles.labelSmall.copyWith(color: AppColors.sand)),
        ]),
        const Spacer(),
        Row(mainAxisSize: MainAxisSize.min, children: [
          _GlassBtn(
            icon: _playing ? Icons.pause_rounded : Icons.record_voice_over_rounded,
            onTap: _toggleAudio,
          ),
          const SizedBox(width: 8),
          _GlassBtn(
            icon: _showPanel ? Icons.info_rounded : Icons.info_outline_rounded,
            onTap: () => setState(() => _showPanel = !_showPanel),
          ),
        ]),
      ]),
    );
  }

  Widget _buildScanRing() {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, __) => Transform.scale(
        scale: 0.9 + _pulseCtrl.value * 0.15,
        child: Container(
          width: 180, height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.5), width: 2),
          ),
          child: Center(
            child: Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.25), width: 1),
              ),
              child: const Icon(Icons.crop_free_rounded, color: AppColors.gold, size: 44),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHintBadge() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) => Icon(
              _modelPlaced ? Icons.check_circle_rounded : Icons.crop_free_rounded,
              color: _modelPlaced
                  ? AppColors.success
                  : AppColors.gold.withValues(alpha: 0.5 + _pulseCtrl.value * 0.5),
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(child: Text(_hint, style: AppTextStyles.bodySmall.copyWith(color: AppColors.cream))),
        ]),
      ),
    );
  }

  Widget _buildFactCards() {
    return SizedBox(
      height: 108,
      child: PageView.builder(
        controller: _pageCtrl,
        itemCount: _facts.length,
        onPageChanged: (i) => setState(() => _factIndex = i),
        itemBuilder: (_, i) {
          final f = _facts[i];
          final active = i == _factIndex;
          return AnimatedScale(
            scale: active ? 1.0 : 0.95,
            duration: const Duration(milliseconds: 200),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: f.color.withValues(alpha: active ? 0.7 : 0.25)),
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: f.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(f.icon, color: f.color, size: 20),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(f.title, style: AppTextStyles.label.copyWith(color: f.color)),
                      const SizedBox(height: 3),
                      Text(f.body, style: AppTextStyles.bodySmall.copyWith(color: AppColors.sand, height: 1.4), maxLines: 3, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(children: [
        Expanded(
          child: _ActionBtn(
            icon: Icons.explore_rounded,
            label: 'Treasure Hunt',
            color: AppColors.terra,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => TreasureHuntScreen(monument: widget.monument))),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _modelPlaced
              ? _ActionBtn(icon: Icons.refresh_rounded, label: 'Reset',   color: AppColors.muted, onTap: _resetModel)
              : _ActionBtn(icon: Icons.touch_app_rounded, label: 'Tap to Place', color: AppColors.gold, onTap: null),
        ),
      ]),
    );
  }
}

// Data + helper widgets

class _Fact {
  final IconData icon;
  final String title, body;
  final Color color;
  const _Fact(this.icon, this.title, this.body, this.color);
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
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const _ActionBtn({required this.icon, required this.label, required this.color, this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        color: onTap != null ? color.withValues(alpha: 0.18) : Colors.black38,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: (onTap != null ? color : AppColors.muted).withValues(alpha: 0.4)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: onTap != null ? color : AppColors.muted, size: 22),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.labelSmall.copyWith(color: onTap != null ? color : AppColors.muted)),
      ]),
    ),
  );
}
