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
}
