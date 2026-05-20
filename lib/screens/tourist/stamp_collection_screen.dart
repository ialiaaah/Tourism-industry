import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/firestore_service.dart';
import 'package:intl/intl.dart';

class StampCollectionScreen extends StatelessWidget {
  const StampCollectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final service = context.watch<FirestoreService>();
    final stamps = service.collectedStamps;
    final totalStops = service.currentJoinedTour?.stops.length ?? 0;


    return Scaffold(
      appBar: AppBar(title: const Text('My Stamps')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(Icons.workspace_premium, size: 64, color: Colors.amber),
                  const SizedBox(height: 16),
                  Text(
                    '${stamps.length} / $totalStops Stamps Collected',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  if (stamps.length > 0 && stamps.length == totalStops)
                    const Padding(
                      padding: EdgeInsets.only(top: 12.0),
                      child: Text(
                        '🏆 Congratulations! You have completed this tour! 🏆',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Stamp History',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: stamps.isEmpty
                  ? const Center(
                      child: Text(
                        'No stamps yet. Answer quizzes correctly at each stop to earn stamps!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    )
                  : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: stamps.length,
                      itemBuilder: (context, index) {
                        final stamp = stamps[index];
                        return Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.verified, size: 48, color: Colors.teal),
                                const SizedBox(height: 8),
                                Text(
                                  stamp.stopName,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('MMM d, h:mm a').format(stamp.dateEarned),
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
