import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:color_match_trail/app/app.dart';
import 'package:color_match_trail/core/services/service_locator.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await ServiceLocator.instance.initialize();
  });

  tearDownAll(() {
    ServiceLocator.instance.dispose();
  });

  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ColorMatchTrailApp());
    expect(find.byType(ColorMatchTrailApp), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
