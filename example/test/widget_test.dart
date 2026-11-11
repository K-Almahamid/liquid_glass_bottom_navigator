import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_bottom_navigator/liquid_glass_bottom_navigator.dart';

import 'package:liquid_glass_bottom_navigator_example/main.dart';

void main() {
  testWidgets(
    'five destinations render and the bar stays put while scrolling',
    (tester) async {
      await tester.pumpWidget(const LiquidGlassExampleApp());
      await tester.pumpAndSettle();

      expect(_title(tester), 'Home');
      expect(find.text('Light on the wall'), findsOneWidget);
      expect(
        find.text('Hold and drag the selected tab to switch destinations.'),
        findsOneWidget,
      );

      final bar = find.byType(LiquidGlassNavigationBar);
      final before = tester.getTopLeft(bar);
      expect(
        tester.widget<LiquidGlassNavigationBar>(bar).enableDragSelection,
        isTrue,
      );
      expect(tester.widget<LiquidGlassNavigationBar>(bar).items, hasLength(5));
      expect(
        tester.widget<LiquidGlassNavigationBar>(bar).items[2].badge?.count,
        4,
      );
      expect(
        tester.widget<LiquidGlassNavigationBar>(bar).items[3].badge?.kind,
        LiquidGlassBadgeKind.dot,
      );
      expect(
        tester.widget<LiquidGlassNavigationBar>(bar).items[4].child,
        isA<CircleAvatar>(),
      );
      expect(tester.widget<LiquidGlassNavigationBar>(bar).style.height, 58);
      expect(
        tester.widget<LiquidGlassNavigationBar>(bar).style.padding,
        const EdgeInsets.all(6),
      );

      final home = scrollableState(tester, const ValueKey('home-scroll'));
      expect(home.position.maxScrollExtent, greaterThan(0));
      await tester.drag(
        find.byKey(const ValueKey('home-scroll')),
        const Offset(0, -280),
      );
      await tester.pumpAndSettle();
      expect(home.position.pixels, greaterThan(40));
      expect(tester.getTopLeft(bar), before);
      expect(_bar(tester).currentIndex, 0);

      await tapTab(tester, find.byIcon(Icons.search_rounded));
      expect(_title(tester), 'Search');
      expect(find.text('Places, notes, messages'), findsOneWidget);
      expect(find.text('Suggestions'), findsOneWidget);
      expect(find.text('Courtyard at dusk'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('search-field')), 'zzzz');
      await tester.pump();
      expect(find.text('No matches'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('search-field')), 'platform');
      await tester.pump();
      expect(find.text('Platform change'), findsOneWidget);
      expect(find.text('No matches'), findsNothing);

      await tapTab(tester, find.byIcon(Icons.inbox_outlined));
      expect(_title(tester), 'Inbox');
      expect(find.text('4 unread'), findsOneWidget);
      expect(find.text('The table by the window'), findsOneWidget);
      expect(find.text('Short list'), findsOneWidget);

      await tapTab(tester, find.byIcon(Icons.bookmark_outline_rounded));
      expect(_title(tester), 'Saved');
      expect(find.text('Bookmarks'), findsOneWidget);

      await tapTab(tester, find.descendant(of: bar, matching: find.text('K')));
      expect(_title(tester), 'Profile');
      expect(find.text('Kai Morgan'), findsWidgets);
      expect(find.text('Quiet hours'), findsOneWidget);

      await tapTab(tester, find.byIcon(Icons.home_rounded));
      final restored = scrollableState(tester, const ValueKey('home-scroll'));
      expect(restored.position.pixels, greaterThan(40));
      restored.position.jumpTo(0);
      await tester.pump();
      expect(_title(tester), 'Home');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('appearance controls close from the back arrow', (tester) async {
    await tester.pumpWidget(const LiquidGlassExampleApp());
    await openAppearance(tester);

    expect(find.text('Appearance'), findsWidgets);
    expect(find.text('Motion'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Layout'),
      200,
      scrollable: appearanceScrollable(tester),
    );
    expect(find.text('Layout'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Appearance'), findsNothing);
    expect(find.text('Motion'), findsNothing);
  });

  testWidgets('appearance controls update the bar', (tester) async {
    await tester.pumpWidget(const LiquidGlassExampleApp());
    await openAppearance(tester);
    final sheet = appearanceScrollable(tester);

    Future<void> reveal(String label) async {
      final finder = find.text(label);
      await tester.scrollUntilVisible(finder, 200, scrollable: sheet);
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
    }

    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('Label mode'), findsOneWidget);
    expect(find.text('Indicator'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('System'), findsOneWidget);
    expect(find.text('Icons only'), findsOneWidget);
    expect(find.text('Selected'), findsOneWidget);
    expect(find.text('Morph'), findsOneWidget);
    expect(find.text('Spring'), findsOneWidget);
    expect(find.text('Snappy'), findsOneWidget);
    expect(find.text('Gentle'), findsOneWidget);

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(LiquidGlassNavigationBar)))
          .brightness,
      Brightness.dark,
    );
    expect(
      Theme.of(tester.element(find.text('Theme'))).brightness,
      Brightness.dark,
    );

    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(LiquidGlassNavigationBar)))
          .brightness,
      Brightness.light,
    );

    await tester.tap(find.text('Slide'));
    await tester.pumpAndSettle();
    expect(_bar(tester).indicatorStyle, LiquidGlassIndicatorStyle.slidingPill);

    await tester.tap(find.text('Icons only'));
    await tester.pumpAndSettle();
    expect(_bar(tester).labelMode, LiquidGlassLabelMode.hidden);

    await tester.tap(find.text('All labels'));
    await tester.pumpAndSettle();
    expect(_bar(tester).labelMode, LiquidGlassLabelMode.always);

    await tester.tap(find.text('None'));
    await tester.pumpAndSettle();
    expect(_bar(tester).motion.enabled, isFalse);

    await reveal('Drag selection');
    expect(find.text('Drag selection'), findsOneWidget);
    await tester.tap(find.text('Drag selection'));
    await tester.pumpAndSettle();
    expect(_bar(tester).enableDragSelection, isFalse);

    await reveal('Haptics');
    await tester.tap(find.text('Haptics'));
    await tester.pumpAndSettle();
    expect(_bar(tester).hapticsEnabled, isFalse);

    await reveal('Reduced motion');
    await tester.tap(find.text('Reduced motion'));
    await tester.pumpAndSettle();
    expect(
      MediaQuery.of(tester.element(find.byType(LiquidGlassNavigationBar)))
          .disableAnimations,
      isTrue,
    );

    await reveal('Equal slots');
    expect(find.text('Equal slots'), findsOneWidget);
    await tester.tap(find.text('Equal slots'));
    await tester.pumpAndSettle();
    expect(_bar(tester).style.itemLayout, LiquidGlassItemLayout.intrinsic);

    await reveal('Compact width');
    await tester.tap(find.text('Compact width'));
    await tester.pumpAndSettle();
    expect(_bar(tester).style.width, 280);

    await reveal('Respect safe area');
    expect(find.text('Respect safe area'), findsOneWidget);
    await tester.tap(find.text('Respect safe area'));
    await tester.pumpAndSettle();
    expect(_bar(tester).style.respectSafeArea, isFalse);

    await reveal('Right to left');
    await tester.tap(find.text('Right to left'));
    await tester.pumpAndSettle();
    expect(
      Directionality.of(tester.element(find.byType(LiquidGlassNavigationBar))),
      TextDirection.rtl,
    );

    await reveal('Labels');
    await tester.tap(find.text('Labels'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(LiquidGlassNavigationBar),
        matching: find.text('Home'),
      ),
      findsNothing,
    );

    await reveal('Items');
    await tester.tap(find.text('Items'));
    await tester.pumpAndSettle();

    await reveal('Height');
    expect(find.text('Blur'), findsOneWidget);
    expect(find.text('Radius'), findsOneWidget);
    expect(find.text('Margin'), findsOneWidget);
    expect(find.text('Padding'), findsOneWidget);
    expect(find.text('Item spacing'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('height-slider')));
    await tester.tap(find.byKey(const Key('height-slider')));
    await tester.pumpAndSettle();
    expect(_bar(tester).style.height, isNot(58));
    expect(find.byType(LiquidGlassNavigationBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('narrow large text does not overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final overflows = <String>[];
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      final message = details.exceptionAsString();
      if (message.contains('overflowed')) {
        overflows.add(message);
      }
      previous?.call(details);
    };
    addTearDown(() => FlutterError.onError = previous);

    await tester.pumpWidget(const LiquidGlassExampleApp());
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const ValueKey('home-scroll')),
      const Offset(0, -120),
    );
    await tester.pumpAndSettle();
    await tapTab(tester, find.byIcon(Icons.search_rounded));
    await tapTab(tester, find.byIcon(Icons.inbox_outlined));
    await tapTab(tester, find.byIcon(Icons.bookmark_outline_rounded));
    await tapTab(
      tester,
      find.descendant(
        of: find.byType(LiquidGlassNavigationBar),
        matching: find.text('K'),
      ),
    );
    expect(_title(tester), 'Profile');
    await openAppearance(tester);
    await tester.scrollUntilVisible(
      find.text('Item spacing'),
      200,
      scrollable: appearanceScrollable(tester),
    );
    await tester.pumpAndSettle();

    expect(overflows, isEmpty);
    expect(tester.takeException(), isNull);
  });
}

String _title(WidgetTester tester) {
  return tester.widget<Text>(find.byKey(const Key('page-title'))).data!;
}

LiquidGlassNavigationBar _bar(WidgetTester tester) {
  return tester.widget<LiquidGlassNavigationBar>(
    find.byType(LiquidGlassNavigationBar),
  );
}

ScrollableState scrollableState(WidgetTester tester, ValueKey<String> key) {
  return tester.state<ScrollableState>(
    find.descendant(of: find.byKey(key), matching: find.byType(Scrollable)),
  );
}

Finder appearanceScrollable(WidgetTester tester) {
  return find.descendant(
    of: find.byKey(const Key('appearance-scroll')),
    matching: find.byType(Scrollable),
  );
}

Future<void> openAppearance(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Open appearance controls'));
  await tester.pumpAndSettle();
}

Future<void> tapTab(WidgetTester tester, Finder finder) async {
  final rect = tester.getRect(finder);
  await tester.tapAt(rect.bottomCenter - const Offset(0, 2));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}
