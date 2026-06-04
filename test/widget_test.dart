import 'package:flutter_test/flutter_test.dart';
import 'package:e_ticketing_uts/main.dart';

void main() {
  testWidgets('App renders splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ETicketingApp());
    expect(find.text('E-Ticketing Helpdesk'), findsNothing);
  });
}
