import 'package:flutter_test/flutter_test.dart';
import 'package:smartmove/main.dart';

void main() {
  testWidgets('SmartMove app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartMoveApp());

    expect(find.text('SmartMove'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });
}