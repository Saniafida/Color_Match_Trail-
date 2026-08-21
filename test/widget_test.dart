import 'package:flutter_test/flutter_test.dart';
import 'package:color_match_trail/app/app.dart';
import 'package:color_match_trail/core/services/service_locator.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await ServiceLocator.instance.initialize();

    await tester.pumpWidget(const ColorMatchTrailApp());
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(ColorMatchTrailApp), findsOneWidget);
  });
}
