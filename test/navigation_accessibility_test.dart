import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

void main() {
  testWidgets('exposes tab semantics, selection, and a readable name', (
    tester,
  ) async {
    await pumpNavigationBar(
      tester,
      items: sampleItems(withBadge: true),
      currentIndex: 2,
      onIndexChanged: (_) {},
      labelMode: LiquidGlassLabelMode.selected,
      semanticsLabel: 'Primary',
    );

    final home = tester.getSemantics(find.bySemanticsLabel('Home'));
    final inbox = tester.getSemantics(
      find.bySemanticsLabel('Inbox, 12 notifications'),
    );
    expect(home.flagsCollection.isSelected, isNot(Tristate.isTrue));
    expect(inbox.flagsCollection.isSelected, Tristate.isTrue);
    expect(inbox.getSemanticsData().role, SemanticsRole.tab);
    expect(
      tester
          .getSemantics(find.byType(LiquidGlassNavigationBar))
          .getSemanticsData()
          .role,
      SemanticsRole.tabBar,
    );
    expect(
      tester
          .getSemantics(find.byType(LiquidGlassNavigationBar))
          .getSemanticsData()
          .label,
      'Primary',
    );

    final slot = indicatorRender(tester).debugItemRects[0];
    expect(slot.width, greaterThanOrEqualTo(48));
    expect(slot.height, greaterThanOrEqualTo(48));
  });

  testWidgets('reduced motion is reflected by an immediate indicator move', (
    tester,
  ) async {
    await pumpNavigationBar(
      tester,
      items: sampleItems(withLabels: false),
      currentIndex: 0,
      onIndexChanged: (_) {},
      disableAnimations: true,
      style: const LiquidGlassNavigationStyle(
        margin: EdgeInsets.zero,
        padding: EdgeInsets.zero,
        indicatorInset: EdgeInsets.zero,
        respectSafeArea: false,
        blurSigma: 0,
        elevation: 0,
      ),
    );
    await pumpNavigationBar(
      tester,
      items: sampleItems(withLabels: false),
      currentIndex: 2,
      onIndexChanged: (_) {},
      disableAnimations: true,
      style: const LiquidGlassNavigationStyle(
        margin: EdgeInsets.zero,
        padding: EdgeInsets.zero,
        indicatorInset: EdgeInsets.zero,
        respectSafeArea: false,
        blurSigma: 0,
        elevation: 0,
      ),
    );
    await tester.pump();
    final render = indicatorRender(tester);
    expect(
      render.debugIndicatorRect!.center.dx,
      closeTo(render.debugItemRects[2].center.dx, 1),
    );
  });
}
