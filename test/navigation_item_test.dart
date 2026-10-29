import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_bottom_navigator/src/item.dart';

import 'harness.dart';

void main() {
  test(
    'semantic label prefers an explicit label, then text, then a tab number',
    () {
      expect(
        liquidGlassItemSemantics(
          const LiquidGlassNavigationItem(
            icon: Icons.person,
            semanticLabel: 'Profile',
          ),
          3,
        ),
        'Profile',
      );
      expect(
        liquidGlassItemSemantics(
          const LiquidGlassNavigationItem(icon: Icons.home, label: 'Home'),
          0,
        ),
        'Home',
      );
      expect(
        liquidGlassItemSemantics(
          const LiquidGlassNavigationItem(icon: Icons.circle),
          1,
        ),
        'Tab 2',
      );
      expect(
        liquidGlassItemSemantics(
          const LiquidGlassNavigationItem(
            icon: Icons.inbox,
            label: 'Inbox',
            badge: LiquidGlassBadge.count(12),
          ),
          0,
        ),
        'Inbox, 12 notifications',
      );
      expect(
        liquidGlassItemSemantics(
          const LiquidGlassNavigationItem(
            icon: Icons.inbox,
            badge: LiquidGlassBadge.count(120),
          ),
          0,
        ),
        'Tab 1, 99 or more notifications',
      );
      expect(
        liquidGlassItemSemantics(
          const LiquidGlassNavigationItem(
            icon: Icons.circle,
            badge: LiquidGlassBadge.dot(),
          ),
          0,
        ),
        'Tab 1, new notification',
      );
      expect(const LiquidGlassBadge.count(0).isVisible, isFalse);
      expect(const LiquidGlassBadge.count(140).displayCount, '99+');
    },
  );

  test('item construction rejects an empty destination', () {
    expect(() => LiquidGlassNavigationItem(), throwsAssertionError);
    expect(
      () => LiquidGlassNavigationItem(label: 'Notes'),
      throwsAssertionError,
    );
    expect(() => LiquidGlassBadge.count(3, maxCount: 0), throwsAssertionError);
  });

  test(
    'motion presets and style defaults stay inside their documented ranges',
    () {
      const spring = LiquidGlassMotion.spring();
      expect(spring.enabled, isTrue);
      expect(spring.morphIntensity, inInclusiveRange(0, 1));
      expect(LiquidGlassMotion.none().enabled, isFalse);
      expect(
        LiquidGlassMotion.snappy().duration.inMilliseconds,
        lessThan(spring.duration.inMilliseconds),
      );
      expect(const LiquidGlassNavigationStyle().blurSigma, greaterThan(0));
      expect(const LiquidGlassNavigationStyle(blurSigma: 0).blurSigma, 0);
      expect(
        LiquidGlassNavigationTheme.light.resolve(ThemeData.light()),
        same(LiquidGlassNavigationTheme.light),
      );
    },
  );

  testWidgets('builds icon, label, custom child, and badge items', (
    tester,
  ) async {
    await pumpNavigationBar(
      tester,
      currentIndex: 0,
      onIndexChanged: (_) {},
      items: <LiquidGlassNavigationItem>[
        const LiquidGlassNavigationItem(icon: Icons.home_rounded),
        const LiquidGlassNavigationItem(
          icon: Icons.search_rounded,
          label: 'Search',
        ),
        const LiquidGlassNavigationItem(
          label: 'Notes',
          child: Icon(Icons.note_alt_outlined),
        ),
        const LiquidGlassNavigationItem(
          child: CircleAvatar(radius: 14, child: Text('A')),
          semanticLabel: 'Profile',
        ),
        const LiquidGlassNavigationItem(
          icon: Icons.inbox_outlined,
          label: 'Inbox',
          badge: LiquidGlassBadge.count(12),
        ),
      ],
    );

    expect(find.byIcon(Icons.home_rounded), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Notes'), findsOneWidget);
    expect(find.byIcon(Icons.note_alt_outlined), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.bySemanticsLabel('Profile'), findsOneWidget);
  });

  testWidgets(
    'hides labels, shows every label, or shows only the selected label',
    (tester) async {
      Future<void> pump(LiquidGlassLabelMode mode) {
        return pumpNavigationBar(
          tester,
          currentIndex: 1,
          onIndexChanged: (_) {},
          labelMode: mode,
          items: sampleItems(),
        );
      }

      await pump(LiquidGlassLabelMode.hidden);
      expect(find.text('Home'), findsNothing);
      expect(find.text('Search'), findsNothing);

      await pump(LiquidGlassLabelMode.always);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
      expect(find.text('Inbox'), findsOneWidget);

      await pump(LiquidGlassLabelMode.selected);
      final homeOpacity = tester.widget<Opacity>(
        find.ancestor(of: find.text('Home'), matching: find.byType(Opacity)),
      );
      final searchOpacity = tester.widget<Opacity>(
        find.ancestor(of: find.text('Search'), matching: find.byType(Opacity)),
      );
      expect(homeOpacity.opacity, 0);
      expect(searchOpacity.opacity, 1);
    },
  );

  testWidgets(
    'empty and single-item bars build, and an invalid index selects nothing',
    (tester) async {
      await pumpNavigationBar(
        tester,
        items: const <LiquidGlassNavigationItem>[],
        currentIndex: 0,
        onIndexChanged: (_) {},
      );
      expect(find.byType(LiquidGlassNavigationBar), findsOneWidget);
      expect(indicatorRender(tester).debugIndicatorRect, isNull);

      var taps = 0;
      await pumpNavigationBar(
        tester,
        items: const <LiquidGlassNavigationItem>[
          LiquidGlassNavigationItem(icon: Icons.home_rounded, label: 'Home'),
        ],
        currentIndex: 0,
        onIndexChanged: (_) => taps++,
      );
      await tester.tap(find.byIcon(Icons.home_rounded));
      expect(taps, 0);

      await pumpNavigationBar(
        tester,
        items: sampleItems(),
        currentIndex: 9,
        onIndexChanged: (_) {},
      );
      expect(indicatorRender(tester).debugIndicatorRect, isNull);
      expect(
        tester
            .getSemantics(find.bySemanticsLabel('Home'))
            .flagsCollection
            .isSelected,
        isNot(Tristate.isTrue),
      );
    },
  );

  testWidgets(
    'count badges cap at 99+ and do not change intrinsic item width',
    (tester) async {
      const style = LiquidGlassNavigationStyle(
        margin: EdgeInsets.zero,
        respectSafeArea: false,
        blurSigma: 0,
        elevation: 0,
        itemLayout: LiquidGlassItemLayout.intrinsic,
        padding: EdgeInsets.zero,
      );
      await pumpNavigationBar(
        tester,
        style: style,
        currentIndex: 0,
        onIndexChanged: (_) {},
        items: const <LiquidGlassNavigationItem>[
          LiquidGlassNavigationItem(icon: Icons.inbox_outlined, label: 'Inbox'),
        ],
      );
      final withoutBadge = indicatorRender(tester).debugItemRects.single.width;

      await pumpNavigationBar(
        tester,
        style: style,
        currentIndex: 0,
        onIndexChanged: (_) {},
        items: const <LiquidGlassNavigationItem>[
          LiquidGlassNavigationItem(
            icon: Icons.inbox_outlined,
            label: 'Inbox',
            badge: LiquidGlassBadge.count(140),
          ),
        ],
      );
      expect(find.text('99+'), findsOneWidget);
      expect(
        indicatorRender(tester).debugItemRects.single.width,
        closeTo(withoutBadge, 0.1),
      );
    },
  );

  testWidgets('a custom badge child is painted without widening the item', (
    tester,
  ) async {
    const style = LiquidGlassNavigationStyle(
      margin: EdgeInsets.zero,
      respectSafeArea: false,
      blurSigma: 0,
      elevation: 0,
      itemLayout: LiquidGlassItemLayout.intrinsic,
      padding: EdgeInsets.zero,
    );
    await pumpNavigationBar(
      tester,
      style: style,
      currentIndex: 0,
      onIndexChanged: (_) {},
      items: const [
        LiquidGlassNavigationItem(
          icon: Icons.circle,
          badge: LiquidGlassBadge.child(Text('!')),
        ),
      ],
    );
    expect(find.text('!'), findsOneWidget);
  });
}
