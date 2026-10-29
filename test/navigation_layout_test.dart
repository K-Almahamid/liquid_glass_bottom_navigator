import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_bottom_navigator/src/navigation_layout.dart';

import 'harness.dart';

void main() {
  testWidgets('adaptive theme follows brightness and explicit themes do not', (
    tester,
  ) async {
    Future<Color> selectedColor({
      required ThemeData themeData,
      required LiquidGlassNavigationTheme theme,
    }) async {
      await pumpNavigationBar(
        tester,
        items: sampleItems(),
        currentIndex: 0,
        onIndexChanged: (_) {},
        theme: theme,
        themeData: themeData,
      );
      final icon = tester.widget<Icon>(find.byIcon(Icons.home_rounded));
      return icon.color!;
    }

    final lightTheme = ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
    );
    final darkTheme = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
    );
    final light = await selectedColor(
      themeData: lightTheme,
      theme: const LiquidGlassNavigationTheme.adaptive(),
    );
    final dark = await selectedColor(
      themeData: darkTheme,
      theme: const LiquidGlassNavigationTheme.adaptive(),
    );
    expect(light, lightTheme.colorScheme.primary);
    expect(dark, darkTheme.colorScheme.primary);
    expect(light, isNot(dark));

    final fixed = await selectedColor(
      themeData: darkTheme,
      theme: LiquidGlassNavigationTheme.light,
    );
    expect(fixed, LiquidGlassNavigationTheme.light.selectedForeground);
  });

  testWidgets('explicit style colors replace the resolved theme', (
    tester,
  ) async {
    const override = Color(0xFF010203);
    await pumpNavigationBar(
      tester,
      items: sampleItems(),
      currentIndex: 0,
      onIndexChanged: (_) {},
      theme: const LiquidGlassNavigationTheme.adaptive(),
      style: const LiquidGlassNavigationStyle(
        margin: EdgeInsets.zero,
        respectSafeArea: false,
        blurSigma: 0,
        elevation: 0,
        selectedForeground: override,
        backgroundOpacity: 0.4,
      ),
    );
    final icon = tester.widget<Icon>(find.byIcon(Icons.home_rounded));
    expect(icon.color, override);
  });

  testWidgets(
    'zero blur removes the backdrop filter and a positive sigma keeps one',
    (tester) async {
      await pumpNavigationBar(
        tester,
        items: sampleItems(),
        currentIndex: 0,
        onIndexChanged: (_) {},
      );
      expect(find.byType(BackdropFilter), findsNothing);

      await pumpNavigationBar(
        tester,
        items: sampleItems(),
        currentIndex: 0,
        onIndexChanged: (_) {},
        style: const LiquidGlassNavigationStyle(
          blurSigma: 12,
          margin: EdgeInsets.zero,
          respectSafeArea: false,
        ),
      );
      expect(find.byType(BackdropFilter), findsOneWidget);
      expect(find.byType(ClipRRect), findsWidgets);
    },
  );

  testWidgets('the blur is clipped to the bar and can see content behind it', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        themeAnimationDuration: Duration.zero,
        home: Scaffold(
          body: Stack(
            children: <Widget>[
              ColoredBox(
                key: Key('behind'),
                color: Color(0xFF224466),
                child: SizedBox.expand(),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: LiquidGlassNavigationBar(
                  currentIndex: 0,
                  items: <LiquidGlassNavigationItem>[
                    LiquidGlassNavigationItem(icon: Icons.home_rounded),
                    LiquidGlassNavigationItem(icon: Icons.search_rounded),
                    LiquidGlassNavigationItem(icon: Icons.inbox_outlined),
                    LiquidGlassNavigationItem(icon: Icons.person_outline),
                  ],
                  style: LiquidGlassNavigationStyle(
                    blurSigma: 12,
                    margin: EdgeInsets.zero,
                    respectSafeArea: false,
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(BackdropFilter), findsOneWidget);
    final filter = tester.renderObject(find.byType(BackdropFilter));
    final behind = tester.renderObject(find.byKey(const Key('behind')));
    final filterAncestors = <RenderObject>{};
    RenderObject? cursor = filter;
    while (cursor != null) {
      filterAncestors.add(cursor);
      cursor = cursor.parent;
    }
    RenderObject? shared = behind;
    while (shared != null && !filterAncestors.contains(shared)) {
      shared = shared.parent;
    }
    expect(shared, isNotNull);
    cursor = filter.parent;
    while (cursor != null && cursor != shared) {
      expect(cursor.isRepaintBoundary, isFalse);
      cursor = cursor.parent;
    }
    expect(
      find.descendant(
        of: find.byType(BackdropFilter),
        matching: find.byType(RepaintBoundary),
      ),
      findsOneWidget,
    );
  });

  testWidgets('equal slots follow direction and a custom width is honored', (
    tester,
  ) async {
    const style = LiquidGlassNavigationStyle(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      indicatorInset: EdgeInsets.zero,
      respectSafeArea: false,
      blurSigma: 0,
      elevation: 0,
      itemSpacing: 0,
    );
    await pumpNavigationBar(
      tester,
      items: sampleItems(withLabels: false),
      currentIndex: 0,
      onIndexChanged: (_) {},
      style: style,
      surface: const Size(300, 200),
    );
    final ltr = indicatorRender(tester).debugItemRects;
    expect(ltr[0].left, closeTo(0, 0.1));
    expect(ltr[1].left, greaterThan(ltr[0].right - 0.1));
    expect(ltr[2].right, closeTo(300, 0.5));

    await pumpNavigationBar(
      tester,
      items: sampleItems(withLabels: false),
      currentIndex: 0,
      onIndexChanged: (_) {},
      style: style,
      surface: const Size(300, 200),
      textDirection: TextDirection.rtl,
    );
    final rtl = indicatorRender(tester).debugItemRects;
    expect(rtl[0].right, closeTo(300, 0.5));
    expect(rtl[0].left, greaterThan(rtl[2].right));

    await pumpNavigationBar(
      tester,
      items: sampleItems(withLabels: false),
      currentIndex: 0,
      onIndexChanged: (_) {},
      style: style.copyWith(width: 180),
      surface: const Size(360, 200),
    );
    expect(
      tester.getSize(find.byType(LiquidNavigationLayout)).width,
      closeTo(180, 0.5),
    );
  });

  testWidgets('safe area, text scale, and narrow widths stay finite', (
    tester,
  ) async {
    await pumpNavigationBar(
      tester,
      items: sampleItems(),
      currentIndex: 0,
      onIndexChanged: (_) {},
      style: const LiquidGlassNavigationStyle(
        margin: EdgeInsets.zero,
        blurSigma: 0,
        elevation: 0,
      ),
    );
    final compact = tester.getSize(find.byType(LiquidGlassNavigationBar));

    await pumpNavigationBar(
      tester,
      items: sampleItems(),
      currentIndex: 0,
      onIndexChanged: (_) {},
      style: const LiquidGlassNavigationStyle(
        margin: EdgeInsets.zero,
        blurSigma: 0,
        elevation: 0,
        respectSafeArea: true,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            padding: EdgeInsets.only(bottom: 30),
            size: Size(360, 240),
          ),
          child: const Scaffold(body: SizedBox.shrink()),
        ),
      ),
    );
    await pumpNavigationBar(
      tester,
      items: sampleItems(),
      currentIndex: 0,
      onIndexChanged: (_) {},
      style: const LiquidGlassNavigationStyle(
        margin: EdgeInsets.zero,
        blurSigma: 0,
        elevation: 0,
      ),
    );
    // The harness MediaQuery replaces padding, so apply the inset through a local wrapper.
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: MediaQuery(
          data: const MediaQueryData(
            padding: EdgeInsets.only(bottom: 34),
            size: Size(360, 240),
          ),
          child: const Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              width: 360,
              child: LiquidGlassNavigationBar(
                items: <LiquidGlassNavigationItem>[
                  LiquidGlassNavigationItem(
                    icon: Icons.home_rounded,
                    label: 'Home',
                  ),
                  LiquidGlassNavigationItem(
                    icon: Icons.search_rounded,
                    label: 'Search',
                  ),
                ],
                currentIndex: 0,
                style: LiquidGlassNavigationStyle(
                  margin: EdgeInsets.zero,
                  blurSigma: 0,
                  elevation: 0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final withSafeArea = tester.getSize(find.byType(LiquidGlassNavigationBar));
    expect(withSafeArea.height, greaterThan(compact.height));

    await pumpNavigationBar(
      tester,
      items: sampleItems(),
      currentIndex: 0,
      onIndexChanged: (_) {},
      textScale: 2.4,
      surface: const Size(220, 320),
    );
    expect(
      tester.getSize(find.byType(LiquidGlassNavigationBar)).height,
      greaterThan(64),
    );
    expect(tester.takeException(), isNull);
  });
}
