import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/firestore_service.dart';
import 'add_stop_screen.dart';
import 'tour_summary_screen.dart';

class CreateTourScreen extends StatefulWidget {
  const CreateTourScreen({Key? key}) : super(key: key);

  @override
  State<CreateTourScreen> createState() => _CreateTourScreenState();
}

class _CreateTourScreenState extends State<CreateTourScreen> {
  // ── Palette ──────────────────────────────────────────────────────────────────
  static const _bg      = Color(0xFF1E1308);
  static const _card    = Color(0xFF2E1E0C);
  static const _cardAlt = Color(0xFF3A2410);
  static const _gold    = Color(0xFFDFAF58);
  static const _terra   = Color(0xFFD4581E);
  static const _cream   = Color(0xFFF5EDD8);
  static const _sand    = Color(0xFFE0C896);
  static const _muted   = Color(0xFF8A7560);

  final _titleController = TextEditingController();
  final _descController  = TextEditingController();
  final List<Stop> _stops = [];
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration({
    required String label,
    IconData? icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, color: _muted) : null,
      labelStyle: GoogleFonts.inter(color: _muted, fontSize: 14),
      hintStyle: GoogleFonts.inter(color: _muted.withValues(alpha: 0.5)),
      filled: true,
      fillColor: _card,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _gold.withValues(alpha: 0.25)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _gold, width: 1.5),
      ),
    );
  }

  Future<void> _navigateToAddStop() async {
    final result = await Navigator.push<Stop>(
      context,
      MaterialPageRoute(builder: (_) => const AddStopScreen()),
    );
    if (result != null) setState(() => _stops.add(result));
  }

  Future<void> _finishTour() async {
    if (_titleController.text.trim().isEmpty || _stops.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _cardAlt,
          content: Row(children: [
            const Icon(Icons.warning_amber_rounded, color: _terra, size: 18),
            const SizedBox(width: 8),
            Text('Add a title and at least one stop.',
                style: GoogleFonts.inter(color: _cream)),
          ]),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final service = context.read<FirestoreService>();
      final accessCode = await service.createTour(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        stops: _stops,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => TourSummaryScreen(
              title: _titleController.text.trim(),
              accessCode: accessCode,
              stopsCount: _stops.length,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: _cardAlt,
            content: Text('Failed to create tour: $e',
                style: GoogleFonts.inter(color: _cream)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _card,
        foregroundColor: _cream,
        elevation: 0,
        title: Text('Create Heritage Route',
            style: GoogleFonts.playfairDisplay(
                color: _gold, fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Route details ──────────────────────────────────────────────
            _sectionLabel('Route Details'),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              style: GoogleFonts.inter(color: _cream, fontSize: 15),
              decoration: _fieldDecoration(
                label: 'Route Title *',
                icon: Icons.route_rounded,
                hint: 'e.g. Cairo 2025 Cultural Programme',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _descController,
              style: GoogleFonts.inter(color: _cream, fontSize: 14),
              maxLines: 3,
              decoration: _fieldDecoration(
                label: 'Short Description',
                icon: Icons.notes_rounded,
                hint: 'Theme, audience, purpose…',
              ),
            ),

            const SizedBox(height: 32),

            // ── Stops ──────────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _sectionLabel('Cultural Stops  (${_stops.length})'),
                OutlinedButton.icon(
                  icon: const Icon(Icons.add_location_alt_rounded, size: 18),
                  label: Text('Add Stop',
                      style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _gold,
                    side: const BorderSide(color: _gold, width: 1.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                  ),
                  onPressed: _navigateToAddStop,
                ),
              ],
            ),

            const SizedBox(height: 14),

            if (_stops.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _gold.withValues(alpha: 0.15)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.add_location_alt_rounded,
                        size: 48, color: _muted.withValues(alpha: 0.4)),
                    const SizedBox(height: 12),
                    Text('No stops yet.',
                        style: GoogleFonts.inter(color: _muted, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text('Tap "Add Stop" to add your first one.',
                        style: GoogleFonts.inter(
                            color: _muted.withValues(alpha: 0.6),
                            fontSize: 12)),
                  ],
                ),
              ),

            ...List.generate(_stops.length, (index) {
              final stop = _stops[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _gold.withValues(alpha: 0.25)),
                ),
                child: Row(children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: _cardAlt),
                    child: Center(
                      child: Text('${index + 1}',
                          style: GoogleFonts.inter(
                              color: _gold,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(stop.name,
                            style: GoogleFonts.inter(
                                color: _cream,
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                        if (stop.quiz != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(children: [
                              const Icon(Icons.quiz_rounded,
                                  size: 12, color: _terra),
                              const SizedBox(width: 4),
                              Text('Quiz included',
                                  style: GoogleFonts.inter(
                                      color: _terra, fontSize: 11)),
                            ]),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded,
                        size: 18, color: _muted.withValues(alpha: 0.6)),
                    onPressed: () => setState(() => _stops.removeAt(index)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ]),
              );
            }),

            const SizedBox(height: 36),

            // ── Generate button ────────────────────────────────────────────
            ElevatedButton.icon(
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.qr_code_2_rounded),
              label: Text(
                _isSaving
                    ? 'Creating Route…'
                    : 'Generate Route & Access Code',
                style: GoogleFonts.inter(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: _bg,
                disabledBackgroundColor: _muted,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              onPressed: _isSaving ? null : _finishTour,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(text,
      style: GoogleFonts.inter(
          color: _sand, fontWeight: FontWeight.bold, fontSize: 14));
}
