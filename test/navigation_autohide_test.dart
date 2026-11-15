import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_bottom_navigator/src/glass_surface.dart';
import 'package:liquid_glass_bottom_navigator/src/hide_slide.dart';

import 'harness.dart';

void main() {
  test('repeated hide requests notify once', () {
    final controller = LiquidGlassVisibilityController();
    var notifications = 0;
    controller.addListener(() => notifications++);
    controller.hide();
    controller.hide();
    expect(controller.isHidden, isTrue);
    expect(notifications, 1);
    controller.show();
    controller.toggle();
    expect(controller.isHidden, isTrue);
    expect(notifications, 3);
    controller.dispose();
  });

  testWidgets('auto-hide is off by default and keeps the resting glass', (
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
    expect(bar.enableScrollAutoHide, isFalse);
    expect(find.byType(HideSlide), findsNothing);
    final resting = tester.getSize(find.byType(GlassSurface));

    final controller = LiquidGlassVisibilityController(hidden: true);
    addTearDown(controller.dispose);
    await pumpNavigationBar(
      tester,
      items: sampleItems(),
      currentIndex: 0,
      onIndexChanged: (_) {},
      visibilityController: controller,
    );
    await tester.pumpAndSettle();
    expect(controller.isHidden, isTrue);
    expect(tester.getSize(find.byType(GlassSurface)), resting);
    expect(find.byType(HideSlide), findsNothing);
  });

  testWidgets('hiding keeps the layout and moves the bar off the view', (
    tester,
  ) async {
    final controller = LiquidGlassVisibilityController();
    final selections = <int>[];
    addTearDown(controller.dispose);
    await pumpNavigationBar(
      tester,
      items: sampleItems(),
      currentIndex: 0,
      onIndexChanged: selections.add,
      enableScrollAutoHide: true,
      visibilityController: controller,
      motion: const LiquidGlassMotion.none(),
    );
    await tester.pumpAndSettle();
    final visible = tester.getSize(find.byType(GlassSurface));
    controller.hide();
    await tester.pump();
    expect(tester.getSize(find.byType(GlassSurface)), visible);
    expect(selections, isEmpty);
    final slide = tester.renderObject<RenderHideSlide>(find.byType(HideSlide));
    expect(slide.animation.value, 1);
    final box = tester.getRect(find.byType(HideSlide));
    final viewport =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    expect(box.top + slide.debugTravel, greaterThanOrEqualTo(viewport - 0.5));
    await tester.tapAt(tester.getCenter(find.byIcon(Icons.search_rounded)));
    await tester.pump();
    expect(selections, isEmpty);
  });

  testWidgets('a hide reverses from its current travel', (tester) async {
    final controller = LiquidGlassVisibilityController();
    addTearDown(controller.dispose);
    await pumpNavigationBar(
      tester,
      items: sampleItems(),
      currentIndex: 0,
      onIndexChanged: (_) {},
      enableScrollAutoHide: true,
      visibilityController: controller,
    );
    await tester.pumpAndSettle();
    controller.hide();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    final mid = tester.renderObject<RenderHideSlide>(find.byType(HideSlide));
    expect(mid.animation.value, greaterThan(0));
    expect(mid.animation.value, lessThan(1));
    final going = mid.debugTravel;
    controller.show();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    final back = tester.renderObject<RenderHideSlide>(find.byType(HideSlide));
    expect(back.debugTravel, lessThan(going));
    expect(back.animation.value, greaterThan(0));
    await tester.pumpAndSettle();
    expect(back.animation.value, 0);
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('show reverses into a hide without a jump', (tester) async {
    final controller = LiquidGlassVisibilityController();
    addTearDown(controller.dispose);
    await pumpNavigationBar(
      tester,
      items: sampleItems(),
      currentIndex: 1,
      onIndexChanged: (_) {},
      enableScrollAutoHide: true,
      visibilityController: controller,
      motion: const LiquidGlassMotion.none(),
    );
    await tester.pumpAndSettle();
    controller.hide();
    await tester.pump();
    await pumpNavigationBar(
      tester,
      items: sampleItems(),
      currentIndex: 1,
      onIndexChanged: (_) {},
      enableScrollAutoHide: true,
      visibilityController: controller,
    );
    await tester.pump();
    controller.show();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    final showing = tester.renderObject<RenderHideSlide>(
      find.byType(HideSlide),
    );
    expect(showing.animation.value, greaterThan(0));
    expect(showing.animation.value, lessThan(1));
    final shownTravel = showing.debugTravel;
    controller.hide();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(
      tester.renderObject<RenderHideSlide>(find.byType(HideSlide)).debugTravel,
      greaterThan(shownTravel),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .renderObject<RenderHideSlide>(find.byType(HideSlide))
          .animation
          .value,
      1,
    );
  });

  testWidgets('reduced motion jumps and then stays idle', (tester) async {
    final controller = LiquidGlassVisibilityController();
    addTearDown(controller.dispose);
    await pumpNavigationBar(
      tester,
      items: sampleItems(),
      currentIndex: 0,
      onIndexChanged: (_) {},
      enableScrollAutoHide: true,
      visibilityController: controller,
      disableAnimations: true,
    );
    await tester.pumpAndSettle();
    controller.hide();
    await tester.pump();
    expect(
      tester
          .renderObject<RenderHideSlide>(find.byType(HideSlide))
          .animation
          .value,
      1,
    );
    expect(tester.binding.transientCallbackCount, 0);
    final handle = tester.ensureSemantics();
    final root =
        tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!;
    root.visitChildren((SemanticsNode node) {
      _expectLabelAbsent(node, 'Home');
      return true;
    });
    handle.dispose();
  });

  testWidgets('changing the index while hidden does not notify', (
    tester,
  ) async {
    final controller = LiquidGlassVisibilityController(hidden: true);
    final selections = <int>[];
    addTearDown(controller.dispose);
    await pumpNavigationBar(
      tester,
      items: sampleItems(),
      currentIndex: 0,
      onIndexChanged: selections.add,
      enableScrollAutoHide: true,
      visibilityController: controller,
      motion: const LiquidGlassMotion.none(),
    );
    await tester.pump();
    await pumpNavigationBar(
      tester,
      items: sampleItems(),
      currentIndex: 2,
      onIndexChanged: selections.add,
      enableScrollAutoHide: true,
      visibilityController: controller,
      motion: const LiquidGlassMotion.none(),
    );
    await tester.pump();
    expect(selections, isEmpty);
    expect(controller.isHidden, isTrue);
  });

  testWidgets('scroll down hides and scroll up shows once', (tester) async {
    final controller = LiquidGlassVisibilityController();
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
    expect(controller.isHidden, isFalse);

    await tester.drag(find.byType(ListView), const Offset(0, -80));
    await tester.pumpAndSettle();
    expect(controller.isHidden, isTrue);
    expect(notifications, 1);

    await tester.drag(find.byType(ListView), const Offset(0, -80));
    await tester.pumpAndSettle();
    expect(notifications, 1);

    await tester.drag(find.byType(ListView), const Offset(0, 40));
    await tester.pumpAndSettle();
    expect(controller.isHidden, isFalse);
    expect(notifications, 2);
  });

  testWidgets('upward scrolling shows with less movement than a hide', (
    tester,
  ) async {
    final controller = LiquidGlassVisibilityController();
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
    await tester.drag(find.byType(ListView), const Offset(0, -30));
    await tester.pumpAndSettle();
    expect(controller.isHidden, isFalse);
    await tester.drag(find.byType(ListView), const Offset(0, -80));
    await tester.pumpAndSettle();
    expect(controller.isHidden, isTrue);
    await tester.drag(find.byType(ListView), const Offset(0, 20));
    await tester.pumpAndSettle();
    expect(controller.isHidden, isFalse);
  });

  testWidgets('jitter and horizontal or nested scrolls do not toggle', (
    tester,
  ) async {
    final controller = LiquidGlassVisibilityController();
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
    expect(controller.isHidden, isFalse);

    await tester.drag(find.byType(ListView).first, const Offset(0, -12));
    await tester.drag(find.byType(ListView).first, const Offset(0, 12));
    await tester.pumpAndSettle();
    expect(controller.isHidden, isFalse);
    expect(seen, greaterThan(0));
  });

  testWidgets(
    'a nested vertical list is ignored unless the predicate allows it',
    (tester) async {
      final controller = LiquidGlassVisibilityController();
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
      expect(controller.isHidden, isFalse);

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
      expect(controller.isHidden, isTrue);
    },
  );

  testWidgets('jumpTo and top overscroll do not hide', (tester) async {
    final controller = LiquidGlassVisibilityController();
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
    expect(controller.isHidden, isFalse);
    final animation = scroll.animateTo(
      40,
      duration: const Duration(milliseconds: 200),
      curve: Curves.linear,
    );
    await tester.pumpAndSettle();
    await animation;
    expect(controller.isHidden, isFalse);

    scroll.jumpTo(0);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, 80));
    await tester.pumpAndSettle();
    expect(controller.isHidden, isFalse);
  });

  testWidgets('only the active page observer drives visibility', (
    tester,
  ) async {
    final controller = LiquidGlassVisibilityController();
    addTearDown(controller.dispose);
    var page = 0;
    Future<void> pumpPage() {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Expanded(
                  child: IndexedStack(
                    index: page,
                    children: [
                      LiquidGlassScrollObserver(
                        controller: controller,
                        child: ListView(
                          children: [
                            for (var i = 0; i < 30; i++)
                              SizedBox(height: 40, child: Text('active $i')),
                          ],
                        ),
                      ),
                      ListView(
                        children: [
                          for (var i = 0; i < 30; i++)
                            SizedBox(height: 40, child: Text('quiet $i')),
                        ],
                      ),
                    ],
                  ),
                ),
                _bar(controller),
              ],
            ),
          ),
        ),
      );
    }

    await pumpPage();
    await tester.pumpAndSettle();
    page = 1;
    await pumpPage();
    await tester.pumpAndSettle();
    await tester.drag(find.text('quiet 4'), const Offset(0, -120));
    await tester.pumpAndSettle();
    expect(controller.isHidden, isFalse);
    page = 0;
    await pumpPage();
    await tester.pumpAndSettle();
    await tester.drag(find.text('active 4'), const Offset(0, -120));
    await tester.pumpAndSettle();
    expect(controller.isHidden, isTrue);
  });

  testWidgets('RTL, text scale, and surface sizes keep one full bar', (
    tester,
  ) async {
    final controller = LiquidGlassVisibilityController();
    addTearDown(controller.dispose);
    for (final surface in const <Size>[
      Size(320, 480),
      Size(800, 400),
      Size(360, 240),
    ]) {
      await pumpNavigationBar(
        tester,
        items: sampleItems(withBadge: true),
        currentIndex: 2,
        onIndexChanged: (_) {},
        enableScrollAutoHide: true,
        visibilityController: controller,
        textDirection: TextDirection.rtl,
        textScale: 1.6,
        surface: surface,
        motion: const LiquidGlassMotion.none(),
      );
      await tester.pumpAndSettle();
      final width = tester.getSize(find.byType(GlassSurface)).width;
      controller.hide();
      await tester.pump();
      expect(tester.getSize(find.byType(GlassSurface)).width, width);
      expect(tester.takeException(), isNull);
      controller.show();
      await tester.pump();
    }
  });

  testWidgets('label modes, badges, and custom children stay in the bar', (
    tester,
  ) async {
    final controller = LiquidGlassVisibilityController();
    addTearDown(controller.dispose);
    final items = <LiquidGlassNavigationItem>[
      const LiquidGlassNavigationItem(icon: Icons.home_rounded, label: 'Home'),
      const LiquidGlassNavigationItem(
        icon: Icons.inbox_outlined,
        label: 'Inbox',
        badge: LiquidGlassBadge.count(4),
      ),
      const LiquidGlassNavigationItem(
        label: 'Profile',
        child: CircleAvatar(radius: 14, child: Text('K')),
      ),
    ];
    for (final mode in LiquidGlassLabelMode.values) {
      await pumpNavigationBar(
        tester,
        items: items,
        currentIndex: 1,
        onIndexChanged: (_) {},
        enableScrollAutoHide: true,
        visibilityController: controller,
        labelMode: mode,
        motion: const LiquidGlassMotion.none(),
        padding: const EdgeInsets.only(bottom: 20),
        style: testStyle.copyWith(respectSafeArea: true),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('4'), findsOneWidget);
      expect(tester.getSize(find.byType(GlassSurface)).width, greaterThan(48));
    }
    await pumpNavigationBar(
      tester,
      items: items,
      currentIndex: 2,
      onIndexChanged: (_) {},
      enableScrollAutoHide: true,
      visibilityController: controller,
      motion: const LiquidGlassMotion.none(),
    );
    await tester.pump();
    expect(find.text('K'), findsOneWidget);
  });

  testWidgets('a hidden bar does not block the content under it', (
    tester,
  ) async {
    final controller = LiquidGlassVisibilityController();
    var taps = 0;
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Align(
                alignment: Alignment.bottomCenter,
                child: TextButton(
                  onPressed: () => taps++,
                  child: const Text('Under'),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: LiquidGlassNavigationBar(
                  enableScrollAutoHide: true,
                  visibilityController: controller,
                  currentIndex: 0,
                  onIndexChanged: (_) {},
                  motion: const LiquidGlassMotion.none(),
                  style: testStyle,
                  items: sampleItems(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    controller.hide();
    await tester.pump();
    await tester.tap(find.text('Under'));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('a hide during a drag waits until the drag ends', (tester) async {
    final controller = LiquidGlassVisibilityController();
    final selections = <int>[];
    addTearDown(controller.dispose);
    await pumpNavigationBar(
      tester,
      items: sampleItems(),
      currentIndex: 0,
      onIndexChanged: selections.add,
      enableScrollAutoHide: true,
      enableDragSelection: true,
      visibilityController: controller,
      motion: const LiquidGlassMotion.none(),
    );
    await tester.pumpAndSettle();
    final gesture = await tester.startGesture(
      tester.getCenter(find.byIcon(Icons.home_rounded)),
    );
    await gesture.moveBy(const Offset(80, 0));
    await tester.pump();
    controller.hide();
    await tester.pump();
    expect(
      tester
          .renderObject<RenderHideSlide>(find.byType(HideSlide))
          .animation
          .value,
      0,
    );
    await gesture.up();
    await tester.pump();
    expect(
      tester
          .renderObject<RenderHideSlide>(find.byType(HideSlide))
          .animation
          .value,
      1,
    );
    expect(selections.length, lessThanOrEqualTo(1));
  });

  testWidgets('replacing the controller detaches the previous one', (
    tester,
  ) async {
    final first = LiquidGlassVisibilityController();
    final second = LiquidGlassVisibilityController();
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    await pumpNavigationBar(
      tester,
      items: sampleItems(),
      currentIndex: 0,
      onIndexChanged: (_) {},
      enableScrollAutoHide: true,
      visibilityController: first,
      motion: const LiquidGlassMotion.none(),
    );
    await tester.pumpAndSettle();
    await pumpNavigationBar(
      tester,
      items: sampleItems(),
      currentIndex: 0,
      onIndexChanged: (_) {},
      enableScrollAutoHide: true,
      visibilityController: second,
      motion: const LiquidGlassMotion.none(),
    );
    await tester.pumpAndSettle();
    first.hide();
    await tester.pump();
    expect(
      tester
          .renderObject<RenderHideSlide>(find.byType(HideSlide))
          .animation
          .value,
      0,
    );
    second.hide();
    await tester.pump();
    expect(
      tester
          .renderObject<RenderHideSlide>(find.byType(HideSlide))
          .animation
          .value,
      1,
    );
  });

  testWidgets('a theme change and a rejected tap do not restart selection', (
    tester,
  ) async {
    final controller = LiquidGlassVisibilityController();
    final selections = <int>[];
    addTearDown(controller.dispose);
    await pumpNavigationBar(
      tester,
      items: sampleItems(),
      currentIndex: 0,
      onIndexChanged: selections.add,
      enableScrollAutoHide: true,
      visibilityController: controller,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.search_rounded));
    await tester.pump();
    expect(selections, [1]);
    controller.hide();
    await tester.pump(const Duration(milliseconds: 50));
    await pumpNavigationBar(
      tester,
      items: sampleItems(),
      currentIndex: 0,
      onIndexChanged: selections.add,
      enableScrollAutoHide: true,
      visibilityController: controller,
      themeData: ThemeData(brightness: Brightness.dark, useMaterial3: true),
    );
    await tester.pumpAndSettle();
    expect(controller.isHidden, isTrue);
    expect(selections, [1]);
    expect(find.byIcon(Icons.home_rounded), findsWidgets);
  });

  testWidgets('the bar does not dispose a caller-owned controller', (
    tester,
  ) async {
    final controller = LiquidGlassVisibilityController();
    await pumpNavigationBar(
      tester,
      items: sampleItems(),
      currentIndex: 0,
      onIndexChanged: (_) {},
      enableScrollAutoHide: true,
      visibilityController: controller,
      motion: const LiquidGlassMotion.none(),
    );
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    controller.hide();
    expect(controller.isHidden, isTrue);
    controller.dispose();
  });

  testWidgets('disposing during a hide or a drag leaves no ticker', (
    tester,
  ) async {
    final controller = LiquidGlassVisibilityController();
    addTearDown(controller.dispose);
    await pumpNavigationBar(
      tester,
      items: sampleItems(),
      currentIndex: 0,
      onIndexChanged: (_) {},
      enableScrollAutoHide: true,
      enableDragSelection: true,
      visibilityController: controller,
    );
    await tester.pumpAndSettle();
    final gesture = await tester.startGesture(
      tester.getCenter(find.byIcon(Icons.home_rounded)),
    );
    await gesture.moveBy(const Offset(40, 0));
    controller.hide();
    await tester.pump(const Duration(milliseconds: 30));
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
    expect(tester.binding.transientCallbackCount, 0);
    await gesture.up();
  });

  testWidgets('a disabled observer does not change visibility', (tester) async {
    final controller = LiquidGlassVisibilityController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LiquidGlassScrollObserver(
            controller: controller,
            enabled: false,
            child: ListView(
              children: [
                for (var i = 0; i < 30; i++)
                  SizedBox(height: 40, child: Text('row $i')),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -160));
    await tester.pumpAndSettle();
    expect(controller.isHidden, isFalse);
  });
}

void _expectLabelAbsent(SemanticsNode node, String label) {
  expect(node.label, isNot(label));
  node.visitChildren((SemanticsNode child) {
    _expectLabelAbsent(child, label);
    return true;
  });
}

Widget _bar(LiquidGlassVisibilityController controller) {
  return LiquidGlassNavigationBar(
    enableScrollAutoHide: true,
    visibilityController: controller,
    currentIndex: 0,
    onIndexChanged: (_) {},
    motion: const LiquidGlassMotion.none(),
    style: testStyle,
    items: sampleItems(),
  );
}

Future<void> _pumpScroll(
  WidgetTester tester, {
  required LiquidGlassVisibilityController controller,
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
