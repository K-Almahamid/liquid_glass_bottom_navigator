import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_bottom_navigator/src/glass_surface.dart';

import 'harness.dart';

void main() {
  const items = <LiquidGlassNavigationItem>[
    LiquidGlassNavigationItem(icon: Icons.home_rounded, label: 'Home'),
    LiquidGlassNavigationItem(icon: Icons.search_rounded, label: 'Search'),
    LiquidGlassNavigationItem(icon: Icons.inbox_outlined, label: 'Inbox'),
  ];

  Future<void> show(
    WidgetTester tester,
    int index, {
    bool disableAnimations = false,
    bool drag = false,
    LiquidGlassLabelMode mode = LiquidGlassLabelMode.selected,
  }) {
    return pumpNavigationBar(
      tester,
      items: items,
      currentIndex: index,
      onIndexChanged: (_) {},
      labelMode: mode,
      disableAnimations: disableAnimations,
      enableDragSelection: drag,
    );
  }

  testWidgets('selected-only icons move with the selection spring', (
    tester,
  ) async {
    await show(tester, 0);
    await tester.pump(const Duration(seconds: 1));
    final glass = tester.getRect(find.byType(GlassSurface)).center.dy;
    final homeStart = tester.getRect(find.byIcon(Icons.home_rounded)).center.dy;
    final inboxStart = tester
        .getRect(find.byIcon(Icons.inbox_outlined))
        .center
        .dy;
    expect(homeStart, lessThan(glass - 2));
    expect(inboxStart, closeTo(glass, 0.75));

    await show(tester, 2);
    await tester.pump(const Duration(milliseconds: 80));
    final homeMid = tester.getRect(find.byIcon(Icons.home_rounded)).center.dy;
    final inboxMid = tester
        .getRect(find.byIcon(Icons.inbox_outlined))
        .center
        .dy;
    expect(homeMid, greaterThan(homeStart + 0.5));
    expect(homeMid, lessThan(glass));
    expect(inboxMid, lessThan(inboxStart - 0.5));
    expect(tester.takeException(), isNull);

    await tester.pump(const Duration(seconds: 1));
    final settled = tester.getRect(find.byType(GlassSurface)).center.dy;
    expect(
      tester.getRect(find.byIcon(Icons.home_rounded)).center.dy,
      closeTo(settled, 0.75),
    );
    final inbox = tester.getRect(find.byIcon(Icons.inbox_outlined));
    expect(inbox.center.dy, lessThan(settled - 2));
    final label = tester.getRect(find.text('Inbox'));
    final capsule = _capsule(tester);
    expect(label.top, greaterThan(inbox.bottom - 1));
    expect(capsule.top, lessThanOrEqualTo(inbox.top + 0.5));
    expect(capsule.bottom, greaterThanOrEqualTo(label.bottom - 0.5));
    expect(((inbox.top + label.bottom) / 2), closeTo(capsule.center.dy, 1.5));
  });

  testWidgets('reduced motion applies the selected-only layout immediately', (
    tester,
  ) async {
    await show(tester, 0, disableAnimations: true);
    await show(tester, 1, disableAnimations: true);
    final glass = tester.getRect(find.byType(GlassSurface)).center.dy;
    expect(
      tester.getRect(find.byIcon(Icons.home_rounded)).center.dy,
      closeTo(glass, 0.75),
    );
    expect(
      tester.getRect(find.byIcon(Icons.search_rounded)).center.dy,
      lessThan(glass - 2),
    );
  });

  testWidgets('rapid selected-only changes settle without an exception', (
    tester,
  ) async {
    await show(tester, 0);
    await show(tester, 2);
    await tester.pump(const Duration(milliseconds: 40));
    await show(tester, 1);
    await tester.pump(const Duration(milliseconds: 40));
    await show(tester, 0);
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
    final glass = tester.getRect(find.byType(GlassSurface)).center.dy;
    expect(
      tester.getRect(find.byIcon(Icons.home_rounded)).center.dy,
      lessThan(glass - 2),
    );
    expect(
      tester.getRect(find.byIcon(Icons.inbox_outlined)).center.dy,
      closeTo(glass, 0.75),
    );
  });

  testWidgets('disposing during a selected-only move does not throw', (
    tester,
  ) async {
    await show(tester, 0);
    await show(tester, 2);
    await tester.pump(const Duration(milliseconds: 30));
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });

  testWidgets('switching label mode recenters icons only and selected only', (
    tester,
  ) async {
    await show(tester, 1, mode: LiquidGlassLabelMode.always);
    await tester.pump(const Duration(seconds: 1));
    final always = tester.getRect(find.byIcon(Icons.home_rounded)).center.dy;

    await show(tester, 1, mode: LiquidGlassLabelMode.hidden);
    await tester.pump(const Duration(seconds: 1));
    final glass = tester.getRect(find.byType(GlassSurface)).center.dy;
    expect(
      tester.getRect(find.byIcon(Icons.home_rounded)).center.dy,
      closeTo(glass, 0.75),
    );
    expect(
      tester.getRect(find.byIcon(Icons.search_rounded)).center.dy,
      closeTo(glass, 0.75),
    );
    expect(find.text('Home'), findsNothing);

    await show(tester, 1, mode: LiquidGlassLabelMode.selected);
    await tester.pump(const Duration(seconds: 1));
    expect(
      tester.getRect(find.byIcon(Icons.home_rounded)).center.dy,
      closeTo(glass, 0.75),
    );
    expect(
      tester.getRect(find.byIcon(Icons.search_rounded)).center.dy,
      lessThan(glass - 2),
    );
    expect(always, lessThan(glass - 2));
  });

  testWidgets('a drag preview does not label an uncommitted destination', (
    tester,
  ) async {
    final selections = <int>[];
    await pumpNavigationBar(
      tester,
      items: items,
      currentIndex: 0,
      onIndexChanged: selections.add,
      labelMode: LiquidGlassLabelMode.selected,
      enableDragSelection: true,
    );
    await tester.pump(const Duration(seconds: 1));
    final glass = tester.getRect(find.byType(GlassSurface)).center.dy;
    final box = indicatorRender(tester);
    final slot = box.localToGlobal(box.debugItemRects[1].center);
    final gesture = await tester.startGesture(
      box.localToGlobal(box.debugItemRects[0].center),
    );
    await gesture.moveTo(slot);
    await tester.pump();
    expect(selections, isEmpty);
    expect(
      tester.getRect(find.byIcon(Icons.search_rounded)).center.dy,
      closeTo(glass, 0.75),
    );
    expect(
      tester.getRect(find.byIcon(Icons.home_rounded)).center.dy,
      lessThan(glass - 2),
    );
    await gesture.up();
    await tester.pump();
    expect(selections, <int>[1]);
  });

  testWidgets('a rejected selection springs the selected-only label back', (
    tester,
  ) async {
    await pumpNavigationBar(
      tester,
      items: items,
      currentIndex: 0,
      onIndexChanged: (_) {},
      labelMode: LiquidGlassLabelMode.selected,
      enableDragSelection: true,
    );
    await tester.pump(const Duration(seconds: 1));
    final box = indicatorRender(tester);
    final gesture = await tester.startGesture(
      box.localToGlobal(box.debugItemRects[0].center),
    );
    await gesture.moveTo(box.localToGlobal(box.debugItemRects[1].center));
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    final glass = tester.getRect(find.byType(GlassSurface)).center.dy;
    expect(
      tester.getRect(find.byIcon(Icons.home_rounded)).center.dy,
      lessThan(glass - 2),
    );
    expect(
      tester.getRect(find.byIcon(Icons.search_rounded)).center.dy,
      closeTo(glass, 0.75),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'a badge follows the unselected icon, not a reserved label band',
    (tester) async {
      await pumpNavigationBar(
        tester,
        items: const <LiquidGlassNavigationItem>[
          LiquidGlassNavigationItem(
            icon: Icons.home_rounded,
            label: 'Home',
            badge: LiquidGlassBadge.count(4),
          ),
          LiquidGlassNavigationItem(
            icon: Icons.search_rounded,
            label: 'Search',
          ),
        ],
        currentIndex: 1,
        onIndexChanged: (_) {},
        labelMode: LiquidGlassLabelMode.selected,
      );
      await tester.pump(const Duration(seconds: 1));
      final icon = tester.getRect(find.byIcon(Icons.home_rounded));
      final badge = tester.getRect(find.text('4'));
      final glass = tester.getRect(find.byType(GlassSurface)).center.dy;
      expect(icon.center.dy, closeTo(glass, 0.75));
      expect(badge.center.dy, lessThan(icon.top + 6));
      expect(badge.center.dx, greaterThan(icon.right - 4));
    },
  );
}

Rect _capsule(WidgetTester tester) {
  final box = indicatorRender(tester);
  return box.debugIndicatorRect!.shift(box.localToGlobal(Offset.zero));
}
