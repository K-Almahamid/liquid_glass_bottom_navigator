import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_bottom_navigator/src/glass_shader.dart';
import 'package:liquid_glass_bottom_navigator/src/glass_surface.dart';

import 'harness.dart';

void main() {
  test('classic material is the default', () {
    const material = LiquidGlassMaterial();
    expect(material.mode, LiquidGlassRenderMode.classic);
    expect(material.variant, LiquidGlassMaterialVariant.regular);
    expect(material.refractionStrength, 0.35);
    expect(material, LiquidGlassMaterial.classic);
    expect(
      LiquidGlassMaterial.refractive.mode,
      LiquidGlassRenderMode.refractive,
    );
    expect(
      LiquidGlassMaterial.refractive.variant,
      LiquidGlassMaterialVariant.regular,
    );
    expect(LiquidGlassMaterial.refractive.refractionStrength, 0.58);
    expect(LiquidGlassMaterial.refractive.edgeThickness, 0.52);
    expect(LiquidGlassMaterial.refractive.highlightIntensity, 0.36);
    expect(refractiveSoftenSigma(0), 0);
    expect(refractiveSoftenSigma(18), 0);
    expect(refractiveLensMargin, greaterThan(8));
    expect(LiquidGlassMaterial.refractive, isNot(LiquidGlassMaterial.classic));
    expect(
      () => LiquidGlassMaterial(refractionStrength: 2),
      throwsAssertionError,
    );
  });

  test('clear glass keeps less of the theme tint', () {
    const tint = Color(0x66F7F4EF);
    final regular = glassFillTint(
      const LiquidGlassMaterial(mode: LiquidGlassRenderMode.enhanced),
      tint,
      shaderActive: false,
      highContrast: false,
    );
    final clear = glassFillTint(
      const LiquidGlassMaterial(
        mode: LiquidGlassRenderMode.enhanced,
        variant: LiquidGlassMaterialVariant.clear,
      ),
      tint,
      shaderActive: false,
      highContrast: false,
    );
    expect(clear.a, lessThan(regular.a));
    final refractiveRegular = glassFillTint(
      const LiquidGlassMaterial(mode: LiquidGlassRenderMode.refractive),
      tint,
      shaderActive: true,
      highContrast: false,
    );
    final refractiveClear = glassFillTint(
      const LiquidGlassMaterial(
        mode: LiquidGlassRenderMode.refractive,
        variant: LiquidGlassMaterialVariant.clear,
      ),
      tint,
      shaderActive: true,
      highContrast: false,
    );
    expect(refractiveClear.a, lessThan(refractiveRegular.a * 0.5));
    expect(
      glassFillTint(
        const LiquidGlassMaterial(),
        tint,
        shaderActive: false,
        highContrast: false,
      ),
      tint,
    );
  });

  testWidgets('classic and enhanced keep the same glass size', (tester) async {
    await pumpNavigationBar(
      tester,
      items: sampleItems(),
      currentIndex: 0,
      onIndexChanged: (_) {},
    );
    await tester.pumpAndSettle();
    final classic = tester.getSize(find.byType(GlassSurface));

    await pumpNavigationBar(
      tester,
      items: sampleItems(),
      currentIndex: 0,
      onIndexChanged: (_) {},
      material: const LiquidGlassMaterial(mode: LiquidGlassRenderMode.enhanced),
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(GlassSurface)), classic);
    expect(tester.takeException(), isNull);
  });

  testWidgets('refractive mode paints even when the shader is unavailable', (
    tester,
  ) async {
    await pumpNavigationBar(
      tester,
      items: sampleItems(),
      currentIndex: 1,
      onIndexChanged: (_) {},
      material: const LiquidGlassMaterial(
        mode: LiquidGlassRenderMode.refractive,
        variant: LiquidGlassMaterialVariant.clear,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    expect(find.byType(LiquidGlassNavigationBar), findsOneWidget);
    expect(find.byIcon(Icons.search_rounded), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('switching the material does not notify or leak a ticker', (
    tester,
  ) async {
    final selections = <int>[];
    Future<void> pump(LiquidGlassMaterial material) {
      return pumpNavigationBar(
        tester,
        items: sampleItems(),
        currentIndex: 0,
        onIndexChanged: selections.add,
        material: material,
      );
    }

    await pump(const LiquidGlassMaterial());
    await tester.pumpAndSettle();
    await pump(const LiquidGlassMaterial(mode: LiquidGlassRenderMode.enhanced));
    await tester.pump();
    await pump(
      const LiquidGlassMaterial(mode: LiquidGlassRenderMode.refractive),
    );
    await tester.pump(const Duration(milliseconds: 20));
    await tester.pumpWidget(const SizedBox.shrink());
    expect(selections, isEmpty);
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });

  test(
    'the refraction program compiles from the package shader asset',
    () async {
      final program = await ui.FragmentProgram.fromAsset(
        RefractiveGlassFilter.localAsset,
      );
      final shader = program.fragmentShader();
      shader.setFloat(2, 32);
      shader.dispose();
      await RefractiveGlassFilter.ensureLoaded();
      expect(RefractiveGlassFilter.loadError, isNull);
      expect(RefractiveGlassFilter.program, isNotNull);
    },
  );

  test('edge normals point out of the rounded glass', () {
    const wide = Size(320, 64);
    final top = refractiveSurfaceNormal(const Offset(160, 2), wide, 32);
    final bottom = refractiveSurfaceNormal(const Offset(160, 62), wide, 32);
    final left = refractiveSurfaceNormal(const Offset(2, 32), wide, 32);
    final right = refractiveSurfaceNormal(const Offset(318, 32), wide, 32);
    expect(top.dy, lessThan(-0.8));
    expect(top.dx.abs(), lessThan(0.2));
    expect(bottom.dy, greaterThan(0.8));
    expect(left.dx, lessThan(-0.8));
    expect(right.dx, greaterThan(0.8));

    final corner = refractiveSurfaceNormal(const Offset(8, 8), wide, 32);
    expect(corner.dx, lessThan(0));
    expect(corner.dy, lessThan(0));
    expect((corner.distance - 1).abs(), lessThan(0.05));

    const circle = Size(64, 64);
    final circleTop = refractiveSurfaceNormal(const Offset(32, 2), circle, 32);
    final circleBottom = refractiveSurfaceNormal(
      const Offset(32, 62),
      circle,
      32,
    );
    expect(circleTop.dy, lessThan(-0.8));
    expect(circleBottom.dy, greaterThan(0.8));

    const morphing = Size(180, 52);
    final midTop = refractiveSurfaceNormal(const Offset(90, 2), morphing, 18);
    final midBottom = refractiveSurfaceNormal(
      const Offset(90, 50),
      morphing,
      18,
    );
    expect(midTop.dy, lessThan(-0.8));
    expect(midBottom.dy, greaterThan(0.8));

    const small = Size(48, 36);
    final smallTop = refractiveSurfaceNormal(const Offset(24, 1), small, 40);
    expect(smallTop.dy, lessThan(0));
    const large = Size(800, 72);
    final largeBottom = refractiveSurfaceNormal(
      const Offset(400, 70),
      large,
      36,
    );
    expect(largeBottom.dy, greaterThan(0.8));
  });
}
