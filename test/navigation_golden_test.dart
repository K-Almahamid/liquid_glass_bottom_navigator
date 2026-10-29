import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_bottom_navigator/liquid_glass_bottom_navigator.dart';

void main() {
  testWidgets('light glass bar', (tester) async {
    await _pumpGolden(
      tester,
      theme: LiquidGlassNavigationTheme.light,
      background: const Color(0xFFE7E1D8),
      fileName: 'goldens/light_navigation_bar.png',
    );
  });

  testWidgets('dark glass bar', (tester) async {
    await _pumpGolden(
      tester,
      theme: LiquidGlassNavigationTheme.dark,
      background: const Color(0xFF101418),
      fileName: 'goldens/dark_navigation_bar.png',
    );
  });
}

/// Goldens use blur sigma 0. Backdrop sampling in widget tests is not stable
/// across runs, so these images lock tint, type, indicator, and badge instead.
Future<void> _pumpGolden(
  WidgetTester tester, {
  required LiquidGlassNavigationTheme theme,
  required Color background,
  required String fileName,
}) async {
  await tester.binding.setSurfaceSize(const Size(400, 180));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      themeAnimationDuration: Duration.zero,
      home: ColoredBox(
        color: background,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: LiquidGlassNavigationBar(
            currentIndex: 1,
            onIndexChanged: (_) {},
            theme: theme,
            labelMode: LiquidGlassLabelMode.always,
            style: const LiquidGlassNavigationStyle(
              margin: EdgeInsets.fromLTRB(16, 0, 16, 12),
              blurSigma: 0,
              respectSafeArea: false,
            ),
            items: const <LiquidGlassNavigationItem>[
              LiquidGlassNavigationItem(
                icon: Icons.home_rounded,
                label: 'Home',
              ),
              LiquidGlassNavigationItem(
                icon: Icons.search_rounded,
                label: 'Search',
              ),
              LiquidGlassNavigationItem(
                icon: Icons.inbox_outlined,
                label: 'Inbox',
                badge: LiquidGlassBadge.count(4),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await expectLater(
    find.byType(LiquidGlassNavigationBar),
    matchesGoldenFile(fileName),
  );
}
