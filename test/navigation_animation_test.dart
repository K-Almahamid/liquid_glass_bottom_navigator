import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

void main() {
  testWidgets(
    'the indicator moves forward and backward, then rests on the selected slot',
    (tester) async {
      var index = 0;
      Future<void> show() {
        return pumpNavigationBar(
          tester,
          items: sampleItems(withLabels: false),
          currentIndex: index,
          onIndexChanged: (_) {},
          indicatorStyle: LiquidGlassIndicatorStyle.morphingPill,
          style: const LiquidGlassNavigationStyle(
            margin: EdgeInsets.zero,
            padding: EdgeInsets.zero,
            indicatorInset: EdgeInsets.zero,
            respectSafeArea: false,
            blurSigma: 0,
            elevation: 0,
            itemSpacing: 0,
          ),
        );
      }

      await show();
      final start = indicatorRender(tester).debugIndicatorRect!;
      index = 2;
      await show();
      await tester.pump(const Duration(milliseconds: 80));
      final movingForward = indicatorRender(tester).debugIndicatorRect!;
      expect(movingForward.center.dx, greaterThan(start.center.dx + 4));

      await tester.pump(const Duration(seconds: 1));
      final forwardRest = indicatorRender(tester).debugIndicatorRect!;
      final slot = indicatorRender(tester).debugItemRects[2];
      expect(forwardRest.center.dx, closeTo(slot.center.dx, 1));
      expect(forwardRest.width, closeTo(slot.width, 1));

      index = 0;
      await show();
      await tester.pump(const Duration(milliseconds: 80));
      expect(
        indicatorRender(tester).debugIndicatorRect!.center.dx,
        lessThan(forwardRest.center.dx - 4),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(
        indicatorRender(tester).debugIndicatorRect!.center.dx,
        closeTo(indicatorRender(tester).debugItemRects[0].center.dx, 1),
      );
    },
  );

  testWidgets(
    'disabled motion and reduced motion jump without an in-flight spring',
    (tester) async {
      Future<Rect> rest(
        LiquidGlassMotion motion, {
        required bool disableAnimations,
      }) async {
        await pumpNavigationBar(
          tester,
          items: sampleItems(withLabels: false),
          currentIndex: 0,
          onIndexChanged: (_) {},
          motion: motion,
          disableAnimations: disableAnimations,
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
          motion: motion,
          disableAnimations: disableAnimations,
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
        return render.debugIndicatorRect!;
      }

      final disabled = await rest(
        LiquidGlassMotion.none(),
        disableAnimations: false,
      );
      expect(
        disabled.center.dx,
        closeTo(indicatorRender(tester).debugItemRects[2].center.dx, 1),
      );
      expect(tester.binding.transientCallbackCount, 0);

      final reduced = await rest(
        const LiquidGlassMotion.spring(),
        disableAnimations: true,
      );
      expect(
        reduced.center.dx,
        closeTo(indicatorRender(tester).debugItemRects[2].center.dx, 1),
      );
      expect(tester.binding.transientCallbackCount, 0);
    },
  );

  testWidgets('changing the item count snaps instead of keeping a stale slot', (
    tester,
  ) async {
    await pumpNavigationBar(
      tester,
      items: sampleItems(),
      currentIndex: 2,
      onIndexChanged: (_) {},
    );
    await tester.pump(const Duration(milliseconds: 16));
    await pumpNavigationBar(
      tester,
      items: const <LiquidGlassNavigationItem>[
        LiquidGlassNavigationItem(icon: Icons.home_rounded, label: 'Only'),
      ],
      currentIndex: 0,
      onIndexChanged: (_) {},
    );
    await tester.pump();
    final render = indicatorRender(tester);
    expect(render.debugItemRects, hasLength(1));
    expect(render.targetIndex, 0);
    expect(
      render.debugIndicatorRect!.center.dx,
      closeTo(render.debugItemRects.single.center.dx, 1),
    );
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('disposing the bar releases its ticker', (tester) async {
    await pumpNavigationBar(
      tester,
      items: sampleItems(),
      currentIndex: 0,
      onIndexChanged: (_) {},
    );
    await pumpNavigationBar(
      tester,
      items: sampleItems(),
      currentIndex: 1,
      onIndexChanged: (_) {},
    );
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.binding.transientCallbackCount, 0);
  });

  test('duration and bounce change the spring in the documented direction', () {
    final slow = const LiquidGlassMotion(
      duration: Duration(milliseconds: 640),
      bounce: 0,
    ).spring;
    final fast = const LiquidGlassMotion(
      duration: Duration(milliseconds: 280),
      bounce: 0,
    ).spring;
    expect(slow.stiffness, lessThan(fast.stiffness));
    expect(const LiquidGlassMotion(bounce: 0.2).spring.bounce, greaterThan(0));
    expect(const LiquidGlassMotion(bounce: 0).spring.bounce, closeTo(0, 0.001));
  });

  testWidgets('sliding pill stays rigid while morphing pill stretches', (
    tester,
  ) async {
    const style = LiquidGlassNavigationStyle(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      indicatorInset: EdgeInsets.zero,
      respectSafeArea: false,
      blurSigma: 0,
      elevation: 0,
    );

    Future<double> width(LiquidGlassIndicatorStyle indicatorStyle) async {
      await pumpNavigationBar(
        tester,
        items: sampleItems(withLabels: false),
        currentIndex: 0,
        onIndexChanged: (_) {},
        indicatorStyle: indicatorStyle,
        motion: const LiquidGlassMotion(
          duration: Duration(milliseconds: 480),
          bounce: 0,
          morphIntensity: 1,
        ),
        style: style,
      );
      await pumpNavigationBar(
        tester,
        items: sampleItems(withLabels: false),
        currentIndex: 2,
        onIndexChanged: (_) {},
        indicatorStyle: indicatorStyle,
        motion: const LiquidGlassMotion(
          duration: Duration(milliseconds: 480),
          bounce: 0,
          morphIntensity: 1,
        ),
        style: style,
      );
      await tester.pump(const Duration(milliseconds: 90));
      return indicatorRender(tester).debugIndicatorRect!.width;
    }

    final rigid = await width(LiquidGlassIndicatorStyle.slidingPill);
    final slot = indicatorRender(tester).debugItemRects[2].width;
    expect(rigid, closeTo(slot, 2));
    final stretched = await width(LiquidGlassIndicatorStyle.morphingPill);
    expect(stretched, greaterThan(rigid + 12));
  });

  testWidgets('a shorter spring is farther along after the same elapsed time', (
    tester,
  ) async {
    const style = LiquidGlassNavigationStyle(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      indicatorInset: EdgeInsets.zero,
      respectSafeArea: false,
      blurSigma: 0,
      elevation: 0,
    );

    Future<double> travel(Duration duration) async {
      await pumpNavigationBar(
        tester,
        items: sampleItems(withLabels: false),
        currentIndex: 0,
        onIndexChanged: (_) {},
        indicatorStyle: LiquidGlassIndicatorStyle.slidingPill,
        motion: LiquidGlassMotion(
          duration: duration,
          bounce: 0,
          morphIntensity: 0,
        ),
        style: style,
      );
      final start = indicatorRender(tester).debugIndicatorRect!.center.dx;
      await pumpNavigationBar(
        tester,
        items: sampleItems(withLabels: false),
        currentIndex: 2,
        onIndexChanged: (_) {},
        indicatorStyle: LiquidGlassIndicatorStyle.slidingPill,
        motion: LiquidGlassMotion(
          duration: duration,
          bounce: 0,
          morphIntensity: 0,
        ),
        style: style,
      );
      await tester.pump(const Duration(milliseconds: 40));
      return indicatorRender(tester).debugIndicatorRect!.center.dx - start;
    }

    final quick = await travel(const Duration(milliseconds: 180));
    final slow = await travel(const Duration(milliseconds: 900));
    expect(quick, greaterThan(slow + 8));
  });

  testWidgets('direction and width changes keep the indicator on the slot', (
    tester,
  ) async {
    const style = LiquidGlassNavigationStyle(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      indicatorInset: EdgeInsets.zero,
      respectSafeArea: false,
      blurSigma: 0,
      elevation: 0,
    );
    await pumpNavigationBar(
      tester,
      items: sampleItems(withLabels: false),
      currentIndex: 0,
      onIndexChanged: (_) {},
      indicatorStyle: LiquidGlassIndicatorStyle.slidingPill,
      style: style,
      surface: const Size(300, 200),
    );
    await pumpNavigationBar(
      tester,
      items: sampleItems(withLabels: false),
      currentIndex: 2,
      onIndexChanged: (_) {},
      indicatorStyle: LiquidGlassIndicatorStyle.slidingPill,
      style: style,
      surface: const Size(300, 200),
    );
    await tester.pump(const Duration(milliseconds: 30));
    await pumpNavigationBar(
      tester,
      items: sampleItems(withLabels: false),
      currentIndex: 2,
      onIndexChanged: (_) {},
      indicatorStyle: LiquidGlassIndicatorStyle.slidingPill,
      style: style,
      surface: const Size(300, 200),
      textDirection: TextDirection.rtl,
    );
    await tester.pump();
    final rtl = indicatorRender(tester);
    final rtlSlotWidth = rtl.debugItemRects[2].width;
    expect(
      rtl.debugIndicatorRect!.center.dx,
      closeTo(rtl.debugItemRects[2].center.dx, 1),
    );

    await pumpNavigationBar(
      tester,
      items: sampleItems(withLabels: false),
      currentIndex: 2,
      onIndexChanged: (_) {},
      indicatorStyle: LiquidGlassIndicatorStyle.slidingPill,
      style: style,
      surface: const Size(420, 200),
      textDirection: TextDirection.rtl,
    );
    await tester.pump(const Duration(seconds: 1));
    final wide = indicatorRender(tester);
    expect(wide.debugItemRects[2].width, greaterThan(rtlSlotWidth));
    expect(
      wide.debugIndicatorRect!.center.dx,
      closeTo(wide.debugItemRects[2].center.dx, 1),
    );
  });
}
