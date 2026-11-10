import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Slot under [point], or null when [point] misses every slot.
///
/// A gap between slots is not a selection. The nearest slot is not used.
int? liquidSlotAt(List<Rect> slots, Offset point) {
  for (var i = 0; i < slots.length; i++) {
    if (slots[i].contains(point)) {
      return i;
    }
  }
  return null;
}

/// Indicator placement while a finger drags the selected capsule.
///
/// [slots] are the resting indicator rectangles. [centerX] is the finger
/// position minus the grab offset from pointer-down, so the capsule does not
/// jump onto the finger. [stretch] adds the liquid leading/trailing growth.
/// Reduced motion passes `stretch: false`.
class LiquidDragPlacement {
  /// Creates a drag placement.
  const LiquidDragPlacement({
    required this.rect,
    required this.blob,
    required this.travelRight,
  });

  /// Capsule bounds before the row clips the stroke.
  final Rect rect;

  /// Droplet amount from `0` at rest to `1` at full stretch.
  final double blob;

  /// Whether the leading end points to the right in local coordinates.
  final bool travelRight;
}

/// Builds [LiquidDragPlacement] from measured slots and a dragged center.
LiquidDragPlacement liquidDragPlacement({
  required List<Rect> slots,
  required Rect origin,
  required double centerX,
  required bool stretch,
  required double morphIntensity,
}) {
  final width = _widthAt(slots, centerX, origin.width);
  final height = origin.height;
  final bounds = _slotBounds(slots, origin);
  final half = width / 2;
  final minCenter = bounds.left + half;
  final maxCenter = math.max(minCenter, bounds.right - half);
  final cx = centerX.clamp(minCenter, maxCenter).toDouble();
  final top = origin.center.dy - height / 2;
  var rect = Rect.fromLTWH(cx - half, top, width, height);
  final delta = cx - origin.center.dx;
  final travelRight = delta >= 0;
  final intensity = morphIntensity.clamp(0.0, 1.0);
  if (!stretch || intensity <= 0 || delta.abs() < 1) {
    return LiquidDragPlacement(rect: rect, blob: 0, travelRight: travelRight);
  }
  final cap = rect.width * 0.85;
  final extra = math.min(delta.abs() * 0.4, cap) * intensity;
  final leading = extra * 0.72;
  final trailing = extra * 0.28;
  final left = travelRight ? rect.left - trailing : rect.left - leading;
  final right = travelRight ? rect.right + leading : rect.right + trailing;
  rect = Rect.fromLTRB(left, rect.top, math.max(left, right), rect.bottom);
  final blob = cap <= 0 ? 0.0 : (extra / cap).clamp(0.0, 1.0);
  return LiquidDragPlacement(rect: rect, blob: blob, travelRight: travelRight);
}

Rect _slotBounds(List<Rect> slots, Rect origin) {
  var left = origin.left;
  var right = origin.right;
  var top = origin.top;
  var bottom = origin.bottom;
  for (final slot in slots) {
    left = math.min(left, slot.left);
    right = math.max(right, slot.right);
    top = math.min(top, slot.top);
    bottom = math.max(bottom, slot.bottom);
  }
  return Rect.fromLTRB(left, top, right, bottom);
}

double _widthAt(List<Rect> slots, double x, double fallback) {
  if (slots.isEmpty) {
    return fallback;
  }
  final ordered = List<Rect>.of(slots)
    ..sort((a, b) => a.left.compareTo(b.left));
  for (final slot in ordered) {
    if (x >= slot.left && x <= slot.right) {
      return slot.width;
    }
  }
  for (var i = 0; i < ordered.length - 1; i++) {
    final a = ordered[i];
    final b = ordered[i + 1];
    if (x > a.right && x < b.left && b.left > a.right) {
      final t = (x - a.right) / (b.left - a.right);
      return a.width + (b.width - a.width) * t;
    }
  }
  if (x < ordered.first.left) {
    return ordered.first.width;
  }
  return ordered.last.width;
}

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
  final extra = travel.abs() * 0.72 * morphIntensity * envelope;
  final pinch = envelope * morphIntensity * 4;
  final leading = extra * 0.72;
  final trailing = extra * 0.28;
  final left = travel >= 0 ? base.left - trailing : base.left - leading;
  final right = travel >= 0 ? base.right + leading : base.right + trailing;
  return Rect.fromLTRB(
    left,
    base.top + pinch / 2,
    math.max(left, right),
    math.max(base.top + pinch / 2, base.bottom - pinch / 2),
  );
}

/// Closed bubble for [rect].
///
/// [blob] is `0` at rest and `1` at the strongest stretch. The leading end
/// stays a full semicircle. The trailing end narrows, so the shape is a
/// droplet while it travels and a stadium when it settles. Both caps sit on
/// the ends of [rect]. This is outline geometry, not optical refraction.
Path liquidBubblePath({
  required Rect rect,
  required double cornerRadius,
  required double blob,
  required bool travelRight,
}) {
  if (rect.width <= 0 || rect.height <= 0) {
    return Path();
  }
  final amount = blob.clamp(0.0, 1.0);
  final double limit = math.min(rect.width, rect.height) / 2;
  final double radius = math.min(math.max(cornerRadius, 0.0), limit);
  if (amount <= 0.001) {
    return Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
  }

  final head = limit;
  final tail = math.max(2.0, head * (1 - 0.46 * amount));
  final fitted = _fitEnds(rect.width, head, tail);
  final headRadius = fitted.$1;
  final tailRadius = fitted.$2;
  final midY = rect.center.dy;
  final headCx = travelRight ? rect.right - headRadius : rect.left + headRadius;
  final tailCx = travelRight ? rect.left + tailRadius : rect.right - tailRadius;
  final headTop = Offset(headCx, midY - headRadius);
  final tailTop = Offset(tailCx, midY - tailRadius);
  final tailBottom = Offset(tailCx, midY + tailRadius);
  // 0 radians is the right side of the oval and positive sweeps go clockwise.
  // A 180 degree [Path.arcToPoint] is ambiguous and was sweeping the trailing
  // cap inward, which left that end as a flat cut. Explicit sweeps keep both
  // caps on the outside of [rect].
  final sweep = travelRight ? math.pi : -math.pi;

  return Path()
    ..moveTo(tailTop.dx, tailTop.dy)
    ..cubicTo(
      _mix(tailCx, headCx, 0.38),
      midY - tailRadius,
      _mix(tailCx, headCx, 0.72),
      midY - headRadius,
      headTop.dx,
      headTop.dy,
    )
    ..arcTo(
      Rect.fromCircle(center: Offset(headCx, midY), radius: headRadius),
      -math.pi / 2,
      sweep,
      false,
    )
    ..cubicTo(
      _mix(tailCx, headCx, 0.72),
      midY + headRadius,
      _mix(tailCx, headCx, 0.38),
      midY + tailRadius,
      tailBottom.dx,
      tailBottom.dy,
    )
    ..arcTo(
      Rect.fromCircle(center: Offset(tailCx, midY), radius: tailRadius),
      math.pi / 2,
      sweep,
      false,
    )
    ..close();
}

(double, double) _fitEnds(double width, double head, double tail) {
  final sum = head + tail;
  if (sum <= width || sum <= 0) {
    return (head, tail);
  }
  final scale = width / sum;
  return (head * scale, tail * scale);
}

double _mix(double a, double b, double t) => a + (b - a) * t;
