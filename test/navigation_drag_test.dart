import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_bottom_navigator/src/navigation_layout.dart';

import 'harness.dart';

void main() {
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('drag is ignored unless enableDragSelection is set', (
    tester,
  ) async {
    final selections = <int>[];
    await pumpNavigationBar(
      tester,
      items: sampleItems(),
      currentIndex: 0,
      onIndexChanged: selections.add,
    );
    final before = _center(tester);
    final gesture = await tester.startGesture(_slot(tester, 0));
    await gesture.moveBy(const Offset(80, 0));
    await tester.pump();
    expect(_center(tester).dx, closeTo(before.dx, 0.5));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(selections, isEmpty);
  });

  testWidgets('a tap still selects when dragging is enabled', (tester) async {
    final selections = <int>[];
    await _pump(tester, selections);
    await tester.tap(find.byIcon(Icons.search_rounded));
    await tester.pump();
    expect(selections, <int>[1]);
  });

  testWidgets('movement inside the touch slop stays a tap', (tester) async {
    final selections = <int>[];
    await _pump(tester, selections);
    final gesture = await tester.startGesture(_slot(tester, 1));
    await gesture.moveBy(const Offset(8, 0));
    await gesture.up();
    await tester.pump();
    expect(selections, <int>[1]);
  });

  testWidgets('the indicator follows the finger without a callback', (
    tester,
  ) async {
    final selections = <int>[];
    await _pump(tester, selections);
    final before = _center(tester);
    final gesture = await tester.startGesture(_slot(tester, 0));
    await gesture.moveBy(const Offset(36, 0));
    await tester.pump();
    expect(_center(tester).dx - before.dx, closeTo(36, 2));
    expect(selections, isEmpty);
    await gesture.up();
  });

  testWidgets('reversing direction follows the finger without a callback', (
    tester,
  ) async {
    final selections = <int>[];
    await _pump(tester, selections);
    final before = _center(tester);
    final gesture = await tester.startGesture(_slot(tester, 0));
    await gesture.moveBy(const Offset(80, 0));
    await tester.pump();
    final forward = _center(tester);
    expect(forward.dx, greaterThan(before.dx + 40));
    await gesture.moveBy(const Offset(-50, 0));
    await tester.pump();
    final back = _center(tester);
    expect(back.dx, closeTo(forward.dx - 50, 3));
    expect(back.dx, greaterThan(before.dx + 10));
    expect(selections, isEmpty);
    await gesture.moveBy(Offset(before.dx - back.dx, 0));
    await tester.pump();
    expect(_center(tester).dx, closeTo(before.dx, 3));
    expect(selections, isEmpty);
    await gesture.up();
    await tester.pump();
    expect(selections, isEmpty);
  });

  testWidgets('release on another destination reports that index once', (
    tester,
  ) async {
    final selections = <int>[];
    final haptics = _haptics();
    await _pump(tester, selections);
    await _dragTo(tester, 1);
    expect(selections, <int>[1]);
    expect(haptics, hasLength(1));
    expect(haptics.single.arguments, 'HapticFeedbackType.selectionClick');
  });

  testWidgets('one drag can cross several destinations', (tester) async {
    final selections = <int>[];
    await _pump(tester, selections);
    await _dragTo(tester, 2);
    expect(selections, <int>[2]);
  });

  testWidgets('release in a gap springs back without a callback', (
    tester,
  ) async {
    final selections = <int>[];
    await _pump(tester, selections, style: testStyle.copyWith(itemSpacing: 28));
    final home = _center(tester);
    final render = indicatorRender(tester);
    final box = _box(tester);
    final slots = render.debugItemRects;
    final gap = box.localToGlobal(
      Offset((slots[0].right + slots[1].left) / 2, slots[0].center.dy),
    );
    final gesture = await tester.startGesture(_slot(tester, 0));
    await gesture.moveTo(gap);
    await tester.pump();
    expect(selections, isEmpty);
    final dragged = _center(tester);
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    expect(selections, isEmpty);
    expect((_center(tester).dx - home.dx).abs(), greaterThan(1));
    expect(
      (_center(tester).dx - home.dx).abs(),
      lessThan((dragged.dx - home.dx).abs()),
    );
    await tester.pumpAndSettle();
    expect(_center(tester).dx, closeTo(home.dx, 0.5));
  });

  testWidgets('release on the original destination does not call back', (
    tester,
  ) async {
    final selections = <int>[];
    final haptics = _haptics();
    await _pump(tester, selections);
    final home = _center(tester);
    final gesture = await tester.startGesture(_slot(tester, 0));
    await gesture.moveBy(const Offset(24, 0));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(selections, isEmpty);
    expect(haptics, isEmpty);
    expect(_center(tester).dx, closeTo(home.dx, 0.5));
  });

  testWidgets('a cancelled drag returns to the current destination', (
    tester,
  ) async {
    final selections = <int>[];
    await _pump(tester, selections);
    final home = _center(tester);
    final gesture = await tester.startGesture(_slot(tester, 0));
    await gesture.moveBy(const Offset(70, 0));
    await tester.pump();
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(selections, isEmpty);
    expect(_center(tester).dx, closeTo(home.dx, 0.5));
  });

  testWidgets('a rejected selection springs back to currentIndex', (
    tester,
  ) async {
    final selections = <int>[];
    await _pump(tester, selections, accept: false);
    final home = _center(tester);
    await _dragTo(tester, 1, settle: true);
    expect(selections, <int>[1]);
    expect(_center(tester).dx, closeTo(home.dx, 0.5));
  });

  testWidgets('a parent index change during a drag becomes the selection', (
    tester,
  ) async {
    final selections = <int>[];
    final haptics = _haptics();
    final host = await _pump(tester, selections);
    final gesture = await tester.startGesture(_slot(tester, 0));
    await gesture.moveBy(const Offset(40, 0));
    await tester.pump();
    host.index = 2;
    host.rebuild();
    await tester.pumpAndSettle();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(selections, isEmpty);
    expect(haptics, isEmpty);
    expect(
      indicatorRender(tester).debugItemRects[2]
          .contains(indicatorRender(tester).debugIndicatorRect!.center),
      isTrue,
    );
  });

  testWidgets('rapid drags each report one index', (tester) async {
    final selections = <int>[];
    await _pump(tester, selections);
    await _dragTo(tester, 1, settle: true);
    await _dragTo(tester, 2, from: 1, settle: true);
    expect(selections, <int>[1, 2]);
  });

  testWidgets('removing items during a drag drops the preview', (tester) async {
    final selections = <int>[];
    final host = await _pump(tester, selections);
    final gesture = await tester.startGesture(_slot(tester, 0));
    await gesture.moveBy(const Offset(50, 0));
    await tester.pump();
    host.count = 1;
    host.rebuild();
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(selections, isEmpty);
    expect(indicatorRender(tester).debugItemRects, hasLength(1));
    expect(
      indicatorRender(tester).debugItemRects[0]
          .contains(indicatorRender(tester).debugIndicatorRect!.center),
      isTrue,
    );
  });

  testWidgets('disposing during a drag does not throw', (tester) async {
    final selections = <int>[];
    await _pump(tester, selections);
    final gesture = await tester.startGesture(_slot(tester, 0));
    await gesture.moveBy(const Offset(40, 0));
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await gesture.up();
    expect(tester.takeException(), isNull);
  });

  testWidgets('RTL drag uses the visual slot under the finger', (tester) async {
    final selections = <int>[];
    await _pump(tester, selections, textDirection: TextDirection.rtl);
    expect(_slot(tester, 0).dx, greaterThan(_slot(tester, 1).dx));
    await _dragTo(tester, 1);
    expect(selections, <int>[1]);
  });

  testWidgets('intrinsic slots use their measured hit regions', (tester) async {
    final selections = <int>[];
    await _pump(
      tester,
      selections,
      items: <LiquidGlassNavigationItem>[
        const LiquidGlassNavigationItem(
          icon: Icons.home_rounded,
          label: 'Home',
        ),
        const LiquidGlassNavigationItem(
          icon: Icons.search_rounded,
          label: 'Search archive',
        ),
        const LiquidGlassNavigationItem(
          icon: Icons.inbox_outlined,
          label: 'In',
        ),
      ],
      style: testStyle.copyWith(itemLayout: LiquidGlassItemLayout.intrinsic),
    );
    final rects = indicatorRender(tester).debugItemRects;
    expect(rects[1].width, greaterThan(rects[2].width));
    await _dragTo(tester, 1);
    expect(selections, <int>[1]);
  });

  testWidgets('a narrow bar can still drag onto the next slot', (tester) async {
    final selections = <int>[];
    await _pump(tester, selections, surface: const Size(200, 240));
    await _dragTo(tester, 1);
    expect(selections, <int>[1]);
  });

  testWidgets('reduced motion drags without extra stretch', (tester) async {
    final selections = <int>[];
    await _pump(
      tester,
      selections,
      disableAnimations: true,
      indicatorStyle: LiquidGlassIndicatorStyle.morphingPill,
    );
    final before = indicatorRender(tester).debugIndicatorRect!;
    final gesture = await tester.startGesture(_slot(tester, 0));
    await gesture.moveBy(const Offset(30, 0));
    await tester.pump();
    final dragged = indicatorRender(tester).debugIndicatorRect!;
    expect((dragged.width - before.width).abs(), lessThan(8));
    await gesture.up();
    await tester.pump();
    expect(selections, isEmpty);
  });

  testWidgets('morphing stretch is wider than a sliding drag', (tester) async {
    Future<double> width(LiquidGlassIndicatorStyle style) async {
      await _pump(tester, <int>[], indicatorStyle: style);
      final gesture = await tester.startGesture(_slot(tester, 0));
      await gesture.moveBy(const Offset(30, 0));
      await tester.pump();
      final dragged = indicatorRender(tester).debugIndicatorRect!.width;
      await gesture.up();
      await tester.pumpAndSettle();
      return dragged;
    }

    final sliding = await width(LiquidGlassIndicatorStyle.slidingPill);
    final morphing = await width(LiquidGlassIndicatorStyle.morphingPill);
    expect(morphing, greaterThan(sliding + 2));
  });

  testWidgets('disabled haptics stay silent for a successful drag', (
    tester,
  ) async {
    final selections = <int>[];
    final haptics = _haptics();
    await _pump(tester, selections, hapticsEnabled: false);
    await _dragTo(tester, 1);
    expect(selections, <int>[1]);
    expect(haptics, isEmpty);
  });

  testWidgets('keyboard activation still works while dragging is enabled', (
    tester,
  ) async {
    final selections = <int>[];
    await _pump(tester, selections, withLabels: false);
    final nodes = tester
        .widgetList<Focus>(find.byType(Focus))
        .map((focus) => focus.focusNode)
        .whereType<FocusNode>()
        .where((node) => node.debugLabel == 'LiquidGlassNavigationItem')
        .toList();
    nodes[1].requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(selections, <int>[1]);
  });

  testWidgets('a vertical move scrolls the page instead of dragging', (
    tester,
  ) async {
    final selections = <int>[];
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            controller: controller,
            children: [
              SizedBox(
                height: 80,
                child: LiquidGlassNavigationBar(
                  enableDragSelection: true,
                  items: sampleItems(),
                  currentIndex: 0,
                  onIndexChanged: selections.add,
                  style: testStyle,
                  motion: testMotion,
                ),
              ),
              const SizedBox(height: 800),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    final gesture = await tester.startGesture(_slot(tester, 0));
    await gesture.moveBy(const Offset(0, -30));
    await gesture.moveBy(const Offset(0, -90));
    await tester.pump();
    expect(selections, isEmpty);
    expect(controller.offset, greaterThan(0));
    await gesture.up();
  });

  testWidgets('a direction change drops the drag preview', (tester) async {
    final selections = <int>[];
    final host = await _pump(tester, selections);
    final gesture = await tester.startGesture(_slot(tester, 0));
    await gesture.moveBy(const Offset(48, 0));
    await tester.pump();
    host.direction = TextDirection.rtl;
    host.rebuild();
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(selections, isEmpty);
    expect(
      indicatorRender(tester).debugItemRects[0]
          .contains(indicatorRender(tester).debugIndicatorRect!.center),
      isTrue,
    );
    expect(_slot(tester, 0).dx, greaterThan(_slot(tester, 1).dx));
  });

  testWidgets('turning drag off mid-gesture settles on currentIndex', (
    tester,
  ) async {
    final selections = <int>[];
    final host = await _pump(tester, selections);
    final home = _center(tester);
    final gesture = await tester.startGesture(_slot(tester, 0));
    await gesture.moveBy(const Offset(48, 0));
    await tester.pump();
    host.drag = false;
    host.rebuild();
    await tester.pumpAndSettle();
    expect(_center(tester).dx, closeTo(home.dx, 0.5));
    expect(selections, isEmpty);
    await gesture.up();
  });
}

List<MethodCall> _haptics() {
  final calls = <MethodCall>[];
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, (
        MethodCall call,
      ) async {
        if (call.method == 'HapticFeedback.vibrate') {
          calls.add(call);
        }
        return null;
      });
  return calls;
}

RenderBox _box(WidgetTester tester) {
  return tester.renderObject<RenderBox>(find.byType(LiquidNavigationLayout));
}

Offset _slot(WidgetTester tester, int index) {
  final render = indicatorRender(tester);
  return _box(tester).localToGlobal(render.debugItemRects[index].center);
}

Offset _center(WidgetTester tester) {
  final render = indicatorRender(tester);
  return _box(tester).localToGlobal(render.debugIndicatorRect!.center);
}

Future<_DragHostState> _pump(
  WidgetTester tester,
  List<int> selections, {
  bool accept = true,
  TextDirection textDirection = TextDirection.ltr,
  bool disableAnimations = false,
  bool hapticsEnabled = true,
  bool withLabels = true,
  Size surface = const Size(360, 240),
  LiquidGlassNavigationStyle style = testStyle,
  LiquidGlassIndicatorStyle indicatorStyle =
      LiquidGlassIndicatorStyle.slidingPill,
  List<LiquidGlassNavigationItem>? items,
}) async {
  final host = _DragHost(
    selections: selections,
    accept: accept,
    textDirection: textDirection,
    disableAnimations: disableAnimations,
    hapticsEnabled: hapticsEnabled,
    withLabels: withLabels,
    surface: surface,
    style: style,
    indicatorStyle: indicatorStyle,
    items: items,
  );
  await tester.pumpWidget(host);
  await tester.pump();
  return tester.state<_DragHostState>(find.byType(_DragHost));
}

Future<void> _dragTo(
  WidgetTester tester,
  int index, {
  int from = 0,
  bool settle = false,
}) async {
  final gesture = await tester.startGesture(_slot(tester, from));
  await gesture.moveTo(_slot(tester, index));
  await tester.pump();
  await gesture.up();
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

class _DragHost extends StatefulWidget {
  const _DragHost({
    required this.selections,
    required this.accept,
    required this.textDirection,
    required this.disableAnimations,
    required this.hapticsEnabled,
    required this.withLabels,
    required this.surface,
    required this.style,
    required this.indicatorStyle,
    required this.items,
  });

  final List<int> selections;
  final bool accept;
  final TextDirection textDirection;
  final bool disableAnimations;
  final bool hapticsEnabled;
  final bool withLabels;
  final Size surface;
  final LiquidGlassNavigationStyle style;
  final LiquidGlassIndicatorStyle indicatorStyle;
  final List<LiquidGlassNavigationItem>? items;

  @override
  State<_DragHost> createState() => _DragHostState();
}

class _DragHostState extends State<_DragHost> {
  int index = 0;
  int count = 3;
  bool drag = true;
  TextDirection? direction;

  void rebuild() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final items = (widget.items ?? sampleItems(withLabels: widget.withLabels))
        .take(count)
        .toList();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeAnimationDuration: Duration.zero,
      home: MediaQuery(
        data: MediaQueryData(
          size: widget.surface,
          disableAnimations: widget.disableAnimations,
        ),
        child: Directionality(
          textDirection: direction ?? widget.textDirection,
          child: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                width: widget.surface.width,
                child: LiquidGlassNavigationBar(
                  enableDragSelection: drag,
                  items: items,
                  currentIndex: index,
                  onIndexChanged: (value) {
                    widget.selections.add(value);
                    if (widget.accept) {
                      setState(() => index = value);
                    }
                  },
                  style: widget.style,
                  motion: testMotion,
                  hapticsEnabled: widget.hapticsEnabled,
                  indicatorStyle: widget.indicatorStyle,
                  labelMode: LiquidGlassLabelMode.always,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
