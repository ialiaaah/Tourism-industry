import 'package:flutter/material.dart';
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
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final List<Stop> _stops = [];

  void _navigateToAddStop() async {
    final result = await Navigator.push<Stop>(
      context,
      MaterialPageRoute(builder: (_) => const AddStopScreen()),
    );
    if (result != null) {
      setState(() {
        _stops.add(result);
      });
    }
  }

  void _finishTour() async {
    if (_titleController.text.isEmpty || _stops.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title and add at least one stop.')),
      );
      return;
    }
    final service = context.read<FirestoreService>();
    try {
      final accessCode = await service.createTour(
        title: _titleController.text,
        description: _descController.text,
        stops: _stops,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => TourSummaryScreen(
              title: _titleController.text,
              accessCode: accessCode,
              stopsCount: _stops.length,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create tour: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Heritage Route')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Route Title (e.g. Cairo 2025 Cultural Programme)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Short Description (theme, audience, purpose)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Cultural Stops Added: ${_stops.length}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: _navigateToAddStop,
                  icon: const Icon(Icons.add_location_alt),
                  label: const Text('Add Cultural Stop'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _stops.length,
              itemBuilder: (context, index) {
                final stop = _stops[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFCBA153).withOpacity(0.2),
                        child: const Icon(Icons.place, color: Color(0xFF0F1B29)),
                      ),
                      title: Text(stop.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        stop.quiz != null ? 'Quiz included' : 'No quiz',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  );
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _finishTour,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF0F1B29),
                foregroundColor: const Color(0xFFCBA153),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Generate Route & Access Code', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
