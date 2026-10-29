import 'dart:math' as math;
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
    expect(morphed.right - rigid.right, greaterThan(rigid.left - morphed.left));

    final backward = liquidIndicatorRect(
      from: to,
      to: from,
      t: 0.5,
      morphIntensity: 1,
      morph: true,
    );
    expect(backward.width, greaterThan(rigid.width + 20));
    expect(backward.center.dx, lessThan(to.center.dx));
    expect(
      rigid.left - backward.left,
      greaterThan(backward.right - rigid.right),
    );
  });

  test(
    'the bubble is a pill at rest and narrower at the trailing end in flight',
    () {
      final settled = liquidBubblePath(
        rect: from,
        cornerRadius: 24,
        blob: 0,
        travelRight: true,
      );
      expect(settled.getBounds(), from);

      final moving = liquidIndicatorRect(
        from: from,
        to: to,
        t: 0.5,
        morphIntensity: 1,
        morph: true,
      );
      final forward = liquidBubblePath(
        rect: moving,
        cornerRadius: 24,
        blob: 1,
        travelRight: true,
      );
      expect(
        forward.contains(Offset(moving.right - 2, moving.center.dy)),
        isTrue,
      );
      expect(
        forward.contains(Offset(moving.left + 2, moving.center.dy)),
        isTrue,
      );
      expect(
        forward.contains(Offset(moving.left + 2, moving.top + 1)),
        isFalse,
      );
      _expectCapsOnRect(forward, moving);

      final backward = liquidBubblePath(
        rect: moving,
        cornerRadius: 24,
        blob: 1,
        travelRight: false,
      );
      expect(
        backward.contains(Offset(moving.left + 2, moving.center.dy)),
        isTrue,
      );
      expect(
        backward.contains(Offset(moving.right - 2, moving.center.dy)),
        isTrue,
      );
      expect(
        backward.contains(Offset(moving.right - 2, moving.top + 1)),
        isFalse,
      );
      _expectCapsOnRect(backward, moving);
    },
  );

  test('both caps stay on the rect through a transition and a retarget', () {
    const samples = <double>[0, 0.12, 0.5, 1];
    for (final t in samples) {
      final forward = liquidIndicatorRect(
        from: from,
        to: to,
        t: t,
        morphIntensity: 1,
        morph: true,
      );
      final forwardPath = liquidBubblePath(
        rect: forward,
        cornerRadius: 24,
        blob: mathBlob(t),
        travelRight: true,
      );
      _expectCapsOnRect(forwardPath, forward);

      final backward = liquidIndicatorRect(
        from: to,
        to: from,
        t: t,
        morphIntensity: 1,
        morph: true,
      );
      final backwardPath = liquidBubblePath(
        rect: backward,
        cornerRadius: 24,
        blob: mathBlob(t),
        travelRight: false,
      );
      _expectCapsOnRect(backwardPath, backward);
    }

    final inFlight = liquidIndicatorRect(
      from: from,
      to: to,
      t: 0.45,
      morphIntensity: 1,
      morph: true,
    );
    const redirected = Rect.fromLTWH(110, 8, 80, 48);
    final retargeted = liquidIndicatorRect(
      from: inFlight,
      to: redirected,
      t: 0.3,
      morphIntensity: 1,
      morph: true,
    );
    _expectCapsOnRect(
      liquidBubblePath(
        rect: retargeted,
        cornerRadius: 24,
        blob: mathBlob(0.3),
        travelRight: redirected.center.dx >= inFlight.center.dx,
      ),
      retargeted,
    );

    final reduced = liquidIndicatorRect(
      from: from,
      to: to,
      t: 0.5,
      morphIntensity: 1,
      morph: false,
    );
    _expectCapsOnRect(
      liquidBubblePath(
        rect: reduced,
        cornerRadius: 24,
        blob: 0,
        travelRight: true,
      ),
      reduced,
    );
  });
}

double mathBlob(double t) => math.sin(t.clamp(0.0, 1.0) * math.pi);

void _expectCapsOnRect(Path path, Rect rect) {
  final bounds = path.getBounds();
  expect(bounds.left, closeTo(rect.left, 1));
  expect(bounds.right, closeTo(rect.right, 1));
  expect(bounds.top, greaterThanOrEqualTo(rect.top - 0.5));
  expect(bounds.bottom, lessThanOrEqualTo(rect.bottom + 0.5));
  expect(path.contains(Offset(rect.left + 1, rect.center.dy)), isTrue);
  expect(path.contains(Offset(rect.right - 1, rect.center.dy)), isTrue);
}
