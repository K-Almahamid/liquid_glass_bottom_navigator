import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_bottom_navigator/src/navigation_layout.dart';

import 'harness.dart';

void main() {
  testWidgets('seeded selections, mode changes, and remounts stay consistent', (
    tester,
  ) async {
    final random = math.Random(11);
    final selections = <int>[];
    var index = 0;
    var expected = 0;
    const icons = <IconData>[
      Icons.home_rounded,
      Icons.search_rounded,
      Icons.inbox_outlined,
    ];

    Future<void> show({
      LiquidGlassLabelMode mode = LiquidGlassLabelMode.always,
      ThemeData? themeData,
      bool reduced = false,
      List<LiquidGlassNavigationItem>? items,
    }) {
      return pumpNavigationBar(
        tester,
        items: items ?? sampleItems(withBadge: true),
        currentIndex: index,
        onIndexChanged: (value) {
          selections.add(value);
          index = value;
        },
        labelMode: mode,
        themeData: themeData,
        disableAnimations: reduced,
        enableDragSelection: true,
      );
    }

    await show();
    for (var i = 0; i < 40; i++) {
      final next = random.nextInt(3);
      if (next != index) {
        expected++;
        await tester.tap(find.byIcon(icons[next]));
        await show(mode: LiquidGlassLabelMode.values[i % 3]);
      }
      await tester.pump(const Duration(milliseconds: 12));
    }

    for (var i = 0; i < 20; i++) {
      await show(
        mode: LiquidGlassLabelMode.values[i % 3],
        themeData: ThemeData(
          brightness: i.isEven ? Brightness.light : Brightness.dark,
          useMaterial3: true,
        ),
        reduced: i.isOdd,
      );
      await tester.pump(const Duration(milliseconds: 8));
    }

    final swapped = <LiquidGlassNavigationItem>[...sampleItems().reversed];
    await show(items: swapped);
    await tester.pump(const Duration(milliseconds: 16));
    await show(items: sampleItems());

    for (var i = 0; i < 12; i++) {
      await show();
      await tester.pump(const Duration(milliseconds: 10));
      await tester.pumpWidget(const SizedBox.shrink());
    }
    await show();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(selections, hasLength(expected));
    expect(selections.every((value) => value >= 0 && value < 3), isTrue);
    expect(index, inInclusiveRange(0, 2));
    expect(indicatorRender(tester).targetIndex, index);
    expect(tester.binding.transientCallbackCount, 0);

    RenderLiquidNavigation.debugResetFrameCounters();
    await tester.pump(const Duration(milliseconds: 200));
    expect(RenderLiquidNavigation.debugPaintCount, 0);
  });
}
