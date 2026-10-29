import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

void main() {
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  List<MethodCall> hapticCalls() {
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

  testWidgets('tapping an unselected item reports that index once', (
    tester,
  ) async {
    final selections = <int>[];
    final haptics = hapticCalls();
    await pumpNavigationBar(
      tester,
      items: sampleItems(),
      currentIndex: 0,
      onIndexChanged: selections.add,
    );

    await tester.tap(find.byIcon(Icons.search_rounded));
    await tester.pump();

    expect(selections, <int>[1]);
    expect(haptics, hasLength(1));
    expect(haptics.single.arguments, 'HapticFeedbackType.selectionClick');
  });

  testWidgets('tapping the selected item does not notify or play haptics', (
    tester,
  ) async {
    final selections = <int>[];
    final haptics = hapticCalls();
    await pumpNavigationBar(
      tester,
      items: sampleItems(),
      currentIndex: 1,
      onIndexChanged: selections.add,
    );

    await tester.tap(find.text('Search'));
    await tester.pump();

    expect(selections, isEmpty);
    expect(haptics, isEmpty);
  });

  testWidgets('disabled haptics and programmatic changes stay silent', (
    tester,
  ) async {
    final haptics = hapticCalls();
    await pumpNavigationBar(
      tester,
      items: sampleItems(),
      currentIndex: 0,
      hapticsEnabled: false,
      onIndexChanged: (_) {},
    );
    await tester.tap(find.byIcon(Icons.inbox_outlined));
    await tester.pump();
    expect(haptics, isEmpty);

    await pumpNavigationBar(
      tester,
      items: sampleItems(),
      currentIndex: 2,
      onIndexChanged: (_) {},
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(haptics, isEmpty);
  });

  testWidgets('a null callback ignores taps', (tester) async {
    final haptics = hapticCalls();
    await pumpNavigationBar(
      tester,
      items: sampleItems(),
      currentIndex: 0,
      onIndexChanged: null,
    );
    await tester.tap(find.byIcon(Icons.search_rounded));
    await tester.pump();
    expect(haptics, isEmpty);
    expect(indicatorRender(tester).targetIndex, 0);
  });

  testWidgets('custom children can be tapped to select their item', (
    tester,
  ) async {
    final selections = <int>[];
    await pumpNavigationBar(
      tester,
      currentIndex: 0,
      onIndexChanged: selections.add,
      items: const [
        LiquidGlassNavigationItem(icon: Icons.home_rounded, label: 'Home'),
        LiquidGlassNavigationItem(
          child: Text('Avatar'),
          semanticLabel: 'Profile',
        ),
      ],
    );
    await tester.tap(find.text('Avatar'));
    expect(selections, <int>[1]);
  });

  testWidgets(
    'rapid taps keep a single controller and land on the latest index',
    (tester) async {
      var index = 0;
      Future<void> rebuild() {
        return pumpNavigationBar(
          tester,
          items: sampleItems(),
          currentIndex: index,
          onIndexChanged: (value) => index = value,
        );
      }

      await rebuild();
      await tester.tap(find.byIcon(Icons.search_rounded));
      await rebuild();
      await tester.pump(const Duration(milliseconds: 40));
      await tester.tap(find.byIcon(Icons.inbox_outlined));
      await rebuild();
      await tester.pump(const Duration(milliseconds: 40));
      await tester.pump(const Duration(seconds: 1));

      final render = indicatorRender(tester);
      final destination = render.debugItemRects[2];
      expect(
        render.debugIndicatorRect!.center.dx,
        closeTo(destination.center.dx, 1),
      );
      expect(tester.binding.transientCallbackCount, 0);
    },
  );
}
