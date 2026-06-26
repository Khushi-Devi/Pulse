import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/main.dart';

void main() {
  testWidgets('Pulse app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const PulseApp());
  });
}