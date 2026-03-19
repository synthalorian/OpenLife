import 'package:flutter_test/flutter_test.dart';

import 'package:open_fit/main.dart';

void main() {
  testWidgets('App loads', (WidgetTester tester) async {
    await tester.pumpWidget(const OpenFitApp());
    
    // Should find the app title
    expect(find.text('OPEN FIT'), findsOneWidget);
  });
}
