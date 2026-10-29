import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_bottom_navigator/liquid_glass_bottom_navigator.dart';
import 'package:liquid_glass_bottom_navigator/src/navigation_layout.dart';

export 'package:liquid_glass_bottom_navigator/liquid_glass_bottom_navigator.dart';

const LiquidGlassNavigationStyle testStyle = LiquidGlassNavigationStyle(
  margin: EdgeInsets.zero,
  respectSafeArea: false,
  blurSigma: 0,
  elevation: 0,
  height: 64,
  expandForTextScale: true,
);

const LiquidGlassMotion testMotion = LiquidGlassMotion(
  duration: Duration(milliseconds: 280),
  bounce: 0,
  morphIntensity: 0.8,
);

Future<void> pumpNavigationBar(
  WidgetTester tester, {
  required List<LiquidGlassNavigationItem> items,
  required int currentIndex,
  ValueChanged<int>? onIndexChanged,
  LiquidGlassNavigationStyle style = testStyle,
  LiquidGlassNavigationTheme theme =
      const LiquidGlassNavigationTheme.adaptive(),
  LiquidGlassMotion motion = testMotion,
  LiquidGlassLabelMode labelMode = LiquidGlassLabelMode.always,
  LiquidGlassIndicatorStyle indicatorStyle =
      LiquidGlassIndicatorStyle.slidingPill,
  bool hapticsEnabled = true,
  LiquidGlassHaptic haptic = LiquidGlassHaptic.selection,
  String? semanticsLabel,
  Size surface = const Size(360, 240),
  TextDirection textDirection = TextDirection.ltr,
  bool disableAnimations = false,
  ThemeData? themeData,
  double textScale = 1,
}) {
  return tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      themeAnimationDuration: Duration.zero,
      theme:
          themeData ??
          ThemeData(brightness: Brightness.light, useMaterial3: true),
      home: MediaQuery(
        data: MediaQueryData(
          size: surface,
          disableAnimations: disableAnimations,
          textScaler: TextScaler.linear(textScale),
        ),
        child: Directionality(
          textDirection: textDirection,
          child: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                width: surface.width,
                child: LiquidGlassNavigationBar(
                  items: items,
                  currentIndex: currentIndex,
                  onIndexChanged: onIndexChanged,
                  style: style,
                  theme: theme,
                  motion: motion,
                  labelMode: labelMode,
                  indicatorStyle: indicatorStyle,
                  hapticsEnabled: hapticsEnabled,
                  haptic: haptic,
                  semanticsLabel: semanticsLabel,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

RenderLiquidNavigation indicatorRender(WidgetTester tester) {
  return tester.renderObject<RenderLiquidNavigation>(
    find.byType(LiquidNavigationLayout),
  );
}

List<LiquidGlassNavigationItem> sampleItems({
  bool withLabels = true,
  bool withBadge = false,
}) {
  return <LiquidGlassNavigationItem>[
    LiquidGlassNavigationItem(
      icon: Icons.home_rounded,
      label: withLabels ? 'Home' : null,
    ),
    LiquidGlassNavigationItem(
      icon: Icons.search_rounded,
      label: withLabels ? 'Search' : null,
      badge: withBadge ? const LiquidGlassBadge.dot() : null,
    ),
    LiquidGlassNavigationItem(
      icon: Icons.inbox_outlined,
      label: withLabels ? 'Inbox' : null,
      badge: withBadge ? const LiquidGlassBadge.count(12) : null,
    ),
  ];
}
