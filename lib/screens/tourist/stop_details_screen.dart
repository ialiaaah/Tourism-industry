import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/firestore_service.dart';
import 'ask_question_screen.dart';
import 'monument_scanner_screen.dart';

class StopDetailsScreen extends StatefulWidget {
  final Stop stop;

  const StopDetailsScreen({Key? key, required this.stop}) : super(key: key);

  @override
  State<StopDetailsScreen> createState() => _StopDetailsScreenState();
}

class _StopDetailsScreenState extends State<StopDetailsScreen> {
  int? _selectedAnswerIndex;
  bool _quizAnswered = false;

  Future<void> _submitQuiz(BuildContext context) async {
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
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.workspace_premium, color: Color(0xFFCBA153), size: 32),
              SizedBox(width: 8),
              Text('Correct!'),
            ],
          ),
          content: const Text('You earned a digital stamp for this location!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Awesome!'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incorrect answer. Try again later!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<FirestoreService>();
    final alreadyHasStamp =
        service.collectedStamps.any((s) => s.stopId == widget.stop.id);

    return Scaffold(
      appBar: AppBar(title: Text(widget.stop.name)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero image area
            Container(
              height: 250,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F1B29), Color(0xFF1A3A2A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.account_balance, size: 80, color: Color(0xFFCBA153)),
                    SizedBox(height: 8),
                    Text('Monument Stop',
                        style: TextStyle(color: Colors.white70, fontSize: 16)),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                widget.stop.description,
                style: const TextStyle(fontSize: 16, height: 1.7, color: Colors.black87),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.camera_enhance),
                    label: const Text('Scan Monument'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: const Color(0xFF0F1B29),
                      foregroundColor: const Color(0xFFCBA153),
                    ),
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  MonumentScannerScreen(stop: widget.stop)));
                    },
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.help_outline),
                    label: const Text('Ask the Guide a Question'),
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => AskQuestionScreen(
                                  stopId: widget.stop.id,
                                  stopName: widget.stop.name)));
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 48, thickness: 1),

            // Quiz Section
            if (widget.stop.quiz != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.quiz, color: Color(0xFFCBA153)),
                            const SizedBox(width: 8),
                            const Text(
                              'Stop Quiz',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F1B29)),
                            ),
                            const Spacer(),
                            if (alreadyHasStamp)
                              const Icon(Icons.check_circle,
                                  color: Color(0xFFCBA153), size: 28),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.stop.quiz!.question,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 16),
                        ...List.generate(widget.stop.quiz!.options.length, (index) {
                          final option = widget.stop.quiz!.options[index];
                          final isCorrect =
                              index == widget.stop.quiz!.correctOptionIndex;
                          final isSelected = _selectedAnswerIndex == index;

                          Color? optionColor;
                          if (_quizAnswered || alreadyHasStamp) {
                            if (isCorrect) optionColor = Colors.green.shade50;
                            else if (isSelected) optionColor = Colors.red.shade50;
                          }

                          return GestureDetector(
                            onTap: (_quizAnswered || alreadyHasStamp)
                                ? null
                                : () => setState(
                                    () => _selectedAnswerIndex = index),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFFCBA153)
                                      : Colors.grey.shade300,
                                  width: isSelected ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(10),
                                color: optionColor,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_off,
                                    color: isSelected
                                        ? const Color(0xFFCBA153)
                                        : Colors.grey,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text(option)),
                                ],
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 16),
                        if (!_quizAnswered && !alreadyHasStamp)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _selectedAnswerIndex == null
                                  ? null
                                  : () => _submitQuiz(context),
                              child: const Text('Submit Answer'),
                            ),
                          ),
                        if (alreadyHasStamp)
                          const Text(
                            '✓ You already collected this stamp!',
                            style: TextStyle(
                                color: Colors.green, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
