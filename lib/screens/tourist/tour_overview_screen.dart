import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/firestore_service.dart';
import 'stop_details_screen.dart';
import 'stamp_collection_screen.dart';

class TourOverviewScreen extends StatelessWidget {
  const TourOverviewScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final service = context.watch<FirestoreService>();
    final tour = service.currentJoinedTour;

    if (tour == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('No active tour found.')),
      );
    }

    final stampsCount = service.collectedStamps.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(tour.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.workspace_premium),
            tooltip: 'Stamps',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const StampCollectionScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            tooltip: 'Leave Tour',
            onPressed: () {
              service.leaveTour();
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F1B29), Color(0xFF1A2A3A)], // Nile Navy
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tour.description,
                  style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.white70),
                ),
                const SizedBox(height: 20),
                InkWell(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const StampCollectionScreen()));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBA153).withOpacity(0.2), // Desert Gold
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFCBA153), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Color(0xFFCBA153)),
                        const SizedBox(width: 12),
                        Text(
                          'Stamps Collected: $stampsCount / ${tour.stops.length}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tour.stops.length,
              itemBuilder: (context, index) {
                final stop = tour.stops[index];
                final earnedStamp = service.collectedStamps.any((s) => s.stopId == stop.id);

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: AssetImage(stop.imagePath),
                          fit: BoxFit.cover,
                          onError: (_, __) => const NetworkImage('https://via.placeholder.com/60'), // Fallback
                        ),
                      ),
                    ),
                    title: Text(stop.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        stop.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                    trailing: earnedStamp
                        ? const Icon(Icons.check_circle, color: Color(0xFFCBA153), size: 32) // Desert Gold
                        : const Icon(Icons.chevron_right, color: Color(0xFF0F1B29)),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => StopDetailsScreen(stop: stop)));
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
