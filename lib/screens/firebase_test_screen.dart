import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// A debug screen accessible from the app to test Firebase Firestore connectivity.
/// It writes a document, reads it back, and deletes it — proving end-to-end data flow.
class FirebaseTestScreen extends StatefulWidget {
  const FirebaseTestScreen({Key? key}) : super(key: key);

  @override
  State<FirebaseTestScreen> createState() => _FirebaseTestScreenState();
}

class _FirebaseTestScreenState extends State<FirebaseTestScreen> {
  final List<String> _logs = [];
  bool _running = false;

  void _log(String message) {
    setState(() => _logs.add('[${DateTime.now().toIso8601String()}] $message'));
  }

  Future<void> _runTests() async {
    setState(() {
      _logs.clear();
      _running = true;
    });

    final db = FirebaseFirestore.instance;
    const collectionPath = 'firebase_tests';
    const docId = 'connectivity_test';

    // ---- TEST 1: Write a document ----
    _log('📝 TEST 1: Writing document to "$collectionPath/$docId" ...');
    try {
      await db.collection(collectionPath).doc(docId).set({
        'message': 'Hello from Flutter Web!',
        'timestamp': FieldValue.serverTimestamp(),
        'testNumber': 42,
        'nested': {
          'tourName': 'Giza Plateau Experience',
          'stops': ['Great Pyramid', 'Sphinx'],
        },
      });
      _log('✅ Write SUCCESS — document created in Firestore');
      _log('   📍 Location: Project "tourismprototype" → Collection "$collectionPath" → Doc "$docId"');
    } catch (e) {
      _log('❌ Write FAILED: $e');
      setState(() => _running = false);
      return;
    }

    // ---- TEST 2: Read the document back ----
    _log('');
    _log('📖 TEST 2: Reading document back from Firestore ...');
    try {
      final snapshot = await db.collection(collectionPath).doc(docId).get();
      if (snapshot.exists) {
        final data = snapshot.data()!;
        _log('✅ Read SUCCESS — Data retrieved:');
        data.forEach((key, value) {
          _log('   🔹 $key: $value');
        });
      } else {
        _log('⚠️ Document exists = false (unexpected)');
      }
    } catch (e) {
      _log('❌ Read FAILED: $e');
    }

    // ---- TEST 3: Write a tour to the real "tours" collection ----
    _log('');
    _log('📝 TEST 3: Writing a sample tour to "tours" collection ...');
    try {
      const tourId = 'test_tour_firebase';
      await db.collection('tours').doc(tourId).set({
        'id': tourId,
        'title': 'Firebase Test Tour',
        'description': 'A tour created by the Firebase test script',
        'accessCode': 'FBTEST',
        'stops': [
          {
            'id': 'test_stop_1',
            'name': 'Test Stop',
            'description': 'A test stop to verify Firestore data structure',
            'imagePath': '',
            'arSnippet': 'This is a test AR snippet',
            'quiz': {
              'question': 'Is Firebase connected?',
              'options': ['Yes', 'No', 'Maybe', 'Definitely'],
              'correctOptionIndex': 0,
            },
          }
        ],
        'guideId': 'test_user',
        'createdAt': FieldValue.serverTimestamp(),
      });
      _log('✅ Tour write SUCCESS');
      _log('   📍 Location: "tours/$tourId"');
    } catch (e) {
      _log('❌ Tour write FAILED: $e');
    }

    // ---- TEST 4: List all documents in "tours" collection ----
    _log('');
    _log('📖 TEST 4: Listing all tours in "tours" collection ...');
    try {
      final toursSnapshot = await db.collection('tours').get();
      _log('   Found ${toursSnapshot.docs.length} tour(s):');
      for (final doc in toursSnapshot.docs) {
        final data = doc.data();
        _log('   📌 ${doc.id}: "${data['title']}" (code: ${data['accessCode']})');
      }
    } catch (e) {
      _log('❌ List tours FAILED: $e');
    }

    // ---- TEST 5: Clean up test document ----
    _log('');
    _log('🗑️ TEST 5: Cleaning up test document from "$collectionPath/$docId" ...');
    try {
      await db.collection(collectionPath).doc(docId).delete();
      _log('✅ Delete SUCCESS — test document removed');
    } catch (e) {
      _log('❌ Delete FAILED: $e');
    }

    _log('');
    _log('🏁 All tests completed!');
    _log('');
    _log('📊 DATA STORAGE SUMMARY:');
    _log('   • Firebase Project: tourismprototype');
    _log('   • Firestore Database: (default)');
    _log('   • Region: Determined by your Firebase project settings');
    _log('   • Tours stored at: /tours/{tourId}');
    _log('   • User stamps at: /users/{userId}/stamps/{stampId}');
    _log('   • Questions at: /questions/{questionId}');
    _log('');
    _log('   👉 View your data at: https://console.firebase.google.com/project/tourismprototype/firestore');

    setState(() => _running = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔥 Firebase Test'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear logs',
            onPressed: () => setState(() => _logs.clear()),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _running ? null : _runTests,
                icon: _running
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow),
                label: Text(_running ? 'Running Tests...' : 'Run Firebase Tests'),
              ),
            ),
          ),
          const Divider(),
          Expanded(
            child: _logs.isEmpty
                ? const Center(
                    child: Text(
                      'Press the button above to test Firebase connectivity.\n\n'
                      'Tests will write, read, and delete data from Firestore\n'
                      'to prove the connection is working.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      final log = _logs[index];
                      Color color = Colors.white;
                      if (log.contains('✅')) color = Colors.green;
                      if (log.contains('❌')) color = Colors.red;
                      if (log.contains('📝') || log.contains('📖')) {
                        color = Colors.lightBlueAccent;
                      }
                      if (log.contains('🏁') || log.contains('📊')) {
                        color = Colors.amber;
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          log,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            color: color,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF1E1E1E),
    );
  }
}
