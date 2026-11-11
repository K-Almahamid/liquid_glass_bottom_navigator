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
        final glass = tester.getRect(find.byType(GlassSurface)).center.dy;
        final before = tester.getRect(find.byIcon(Icons.home_rounded));
        if (index == 0) {
          expect(before.center.dy, lessThan(glass - 2));
        } else {
          expect(before.center.dy, closeTo(glass, 0.75));
        }
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
        if (index == 0) {
          expect(after.center.dy, closeTo(glass, 0.75));
        } else {
          expect(after.center.dy, lessThan(glass - 2));
        }
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
      for (final mode in <LiquidGlassLabelMode>[
        LiquidGlassLabelMode.always,
        LiquidGlassLabelMode.hidden,
      ]) {
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
        await tester.pump(const Duration(seconds: 1));
        final after = _iconCenters(tester);
        _expectAligned(after);
        for (var i = 0; i < before.length; i++) {
          expect(after[i], closeTo(before[i], 0.5));
        }
      }

      await pumpNavigationBar(
        tester,
        items: sampleItems(),
        currentIndex: 0,
        onIndexChanged: (_) {},
        labelMode: LiquidGlassLabelMode.selected,
      );
      await tester.pump(const Duration(seconds: 1));
      final glass = tester.getRect(find.byType(GlassSurface)).center.dy;
      final home = tester.getRect(find.byIcon(Icons.home_rounded)).center.dy;
      final search = tester
          .getRect(find.byIcon(Icons.search_rounded))
          .center
          .dy;
      expect(home, lessThan(glass - 2));
      expect(search, closeTo(glass, 0.75));

      await pumpNavigationBar(
        tester,
        items: sampleItems(),
        currentIndex: 2,
        onIndexChanged: (_) {},
        labelMode: LiquidGlassLabelMode.selected,
      );
      await tester.pump(const Duration(seconds: 1));
      final glassAfter = tester.getRect(find.byType(GlassSurface)).center.dy;
      expect(
        tester.getRect(find.byIcon(Icons.home_rounded)).center.dy,
        closeTo(glassAfter, 0.75),
      );
      expect(
        tester.getRect(find.byIcon(Icons.inbox_outlined)).center.dy,
        lessThan(glassAfter - 2),
      );
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

      await pumpNavigationBar(
        tester,
        items: items,
        currentIndex: 2,
        onIndexChanged: (_) {},
        labelMode: LiquidGlassLabelMode.selected,
      );
      final glass = tester.getRect(find.byType(GlassSurface)).center.dy;
      expect(
        tester.getRect(find.byIcon(Icons.home_rounded)).center.dy,
        closeTo(glass, 0.75),
      );
      expect(
        tester.getRect(find.byIcon(Icons.search_rounded)).center.dy,
        closeTo(glass, 0.75),
      );
      expect(
        tester.getRect(find.byIcon(Icons.inbox_outlined)).center.dy,
        lessThan(glass - 2),
      );
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
      expect(label.top, greaterThan(icon.center.dy));
      expect(badge.center.dx, greaterThan(icon.center.dx));
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
      final glass = tester.getRect(find.byType(GlassSurface)).center.dy;
      expect(
        tester.getRect(find.byIcon(Icons.home_rounded)).center.dy,
        closeTo(glass, 0.75),
      );
      expect(
        tester.getRect(find.byIcon(Icons.inbox_outlined)).center.dy,
        closeTo(glass, 0.75),
      );
      expect(
        tester.getRect(find.byIcon(Icons.search_rounded)).center.dy,
        lessThan(glass - 2),
      );
      final render = indicatorRender(tester);
      final indicator = _global(tester, render.debugIndicatorRect!);
      final slot = _global(tester, render.debugItemRects[1]);
      expect(slot.shortestSide, greaterThanOrEqualTo(48));
      final icon = tester.getRect(find.byIcon(Icons.search_rounded));
      final label = tester.getRect(find.text('Search'));
      _expectContains(indicator, icon);
      _expectContains(indicator, label);
      expect(label.top, greaterThan(icon.center.dy));
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
    final search = tester.getRect(find.text('Search'));
    _expectContains(indicator, search);

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
      final glass = tester.getRect(find.byType(GlassSurface)).center.dy;
      final home = tester.getRect(find.byIcon(Icons.home_rounded)).center.dy;
      final avatarRect = tester.getRect(find.byKey(const Key('avatar')));
      final avatar = avatarRect.center.dy;
      final search = tester
          .getRect(find.byIcon(Icons.search_rounded))
          .center
          .dy;
      expect(home, closeTo(glass, 0.75));
      expect(search, closeTo(glass, 0.75));
      expect(avatar, lessThan(glass - 2));

      final indicator = _global(
        tester,
        indicatorRender(tester).debugIndicatorRect!,
      );
      _expectContains(
        indicator,
        tester.getRect(find.byKey(const Key('avatar'))),
      );
      final label = tester.getRect(find.text('Inbox'));
      _expectContains(indicator, label);
      expect(
        tester.getRect(find.text('4')).center.dx,
        greaterThan(avatarRect.center.dx),
      );
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
      final homeStart = tester
          .getRect(find.byIcon(Icons.home_rounded))
          .center
          .dy;
      final archiveStart = tester
          .getRect(find.byIcon(Icons.inbox_outlined))
          .center
          .dy;

      await show(2);
      await tester.pump(const Duration(milliseconds: 120));
      final homeMoving = tester
          .getRect(find.byIcon(Icons.home_rounded))
          .center
          .dy;
      final archiveMoving = tester
          .getRect(find.byIcon(Icons.inbox_outlined))
          .center
          .dy;
      expect(homeMoving, greaterThan(homeStart + 0.5));
      expect(archiveMoving, lessThan(archiveStart - 0.5));
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
      final archiveIcon = tester.getRect(find.byIcon(Icons.inbox_outlined));
      _expectContains(_global(tester, settledRect), archiveIcon);
      final label = tester.getRect(find.text('Archive'));
      final capsule = _global(tester, settledRect);
      _expectContains(capsule, label);
      expect(label.top, greaterThan(archiveIcon.center.dy));
      final settledGlass = tester.getRect(find.byType(GlassSurface)).center.dy;
      expect(archiveIcon.center.dy, lessThan(settledGlass - 2));
      expect(
        tester.getRect(find.byIcon(Icons.home_rounded)).center.dy,
        closeTo(settledGlass, 0.75),
      );
    },
  );

  testWidgets('each label mode contains the visible selected content', (
    tester,
  ) async {
    Future<void> show(LiquidGlassLabelMode mode) {
      return pumpNavigationBar(
        tester,
        items: sampleItems(),
        currentIndex: 0,
        onIndexChanged: (_) {},
        labelMode: mode,
      );
    }

    await show(LiquidGlassLabelMode.always);
    var indicator = _global(
      tester,
      indicatorRender(tester).debugIndicatorRect!,
    );
    final homeIcon = tester.getRect(find.byIcon(Icons.home_rounded));
    final homeLabel = tester.getRect(find.text('Home'));
    _expectContains(indicator, homeIcon);
    _expectContains(indicator, homeLabel);
    expect(indicator.width, greaterThan(indicator.height));
    expect(find.text('Search'), findsOneWidget);

    await show(LiquidGlassLabelMode.hidden);
    indicator = _global(tester, indicatorRender(tester).debugIndicatorRect!);
    _expectContains(indicator, tester.getRect(find.byIcon(Icons.home_rounded)));
    expect(find.text('Home'), findsNothing);
    expect(indicator.width, greaterThan(indicator.height * 1.3));

    await show(LiquidGlassLabelMode.selected);
    indicator = _global(tester, indicatorRender(tester).debugIndicatorRect!);
    _expectContains(indicator, tester.getRect(find.byIcon(Icons.home_rounded)));
    _expectContains(indicator, tester.getRect(find.text('Home')));
    expect(find.text('Search'), findsOneWidget);
  });

  testWidgets('changing label mode during a move keeps the label inside', (
    tester,
  ) async {
    await pumpNavigationBar(
      tester,
      items: sampleItems(),
      currentIndex: 0,
      onIndexChanged: (_) {},
      labelMode: LiquidGlassLabelMode.always,
    );
    await pumpNavigationBar(
      tester,
      items: sampleItems(),
      currentIndex: 2,
      onIndexChanged: (_) {},
      labelMode: LiquidGlassLabelMode.hidden,
    );
    await tester.pump(const Duration(milliseconds: 80));
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 1));
    final indicator = _global(
      tester,
      indicatorRender(tester).debugIndicatorRect!,
    );
    _expectContains(
      indicator,
      tester.getRect(find.byIcon(Icons.inbox_outlined)),
    );
    expect(find.text('Inbox'), findsNothing);
    _expectAligned(_iconCenters(tester));
  });

  testWidgets('a count badge sits on the upper trailing corner', (
    tester,
  ) async {
    await pumpNavigationBar(
      tester,
      items: sampleItems(withBadge: true),
      currentIndex: 2,
      onIndexChanged: (_) {},
    );
    final icon = tester.getRect(find.byIcon(Icons.inbox_outlined));
    final badge = tester.getRect(find.text('12'));
    expect(badge.center.dy, lessThan(icon.top + 6));
    expect(badge.center.dx, greaterThan(icon.right - 4));
  });

  testWidgets('a dot badge sits on the lower trailing corner', (tester) async {
    await pumpNavigationBar(
      tester,
      items: sampleItems(withBadge: true),
      currentIndex: 1,
      onIndexChanged: (_) {},
    );
    final icon = tester.getRect(find.byIcon(Icons.search_rounded));
    final dot = tester.getRect(
      find.byWidgetPredicate(
        (widget) =>
            widget is SizedBox && widget.width == 8 && widget.height == 8,
      ),
    );
    expect(dot.center.dy, greaterThan(icon.center.dy + 4));
    expect(dot.center.dx, greaterThan(icon.center.dx + 4));
  });

  testWidgets('badges mirror to the leading edge in RTL', (tester) async {
    await pumpNavigationBar(
      tester,
      items: sampleItems(withBadge: true),
      currentIndex: 2,
      onIndexChanged: (_) {},
      textDirection: TextDirection.rtl,
    );
    final icon = tester.getRect(find.byIcon(Icons.inbox_outlined));
    final badge = tester.getRect(find.text('12'));
    expect(badge.center.dx, lessThan(icon.center.dx - 4));
    expect(badge.center.dy, lessThan(icon.center.dy));
  });

  testWidgets('badges do not cover the label or grow the capsule', (
    tester,
  ) async {
    await pumpNavigationBar(
      tester,
      items: sampleItems(withBadge: true),
      currentIndex: 2,
      onIndexChanged: (_) {},
      labelMode: LiquidGlassLabelMode.always,
    );
    final label = tester.getRect(find.text('Inbox'));
    final count = tester.getRect(find.text('12'));
    final dot = tester.getRect(
      find.byWidgetPredicate(
        (widget) =>
            widget is SizedBox && widget.width == 8 && widget.height == 8,
      ),
    );
    expect(count.overlaps(label), isFalse);
    expect(dot.overlaps(label), isFalse);
    final indicator = _global(
      tester,
      indicatorRender(tester).debugIndicatorRect!,
    );
    _expectContains(indicator, label);
    expect(indicator.top, lessThan(count.center.dy));
  });

  testWidgets('a custom badge offset still moves the count', (tester) async {
    await pumpNavigationBar(
      tester,
      items: sampleItems(withBadge: true),
      currentIndex: 2,
      onIndexChanged: (_) {},
      style: testStyle.copyWith(badgeOffset: const Offset(0, 14)),
    );
    final icon = tester.getRect(find.byIcon(Icons.inbox_outlined));
    final badge = tester.getRect(find.text('12'));
    expect(badge.center.dy, greaterThan(icon.top));
  });

  testWidgets('edge icons sit on the capsule center in every label mode', (
    tester,
  ) async {
    const icons = <IconData>[
      Icons.home_rounded,
      Icons.search_rounded,
      Icons.inbox_outlined,
      Icons.bookmark_outline_rounded,
      Icons.person_outline_rounded,
    ];
    const labels = <String>['Home', 'Search', 'Inbox', 'Saved', 'Profile'];
    final items = <LiquidGlassNavigationItem>[
      for (var i = 0; i < icons.length; i++)
        LiquidGlassNavigationItem(icon: icons[i], label: labels[i]),
    ];
    for (final direction in TextDirection.values) {
      for (final mode in LiquidGlassLabelMode.values) {
        for (final index in <int>[0, 2, 4]) {
          await pumpNavigationBar(
            tester,
            items: items,
            currentIndex: index,
            onIndexChanged: (_) {},
            labelMode: mode,
            textDirection: direction,
            surface: const Size(402, 240),
          );
          await tester.pump(const Duration(seconds: 1));
          final icon = tester.getRect(find.byIcon(icons[index]));
          final indicator = _global(
            tester,
            indicatorRender(tester).debugIndicatorRect!,
          );
          expect(
            icon.center.dx,
            closeTo(indicator.center.dx, 0.5),
            reason: '$mode $direction index $index',
          );
          if (mode != LiquidGlassLabelMode.hidden) {
            final label = tester.getRect(find.text(labels[index]));
            expect(label.center.dx, closeTo(icon.center.dx, 0.5));
            expect(label.center.dx, closeTo(indicator.center.dx, 0.5));
          }
        }
      }
    }
  });

  testWidgets('badges do not move the capsule off the icon', (tester) async {
    final plain = <LiquidGlassNavigationItem>[
      const LiquidGlassNavigationItem(icon: Icons.home_rounded, label: 'Home'),
      const LiquidGlassNavigationItem(
        icon: Icons.search_rounded,
        label: 'Search',
      ),
      const LiquidGlassNavigationItem(
        icon: Icons.person_outline_rounded,
        label: 'Profile',
      ),
    ];
    final badged = <LiquidGlassNavigationItem>[
      const LiquidGlassNavigationItem(
        icon: Icons.home_rounded,
        label: 'Home',
        badge: LiquidGlassBadge.count(3),
      ),
      const LiquidGlassNavigationItem(
        icon: Icons.search_rounded,
        label: 'Search',
        badge: LiquidGlassBadge.dot(),
      ),
      const LiquidGlassNavigationItem(
        icon: Icons.person_outline_rounded,
        label: 'Profile',
        badge: LiquidGlassBadge.count(9),
      ),
    ];
    for (final direction in TextDirection.values) {
      for (final index in <int>[0, 1, 2]) {
        await pumpNavigationBar(
          tester,
          items: plain,
          currentIndex: index,
          onIndexChanged: (_) {},
          textDirection: direction,
          surface: const Size(402, 240),
        );
        await tester.pump(const Duration(seconds: 1));
        final plainIcon = tester.getRect(
          find.byIcon(
            index == 0
                ? Icons.home_rounded
                : index == 1
                ? Icons.search_rounded
                : Icons.person_outline_rounded,
          ),
        );
        final plainIndicator = _global(
          tester,
          indicatorRender(tester).debugIndicatorRect!,
        );

        await pumpNavigationBar(
          tester,
          items: badged,
          currentIndex: index,
          onIndexChanged: (_) {},
          textDirection: direction,
          surface: const Size(402, 240),
        );
        await tester.pump(const Duration(seconds: 1));
        final icon = tester.getRect(
          find.byIcon(
            index == 0
                ? Icons.home_rounded
                : index == 1
                ? Icons.search_rounded
                : Icons.person_outline_rounded,
          ),
        );
        final indicator = _global(
          tester,
          indicatorRender(tester).debugIndicatorRect!,
        );
        expect(icon.center.dx, closeTo(indicator.center.dx, 0.5));
        expect(icon.center.dx, closeTo(plainIcon.center.dx, 0.5));
        expect(indicator.center.dx, closeTo(plainIndicator.center.dx, 0.5));
        expect(indicator.width, closeTo(plainIndicator.width, 0.5));
      }
    }
  });

  testWidgets('a custom edge child stays centered in the capsule', (
    tester,
  ) async {
    const childKey = Key('profile-mark');
    final items = <LiquidGlassNavigationItem>[
      const LiquidGlassNavigationItem(icon: Icons.home_rounded, label: 'Home'),
      const LiquidGlassNavigationItem(
        icon: Icons.search_rounded,
        label: 'Search',
      ),
      const LiquidGlassNavigationItem(
        label: 'Profile',
        child: SizedBox(key: childKey, width: 28, height: 28),
      ),
    ];
    for (final direction in TextDirection.values) {
      for (final mode in LiquidGlassLabelMode.values) {
        await pumpNavigationBar(
          tester,
          items: items,
          currentIndex: 2,
          onIndexChanged: (_) {},
          labelMode: mode,
          textDirection: direction,
          surface: const Size(360, 240),
        );
        await tester.pump(const Duration(seconds: 1));
        final child = tester.getRect(find.byKey(childKey));
        final indicator = _global(
          tester,
          indicatorRender(tester).debugIndicatorRect!,
        );
        expect(child.center.dx, closeTo(indicator.center.dx, 0.5));
        if (mode != LiquidGlassLabelMode.hidden) {
          final label = tester.getRect(find.text('Profile'));
          expect(label.center.dx, closeTo(child.center.dx, 0.5));
        }
      }
    }
  });

  testWidgets('label modes keep the bar height and center visible content', (
    tester,
  ) async {
    const labels = <String>['Home', 'Search', 'Inbox', 'Saved', 'Profile'];
    const icons = <IconData>[
      Icons.home_rounded,
      Icons.search_rounded,
      Icons.inbox_outlined,
      Icons.bookmark_border_rounded,
      Icons.person_rounded,
    ];
    final items = <LiquidGlassNavigationItem>[
      for (var i = 0; i < labels.length; i++)
        LiquidGlassNavigationItem(icon: icons[i], label: labels[i]),
    ];
    final style = testStyle.copyWith(
      height: 58,
      padding: const EdgeInsets.all(6),
    );

    Future<({double glass, Rect icon, Rect capsule})> measure(
      LiquidGlassLabelMode mode,
      int index, {
      TextDirection direction = TextDirection.ltr,
      double textScale = 1,
      LiquidGlassNavigationStyle? itemStyle,
      List<LiquidGlassNavigationItem>? row,
    }) async {
      await pumpNavigationBar(
        tester,
        items: row ?? items,
        currentIndex: index,
        onIndexChanged: (_) {},
        labelMode: mode,
        style: itemStyle ?? style,
        surface: const Size(402, 240),
        textDirection: direction,
        textScale: textScale,
      );
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
      final icon = tester.getRect(find.byIcon((row ?? items)[index].icon!));
      return (
        glass: tester.getSize(find.byType(GlassSurface)).height,
        icon: icon,
        capsule: _global(tester, indicatorRender(tester).debugIndicatorRect!),
      );
    }

    for (final direction in TextDirection.values) {
      for (final index in <int>[0, 2, 4]) {
        final always = await measure(
          LiquidGlassLabelMode.always,
          index,
          direction: direction,
        );
        final hidden = await measure(
          LiquidGlassLabelMode.hidden,
          index,
          direction: direction,
        );
        final selected = await measure(
          LiquidGlassLabelMode.selected,
          index,
          direction: direction,
        );

        expect(hidden.glass, closeTo(always.glass, 0.5));
        expect(selected.glass, closeTo(always.glass, 0.5));
        final glass = tester.getRect(find.byType(GlassSurface));
        expect(hidden.icon.center.dy, closeTo(glass.center.dy, 0.75));
        expect(hidden.capsule.center.dy, closeTo(glass.center.dy, 0.75));
        expect(
          hidden.capsule.top - glass.top,
          closeTo(glass.bottom - hidden.capsule.bottom, 0.75),
        );
        expect(hidden.icon.center.dy, greaterThan(always.icon.center.dy + 2));
        expect(selected.icon.center.dy, closeTo(always.icon.center.dy, 0.5));
        expect(hidden.capsule.height, lessThan(always.capsule.height - 4));
        expect(selected.capsule.height, closeTo(always.capsule.height, 0.5));
        expect(selected.capsule.width, closeTo(always.capsule.width, 0.5));
        expect(hidden.capsule.width, greaterThan(hidden.capsule.height * 1.3));
        expect(hidden.capsule.width, lessThan(always.capsule.width));
        _expectContains(always.capsule, always.icon);
        _expectContains(hidden.capsule, hidden.icon);
        _expectContains(selected.capsule, selected.icon);
        expect(
          (hidden.capsule.center.dx - hidden.icon.center.dx).abs(),
          lessThan(0.5),
        );
        final hiddenInset = hidden.icon.left - hidden.capsule.left;
        expect(hiddenInset, greaterThanOrEqualTo(14 - 0.5));
        expect(
          hidden.capsule.right - hidden.icon.right,
          closeTo(hiddenInset, 0.5),
        );
        if (direction == TextDirection.ltr) {
          final label = tester.getRect(find.text(labels[index]));
          _expectContains(selected.capsule, label);
          expect(label.right, lessThanOrEqualTo(selected.capsule.right + 0.5));
          final group = (selected.icon.top + label.bottom) / 2;
          expect(group, closeTo(selected.capsule.center.dy, 1.5));
          expect(selected.capsule.center.dy, closeTo(glass.center.dy, 0.75));
          expect(
            selected.icon.center.dy,
            lessThan(selected.capsule.center.dy - 2),
          );
        }
        if (index == 0 || index == labels.length - 1) {
          final outerOnLeft = direction == TextDirection.ltr
              ? index == 0
              : index != 0;
          final side = outerOnLeft
              ? hidden.capsule.left - glass.left
              : glass.right - hidden.capsule.right;
          expect(side, closeTo(hidden.capsule.top - glass.top, 0.75));
        }
        if (index == 2) {
          expect(hidden.icon.center.dx, closeTo(always.icon.center.dx, 0.5));
          expect(selected.icon.center.dx, closeTo(always.icon.center.dx, 0.5));
        }
      }
    }

    final before = await measure(LiquidGlassLabelMode.always, 2);
    final switched = await measure(LiquidGlassLabelMode.hidden, 2);
    final back = await measure(LiquidGlassLabelMode.selected, 2);
    final switchedGlass = tester.getRect(find.byType(GlassSurface)).center.dy;
    expect(switched.icon.center.dy, closeTo(switchedGlass, 0.75));
    expect(back.icon.center.dy, closeTo(before.icon.center.dy, 0.5));
    expect(switched.icon.center.dx, closeTo(before.icon.center.dx, 0.5));
    expect(back.icon.center.dx, closeTo(before.icon.center.dx, 0.5));

    final selectedHome = await measure(LiquidGlassLabelMode.selected, 0);
    final selectedProfile = await measure(LiquidGlassLabelMode.selected, 4);
    final homeAgain = tester.getRect(find.byIcon(Icons.home_rounded));
    final profileGlass = tester.getRect(find.byType(GlassSurface)).center.dy;
    expect(homeAgain.center.dy, closeTo(profileGlass, 0.75));
    expect(
      tester.getRect(find.byIcon(Icons.person_rounded)).center.dy,
      closeTo(selectedProfile.icon.center.dy, 0.5),
    );
    expect(selectedHome.icon.center.dy, lessThan(profileGlass - 2));

    final large = style.copyWith(iconSize: 32);
    final largeAlways = await measure(
      LiquidGlassLabelMode.always,
      2,
      itemStyle: large,
    );
    final largeHidden = await measure(
      LiquidGlassLabelMode.hidden,
      2,
      itemStyle: large,
    );
    expect(largeHidden.glass, closeTo(largeAlways.glass, 0.5));
    expect(
      largeHidden.icon.center.dy,
      greaterThan(largeAlways.icon.center.dy + 2),
    );
    expect(
      largeHidden.capsule.height,
      lessThan(largeAlways.capsule.height - 4),
    );

    final scaledAlways = await measure(
      LiquidGlassLabelMode.always,
      2,
      textScale: 1.6,
    );
    final scaledHidden = await measure(
      LiquidGlassLabelMode.hidden,
      2,
      textScale: 1.6,
    );
    final scaledSelected = await measure(
      LiquidGlassLabelMode.selected,
      2,
      textScale: 1.6,
    );
    expect(
      scaledHidden.icon.center.dy,
      greaterThan(scaledAlways.icon.center.dy + 2),
    );
    expect(
      scaledSelected.icon.center.dy,
      closeTo(scaledAlways.icon.center.dy, 0.5),
    );
    expect(
      scaledHidden.capsule.height,
      lessThan(scaledAlways.capsule.height - 4),
    );
    expect(
      scaledSelected.capsule.height,
      closeTo(scaledAlways.capsule.height, 0.5),
    );
    _expectContains(scaledSelected.capsule, tester.getRect(find.text('Inbox')));

    final custom = <LiquidGlassNavigationItem>[
      items[0],
      items[1],
      LiquidGlassNavigationItem(
        label: 'Profile',
        child: const SizedBox(key: Key('profile-mark'), width: 28, height: 28),
      ),
    ];
    for (final mode in LiquidGlassLabelMode.values) {
      await pumpNavigationBar(
        tester,
        items: custom,
        currentIndex: 2,
        onIndexChanged: (_) {},
        labelMode: mode,
        style: style,
        surface: const Size(402, 240),
      );
      await tester.pump(const Duration(seconds: 1));
      final child = tester.getRect(find.byKey(const Key('profile-mark')));
      final capsule = _global(
        tester,
        indicatorRender(tester).debugIndicatorRect!,
      );
      _expectContains(capsule, child);
      expect(capsule.center.dx, closeTo(child.center.dx, 0.5));
      if (mode != LiquidGlassLabelMode.hidden) {
        _expectContains(capsule, tester.getRect(find.text('Profile')));
      } else {
        expect(find.text('Profile'), findsNothing);
      }
    }

    final plain = await measure(LiquidGlassLabelMode.hidden, 0);
    final badged = <LiquidGlassNavigationItem>[
      LiquidGlassNavigationItem(
        icon: Icons.home_rounded,
        label: 'Home',
        badge: const LiquidGlassBadge.count(4),
      ),
      ...items.skip(1),
    ];
    final withBadge = await measure(
      LiquidGlassLabelMode.hidden,
      0,
      row: badged,
    );
    expect(withBadge.capsule.width, closeTo(plain.capsule.width, 0.5));
    expect(withBadge.capsule.height, closeTo(plain.capsule.height, 0.5));
    expect(find.text('4'), findsOneWidget);
  });
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
  expect(top, inInclusiveRange(4, 14));
  expect(indicator.width, lessThan(glass.width / 2));
  expect(indicator.width, greaterThan(indicator.height));
}

void _expectContains(Rect outer, Rect inner) {
  expect(outer.left, lessThanOrEqualTo(inner.left + 0.5));
  expect(outer.top, lessThanOrEqualTo(inner.top + 0.5));
  expect(outer.right, greaterThanOrEqualTo(inner.right - 0.5));
  expect(outer.bottom, greaterThanOrEqualTo(inner.bottom - 0.5));
}
