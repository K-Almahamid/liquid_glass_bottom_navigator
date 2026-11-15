import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_bottom_navigator/src/collapse_morph.dart';
import 'package:liquid_glass_bottom_navigator/src/navigation_layout.dart';

import 'harness.dart';

void main() {
  test('repeated collapse requests notify once', () {
    final controller = LiquidGlassCollapseController();
    var notices = 0;
    controller.addListener(() => notices++);
    controller.collapse();
    controller.collapse();
    expect(controller.isCollapsed, isTrue);
    expect(notices, 1);
    controller.expand();
    expect(notices, 2);
    controller.dispose();
  });

  testWidgets('collapse is off by default and keeps the resting glass', (
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
    expect(bar.enableScrollCollapse, isFalse);
    expect(find.byType(CollapseMorph), findsNothing);
  });

  testWidgets('a collapsed controller is ignored while the flag is off', (
    tester,
  ) async {
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
    expect(find.byType(CollapseMorph), findsNothing);
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('collapse keeps the layout and shrinks the glass', (
    tester,
  ) async {
    final controller = LiquidGlassCollapseController();
    addTearDown(controller.dispose);
    await pumpNavigationBar(
      tester,
      items: sampleItems(),
      currentIndex: 0,
      onIndexChanged: (_) {},
      enableScrollCollapse: true,
      collapseController: controller,
      motion: const LiquidGlassMotion.none(),
    );
    await tester.pumpAndSettle();
    final morph = tester.renderObject<RenderCollapseMorph>(
      find.byType(CollapseMorph),
    );
    final expanded = morph.size;
    expect(morph.debugVisual, Offset.zero & expanded);
    controller.collapse();
    await tester.pump();
    expect(morph.size, expanded);
    expect(morph.debugVisual.width, lessThan(expanded.width - 40));
    expect(morph.debugVisual.height, greaterThanOrEqualTo(48));
    expect(morph.debugVisual.right, closeTo(expanded.width, 0.1));
    expect(morph.debugVisual.bottom, closeTo(expanded.height, 0.1));
    final paintedMorph = tester.renderObject<RenderCollapseMorph>(
      find.byType(CollapseMorph),
    );
    final icon = tester.getCenter(find.byIcon(Icons.home_rounded));
    final origin = tester.getTopLeft(find.byType(CollapseMorph));
    final center = origin + paintedMorph.debugVisual.center;
    expect((icon - center).distance, lessThan(12));
    expect(paintedMorph.debugShift.distance, greaterThan(20));
    expect(paintedMorph.debugProgress, 1);
  });

  testWidgets('a collapse reverses from its current shape', (tester) async {
    final controller = LiquidGlassCollapseController();
    addTearDown(controller.dispose);
    await pumpNavigationBar(
      tester,
      items: sampleItems(),
      currentIndex: 0,
      onIndexChanged: (_) {},
      enableScrollCollapse: true,
      collapseController: controller,
    );
    await tester.pumpAndSettle();
    controller.collapse();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    final mid = tester
        .renderObject<RenderCollapseMorph>(find.byType(CollapseMorph))
        .debugVisual
        .width;
    final full = tester
        .renderObject<RenderCollapseMorph>(find.byType(CollapseMorph))
        .size
        .width;
    expect(mid, greaterThan(48));
    expect(mid, lessThan(full - 8));
    controller.expand();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    final back = tester
        .renderObject<RenderCollapseMorph>(find.byType(CollapseMorph))
        .debugVisual
        .width;
    expect(back, greaterThan(mid));
    await tester.pumpAndSettle();
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('reduced motion jumps and then stays idle', (tester) async {
    final controller = LiquidGlassCollapseController();
    addTearDown(controller.dispose);
    await pumpNavigationBar(
      tester,
      items: sampleItems(),
      currentIndex: 0,
      onIndexChanged: (_) {},
      enableScrollCollapse: true,
      collapseController: controller,
      disableAnimations: true,
    );
    await tester.pumpAndSettle();
    controller.collapse();
    await tester.pump();
    final morph = tester.renderObject<RenderCollapseMorph>(
      find.byType(CollapseMorph),
    );
    expect(morph.debugVisual.width, lessThan(morph.size.width - 40));
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('scroll down collapses and scroll up expands once', (
    tester,
  ) async {
    final controller = LiquidGlassCollapseController();
    addTearDown(controller.dispose);
    var notices = 0;
    controller.addListener(() => notices++);
    await _pumpScroll(
      tester,
      controller: controller,
      child: ListView(
        children: [
          for (var i = 0; i < 40; i++)
            SizedBox(height: 48, child: Text('row $i')),
        ],
      ),
    );
    await tester.pumpAndSettle();
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(ListView)),
    );
    await gesture.moveBy(const Offset(0, -8));
    await tester.pump();
    expect(controller.isCollapsed, isFalse);
    await gesture.moveBy(const Offset(0, -16));
    await tester.pump();
    expect(controller.isCollapsed, isTrue);
    expect(notices, 1);
    await gesture.moveBy(const Offset(0, -30));
    await tester.pump();
    expect(notices, 1);
    await gesture.moveBy(const Offset(0, 16));
    await tester.pump();
    expect(controller.isCollapsed, isFalse);
    expect(notices, 2);
    await gesture.up();
  });

  testWidgets('upward scrolling expands with less movement than a collapse', (
    tester,
  ) async {
    final controller = LiquidGlassCollapseController();
    addTearDown(controller.dispose);
    await _pumpScroll(
      tester,
      controller: controller,
      child: ListView(
        children: [
          for (var i = 0; i < 40; i++) SizedBox(height: 48, child: Text('$i')),
        ],
      ),
    );
    await tester.pumpAndSettle();
    final down = await tester.startGesture(
      tester.getCenter(find.byType(ListView)),
    );
    await down.moveBy(const Offset(0, -48));
    await tester.pump();
    expect(controller.isCollapsed, isTrue);
    await down.up();
    await tester.pump();
    final up = await tester.startGesture(
      tester.getCenter(find.byType(ListView)),
    );
    await up.moveBy(const Offset(0, 2));
    await tester.pump();
    expect(controller.isCollapsed, isTrue);
    await up.moveBy(const Offset(0, 8));
    await tester.pump();
    expect(controller.isCollapsed, isFalse);
    await up.up();
  });

  testWidgets('horizontal and nested scrolls do not collapse', (tester) async {
    final controller = LiquidGlassCollapseController();
    addTearDown(controller.dispose);
    await _pumpScroll(
      tester,
      controller: controller,
      child: ListView(
        children: [
          SizedBox(
            height: 80,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (var i = 0; i < 8; i++)
                  const SizedBox(width: 120, child: Text('side')),
              ],
            ),
          ),
          for (var i = 0; i < 20; i++)
            SizedBox(height: 40, child: Text('row $i')),
        ],
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).last, const Offset(-180, 0));
    await tester.pumpAndSettle();
    expect(controller.isCollapsed, isFalse);
  });

  testWidgets('jumpTo does not collapse and the top expands', (tester) async {
    final controller = LiquidGlassCollapseController();
    addTearDown(controller.dispose);
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    await _pumpScroll(
      tester,
      controller: controller,
      child: ListView(
        controller: scroll,
        children: [
          for (var i = 0; i < 40; i++) SizedBox(height: 48, child: Text('$i')),
        ],
      ),
    );
    await tester.pumpAndSettle();
    scroll.jumpTo(400);
    await tester.pumpAndSettle();
    expect(controller.isCollapsed, isFalse);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(ListView)),
    );
    await gesture.moveBy(const Offset(0, -80));
    await tester.pump();
    expect(controller.isCollapsed, isTrue);
    await gesture.up();
    await tester.pumpAndSettle();
    final back = scroll.animateTo(
      0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.linear,
    );
    await tester.pumpAndSettle();
    await back;
    expect(controller.isCollapsed, isTrue);
    final parked = scroll.animateTo(
      24,
      duration: const Duration(milliseconds: 50),
      curve: Curves.linear,
    );
    await tester.pumpAndSettle();
    await parked;
    expect(controller.isCollapsed, isTrue);
    final home = await tester.startGesture(
      tester.getCenter(find.byType(ListView)),
    );
    await home.moveBy(const Offset(0, 40));
    await tester.pump();
    expect(controller.isCollapsed, isFalse);
    await home.up();
  });

  testWidgets('only the active page observer drives collapse', (tester) async {
    final controller = LiquidGlassCollapseController();
    addTearDown(controller.dispose);
    var active = 0;
    final idle = ScrollController();
    addTearDown(idle.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                children: [
                  TextButton(
                    onPressed: () => setState(() => active = 1),
                    child: const Text('switch'),
                  ),
                  Expanded(
                    child: IndexedStack(
                      index: active,
                      children: [
                        LiquidGlassScrollObserver(
                          controller: controller,
                          enabled: active == 0,
                          child: ListView(
                            controller: idle,
                            children: [
                              for (var i = 0; i < 30; i++)
                                SizedBox(height: 40, child: Text('idle $i')),
                            ],
                          ),
                        ),
                        LiquidGlassScrollObserver(
                          controller: controller,
                          enabled: active == 1,
                          child: ListView(
                            children: [
                              for (var i = 0; i < 30; i++)
                                SizedBox(height: 40, child: Text('live $i')),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('switch'));
    await tester.pumpAndSettle();
    idle.jumpTo(400);
    await tester.pumpAndSettle();
    expect(controller.isCollapsed, isFalse);
    await tester.drag(find.text('live 4'), const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(controller.isCollapsed, isTrue);
  });

  testWidgets('RTL parks the compact button on the trailing edge', (
    tester,
  ) async {
    final controller = LiquidGlassCollapseController(collapsed: true);
    addTearDown(controller.dispose);
    await pumpNavigationBar(
      tester,
      items: sampleItems(),
      currentIndex: 0,
      onIndexChanged: (_) {},
      enableScrollCollapse: true,
      collapseController: controller,
      motion: const LiquidGlassMotion.none(),
      textDirection: TextDirection.rtl,
    );
    await tester.pumpAndSettle();
    final morph = tester.renderObject<RenderCollapseMorph>(
      find.byType(CollapseMorph),
    );
    expect(morph.debugVisual.left, closeTo(0, 0.1));
    expect(morph.debugVisual.width, lessThan(morph.size.width / 2));
  });

  testWidgets('a compact tap expands and does not change the index', (
    tester,
  ) async {
    final controller = LiquidGlassCollapseController();
    addTearDown(controller.dispose);
    final changes = <int>[];
    await pumpNavigationBar(
      tester,
      items: sampleItems(withBadge: true),
      currentIndex: 1,
      onIndexChanged: changes.add,
      enableScrollCollapse: true,
      collapseController: controller,
      motion: const LiquidGlassMotion.none(),
    );
    await tester.pumpAndSettle();
    controller.collapse();
    await tester.pump();
    final morph = tester.renderObject<RenderCollapseMorph>(
      find.byType(CollapseMorph),
    );
    await tester.tapAt(
      tester.getTopLeft(find.byType(CollapseMorph)) + morph.debugVisual.center,
    );
    await tester.pump();
    expect(changes, isEmpty);
    expect(controller.isCollapsed, isFalse);
    await tester.pumpAndSettle();
    expect(find.text('Search'), findsWidgets);
  });

  testWidgets('changing label mode does not break semantics', (tester) async {
    final handle = tester.ensureSemantics();
    final controller = LiquidGlassCollapseController();
    addTearDown(controller.dispose);
    Future<void> show(LiquidGlassLabelMode mode) {
      return pumpNavigationBar(
        tester,
        items: sampleItems(),
        currentIndex: 0,
        onIndexChanged: (_) {},
        enableScrollCollapse: true,
        collapseController: controller,
        labelMode: mode,
      );
    }

    await show(LiquidGlassLabelMode.hidden);
    await tester.pumpAndSettle();
    await show(LiquidGlassLabelMode.selected);
    await tester.pumpAndSettle();
    await show(LiquidGlassLabelMode.always);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    handle.dispose();
  });

  testWidgets('a compact bar leaves destinations out of semantics', (
    tester,
  ) async {
    final controller = LiquidGlassCollapseController(collapsed: true);
    addTearDown(controller.dispose);
    final handle = tester.ensureSemantics();
    await pumpNavigationBar(
      tester,
      items: sampleItems(),
      currentIndex: 0,
      onIndexChanged: (_) {},
      enableScrollCollapse: true,
      collapseController: controller,
      motion: const LiquidGlassMotion.none(),
    );
    await tester.pumpAndSettle();
    final root =
        tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!;
    expect(_hasLabel(root, 'Search'), isFalse);
    expect(_hasLabel(root, 'Inbox'), isFalse);
    expect(_hasHint(root, 'Shows navigation'), isTrue);
    handle.dispose();
  });

  testWidgets('a leading tap misses the compact button', (tester) async {
    final controller = LiquidGlassCollapseController(collapsed: true);
    addTearDown(controller.dispose);
    final changes = <int>[];
    await pumpNavigationBar(
      tester,
      items: sampleItems(),
      currentIndex: 0,
      onIndexChanged: changes.add,
      enableScrollCollapse: true,
      collapseController: controller,
      motion: const LiquidGlassMotion.none(),
    );
    await tester.pumpAndSettle();
    final box = tester.getRect(find.byType(CollapseMorph));
    await tester.tapAt(box.centerLeft + const Offset(12, 0));
    await tester.pump();
    expect(controller.isCollapsed, isTrue);
    expect(changes, isEmpty);
  });

  testWidgets('a collapse during a drag waits until the drag ends', (
    tester,
  ) async {
    final controller = LiquidGlassCollapseController();
    addTearDown(controller.dispose);
    await pumpNavigationBar(
      tester,
      items: sampleItems(),
      currentIndex: 0,
      onIndexChanged: (_) {},
      enableScrollCollapse: true,
      enableDragSelection: true,
      collapseController: controller,
    );
    await tester.pumpAndSettle();
    final gesture = await tester.startGesture(
      tester.getCenter(find.byIcon(Icons.home_rounded)),
    );
    await gesture.moveBy(const Offset(48, 0));
    await tester.pump();
    controller.collapse();
    await tester.pump(const Duration(milliseconds: 40));
    final morph = tester.renderObject<RenderCollapseMorph>(
      find.byType(CollapseMorph),
    );
    expect(morph.debugVisual.width, closeTo(morph.size.width, 1));
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    expect(
      tester
          .renderObject<RenderCollapseMorph>(find.byType(CollapseMorph))
          .debugVisual
          .width,
      lessThan(morph.size.width),
    );
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
      enableScrollCollapse: true,
      collapseController: controller,
    );
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    controller.collapse();
    expect(controller.isCollapsed, isTrue);
    controller.dispose();
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
      enableScrollCollapse: true,
      collapseController: first,
      motion: const LiquidGlassMotion.none(),
    );
    await tester.pumpAndSettle();
    await pumpNavigationBar(
      tester,
      items: sampleItems(),
      currentIndex: 0,
      onIndexChanged: (_) {},
      enableScrollCollapse: true,
      collapseController: second,
      motion: const LiquidGlassMotion.none(),
    );
    await tester.pump();
    first.collapse();
    await tester.pump();
    final morph = tester.renderObject<RenderCollapseMorph>(
      find.byType(CollapseMorph),
    );
    expect(morph.debugVisual.width, closeTo(morph.size.width, 1));
    second.collapse();
    await tester.pump();
    expect(morph.debugVisual.width, lessThan(morph.size.width / 2));
  });

  testWidgets('a disabled observer does not change collapse', (tester) async {
    final controller = LiquidGlassCollapseController();
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
    expect(controller.isCollapsed, isFalse);
  });

  testWidgets('disposing during a collapse leaves no ticker', (tester) async {
    final controller = LiquidGlassCollapseController();
    addTearDown(controller.dispose);
    await pumpNavigationBar(
      tester,
      items: sampleItems(),
      currentIndex: 0,
      onIndexChanged: (_) {},
      enableScrollCollapse: true,
      collapseController: controller,
    );
    await tester.pumpAndSettle();
    controller.collapse();
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('a reversal in the same drag expands without a new start', (
    tester,
  ) async {
    final controller = LiquidGlassCollapseController();
    addTearDown(controller.dispose);
    var notices = 0;
    controller.addListener(() => notices++);
    await _pumpScroll(
      tester,
      controller: controller,
      child: ListView(
        children: [
          for (var i = 0; i < 40; i++) SizedBox(height: 48, child: Text('$i')),
        ],
      ),
    );
    await tester.pumpAndSettle();
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(ListView)),
    );
    await gesture.moveBy(const Offset(0, -28));
    await tester.pump();
    expect(controller.isCollapsed, isTrue);
    expect(notices, 1);
    await gesture.moveBy(const Offset(0, 16));
    await tester.pump();
    expect(controller.isCollapsed, isFalse);
    expect(notices, 2);
    await gesture.up();
  });

  testWidgets('a short upward drag during a fling still expands', (
    tester,
  ) async {
    final controller = LiquidGlassCollapseController();
    addTearDown(controller.dispose);
    await _pumpScroll(
      tester,
      controller: controller,
      child: ListView(
        children: [
          for (var i = 0; i < 40; i++) SizedBox(height: 48, child: Text('$i')),
        ],
      ),
    );
    await tester.pumpAndSettle();
    await tester.fling(find.byType(ListView), const Offset(0, -320), 2000);
    await tester.pump(const Duration(milliseconds: 30));
    expect(controller.isCollapsed, isTrue);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(ListView)),
    );
    await gesture.moveBy(const Offset(0, 6));
    await tester.pump();
    await gesture.moveBy(const Offset(0, 18));
    await tester.pump();
    expect(controller.isCollapsed, isFalse);
    await gesture.up();
  });

  testWidgets('rapid direction changes do not stick or notify twice', (
    tester,
  ) async {
    final controller = LiquidGlassCollapseController();
    addTearDown(controller.dispose);
    var notices = 0;
    controller.addListener(() => notices++);
    await _pumpScroll(
      tester,
      controller: controller,
      child: ListView(
        children: [
          for (var i = 0; i < 40; i++) SizedBox(height: 48, child: Text('$i')),
        ],
      ),
    );
    await tester.pumpAndSettle();
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(ListView)),
    );
    for (var i = 0; i < 2; i++) {
      await gesture.moveBy(const Offset(0, -28));
      await tester.pump();
      expect(controller.isCollapsed, isTrue);
      await gesture.moveBy(const Offset(0, 16));
      await tester.pump();
      expect(controller.isCollapsed, isFalse);
    }
    expect(notices, 4);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('movement under the dead zone does not request a change', (
    tester,
  ) async {
    final controller = LiquidGlassCollapseController();
    addTearDown(controller.dispose);
    final trace = LiquidGlassScrollTrace();
    var notices = 0;
    controller.addListener(() => notices++);
    await _pumpScroll(
      tester,
      controller: controller,
      trace: trace,
      child: ListView(
        children: [
          for (var i = 0; i < 40; i++) SizedBox(height: 48, child: Text('$i')),
        ],
      ),
    );
    await tester.pumpAndSettle();
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(ListView)),
    );
    await gesture.moveBy(const Offset(0, -6));
    await tester.pump();
    expect(controller.isCollapsed, isFalse);
    expect(trace.requests, 0);
    expect(notices, 0);
    await gesture.up();
  });

  testWidgets('bottom overscroll does not collapse and a reverse expands', (
    tester,
  ) async {
    final controller = LiquidGlassCollapseController();
    addTearDown(controller.dispose);
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    var notices = 0;
    controller.addListener(() => notices++);
    await _pumpScroll(
      tester,
      controller: controller,
      child: ListView(
        controller: scroll,
        physics: const BouncingScrollPhysics(),
        children: [
          for (var i = 0; i < 8; i++) SizedBox(height: 80, child: Text('$i')),
        ],
      ),
    );
    await tester.pumpAndSettle();
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(ListView)),
    );
    await gesture.moveBy(const Offset(0, -400));
    await tester.pump();
    expect(
      scroll.position.pixels,
      greaterThan(scroll.position.maxScrollExtent),
    );
    expect(controller.isCollapsed, isTrue);
    expect(notices, 1);
    await gesture.moveBy(const Offset(0, -80));
    await tester.pump();
    expect(notices, 1);
    await gesture.moveBy(const Offset(0, 16));
    await tester.pump();
    expect(controller.isCollapsed, isFalse);
    await gesture.up();
  });

  testWidgets('a reverse-axis list collapses toward its end', (tester) async {
    final controller = LiquidGlassCollapseController();
    addTearDown(controller.dispose);
    await _pumpScroll(
      tester,
      controller: controller,
      child: ListView(
        reverse: true,
        children: [
          for (var i = 0; i < 40; i++) SizedBox(height: 48, child: Text('$i')),
        ],
      ),
    );
    await tester.pumpAndSettle();
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(ListView)),
    );
    await gesture.moveBy(const Offset(0, 28));
    await tester.pump();
    expect(controller.isCollapsed, isTrue);
    await gesture.moveBy(const Offset(0, -16));
    await tester.pump();
    expect(controller.isCollapsed, isFalse);
    await gesture.up();
  });

  testWidgets('the selected icon travels without jumping', (tester) async {
    final controller = LiquidGlassCollapseController();
    addTearDown(controller.dispose);
    await pumpNavigationBar(
      tester,
      items: sampleItems(),
      currentIndex: 0,
      onIndexChanged: (_) {},
      enableScrollCollapse: true,
      collapseController: controller,
    );
    await tester.pumpAndSettle();
    final start = tester.getCenter(find.byIcon(Icons.home_rounded));
    controller.collapse();
    await tester.pump();
    var previousX = start.dx;
    var previousWidth = tester
        .renderObject<RenderCollapseMorph>(find.byType(CollapseMorph))
        .size
        .width;
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 40));
      final morph = tester.renderObject<RenderCollapseMorph>(
        find.byType(CollapseMorph),
      );
      final x = tester.getCenter(find.byIcon(Icons.home_rounded)).dx;
      expect(x, greaterThanOrEqualTo(previousX - 0.5));
      expect(x - previousX, lessThan(160));
      expect(morph.debugVisual.width, lessThanOrEqualTo(previousWidth + 0.5));
      expect(
        previousWidth - morph.debugVisual.width,
        lessThan(morph.size.width * 0.5),
      );
      previousX = x;
      previousWidth = morph.debugVisual.width;
    }
    await tester.pumpAndSettle();
    final morph = tester.renderObject<RenderCollapseMorph>(
      find.byType(CollapseMorph),
    );
    final icon = tester.getCenter(find.byIcon(Icons.home_rounded));
    final center =
        tester.getTopLeft(find.byType(CollapseMorph)) +
        morph.debugVisual.center;
    expect((icon - center).distance, lessThan(12));
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('a reversal continues from the current morph progress', (
    tester,
  ) async {
    final controller = LiquidGlassCollapseController();
    addTearDown(controller.dispose);
    await pumpNavigationBar(
      tester,
      items: sampleItems(),
      currentIndex: 0,
      onIndexChanged: (_) {},
      enableScrollCollapse: true,
      collapseController: controller,
    );
    await tester.pumpAndSettle();
    controller.collapse();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 140));
    final morph = tester.renderObject<RenderCollapseMorph>(
      find.byType(CollapseMorph),
    );
    final mid = morph.debugProgress;
    expect(mid, greaterThan(0.05));
    expect(mid, lessThan(0.95));
    controller.expand();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    final next = tester
        .renderObject<RenderCollapseMorph>(find.byType(CollapseMorph))
        .debugProgress;
    expect(next, lessThan(mid));
    expect(next, greaterThan(0));
  });

  testWidgets('scrolling while compact does not relayout the glass', (
    tester,
  ) async {
    final controller = LiquidGlassCollapseController();
    addTearDown(controller.dispose);
    await _pumpScroll(
      tester,
      controller: controller,
      child: ListView(
        children: [
          for (var i = 0; i < 40; i++) SizedBox(height: 48, child: Text('$i')),
        ],
      ),
    );
    await tester.pumpAndSettle();
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(ListView)),
    );
    await gesture.moveBy(const Offset(0, -40));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    final morph = tester.renderObject<RenderCollapseMorph>(
      find.byType(CollapseMorph),
    );
    final layouts = morph.debugLayoutCount;
    final again = await tester.startGesture(
      tester.getCenter(find.byType(ListView)),
    );
    await again.moveBy(const Offset(0, -40));
    await tester.pump();
    await again.up();
    await tester.pump();
    expect(morph.debugLayoutCount, layouts);
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('refractive collapse keeps a finite glass rect', (tester) async {
    final controller = LiquidGlassCollapseController();
    addTearDown(controller.dispose);
    await pumpNavigationBar(
      tester,
      items: sampleItems(),
      currentIndex: 0,
      onIndexChanged: (_) {},
      enableScrollCollapse: true,
      collapseController: controller,
      motion: const LiquidGlassMotion.none(),
      material: const LiquidGlassMaterial(
        mode: LiquidGlassRenderMode.refractive,
      ),
    );
    await tester.pumpAndSettle();
    controller.collapse();
    await tester.pump();
    final morph = tester.renderObject<RenderCollapseMorph>(
      find.byType(CollapseMorph),
    );
    expect(morph.debugVisual.width, lessThan(morph.size.width - 40));
    expect(morph.debugVisual.width, greaterThan(0));
    expect(morph.debugVisual.height, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  test('content fade stays continuous through the morph', () {
    expect(liquidCollapseContentFade(0), 0);
    expect(liquidCollapseContentFade(1), 1);
    expect(liquidCollapseContentFade(0.45), greaterThan(0.15));
    expect(liquidCollapseContentFade(0.45), lessThan(0.85));
    var previous = 0.0;
    for (var step = 1; step <= 20; step++) {
      final value = liquidCollapseContentFade(step / 20);
      expect(value, greaterThanOrEqualTo(previous - 0.0001));
      expect(value - previous, lessThan(0.2));
      previous = value;
    }
  });

  testWidgets('the glass contracts continuously around the selected icon', (
    tester,
  ) async {
    final controller = LiquidGlassCollapseController();
    addTearDown(controller.dispose);
    await pumpNavigationBar(
      tester,
      items: sampleItems(),
      currentIndex: 0,
      onIndexChanged: (_) {},
      enableScrollCollapse: true,
      collapseController: controller,
    );
    await tester.pumpAndSettle();
    controller.collapse();
    await tester.pump();
    var previousWidth = double.infinity;
    var previousX = -1.0;
    const marks = <int>[0, 36, 90, 180, 270, 324, 360];
    var elapsed = 0;
    for (final mark in marks) {
      if (mark > elapsed) {
        await tester.pump(Duration(milliseconds: mark - elapsed));
        elapsed = mark;
      }
      final morph = tester.renderObject<RenderCollapseMorph>(
        find.byType(CollapseMorph),
      );
      final origin = tester.getTopLeft(find.byType(CollapseMorph));
      final visual = morph.debugVisual.shift(origin);
      final icon = tester.getCenter(find.byIcon(Icons.home_rounded));
      expect(visual.inflate(4).contains(icon), isTrue);
      expect(visual.width, lessThanOrEqualTo(previousWidth + 0.5));
      if (previousX >= 0) {
        expect(icon.dx, greaterThanOrEqualTo(previousX - 0.5));
        expect(previousWidth - visual.width, lessThan(140));
      }
      if (mark == 180) {
        final fading = tester.widgetList<Opacity>(
          find.ancestor(
            of: find.text('Search'),
            matching: find.byType(Opacity),
          ),
        );
        expect(
          fading.any(
            (opacity) => opacity.opacity > 0.1 && opacity.opacity < 0.95,
          ),
          isTrue,
        );
      }
      previousWidth = visual.width;
      previousX = icon.dx;
    }
    await tester.pumpAndSettle();
    final settled = tester.renderObject<RenderCollapseMorph>(
      find.byType(CollapseMorph),
    );
    final settledOrigin = tester.getTopLeft(find.byType(CollapseMorph));
    final icon = tester.getCenter(find.byIcon(Icons.home_rounded));
    expect(
      (icon - (settledOrigin + settled.debugVisual.center)).distance,
      lessThan(12),
    );
    controller.expand();
    await tester.pump();
    var expandingWidth = tester
        .renderObject<RenderCollapseMorph>(find.byType(CollapseMorph))
        .debugVisual
        .width;
    for (final mark in <int>[40, 120, 220]) {
      await tester.pump(
        Duration(
          milliseconds: mark == 40 ? 40 : mark - (mark == 120 ? 40 : 120),
        ),
      );
      final width = tester
          .renderObject<RenderCollapseMorph>(find.byType(CollapseMorph))
          .debugVisual
          .width;
      expect(width, greaterThanOrEqualTo(expandingWidth - 0.5));
      expandingWidth = width;
    }
  });
}

bool _hasLabel(SemanticsNode node, String label) {
  if (node.label == label) {
    return true;
  }
  var found = false;
  node.visitChildren((SemanticsNode child) {
    found = found || _hasLabel(child, label);
    return true;
  });
  return found;
}

bool _hasHint(SemanticsNode node, String hint) {
  if (node.hint == hint) {
    return true;
  }
  var found = false;
  node.visitChildren((SemanticsNode child) {
    found = found || _hasHint(child, hint);
    return true;
  });
  return found;
}

Future<void> _pumpScroll(
  WidgetTester tester, {
  required LiquidGlassCollapseController controller,
  required Widget child,
  LiquidGlassScrollTrace? trace,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            Expanded(
              child: LiquidGlassScrollObserver(
                controller: controller,
                trace: trace,
                child: child,
              ),
            ),
            LiquidGlassNavigationBar(
              enableScrollCollapse: true,
              collapseController: controller,
              currentIndex: 0,
              onIndexChanged: (_) {},
              motion: const LiquidGlassMotion.none(),
              style: testStyle,
              items: sampleItems(),
            ),
          ],
        ),
      ),
    ),
  );
}
