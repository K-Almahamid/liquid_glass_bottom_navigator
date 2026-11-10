import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_bottom_navigator/src/indicator_geometry.dart';

void main() {
  const origin = Rect.fromLTWH(10, 4, 40, 20);
  const slots = <Rect>[origin, Rect.fromLTWH(70, 4, 50, 20)];

  test('slot hit uses containment and ignores gaps', () {
    expect(liquidSlotAt(slots, const Offset(20, 10)), 0);
    expect(liquidSlotAt(slots, const Offset(90, 10)), 1);
    expect(liquidSlotAt(slots, const Offset(60, 10)), isNull);
    expect(liquidSlotAt(slots, const Offset(20, 40)), isNull);
  });

  test('slot hit follows laid-out RTL rectangles', () {
    const rtl = <Rect>[
      Rect.fromLTWH(80, 0, 40, 20),
      Rect.fromLTWH(0, 0, 40, 20),
    ];
    expect(liquidSlotAt(rtl, const Offset(90, 10)), 0);
    expect(liquidSlotAt(rtl, const Offset(10, 10)), 1);
    expect(liquidSlotAt(rtl, const Offset(60, 10)), isNull);
  });

  test('drag placement keeps the requested center when stretch is off', () {
    final placed = liquidDragPlacement(
      slots: slots,
      origin: origin,
      centerX: origin.center.dx + 12,
      stretch: false,
      morphIntensity: 1,
    );
    expect(placed.rect.center.dx, closeTo(origin.center.dx + 12, 0.01));
    expect(placed.rect.width, closeTo(origin.width, 0.01));
    expect(placed.blob, 0);
    expect(placed.travelRight, isTrue);
  });

  test('drag placement stretches toward travel and clamps to the slots', () {
    final stretched = liquidDragPlacement(
      slots: slots,
      origin: origin,
      centerX: origin.center.dx + 16,
      stretch: true,
      morphIntensity: 1,
    );
    expect(stretched.rect.width, greaterThan(origin.width));
    expect(stretched.blob, greaterThan(0));
    expect(stretched.travelRight, isTrue);
    expect(stretched.rect.right, greaterThan(origin.right));

    final clamped = liquidDragPlacement(
      slots: slots,
      origin: origin,
      centerX: 1000,
      stretch: false,
      morphIntensity: 1,
    );
    expect(clamped.rect.right, lessThanOrEqualTo(slots.last.right + 0.01));
    expect(clamped.rect.left, greaterThanOrEqualTo(slots.first.left - 0.01));
  });
}
