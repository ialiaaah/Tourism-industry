// Basic widget test that compiles with the TourismApp class

import 'package:flutter_test/flutter_test.dart';
import 'package:tourism_prototype/main.dart';

void main() {
  testWidgets('App compiles and runs without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const TourismApp(firebaseReady: true));
    // Verify that the app widget builds successfully
    expect(find.byType(TourismApp), findsOneWidget);
  });
}
