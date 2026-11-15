import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Slides [child] downward without changing its layout size.
///
/// [animation] is 0 at rest and 1 when the child is fully below the viewport.
/// The travel distance is the gap from the child's bottom to the bottom of
/// the Flutter view, plus the child's height and [extra] for a shadow.
/// A settled value of 0 paints and hits like the child alone.
class HideSlide extends SingleChildRenderObjectWidget {
  /// Creates a slide for [animation].
  const HideSlide({
    required this.animation,
    required this.viewportHeight,
    required this.extra,
    required super.child,
    super.key,
  });

  /// 0 visible, 1 hidden.
  final Animation<double> animation;

  /// Height of the Flutter view, in logical pixels.
  final double viewportHeight;

  /// Extra travel for a shadow that paints outside the child.
  final double extra;

  @override
  RenderHideSlide createRenderObject(BuildContext context) {
    return RenderHideSlide(
      animation: animation,
      viewportHeight: viewportHeight,
      extra: extra,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderHideSlide renderObject) {
    renderObject
      ..animation = animation
      ..viewportHeight = viewportHeight
      ..extra = extra;
  }
}

/// Render object for [HideSlide].
class RenderHideSlide extends RenderProxyBox {
  /// Creates a slide. The child is attached by the widget.
  RenderHideSlide({
    required Animation<double> animation,
    required double viewportHeight,
    required double extra,
  }) : _animation = animation, // ignore: prefer_initializing_formals
       _viewportHeight = viewportHeight, // ignore: prefer_initializing_formals
       _extra = extra; // ignore: prefer_initializing_formals

  Animation<double> _animation;
  double _viewportHeight;
  double _extra;

  /// Slide progress listened to for paint.
  Animation<double> get animation => _animation;

  set animation(Animation<double> value) {
    if (identical(_animation, value)) {
      return;
    }
    if (attached) {
      _animation.removeListener(_onTick);
    }
    _animation = value;
    if (attached) {
      _animation.addListener(_onTick);
    }
    _onTick();
  }

  set viewportHeight(double value) {
    if (_viewportHeight == value) {
      return;
    }
    _viewportHeight = value;
    markNeedsPaint();
  }

  set extra(double value) {
    if (_extra == value) {
      return;
    }
    _extra = value;
    markNeedsPaint();
  }

  /// Downward paint offset at the current animation value.
  double get debugTravel => _travel * _animation.value.clamp(0.0, 1.0);

  double get _travel {
    if (!attached || !hasSize) {
      return 0;
    }
    final globalBottom = localToGlobal(Offset(0, size.height)).dy;
    final gap = math.max(0.0, _viewportHeight - globalBottom);
    return gap + size.height + math.max(0, _extra);
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _animation.addListener(_onTick);
  }

  @override
  void detach() {
    _animation.removeListener(_onTick);
    super.detach();
  }

  void _onTick() {
    markNeedsPaint();
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (_animation.value > 0) {
      return false;
    }
    return super.hitTest(result, position: position);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final progress = _animation.value;
    if (progress >= 1 || child == null) {
      return;
    }
    if (progress <= 0) {
      super.paint(context, offset);
      return;
    }
    context.pushTransform(
      needsCompositing,
      offset,
      Matrix4.translationValues(0, _travel * progress, 0),
      super.paint,
    );
  }
}
