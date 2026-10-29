import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_bottom_navigator/liquid_glass_bottom_navigator.dart';

import 'package:liquid_glass_bottom_navigator_example/main.dart';

void main() {
  testWidgets('selects a destination from the package bar', (tester) async {
    await tester.pumpWidget(const LiquidGlassExampleApp());
    expect(
      tester.widget<Text>(find.byKey(const Key('page-title'))).data,
      'Home',
    );

    await tester.tap(find.byIcon(Icons.search_rounded));
    await tester.pump();

    expect(
      tester.widget<Text>(find.byKey(const Key('page-title'))).data,
      'Search',
    );
    expect(find.byType(LiquidGlassNavigationBar), findsOneWidget);
  });
}
