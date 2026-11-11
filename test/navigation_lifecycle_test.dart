import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_bottom_navigator/src/navigation_layout.dart';

import 'harness.dart';

void main() {
  testWidgets('repeated mount and unmount leaves no ticker', (tester) async {
    for (var i = 0; i < 24; i++) {
      await pumpNavigationBar(
        tester,
        items: sampleItems(),
        currentIndex: i % 3,
        onIndexChanged: (_) {},
        labelMode: LiquidGlassLabelMode.values[i % 3],
      );
      await tester.pump(const Duration(milliseconds: 20));
      await tester.pumpWidget(const SizedBox.shrink());
    }
    expect(tester.takeException(), isNull);
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('rebuilding the same index does not notify or restart motion', (
    tester,
  ) async {
    final selections = <int>[];
    await pumpNavigationBar(
      tester,
      items: sampleItems(),
      currentIndex: 1,
      onIndexChanged: selections.add,
    );
    await tester.pumpAndSettle();
    final before = indicatorRender(tester).debugIndicatorRect!.center;

    for (var i = 0; i < 8; i++) {
      await pumpNavigationBar(
        tester,
        items: sampleItems(),
        currentIndex: 1,
        onIndexChanged: selections.add,
      );
    }
    await tester.pump();

    expect(selections, isEmpty);
    expect(tester.binding.transientCallbackCount, 0);
    expect(
      indicatorRender(tester).debugIndicatorRect!.center.dx,
      closeTo(before.dx, 0.01),
    );
  });

  testWidgets('one hundred programmatic changes emit no selection callback', (
    tester,
  ) async {
    final selections = <int>[];
    for (var i = 0; i < 100; i++) {
      await pumpNavigationBar(
        tester,
        items: sampleItems(),
        currentIndex: i % 3,
        onIndexChanged: selections.add,
        labelMode: LiquidGlassLabelMode.selected,
      );
      await tester.pump(const Duration(milliseconds: 8));
    }
    await tester.pumpAndSettle();
    expect(selections, isEmpty);
    expect(indicatorRender(tester).targetIndex, 99 % 3);
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('alternating taps report exactly one index each', (tester) async {
    final selections = <int>[];
    var index = 0;
    Future<void> pump() {
      return pumpNavigationBar(
        tester,
        items: sampleItems(),
        currentIndex: index,
        onIndexChanged: (value) {
          selections.add(value);
          index = value;
        },
      );
    }

    await pump();
    const icons = <IconData>[
      Icons.home_rounded,
      Icons.search_rounded,
      Icons.inbox_outlined,
    ];
    for (var i = 0; i < 12; i++) {
      final next = (index + 1) % 3;
      await tester.tap(find.byIcon(icons[next]));
      await pump();
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pumpAndSettle();
    expect(selections, hasLength(12));
    expect(selections.toSet(), <int>{0, 1, 2});
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('a rejected tap notifies once and returns to the parent index', (
    tester,
  ) async {
    final selections = <int>[];
    await pumpNavigationBar(
      tester,
      items: sampleItems(),
      currentIndex: 0,
      onIndexChanged: selections.add,
    );
    final home = indicatorRender(tester).debugIndicatorRect!.center;
    await tester.tap(find.byIcon(Icons.search_rounded));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(selections, <int>[1]);
    expect(
      indicatorRender(tester).debugIndicatorRect!.center.dx,
      closeTo(home.dx, 0.5),
    );
    expect(indicatorRender(tester).targetIndex, 0);
  });

  testWidgets(
    'removing the selected item drops the indicator without a throw',
    (tester) async {
      final selections = <int>[];
      await pumpNavigationBar(
        tester,
        items: sampleItems(),
        currentIndex: 2,
        onIndexChanged: selections.add,
      );
      await tester.pump(const Duration(milliseconds: 30));
      final remaining = sampleItems().take(2).toList();
      await pumpNavigationBar(
        tester,
        items: remaining,
        currentIndex: 2,
        onIndexChanged: selections.add,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(selections, isEmpty);
      expect(indicatorRender(tester).targetIndex, isNull);
      expect(indicatorRender(tester).debugIndicatorRect, isNull);
    },
  );

  testWidgets('theme and label mode changes during motion stay finite', (
    tester,
  ) async {
    final selections = <int>[];
    await pumpNavigationBar(
      tester,
      items: sampleItems(),
      currentIndex: 0,
      onIndexChanged: selections.add,
    );
    await pumpNavigationBar(
      tester,
      items: sampleItems(),
      currentIndex: 2,
      onIndexChanged: selections.add,
      labelMode: LiquidGlassLabelMode.selected,
    );
    await tester.pump(const Duration(milliseconds: 40));
    await pumpNavigationBar(
      tester,
      items: sampleItems(withBadge: true),
      currentIndex: 2,
      onIndexChanged: selections.add,
      labelMode: LiquidGlassLabelMode.hidden,
      themeData: ThemeData(brightness: Brightness.dark, useMaterial3: true),
      disableAnimations: true,
    );
    await tester.pumpAndSettle();
    expect(selections, isEmpty);
    expect(tester.takeException(), isNull);
    final capsule = indicatorRender(tester).debugIndicatorRect!;
    expect(capsule.width, greaterThan(0));
    expect(capsule.height, greaterThan(0));
    expect(capsule.width.isFinite, isTrue);
    expect(capsule.height.isFinite, isTrue);
  });

  testWidgets('disposing during a spring leaves no ticker', (tester) async {
    await pumpNavigationBar(
      tester,
      items: sampleItems(),
      currentIndex: 0,
      onIndexChanged: (_) {},
      labelMode: LiquidGlassLabelMode.selected,
    );
    await pumpNavigationBar(
      tester,
      items: sampleItems(),
      currentIndex: 2,
      onIndexChanged: (_) {},
      labelMode: LiquidGlassLabelMode.selected,
    );
    await tester.pump(const Duration(milliseconds: 24));
    expect(tester.binding.transientCallbackCount, greaterThan(0));
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('disposing during a drag leaves no ticker', (tester) async {
    await pumpNavigationBar(
      tester,
      items: sampleItems(),
      currentIndex: 0,
      enableDragSelection: true,
      onIndexChanged: (_) {},
    );
    final start = tester.getCenter(find.byIcon(Icons.home_rounded));
    final gesture = await tester.startGesture(start);
    await gesture.moveBy(const Offset(48, 0));
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('an idle bar does not schedule frames or repaint', (
    tester,
  ) async {
    await pumpNavigationBar(
      tester,
      items: sampleItems(withBadge: true),
      currentIndex: 1,
      onIndexChanged: (_) {},
    );
    await tester.pumpAndSettle();
    RenderLiquidNavigation.debugResetFrameCounters();
    await tester.pump(const Duration(milliseconds: 400));
    expect(RenderLiquidNavigation.debugPaintCount, 0);
    expect(RenderLiquidNavigation.debugContentWalkCount, 0);
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('a spring paints a finite number of frames and then stays idle', (
    tester,
  ) async {
    await pumpNavigationBar(
      tester,
      items: sampleItems(),
      currentIndex: 0,
      onIndexChanged: (_) {},
      labelMode: LiquidGlassLabelMode.selected,
      indicatorStyle: LiquidGlassIndicatorStyle.morphingPill,
    );
    await tester.pumpAndSettle();
    RenderLiquidNavigation.debugResetFrameCounters();
    await pumpNavigationBar(
      tester,
      items: sampleItems(),
      currentIndex: 2,
      onIndexChanged: (_) {},
      labelMode: LiquidGlassLabelMode.selected,
      indicatorStyle: LiquidGlassIndicatorStyle.morphingPill,
    );

    var steps = 0;
    while (tester.binding.transientCallbackCount > 0 && steps < 90) {
      await tester.pump(const Duration(milliseconds: 16));
      steps++;
    }
    final paints = RenderLiquidNavigation.debugPaintCount;
    final walks = RenderLiquidNavigation.debugContentWalkCount;
    expect(steps, greaterThan(1));
    expect(steps, lessThan(90));
    expect(paints, greaterThan(1));
    expect(paints, lessThan(90));
    expect(walks, inInclusiveRange(paints, paints + 1));
    expect(tester.binding.transientCallbackCount, 0);

    await tester.pump(const Duration(milliseconds: 300));
    expect(RenderLiquidNavigation.debugPaintCount, paints);
    expect(RenderLiquidNavigation.debugContentWalkCount, walks);
  });
}
