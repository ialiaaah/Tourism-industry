import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:typed_data';
import '../../models/models.dart';

class AddStopScreen extends StatefulWidget {
  const AddStopScreen({Key? key}) : super(key: key);

  @override
  State<AddStopScreen> createState() => _AddStopScreenState();
}

class _AddStopScreenState extends State<AddStopScreen> {
  // ── Palette ──────────────────────────────────────────────────────────────────
  static const _bg      = Color(0xFF1E1308);
  static const _card    = Color(0xFF2E1E0C);
  static const _cardAlt = Color(0xFF3A2410);
  static const _gold    = Color(0xFFDFAF58);
  static const _terra   = Color(0xFFD4581E);
  static const _cream   = Color(0xFFF5EDD8);
  static const _sand    = Color(0xFFE0C896);
  static const _muted   = Color(0xFF8A7560);

  final _nameController     = TextEditingController();
  final _descController     = TextEditingController();
  final _questionController = TextEditingController();
  final List<TextEditingController> _optionsControllers =
      List.generate(4, (_) => TextEditingController());

  int _correctOptionIndex = 0;
  XFile? _pickedFile;
  Uint8List? _webImageBytes;
  bool _isUploading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _questionController.dispose();
    for (final c in _optionsControllers) {
      c.dispose();
    }
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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() => _pickedFile = image);
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        setState(() => _webImageBytes = bytes);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: _cardAlt,
            content: Row(children: [
              const Icon(Icons.check_circle_rounded, color: _gold, size: 18),
              const SizedBox(width: 8),
              Text('Photo selected: ${image.name}',
                  style: GoogleFonts.inter(color: _cream)),
            ]),
          ),
        );
      }
    }
  }

  Future<String?> _uploadImage(String stopId) async {
    if (_pickedFile == null) return null;
    setState(() => _isUploading = true);
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('stop_images')
          .child('${stopId}_${DateTime.now().millisecondsSinceEpoch}.jpg');

      UploadTask task;
      if (kIsWeb) {
        final bytes = _webImageBytes ?? await _pickedFile!.readAsBytes();
        task = ref.putData(bytes,
            SettableMetadata(contentType: 'image/jpeg'));
      } else {
        task = ref.putFile(File(_pickedFile!.path));
      }

      final snapshot = await task;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('⚠️ Image upload failed: $e');
      return null;
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Widget _buildImagePreview() {
    if (_pickedFile == null) {
      return GestureDetector(
        onTap: _pickImage,
        child: Container(
          height: 180,
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _gold.withValues(alpha: 0.35),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_photo_alternate_rounded,
                  size: 48, color: _muted.withValues(alpha: 0.7)),
              const SizedBox(height: 10),
              Text('Tap to add a stop photo',
                  style: GoogleFonts.inter(color: _muted, fontSize: 13)),
            ],
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        children: [
          kIsWeb && _webImageBytes != null
              ? Image.memory(_webImageBytes!,
                  height: 180, width: double.infinity, fit: BoxFit.cover)
              : Image.file(File(_pickedFile!.path),
                  height: 180, width: double.infinity, fit: BoxFit.cover),
          Positioned(
            top: 10,
            right: 10,
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit_rounded,
                    color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveStop() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _cardAlt,
          content: Row(children: [
            const Icon(Icons.warning_amber_rounded, color: _terra, size: 18),
            const SizedBox(width: 8),
            Text('Stop name is required.',
                style: GoogleFonts.inter(color: _cream)),
          ]),
        ),
      );
      return;
    }

    QuizQuestion? quiz;
    if (_questionController.text.isNotEmpty) {
      final options = _optionsControllers
          .map((c) => c.text.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      if (options.length >= 2) {
        quiz = QuizQuestion(
          question: _questionController.text.trim(),
          options: options,
          correctOptionIndex:
              _correctOptionIndex >= options.length ? 0 : _correctOptionIndex,
        );
      }
    }

    final stopId = 'stop_${DateTime.now().millisecondsSinceEpoch}';
    final imageUrl = await _uploadImage(stopId) ?? '';

    final newStop = Stop(
      id: stopId,
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      imagePath: imageUrl,
      quiz: quiz,
    );

    if (mounted) Navigator.pop(context, newStop);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _card,
        foregroundColor: _cream,
        elevation: 0,
        title: Text('Add a Stop',
            style: GoogleFonts.playfairDisplay(
                color: _gold, fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Stop info ──────────────────────────────────────────────────────
            _sectionLabel('Stop Information'),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              style: GoogleFonts.inter(color: _cream, fontSize: 15),
              decoration: _fieldDecoration(
                label: 'Stop Name *',
                icon: Icons.place_rounded,
                hint: 'e.g. Sphinx of Giza',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _descController,
              style: GoogleFonts.inter(color: _cream, fontSize: 14),
              maxLines: 3,
              decoration: _fieldDecoration(
                label: 'Description',
                icon: Icons.description_rounded,
                hint: 'Historical context, highlights…',
              ),
            ),

            const SizedBox(height: 26),

            // ── Photo ──────────────────────────────────────────────────────────
            _sectionLabel('Stop Photo'),
            const SizedBox(height: 12),
            _buildImagePreview(),
            if (_pickedFile != null) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                label: Text('Change Photo',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _gold,
                  side: BorderSide(color: _gold.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _pickImage,
              ),
            ],

            const SizedBox(height: 30),

            // ── Divider ────────────────────────────────────────────────────────
            Divider(color: _cardAlt.withValues(alpha: 0.8), height: 1),

            const SizedBox(height: 26),

            // ── Quiz ───────────────────────────────────────────────────────────
            _sectionLabel('Quiz Question  (Optional)'),
            const SizedBox(height: 4),
            Text('Tourists earn a stamp when they answer correctly.',
                style: GoogleFonts.inter(color: _muted, fontSize: 12)),
            const SizedBox(height: 14),

            TextField(
              controller: _questionController,
              style: GoogleFonts.inter(color: _cream, fontSize: 14),
              maxLines: 2,
              decoration: _fieldDecoration(
                label: 'Question',
                icon: Icons.help_outline_rounded,
              ),
            ),
            const SizedBox(height: 16),

            ...List.generate(4, (index) {
              final isCorrect = index == _correctOptionIndex;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(children: [
                  // Radio
                  GestureDetector(
                    onTap: () =>
                        setState(() => _correctOptionIndex = index),
                    child: Container(
                      width: 22,
                      height: 22,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isCorrect ? _gold : _muted,
                          width: isCorrect ? 2 : 1.5,
                        ),
                        color: isCorrect
                            ? _gold.withValues(alpha: 0.15)
                            : Colors.transparent,
                      ),
                      child: isCorrect
                          ? const Center(
                              child: Icon(Icons.circle,
                                  size: 10, color: _gold),
                            )
                          : null,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _optionsControllers[index],
                      style: GoogleFonts.inter(
                          color: _cream, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Option ${index + 1}',
                        labelStyle: GoogleFonts.inter(
                            color: _muted, fontSize: 13),
                        helperText: isCorrect ? '✓ Correct answer' : null,
                        helperStyle: GoogleFonts.inter(
                            color: const Color(0xFF4CAF50),
                            fontSize: 11),
                        isDense: true,
                        filled: true,
                        fillColor: _card,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: isCorrect
                                ? _gold.withValues(alpha: 0.5)
                                : _gold.withValues(alpha: 0.2),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: _gold, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                ]),
              );
            }),

            const SizedBox(height: 36),

            // ── Save button ────────────────────────────────────────────────────
            ElevatedButton.icon(
              icon: _isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_rounded),
              label: Text(
                _isUploading ? 'Uploading image…' : 'Save Stop',
                style: GoogleFonts.inter(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: _bg,
                disabledBackgroundColor: _muted,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              onPressed: _isUploading ? null : _saveStop,
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
