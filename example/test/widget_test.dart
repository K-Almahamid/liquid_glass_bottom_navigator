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

  testWidgets('appearance controls close from the back arrow', (tester) async {
    await tester.pumpWidget(const LiquidGlassExampleApp());
    await tester.tap(find.byTooltip('Open appearance controls'));
    await tester.pumpAndSettle();

    expect(find.text('Appearance'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Appearance'), findsNothing);
  });

  testWidgets('appearance controls expose layout and safe area', (
    tester,
  ) async {
    await tester.pumpWidget(const LiquidGlassExampleApp());
    await tester.tap(find.byTooltip('Open appearance controls'));
    await tester.pumpAndSettle();

    expect(find.text('Equal slots'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Respect safe area'),
      80,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Respect safe area'), findsOneWidget);
    await tester.tap(find.text('Equal slots'));
    await tester.pumpAndSettle();
    expect(find.byType(LiquidGlassNavigationBar), findsOneWidget);
  });
}
