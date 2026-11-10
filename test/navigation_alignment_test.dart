import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_bottom_navigator/src/glass_surface.dart';

import 'harness.dart';

void main() {
  testWidgets('end capsules use one gap on the top, bottom, and outer side', (
    tester,
  ) async {
    for (final direction in TextDirection.values) {
      for (final index in <int>[0, 2]) {
        await pumpNavigationBar(
          tester,
          items: sampleItems(),
          currentIndex: index,
          onIndexChanged: (_) {},
          labelMode: LiquidGlassLabelMode.selected,
          textDirection: direction,
        );
        final before = tester.getRect(find.byIcon(Icons.home_rounded));
        _expectAligned(_iconCenters(tester));
        _expectEqualOuterGap(tester, index: index, direction: direction);

        await pumpNavigationBar(
          tester,
          items: sampleItems(),
          currentIndex: index == 0 ? 2 : 0,
          onIndexChanged: (_) {},
          labelMode: LiquidGlassLabelMode.selected,
          textDirection: direction,
        );
        await tester.pump(const Duration(seconds: 1));
        final after = tester.getRect(find.byIcon(Icons.home_rounded));
        expect(after.left, closeTo(before.left, 0.5));
        expect(after.top, closeTo(before.top, 0.5));
        _expectEqualOuterGap(
          tester,
          index: index == 0 ? 2 : 0,
          direction: direction,
        );
      }
    }
  });

  testWidgets('a narrow bar keeps the capsule inside the glass', (
    tester,
  ) async {
    await pumpNavigationBar(
      tester,
      items: sampleItems(),
      currentIndex: 0,
      onIndexChanged: (_) {},
      labelMode: LiquidGlassLabelMode.always,
      surface: const Size(150, 240),
      textScale: 1.6,
    );
    expect(tester.takeException(), isNull);
    _expectAligned(_iconCenters(tester));
    final glass = tester.getRect(find.byType(GlassSurface));
    final indicator = _global(
      tester,
      indicatorRender(tester).debugIndicatorRect!,
    );
    expect(indicator.left, greaterThanOrEqualTo(glass.left - 0.5));
    expect(indicator.right, lessThanOrEqualTo(glass.right + 0.5));
    expect(indicator.top, greaterThanOrEqualTo(glass.top - 0.5));
    expect(indicator.bottom, lessThanOrEqualTo(glass.bottom + 0.5));
    expect(glass.height, greaterThanOrEqualTo(48));
  });

  testWidgets(
    'icons share a vertical center in every label mode and stay put',
    (tester) async {
      for (final mode in LiquidGlassLabelMode.values) {
        await pumpNavigationBar(
          tester,
          items: sampleItems(),
          currentIndex: 0,
          onIndexChanged: (_) {},
          labelMode: mode,
        );
        final before = _iconCenters(tester);
        _expectAligned(before);

        await pumpNavigationBar(
          tester,
          items: sampleItems(),
          currentIndex: 2,
          onIndexChanged: (_) {},
          labelMode: mode,
        );
        final after = _iconCenters(tester);
        _expectAligned(after);
        for (var i = 0; i < before.length; i++) {
          expect(after[i], closeTo(before[i], 0.5));
        }
      }
    },
  );

  testWidgets(
    'an icon-only destination uses the same center as a labeled one',
    (tester) async {
      const items = <LiquidGlassNavigationItem>[
        LiquidGlassNavigationItem(icon: Icons.home_rounded, label: 'Home'),
        LiquidGlassNavigationItem(icon: Icons.search_rounded),
        LiquidGlassNavigationItem(icon: Icons.inbox_outlined, label: 'Inbox'),
      ];
      for (final mode in <LiquidGlassLabelMode>[
        LiquidGlassLabelMode.selected,
        LiquidGlassLabelMode.always,
        LiquidGlassLabelMode.hidden,
      ]) {
        await pumpNavigationBar(
          tester,
          items: items,
          currentIndex: 2,
          onIndexChanged: (_) {},
          labelMode: mode,
        );
        _expectAligned(_iconCenters(tester));
      }
    },
  );

  testWidgets('the capsule hugs the selected content and leaves the hit slot', (
    tester,
  ) async {
    for (final brightness in Brightness.values) {
      await pumpNavigationBar(
        tester,
        items: sampleItems(withBadge: true),
        currentIndex: 2,
        onIndexChanged: (_) {},
        labelMode: LiquidGlassLabelMode.selected,
        themeData: ThemeData(brightness: brightness, useMaterial3: true),
      );
      final render = indicatorRender(tester);
      final indicator = _global(tester, render.debugIndicatorRect!);
      final slot = _global(tester, render.debugItemRects[2]);
      final icon = tester.getRect(find.byIcon(Icons.inbox_outlined));
      final label = tester.getRect(find.text('Inbox'));
      final badge = tester.getRect(find.text('12'));

      expect(slot.width, greaterThan(indicator.width + 8));
      expect(slot.height, greaterThanOrEqualTo(48));
      expect(indicator.width, lessThan(slot.width - 16));
      _expectContains(indicator, icon);
      _expectContains(indicator, label);
      _expectContains(indicator, badge);
      expect(indicator.center.dx, closeTo(icon.center.dx, 1.5));
    }
  });

  testWidgets(
    'text scaling keeps icons aligned and the capsule around the label',
    (tester) async {
      await pumpNavigationBar(
        tester,
        items: sampleItems(),
        currentIndex: 1,
        onIndexChanged: (_) {},
        labelMode: LiquidGlassLabelMode.selected,
        textScale: 1.6,
      );
      _expectAligned(_iconCenters(tester));
      final render = indicatorRender(tester);
      final indicator = _global(tester, render.debugIndicatorRect!);
      final slot = _global(tester, render.debugItemRects[1]);
      expect(slot.shortestSide, greaterThanOrEqualTo(48));
      _expectContains(
        indicator,
        tester.getRect(find.byIcon(Icons.search_rounded)),
      );
      _expectContains(indicator, tester.getRect(find.text('Search')));
    },
  );

  testWidgets('intrinsic slots and RTL keep the shared icon center', (
    tester,
  ) async {
    Future<void> show(TextDirection direction) {
      return pumpNavigationBar(
        tester,
        items: sampleItems(),
        currentIndex: 1,
        onIndexChanged: (_) {},
        labelMode: LiquidGlassLabelMode.always,
        textDirection: direction,
        style: testStyle.copyWith(itemLayout: LiquidGlassItemLayout.intrinsic),
      );
    }

    await show(TextDirection.ltr);
    _expectAligned(_iconCenters(tester));
    var render = indicatorRender(tester);
    var indicator = _global(tester, render.debugIndicatorRect!);
    var slot = _global(tester, render.debugItemRects[1]);
    expect(indicator.center.dx, closeTo(slot.center.dx, 1));
    expect(indicator.width, lessThanOrEqualTo(slot.width + 0.5));
    _expectContains(indicator, tester.getRect(find.text('Search')));

    await show(TextDirection.rtl);
    _expectAligned(_iconCenters(tester));
    render = indicatorRender(tester);
    indicator = _global(tester, render.debugIndicatorRect!);
    slot = _global(tester, render.debugItemRects[1]);
    expect(indicator.center.dx, closeTo(slot.center.dx, 1));
    expect(indicator.left, greaterThanOrEqualTo(slot.left - 0.5));
    expect(indicator.right, lessThanOrEqualTo(slot.right + 0.5));
  });

  testWidgets(
    'a custom child shares the icon center and stays inside the capsule',
    (tester) async {
      await pumpNavigationBar(
        tester,
        items: const <LiquidGlassNavigationItem>[
          LiquidGlassNavigationItem(icon: Icons.home_rounded, label: 'Home'),
          LiquidGlassNavigationItem(
            label: 'Inbox',
            badge: LiquidGlassBadge.count(4),
            child: SizedBox(key: Key('avatar'), width: 28, height: 28),
          ),
          LiquidGlassNavigationItem(icon: Icons.search_rounded),
        ],
        currentIndex: 1,
        onIndexChanged: (_) {},
        labelMode: LiquidGlassLabelMode.selected,
      );
      final home = tester.getRect(find.byIcon(Icons.home_rounded)).center.dy;
      final avatar = tester.getRect(find.byKey(const Key('avatar'))).center.dy;
      final search = tester
          .getRect(find.byIcon(Icons.search_rounded))
          .center
          .dy;
      expect(avatar, closeTo(home, 0.5));
      expect(search, closeTo(home, 0.5));

      final indicator = _global(
        tester,
        indicatorRender(tester).debugIndicatorRect!,
      );
      _expectContains(
        indicator,
        tester.getRect(find.byKey(const Key('avatar'))),
      );
      _expectContains(indicator, tester.getRect(find.text('Inbox')));
      _expectContains(indicator, tester.getRect(find.text('4')));
    },
  );

  testWidgets(
    'the morphing capsule stays inside the row and settles on content',
    (tester) async {
      const motion = LiquidGlassMotion(
        duration: Duration(milliseconds: 400),
        bounce: 0,
        morphIntensity: 1,
      );
      Future<void> show(int index) {
        return pumpNavigationBar(
          tester,
          items: const <LiquidGlassNavigationItem>[
            LiquidGlassNavigationItem(icon: Icons.home_rounded, label: 'Home'),
            LiquidGlassNavigationItem(
              icon: Icons.search_rounded,
              label: 'Search',
            ),
            LiquidGlassNavigationItem(
              icon: Icons.inbox_outlined,
              label: 'Archive',
            ),
          ],
          currentIndex: index,
          onIndexChanged: (_) {},
          labelMode: LiquidGlassLabelMode.selected,
          indicatorStyle: LiquidGlassIndicatorStyle.morphingPill,
          motion: motion,
        );
      }

      await show(0);
      final home = indicatorRender(tester).debugIndicatorRect!;
      final homeIcons = _iconCenters(tester);

      await show(2);
      expect(_iconCenters(tester), homeIcons);
      await tester.pump(const Duration(milliseconds: 120));
      final moving = indicatorRender(tester);
      final movingRect = moving.debugIndicatorRect!;
      expect(movingRect.width, greaterThan(home.width + 8));
      expect(movingRect.left, greaterThanOrEqualTo(-0.5));
      expect(movingRect.right, lessThanOrEqualTo(moving.size.width + 0.5));
      expect(movingRect.top, greaterThanOrEqualTo(-0.5));
      expect(movingRect.bottom, lessThanOrEqualTo(moving.size.height + 0.5));

      await tester.pump(const Duration(seconds: 1));
      final settled = indicatorRender(tester);
      final settledRect = settled.debugIndicatorRect!;
      final slot = settled.debugItemRects[2];
      final archive = tester.getRect(find.byIcon(Icons.inbox_outlined));
      expect(
        _global(tester, settledRect).center.dx,
        closeTo(archive.center.dx, 1.5),
      );
      expect(settledRect.width, greaterThan(home.width + 4));
      expect(settledRect.width, lessThan(slot.width - 8));
      _expectContains(
        _global(tester, settledRect),
        tester.getRect(find.text('Archive')),
      );
      expect(_iconCenters(tester), homeIcons);
    },
  );
}

List<double> _iconCenters(WidgetTester tester) {
  return <double>[
    tester.getRect(find.byIcon(Icons.home_rounded)).center.dy,
    if (find.byIcon(Icons.search_rounded).evaluate().isNotEmpty)
      tester.getRect(find.byIcon(Icons.search_rounded)).center.dy,
    if (find.byIcon(Icons.inbox_outlined).evaluate().isNotEmpty)
      tester.getRect(find.byIcon(Icons.inbox_outlined)).center.dy,
  ];
}

void _expectAligned(List<double> centers) {
  expect(centers, isNotEmpty);
  for (final center in centers) {
    expect(center, closeTo(centers.first, 0.5));
  }
}

Rect _global(WidgetTester tester, Rect local) {
  final box = indicatorRender(tester);
  return local.shift(box.localToGlobal(Offset.zero));
}

void _expectEqualOuterGap(
  WidgetTester tester, {
  required int index,
  required TextDirection direction,
}) {
  final glass = tester.getRect(find.byType(GlassSurface));
  final indicator = _global(
    tester,
    indicatorRender(tester).debugIndicatorRect!,
  );
  final top = indicator.top - glass.top;
  final bottom = glass.bottom - indicator.bottom;
  final outerOnLeft = direction == TextDirection.ltr ? index == 0 : index != 0;
  final side = outerOnLeft
      ? indicator.left - glass.left
      : glass.right - indicator.right;
  expect(bottom, closeTo(top, 0.75));
  expect(side, closeTo(top, 0.75));
  expect(top, inInclusiveRange(4, 10));
  expect(indicator.width, lessThan(glass.width / 2));
}

void _expectContains(Rect outer, Rect inner) {
  expect(outer.left, lessThanOrEqualTo(inner.left + 0.5));
  expect(outer.top, lessThanOrEqualTo(inner.top + 0.5));
  expect(outer.right, greaterThanOrEqualTo(inner.right - 0.5));
  expect(outer.bottom, greaterThanOrEqualTo(inner.bottom - 0.5));
}
