import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/firestore_service.dart';
import 'tour_overview_screen.dart';

class JoinTourScreen extends StatefulWidget {
  const JoinTourScreen({super.key});

  @override
  State<JoinTourScreen> createState() => _JoinTourScreenState();
}

class _JoinTourScreenState extends State<JoinTourScreen> {
  static const _bg    = Color(0xFF1E1308);
  static const _card  = Color(0xFF2E1E0C);
  static const _gold  = Color(0xFFDFAF58);
  static const _terra = Color(0xFFD4581E);
  static const _cream = Color(0xFFF5EDD8);
  static const _sand  = Color(0xFFE0C896);
  static const _muted = Color(0xFF8A7560);

  final _codeController = TextEditingController();
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isScanning = false;
  bool _isLoading = false;

  Future<void> _joinWithCode(String code) async {
    final trimmed = code.trim().toUpperCase();
    if (trimmed.isEmpty) return;

    setState(() => _isLoading = true);

    final service = context.read<FirestoreService>();
    final success = await service.joinTour(trimmed);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      if (_isScanning) {
        _scannerController.stop();
        setState(() => _isScanning = false);
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TourOverviewScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF3A2410),
          content: Row(children: [
            const Icon(Icons.error_outline, color: _terra, size: 18),
            const SizedBox(width: 8),
            Text('Invalid code or tour not found.',
                style: GoogleFonts.inter(color: _cream)),
          ]),
        ),
      );
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _card,
        foregroundColor: _cream,
        elevation: 0,
        title: Text('Join a Tour',
            style: GoogleFonts.playfairDisplay(
                color: _gold, fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
      ),
      body: _isScanning ? _buildScanner() : _buildForm(),
    );
  }

  // ── QR Scanner view ────────────────────────────────────────────────────────
  Widget _buildScanner() {
    return Stack(
      children: [
        MobileScanner(
          controller: _scannerController,
          onDetect: (capture) {
            final code = capture.barcodes.firstOrNull?.rawValue;
            if (code != null) _joinWithCode(code);
          },
        ),
        // Overlay frame
        Center(
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              border: Border.all(color: _gold, width: 3),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        Positioned(
          top: 48,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('Point at the tour QR code',
                  style: GoogleFonts.inter(color: _cream, fontSize: 13)),
            ),
          ),
        ),
        Positioned(
          bottom: 48,
          left: 24,
          right: 24,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.close),
            label: const Text('Cancel'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _card,
              foregroundColor: _cream,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              _scannerController.stop();
              setState(() => _isScanning = false);
            },
          ),
        ),
      ],
    );
  }

  // ── Manual code entry form ─────────────────────────────────────────────────
  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Icon + title ───────────────────────────────────────────────────
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _card,
                shape: BoxShape.circle,
                border: Border.all(color: _gold.withValues(alpha: 0.4)),
              ),
              child: const Icon(Icons.tour_rounded, color: _gold, size: 48),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Enter Access Code',
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
                color: _cream, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Your guide will share a 6-character code.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: _muted, fontSize: 13),
          ),
          const SizedBox(height: 36),

          // ── Code field ─────────────────────────────────────────────────────
          TextField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceMono(
                color: _cream, fontSize: 28, fontWeight: FontWeight.bold,
                letterSpacing: 8),
            maxLength: 6,
            decoration: InputDecoration(
              counterText: '',
              hintText: 'XXXXXX',
              hintStyle: GoogleFonts.spaceMono(
                  color: _muted, fontSize: 28, letterSpacing: 8),
              filled: true,
              fillColor: _card,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: _gold.withValues(alpha: 0.4)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _gold, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Join button ────────────────────────────────────────────────────
          ElevatedButton(
            onPressed: _isLoading
                ? null
                : () => _joinWithCode(_codeController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: _terra,
              foregroundColor: _cream,
              disabledBackgroundColor: _muted,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text('Join Tour',
                    style: GoogleFonts.inter(
                        fontSize: 17, fontWeight: FontWeight.bold)),
          ),

          const SizedBox(height: 36),

          // ── Divider ────────────────────────────────────────────────────────
          Row(children: [
            const Expanded(child: Divider(color: Color(0xFF3A2410))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('OR',
                  style: GoogleFonts.inter(
                      color: _muted, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            const Expanded(child: Divider(color: Color(0xFF3A2410))),
          ]),

          const SizedBox(height: 36),

          // ── QR Scan button ─────────────────────────────────────────────────
          OutlinedButton.icon(
            icon: const Icon(Icons.qr_code_scanner_rounded, size: 24),
            label: Text('Scan QR Code',
                style: GoogleFonts.inter(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              foregroundColor: _gold,
              side: const BorderSide(color: _gold, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () async {
              await _scannerController.start();
              setState(() => _isScanning = true);
            },
          ),
        ],
      ),
    );
  }
}
