import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_bottom_navigator/src/indicator_geometry.dart';

void main() {
  const from = Rect.fromLTWH(10, 8, 80, 48);
  const to = Rect.fromLTWH(210, 8, 80, 48);

  test('resting progress matches the endpoints', () {
    expect(
      liquidIndicatorRect(
        from: from,
        to: to,
        t: 0,
        morphIntensity: 1,
        morph: true,
      ),
      from,
    );
    expect(
      liquidIndicatorRect(
        from: from,
        to: to,
        t: 1,
        morphIntensity: 1,
        morph: true,
      ),
      to,
    );
    expect(
      liquidIndicatorRect(
        from: from,
        to: to,
        t: 0.5,
        morphIntensity: 0,
        morph: true,
      ).width,
      closeTo(80, 0.1),
    );
  });

  test('morphing stretches the capsule at mid travel and still reaches the destination', () {
    final morphed = liquidIndicatorRect(
      from: from,
      to: to,
      t: 0.5,
      morphIntensity: 1,
      morph: true,
    );
    final rigid = liquidIndicatorRect(
      from: from,
      to: to,
      t: 0.5,
      morphIntensity: 0,
      morph: false,
    );
    expect(morphed.width, greaterThan(rigid.width + 20));
    expect(morphed.center.dx, greaterThan(from.center.dx));
    expect(morphed.center.dx, lessThan(to.center.dx));

    final backward = liquidIndicatorRect(
      from: to,
      to: from,
      t: 0.5,
      morphIntensity: 1,
      morph: true,
    );
    expect(backward.width, greaterThan(rigid.width + 20));
    expect(backward.center.dx, lessThan(to.center.dx));
  });
}
