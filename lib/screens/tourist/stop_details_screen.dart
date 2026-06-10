import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../models/models.dart';
import '../../services/firestore_service.dart';
import 'ask_question_screen.dart';

class StopDetailsScreen extends StatefulWidget {
  final Stop stop;
  const StopDetailsScreen({Key? key, required this.stop}) : super(key: key);

  @override
  State<StopDetailsScreen> createState() => _StopDetailsScreenState();
}

class _StopDetailsScreenState extends State<StopDetailsScreen> {
  // ── Palette ─────────────────────────────────────────────────────────────────
  static const _bg      = Color(0xFF1E1308);
  static const _card    = Color(0xFF2E1E0C);
  static const _cardAlt = Color(0xFF3A2410);
  static const _gold    = Color(0xFFDFAF58);
  static const _terra   = Color(0xFFD4581E);
  static const _cream   = Color(0xFFF5EDD8);
  static const _sand    = Color(0xFFE0C896);
  static const _muted   = Color(0xFF8A7560);

  int? _selectedAnswerIndex;
  bool _quizAnswered = false;

  // ── Quiz submission ──────────────────────────────────────────────────────────
  Future<void> _submitQuiz() async {
    if (_selectedAnswerIndex == null) return;
    final service = context.read<FirestoreService>();
    final isCorrect = await service.submitQuizAnswer(
      widget.stop.id,
      widget.stop.name,
      _selectedAnswerIndex!,
      widget.stop.quiz!,
    );
    if (!mounted) return;
    if (isCorrect) {
      setState(() => _quizAnswered = true);
      _showStampDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _cardAlt,
          content: Row(children: [
            const Icon(Icons.close_rounded, color: _terra, size: 18),
            const SizedBox(width: 8),
            Text('Not quite — try again!',
                style: GoogleFonts.inter(color: _cream)),
          ]),
        ),
      );
    }
  }

  void _showStampDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Icon(Icons.workspace_premium, color: _gold, size: 30),
          const SizedBox(width: 10),
          Text('Correct!',
              style: GoogleFonts.playfairDisplay(
                  color: _cream, fontWeight: FontWeight.bold)),
        ]),
        content: Text(
          'You answered correctly and earned a digital stamp for this stop!',
          style: GoogleFonts.inter(color: _sand, fontSize: 14),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _gold,
              foregroundColor: _bg,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context),
            child: Text('Awesome!',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── Hero image ───────────────────────────────────────────────────────────────
  Widget _buildHeroImage() {
    final imgPath = widget.stop.imagePath;
    final isNetwork =
        imgPath.startsWith('http://') || imgPath.startsWith('https://');
    final isBase64 = imgPath.startsWith('data:image');

    Widget imageWidget;
    if (isBase64) {
      try {
        final base64Str = imgPath.contains(',') ? imgPath.split(',').last : imgPath;
        final bytes = base64Decode(base64Str);
        imageWidget = Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, __, ___) => _fallbackHero(),
        );
      } catch (_) {
        return _fallbackHero();
      }
    } else if (isNetwork) {
      imageWidget = Image.network(
        imgPath,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _fallbackHero(),
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : Center(
                child: CircularProgressIndicator(
                  value: progress.expectedTotalBytes != null
                      ? progress.cumulativeBytesLoaded /
                          progress.expectedTotalBytes!
                      : null,
                  color: _gold,
                ),
              ),
      );
    } else if (imgPath.isNotEmpty) {
      imageWidget = Image.asset(
        imgPath,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _fallbackHero(),
      );
    } else {
      return _fallbackHero();
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        imageWidget,
        // Gradient so stop name is readable
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.transparent, Colors.black87],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.45, 1.0],
            ),
          ),
        ),
        Positioned(
          bottom: 18,
          left: 18,
          right: 18,
          child: Text(
            widget.stop.name,
            style: GoogleFonts.playfairDisplay(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              shadows: const [Shadow(blurRadius: 8, color: Colors.black)],
            ),
          ),
        ),
      ],
    );
  }

  Widget _fallbackHero() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_bg, _card],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.account_balance, size: 72, color: _gold),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              widget.stop.name,
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                  color: _cream,
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service         = context.watch<FirestoreService>();
    final alreadyHasStamp =
        service.collectedStamps.any((s) => s.stopId == widget.stop.id);

    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        slivers: [
          // ── Collapsing hero ─────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: _card,
            foregroundColor: _cream,
            flexibleSpace: FlexibleSpaceBar(background: _buildHeroImage()),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Description ────────────────────────────────────────────
                  Text(
                    widget.stop.description,
                    style: GoogleFonts.inter(
                        fontSize: 15, height: 1.75, color: _sand),
                  ),

                  const SizedBox(height: 24),

                  // ── Ask guide button ────────────────────────────────────────
                  OutlinedButton.icon(
                    icon: const Icon(Icons.help_outline_rounded),
                    label: Text('Ask the Guide a Question',
                        style: GoogleFonts.inter(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      side: BorderSide(
                          color: _gold.withValues(alpha: 0.6)),
                      foregroundColor: _gold,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AskQuestionScreen(
                          stopId: widget.stop.id,
                          stopName: widget.stop.name,
                        ),
                      ),
                    ),
                  ),

                  // ── Quiz section ────────────────────────────────────────────
                  if (widget.stop.quiz != null) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      child: Divider(
                          color: _cardAlt.withValues(alpha: 0.8),
                          height: 1),
                    ),
                    _buildQuiz(alreadyHasStamp),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuiz(bool alreadyHasStamp) {
    final quiz = widget.stop.quiz!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: alreadyHasStamp
              ? _gold.withValues(alpha: 0.5)
              : _cardAlt,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(children: [
            const Icon(Icons.quiz_rounded, color: _gold, size: 22),
            const SizedBox(width: 8),
            Text('Stop Quiz',
                style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _cream)),
            const Spacer(),
            if (alreadyHasStamp)
              const Icon(Icons.workspace_premium, color: _gold, size: 26),
          ]),
          const SizedBox(height: 4),
          Text('Answer correctly to earn a digital stamp!',
              style: GoogleFonts.inter(color: _muted, fontSize: 12)),
          const SizedBox(height: 18),

          // Question
          Text(quiz.question,
              style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _cream)),
          const SizedBox(height: 16),

          // Options
          ...List.generate(quiz.options.length, (index) {
            final isCorrect  = index == quiz.correctOptionIndex;
            final isSelected = _selectedAnswerIndex == index;
            final answered   = _quizAnswered || alreadyHasStamp;

            Color borderColor = _cardAlt;
            Color bgColor     = Colors.transparent;

            if (answered) {
              if (isCorrect) {
                borderColor = const Color(0xFF4CAF50);
                bgColor     = const Color(0xFF4CAF50).withValues(alpha: 0.1);
              } else if (isSelected) {
                borderColor = _terra;
                bgColor     = _terra.withValues(alpha: 0.1);
              }
            } else if (isSelected) {
              borderColor = _gold;
              bgColor     = _gold.withValues(alpha: 0.08);
            }

            return GestureDetector(
              onTap: answered
                  ? null
                  : () => setState(() => _selectedAnswerIndex = index),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: bgColor,
                  border: Border.all(
                      color: borderColor,
                      width: isSelected && !answered ? 2 : 1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  Icon(
                    answered
                        ? (isCorrect
                            ? Icons.check_circle
                            : (isSelected
                                ? Icons.cancel
                                : Icons.radio_button_off))
                        : (isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off),
                    color: answered
                        ? (isCorrect
                            ? const Color(0xFF4CAF50)
                            : (isSelected ? _terra : _muted))
                        : (isSelected ? _gold : _muted),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(quiz.options[index],
                        style:
                            GoogleFonts.inter(color: _cream, fontSize: 14)),
                  ),
                ]),
              ),
            );
          }),

          const SizedBox(height: 8),

          if (!_quizAnswered && !alreadyHasStamp)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _gold,
                  foregroundColor: _bg,
                  disabledBackgroundColor: _cardAlt,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed:
                    _selectedAnswerIndex == null ? null : _submitQuiz,
                child: Text('Submit Answer',
                    style:
                        GoogleFonts.inter(fontWeight: FontWeight.bold)),
              ),
            ),

          if (alreadyHasStamp)
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.workspace_premium, color: _gold, size: 20),
              const SizedBox(width: 8),
              Text('Stamp already collected!',
                  style: GoogleFonts.inter(
                      color: _gold, fontWeight: FontWeight.bold)),
            ]),
        ],
      ),
    );
  }
}
