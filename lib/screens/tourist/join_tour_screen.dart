import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/firestore_service.dart';
import 'tour_overview_screen.dart';

class JoinTourScreen extends StatefulWidget {
  const JoinTourScreen({Key? key}) : super(key: key);

  @override
  State<JoinTourScreen> createState() => _JoinTourScreenState();
}

class _JoinTourScreenState extends State<JoinTourScreen> {
  final _codeController = TextEditingController();
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isScanning = false;

  void _joinWithCode(String code) async {
    if (code.isEmpty) return;
    
    final service = context.read<FirestoreService>();
    final success = await service.joinTour(code);
    
    if (success) {
      if (_isScanning) {
         _scannerController.stop();
        if (mounted) setState(() => _isScanning = false);
      }
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const TourOverviewScreen()),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid access code or tour not found.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join a Tour')),
      body: _isScanning
          ? Stack(
              children: [
                MobileScanner(
                  controller: _scannerController,
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    if (barcodes.isNotEmpty) {
                      final code = barcodes.first.rawValue;
                      if (code != null) {
                        _joinWithCode(code);
                      }
                    }
                  },
                ),
                Positioned(
                  bottom: 50,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.close),
                      label: const Text('Cancel Scan'),
                      onPressed: () {
                        _scannerController.stop();
                        setState(() => _isScanning = false);
                      },
                    ),
                  ),
                )
              ],
            )
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Enter Access Code',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _codeController,
                    decoration: const InputDecoration(
                      labelText: 'Code',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.vpn_key),
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _joinWithCode(_codeController.text),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF0F1B29), // Nile Navy
                      foregroundColor: const Color(0xFFCBA153), // Desert Gold
                    ),
                    child: const Text('Join Tour', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 48),
                  const Text(
                    'OR',
                    style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  OutlinedButton.icon(
                    onPressed: () async {
                      setState(() => _isScanning = true);
                      await _scannerController.start();
                    },
                    icon: const Icon(Icons.qr_code_scanner, size: 32),
                    label: const Text('Scan QR Code', style: TextStyle(fontSize: 18)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: const BorderSide(color: Color(0xFF0F1B29), width: 2), // Nile Navy
                      foregroundColor: const Color(0xFF0F1B29),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
