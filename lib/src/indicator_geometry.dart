import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Indicator rectangle for a selection transition.
///
/// [t] is the spring progress. Values outside `0..1` are clamped.
///
/// When [morph] is true, the capsule grows along its direction of travel and
/// returns to the destination size at the end. The extra width follows a sine
/// envelope, so the stretch is zero at both endpoints. A small vertical pinch
/// keeps the stretch from looking heavier than the resting capsule.
///
/// This is geometry only. It is not a refraction shader.
Rect liquidIndicatorRect({
  required Rect from,
  required Rect to,
  required double t,
  required double morphIntensity,
  required bool morph,
}) {
  final progress = t.clamp(0.0, 1.0);
  final base = Rect.lerp(from, to, progress)!;
  if (!morph || morphIntensity <= 0 || progress == 0 || progress == 1) {
    return base;
  }
  final travel = to.center.dx - from.center.dx;
  final envelope = math.sin(progress * math.pi);
  final extra = travel.abs() * 0.45 * morphIntensity * envelope;
  final pinch = envelope * morphIntensity * 3;
  final leading = extra * 0.65;
  final trailing = extra * 0.35;
  final left = travel >= 0 ? base.left - trailing : base.left - leading;
  final right = travel >= 0 ? base.right + leading : base.right + trailing;
  return Rect.fromLTRB(
    left,
    base.top + pinch / 2,
    math.max(left, right),
    math.max(base.top + pinch / 2, base.bottom - pinch / 2),
  );
}
