import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_bottom_navigator/src/collapse_frame.dart';
import 'package:liquid_glass_bottom_navigator/src/glass_surface.dart';

import 'harness.dart';

void main() {
  test('repeated collapse requests notify once', () {
    final controller = LiquidGlassCollapseController();
    var notifications = 0;
    controller.addListener(() => notifications++);
    controller.collapse();
    controller.collapse();
    expect(controller.isCollapsed, isTrue);
    expect(notifications, 1);
    controller.expand();
    controller.expand();
    expect(notifications, 2);
    controller.toggle();
    expect(controller.isCollapsed, isTrue);
    expect(notifications, 3);
    controller.dispose();
  });

  testWidgets('collapse is off by default and keeps the expanded glass', (
    tester,
  ) async {
    await pumpNavigationBar(
      tester,
      items: sampleItems(),
      currentIndex: 0,
      onIndexChanged: (_) {},
    );
    await tester.pumpAndSettle();
    final bar = tester.widget<LiquidGlassNavigationBar>(
      find.byType(LiquidGlassNavigationBar),
    );
    expect(bar.enableCollapse, isFalse);
    expect(find.byType(CollapseFrame), findsNothing);
    expect(find.byType(GlassSurface), findsOneWidget);
    final expanded = tester.getSize(find.byType(GlassSurface));

    final controller = LiquidGlassCollapseController(collapsed: true);
    addTearDown(controller.dispose);
    await pumpNavigationBar(
      tester,
      items: sampleItems(),
      currentIndex: 0,
      onIndexChanged: (_) {},
      collapseController: controller,
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(GlassSurface)), expanded);
    expect(controller.isCollapsed, isTrue);
  });

  testWidgets('programmatic collapse and expand keep the selection', (
    tester,
  ) async {
    final controller = LiquidGlassCollapseController();
    final selections = <int>[];
    addTearDown(controller.dispose);
    await pumpNavigationBar(
      tester,
      items: sampleItems(withBadge: true),
      currentIndex: 2,
      onIndexChanged: selections.add,
      enableCollapse: true,
      collapseController: controller,
      motion: const LiquidGlassMotion.none(),
    );
    await tester.pumpAndSettle();
    final expanded = tester.getSize(find.byType(CollapseFrame));

    controller.collapse();
    await tester.pump();
    final collapsed = tester.getSize(find.byType(CollapseFrame));
    expect(collapsed.width, lessThan(expanded.width));
    expect(collapsed.width, greaterThanOrEqualTo(48));
    expect(collapsed.height, greaterThanOrEqualTo(48));
    expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
    expect(selections, isEmpty);

    await tester.tap(find.byType(CollapseFrame));
    await tester.pump();
    expect(controller.isCollapsed, isFalse);
    expect(tester.getSize(find.byType(CollapseFrame)).width, expanded.width);
    expect(selections, isEmpty);
  });

  testWidgets('a spring collapse passes through a smaller midpoint', (
    tester,
  ) async {
    final controller = LiquidGlassCollapseController();
    addTearDown(controller.dispose);
    await pumpNavigationBar(
      tester,
      items: sampleItems(),
      currentIndex: 1,
      onIndexChanged: (_) {},
      enableCollapse: true,
      collapseController: controller,
    );
    await tester.pumpAndSettle();
    final expanded = tester.getSize(find.byType(CollapseFrame)).width;
    controller.collapse();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 90));
    final mid = tester.getSize(find.byType(CollapseFrame)).width;
    expect(mid, lessThan(expanded));
    expect(mid, greaterThan(48));
    controller.expand();
    await tester.pump(const Duration(milliseconds: 40));
    final reversed = tester.getSize(find.byType(CollapseFrame)).width;
    expect(reversed, isNot(mid));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(CollapseFrame)).width, expanded);
  });

  testWidgets('reduced motion jumps and then stops scheduling frames', (
    tester,
  ) async {
    final controller = LiquidGlassCollapseController();
    addTearDown(controller.dispose);
    await pumpNavigationBar(
      tester,
      items: sampleItems(),
      currentIndex: 0,
      onIndexChanged: (_) {},
      enableCollapse: true,
      collapseController: controller,
      disableAnimations: true,
    );
    await tester.pumpAndSettle();
    controller.collapse();
    await tester.pump();
    final frame = tester.renderObject<RenderCollapseFrame>(
      find.byType(CollapseFrame),
    );
    expect(frame.progress, 1);
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('changing the index while collapsed does not notify', (
    tester,
  ) async {
    final controller = LiquidGlassCollapseController(collapsed: true);
    final selections = <int>[];
    addTearDown(controller.dispose);
    var index = 0;
    Future<void> pump(int next) {
      index = next;
      return pumpNavigationBar(
        tester,
        items: sampleItems(),
        currentIndex: index,
        onIndexChanged: selections.add,
        enableCollapse: true,
        collapseController: controller,
        motion: const LiquidGlassMotion.none(),
      );
    }

    await pump(0);
    await tester.pumpAndSettle();
    await pump(1);
    await tester.pump();
    expect(find.byIcon(Icons.search_rounded), findsWidgets);
    expect(selections, isEmpty);
    expect(controller.isCollapsed, isTrue);
  });

  testWidgets('scroll down collapses and scroll up expands once', (
    tester,
  ) async {
    final controller = LiquidGlassCollapseController();
    var notifications = 0;
    controller.addListener(() => notifications++);
    addTearDown(controller.dispose);
    await _pumpScroll(
      tester,
      controller: controller,
      child: ListView(
        children: [
          for (var i = 0; i < 40; i++)
            SizedBox(height: 36, child: Text('row $i')),
        ],
      ),
    );
    await tester.drag(find.byType(ListView), const Offset(0, -20));
    await tester.pumpAndSettle();
    expect(controller.isCollapsed, isFalse);

    await tester.drag(find.byType(ListView), const Offset(0, -80));
    await tester.pumpAndSettle();
    expect(controller.isCollapsed, isTrue);
    expect(notifications, 1);

    await tester.drag(find.byType(ListView), const Offset(0, -80));
    await tester.pumpAndSettle();
    expect(notifications, 1);

    await tester.drag(find.byType(ListView), const Offset(0, 120));
    await tester.pumpAndSettle();
    expect(controller.isCollapsed, isFalse);
    expect(notifications, 2);
  });

  testWidgets('jitter and horizontal or nested scrolls do not toggle', (
    tester,
  ) async {
    final controller = LiquidGlassCollapseController();
    addTearDown(controller.dispose);
    var seen = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: NotificationListener<ScrollNotification>(
          onNotification: (_) {
            seen++;
            return false;
          },
          child: Scaffold(
            body: Column(
              children: [
                Expanded(
                  child: LiquidGlassScrollObserver(
                    controller: controller,
                    child: ListView(
                      children: [
                        SizedBox(
                          height: 72,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              for (var i = 0; i < 8; i++)
                                const SizedBox(width: 80, child: Text('card')),
                            ],
                          ),
                        ),
                        for (var i = 0; i < 30; i++)
                          SizedBox(height: 40, child: Text('row $i')),
                      ],
                    ),
                  ),
                ),
                _bar(controller),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.text('card').first, const Offset(-120, 0));
    await tester.pumpAndSettle();
    expect(controller.isCollapsed, isFalse);

    await tester.drag(find.byType(ListView).first, const Offset(0, -12));
    await tester.drag(find.byType(ListView).first, const Offset(0, 12));
    await tester.pumpAndSettle();
    expect(controller.isCollapsed, isFalse);
    expect(seen, greaterThan(0));
  });

  testWidgets(
    'a nested vertical list is ignored unless the predicate allows it',
    (tester) async {
      final controller = LiquidGlassCollapseController();
      addTearDown(controller.dispose);
      await _pumpScroll(
        tester,
        controller: controller,
        child: ListView(
          children: [
            SizedBox(
              height: 180,
              child: ListView(
                children: [
                  for (var i = 0; i < 12; i++)
                    SizedBox(height: 40, child: Text('inner $i')),
                ],
              ),
            ),
          ],
        ),
      );
      await tester.drag(find.text('inner 3'), const Offset(0, -100));
      await tester.pumpAndSettle();
      expect(controller.isCollapsed, isFalse);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Expanded(
                  child: LiquidGlassScrollObserver(
                    controller: controller,
                    notificationPredicate: (notification) {
                      return notification.metrics.axis == Axis.vertical &&
                          notification.depth <= 1;
                    },
                    child: ListView(
                      children: [
                        SizedBox(
                          height: 180,
                          child: ListView(
                            children: [
                              for (var i = 0; i < 12; i++)
                                SizedBox(height: 40, child: Text('inner $i')),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _bar(controller),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.drag(find.text('inner 3'), const Offset(0, -100));
      await tester.pumpAndSettle();
      expect(controller.isCollapsed, isTrue);
    },
  );

  testWidgets('jumpTo does not collapse and overscroll does not collapse', (
    tester,
  ) async {
    final controller = LiquidGlassCollapseController();
    final scroll = ScrollController();
    addTearDown(controller.dispose);
    addTearDown(scroll.dispose);
    await _pumpScroll(
      tester,
      controller: controller,
      child: ListView(
        controller: scroll,
        physics: const BouncingScrollPhysics(),
        children: [
          for (var i = 0; i < 40; i++)
            SizedBox(height: 36, child: Text('row $i')),
        ],
      ),
    );
    scroll.jumpTo(180);
    await tester.pumpAndSettle();
    expect(controller.isCollapsed, isFalse);

    await tester.drag(find.byType(ListView), const Offset(0, 80));
    await tester.pumpAndSettle();
    expect(controller.isCollapsed, isFalse);
  });

  testWidgets('RTL collapsed button sits on the leading edge of the row', (
    tester,
  ) async {
    final controller = LiquidGlassCollapseController();
    addTearDown(controller.dispose);
    await pumpNavigationBar(
      tester,
      items: sampleItems(),
      currentIndex: 0,
      onIndexChanged: (_) {},
      enableCollapse: true,
      collapseController: controller,
      textDirection: TextDirection.rtl,
      motion: const LiquidGlassMotion.none(),
      surface: const Size(360, 240),
    );
    await tester.pumpAndSettle();
    controller.collapse();
    await tester.pump();
    final frame = tester.getRect(find.byType(CollapseFrame));
    final host = tester.getRect(
      find.byWidgetPredicate(
        (widget) => widget is Align && widget.heightFactor == 1,
      ),
    );
    expect(frame.left, closeTo(host.left, 1));
    expect(frame.right, lessThan(host.center.dx));
    expect(frame.width, greaterThanOrEqualTo(48));
  });

  testWidgets('a collapse during a drag waits until the drag ends', (
    tester,
  ) async {
    final controller = LiquidGlassCollapseController();
    final selections = <int>[];
    addTearDown(controller.dispose);
    await pumpNavigationBar(
      tester,
      items: sampleItems(),
      currentIndex: 0,
      onIndexChanged: selections.add,
      enableCollapse: true,
      enableDragSelection: true,
      collapseController: controller,
      motion: const LiquidGlassMotion.none(),
    );
    await tester.pumpAndSettle();
    final gesture = await tester.startGesture(
      tester.getCenter(find.byIcon(Icons.home_rounded)),
    );
    await gesture.moveBy(const Offset(80, 0));
    await tester.pump();
    controller.collapse();
    await tester.pump();
    expect(
      tester
          .renderObject<RenderCollapseFrame>(find.byType(CollapseFrame))
          .progress,
      0,
    );
    await gesture.up();
    await tester.pump();
    expect(
      tester
          .renderObject<RenderCollapseFrame>(find.byType(CollapseFrame))
          .progress,
      1,
    );
    expect(selections.length, lessThanOrEqualTo(1));
  });

  testWidgets('replacing the controller detaches the previous one', (
    tester,
  ) async {
    final first = LiquidGlassCollapseController();
    final second = LiquidGlassCollapseController();
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    await pumpNavigationBar(
      tester,
      items: sampleItems(),
      currentIndex: 0,
      onIndexChanged: (_) {},
      enableCollapse: true,
      collapseController: first,
      motion: const LiquidGlassMotion.none(),
    );
    await tester.pumpAndSettle();
    await pumpNavigationBar(
      tester,
      items: sampleItems(),
      currentIndex: 0,
      onIndexChanged: (_) {},
      enableCollapse: true,
      collapseController: second,
      motion: const LiquidGlassMotion.none(),
    );
    await tester.pumpAndSettle();
    first.collapse();
    await tester.pump();
    expect(
      tester
          .renderObject<RenderCollapseFrame>(find.byType(CollapseFrame))
          .progress,
      0,
    );
    second.collapse();
    await tester.pump();
    expect(
      tester
          .renderObject<RenderCollapseFrame>(find.byType(CollapseFrame))
          .progress,
      1,
    );
  });

  testWidgets(
    'collapsed layout keeps the badge, custom child, and hit target',
    (tester) async {
      final controller = LiquidGlassCollapseController(collapsed: true);
      addTearDown(controller.dispose);
      final items = <LiquidGlassNavigationItem>[
        LiquidGlassNavigationItem(
          icon: Icons.home_rounded,
          label: 'Home with a very long label that must stay clipped',
        ),
        LiquidGlassNavigationItem(
          icon: Icons.inbox_outlined,
          label: 'Inbox',
          badge: const LiquidGlassBadge.count(4),
        ),
        LiquidGlassNavigationItem(
          label: 'Profile',
          child: const CircleAvatar(radius: 14, child: Text('K')),
        ),
      ];
      for (final mode in LiquidGlassLabelMode.values) {
        await pumpNavigationBar(
          tester,
          items: items,
          currentIndex: 1,
          onIndexChanged: (_) {},
          enableCollapse: true,
          collapseController: controller,
          labelMode: mode,
          motion: const LiquidGlassMotion.none(),
          surface: const Size(200, 320),
          padding: const EdgeInsets.only(bottom: 20),
          style: testStyle.copyWith(
            respectSafeArea: true,
            margin: EdgeInsets.zero,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final frame = tester.getRect(find.byType(CollapseFrame));
        expect(frame.width, greaterThanOrEqualTo(48));
        expect(frame.height, greaterThanOrEqualTo(48));
        final screen = tester.getSize(find.byType(Scaffold));
        expect(frame.bottom, closeTo(screen.height - 20, 1));
        expect(find.text('4'), findsOneWidget);
      }

      await pumpNavigationBar(
        tester,
        items: items,
        currentIndex: 2,
        onIndexChanged: (_) {},
        enableCollapse: true,
        collapseController: controller,
        motion: const LiquidGlassMotion.none(),
      );
      await tester.pump();
      expect(find.text('K'), findsOneWidget);
      final frame = tester.getRect(find.byType(CollapseFrame));
      final host = tester.getRect(
        find.byWidgetPredicate(
          (widget) => widget is Align && widget.heightFactor == 1,
        ),
      );
      await tester.tapAt(Offset(host.left + 4, frame.center.dy));
      await tester.pump();
      expect(controller.isCollapsed, isTrue);
      await tester.tapAt(frame.center);
      await tester.pump();
      expect(controller.isCollapsed, isFalse);
    },
  );

  testWidgets('a theme change and a rejected tap do not restart selection', (
    tester,
  ) async {
    final controller = LiquidGlassCollapseController();
    final selections = <int>[];
    addTearDown(controller.dispose);
    await pumpNavigationBar(
      tester,
      items: sampleItems(),
      currentIndex: 0,
      onIndexChanged: selections.add,
      enableCollapse: true,
      collapseController: controller,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.search_rounded));
    await tester.pump();
    expect(selections, [1]);
    controller.collapse();
    await tester.pump(const Duration(milliseconds: 50));
    await pumpNavigationBar(
      tester,
      items: sampleItems(),
      currentIndex: 0,
      onIndexChanged: selections.add,
      enableCollapse: true,
      collapseController: controller,
      themeData: ThemeData(brightness: Brightness.dark, useMaterial3: true),
    );
    await tester.pumpAndSettle();
    expect(controller.isCollapsed, isTrue);
    expect(selections, [1]);
    expect(find.byIcon(Icons.home_rounded), findsWidgets);
  });

  testWidgets('the bar does not dispose a caller-owned controller', (
    tester,
  ) async {
    final controller = LiquidGlassCollapseController();
    await pumpNavigationBar(
      tester,
      items: sampleItems(),
      currentIndex: 0,
      onIndexChanged: (_) {},
      enableCollapse: true,
      collapseController: controller,
      motion: const LiquidGlassMotion.none(),
    );
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    controller.collapse();
    expect(controller.isCollapsed, isTrue);
    controller.dispose();
  });

  testWidgets('disposing during collapse leaves no ticker', (tester) async {
    final controller = LiquidGlassCollapseController();
    addTearDown(controller.dispose);
    await pumpNavigationBar(
      tester,
      items: sampleItems(),
      currentIndex: 0,
      onIndexChanged: (_) {},
      enableCollapse: true,
      collapseController: controller,
    );
    await tester.pumpAndSettle();
    controller.collapse();
    await tester.pump(const Duration(milliseconds: 40));
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
    expect(tester.binding.transientCallbackCount, 0);
  });
}

Widget _bar(LiquidGlassCollapseController controller) {
  return LiquidGlassNavigationBar(
    enableCollapse: true,
    collapseController: controller,
    currentIndex: 0,
    onIndexChanged: (_) {},
    motion: const LiquidGlassMotion.none(),
    style: testStyle,
    items: sampleItems(),
  );
}

Future<void> _pumpScroll(
  WidgetTester tester, {
  required LiquidGlassCollapseController controller,
  required Widget child,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            Expanded(
              child: LiquidGlassScrollObserver(
                controller: controller,
                child: child,
              ),
            ),
            _bar(controller),
          ],
        ),
      ),
    ),
  );
}
