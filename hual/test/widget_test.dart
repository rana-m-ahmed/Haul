import 'package:flutter_test/flutter_test.dart';
import 'package:hual/main.dart';

void main() {
  testWidgets('App builds successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const HaulApp());
    expect(find.byType(HaulApp), findsOneWidget);
  });
}
