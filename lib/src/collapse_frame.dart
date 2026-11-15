import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'glass_surface.dart';
import 'item_view.dart';
import 'navigation_layout.dart';
import 'style.dart';
import 'theme.dart';

/// Glass surface that shrinks from the full bar to a compact button.
///
/// The child is laid out at the expanded size. This box reports the
/// interpolated size, clips the glass to that size, and shifts the child so
/// the selected icon moves toward the center. One backdrop blur is painted
/// for the current shape. There is no second glass surface.
class CollapseFrame extends SingleChildRenderObjectWidget {
  /// Creates a collapsing glass frame around the expanded item row.
  const CollapseFrame({
    required this.progress,
    required this.selectedIndex,
    required this.style,
    required this.theme,
    required this.borderRadius,
    required super.child,
    super.key,
  });

  /// 0 is the full bar. 1 is the compact button.
  final double progress;

  /// Selected destination, or null when the index is not valid.
  final int? selectedIndex;

  /// Dimensions and blur. The child is still laid out with these limits.
  final LiquidGlassNavigationStyle style;

  /// Resolved colors for the tint, rim, and shadow.
  final LiquidGlassNavigationTheme theme;

  /// Radius of the current glass shape.
  final BorderRadius borderRadius;

  @override
  RenderCollapseFrame createRenderObject(BuildContext context) {
    return RenderCollapseFrame(
      progress: progress,
      selectedIndex: selectedIndex,
      style: style,
      theme: theme,
      borderRadius: borderRadius,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderCollapseFrame renderObject,
  ) {
    final render = renderObject;
    render
      ..progress = progress
      ..selectedIndex = selectedIndex
      ..style = style
      ..theme = theme
      ..borderRadius = borderRadius;
  }
}

/// Render object for [CollapseFrame].
class RenderCollapseFrame extends RenderBox
    with RenderObjectWithChildMixin<RenderBox> {
  /// Creates a frame. The child is attached by the widget.
  RenderCollapseFrame({
    required double progress,
    required int? selectedIndex,
    required LiquidGlassNavigationStyle style,
    required LiquidGlassNavigationTheme theme,
    required BorderRadius borderRadius,
  }) : _progress = progress, // ignore: prefer_initializing_formals
       _selectedIndex = selectedIndex, // ignore: prefer_initializing_formals
       _style = style, // ignore: prefer_initializing_formals
       _theme = theme, // ignore: prefer_initializing_formals
       _borderRadius = borderRadius; // ignore: prefer_initializing_formals

  double _progress;
  int? _selectedIndex;
  LiquidGlassNavigationStyle _style;
  LiquidGlassNavigationTheme _theme;
  BorderRadius _borderRadius;
  Offset _anchor = Offset.zero;

  /// Current morph, from 0 expanded to 1 collapsed.
  double get progress => _progress;

  set progress(double value) {
    if (_progress == value) {
      return;
    }
    _progress = value;
    markNeedsLayout();
  }

  /// Selected item used as the icon anchor.
  int? get selectedIndex => _selectedIndex;

  set selectedIndex(int? value) {
    if (_selectedIndex == value) {
      return;
    }
    _selectedIndex = value;
    markNeedsLayout();
  }

  set style(LiquidGlassNavigationStyle value) {
    if (_style == value) {
      return;
    }
    _style = value;
    markNeedsLayout();
  }

  set theme(LiquidGlassNavigationTheme value) {
    if (_theme == value) {
      return;
    }
    _theme = value;
    markNeedsPaint();
  }

  set borderRadius(BorderRadius value) {
    if (_borderRadius == value) {
      return;
    }
    _borderRadius = value;
    markNeedsPaint();
  }

  /// Diameter of the compact button for an expanded child of [expanded].
  double extentFor(Size expanded) {
    final preferred = math.max(_style.minTouchTarget, _style.iconSize + 20);
    final limit = math.min(expanded.width, expanded.height);
    if (limit <= 0) {
      return preferred;
    }
    return math.min(preferred, limit);
  }

  Offset get _shift {
    if (_progress <= 0 || child == null) {
      return Offset.zero;
    }
    final center = Offset(size.width / 2, size.height / 2);
    return Offset(
      (center.dx - _anchor.dx) * _progress,
      (center.dy - _anchor.dy) * _progress,
    );
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      _anchor = Offset.zero;
      return;
    }
    child.layout(constraints.loosen(), parentUsesSize: true);
    final expanded = child.size;
    _anchor = Offset(expanded.width / 2, expanded.height / 2);
    final extent = extentFor(expanded);
    final width = _lerp(expanded.width, extent);
    final height = _lerp(expanded.height, extent);
    size = constraints.constrain(Size(width, height));
  }

  double _lerp(double expanded, double collapsed) {
    return expanded + (collapsed - expanded) * _progress.clamp(0.0, 1.0);
  }

  Offset _resolveAnchor(RenderBox child) {
    final index = _selectedIndex;
    final row = _findRow(child);
    if (row == null || index == null) {
      return Offset(child.size.width / 2, child.size.height / 2);
    }
    final center = _iconCenter(row, index);
    if (center == null) {
      return Offset(child.size.width / 2, child.size.height / 2);
    }
    return MatrixUtils.transformPoint(row.getTransformTo(child), center);
  }

  RenderLiquidNavigation? _findRow(RenderObject node) {
    if (node is RenderLiquidNavigation) {
      return node;
    }
    RenderLiquidNavigation? found;
    node.visitChildren((RenderObject child) {
      found ??= _findRow(child);
    });
    return found;
  }

  Offset? _iconCenter(RenderLiquidNavigation row, int index) {
    var slot = row.firstChild;
    var i = 0;
    while (slot != null && i < index) {
      slot = row.childAfter(slot);
      i++;
    }
    if (slot == null) {
      return null;
    }
    final band = _findBand(slot);
    if (band == null || !band.hasSize) {
      return null;
    }
    final center = Offset(band.size.width / 2, band.size.height / 2);
    return MatrixUtils.transformPoint(band.getTransformTo(row), center);
  }

  RenderIconBand? _findBand(RenderObject node) {
    if (node is RenderIconBand) {
      return node;
    }
    RenderIconBand? found;
    node.visitChildren((RenderObject child) {
      found ??= _findBand(child);
    });
    return found;
  }

  RRect get _rrect => _borderRadius.toRRect(Offset.zero & size);

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!size.contains(position) || !_rrect.contains(position)) {
      return false;
    }
    final hitChild = hitTestChildren(result, position: position);
    if (hitChild || _rrect.contains(position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final child = this.child;
    if (child == null) {
      return false;
    }
    return child.hitTest(result, position: position - _shift);
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    final shift = _shift;
    transform.translateByDouble(shift.dx, shift.dy, 0, 1);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (size.isEmpty) {
      return;
    }
    final child = this.child;
    if (child != null && child.hasSize) {
      _anchor = _resolveAnchor(child);
    }
    final blur = _style.effectiveShadowBlur;
    if (blur > 0) {
      final shadow = _rrect.shift(offset + _style.effectiveShadowOffset);
      context.canvas.drawRRect(
        shadow,
        Paint()
          ..color = _theme.shadowColor
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur),
      );
    }
    context.pushClipRRect(
      needsCompositing,
      offset,
      Offset.zero & size,
      _rrect,
      (PaintingContext context, Offset offset) {
        if (_style.blurSigma > 0) {
          context.pushLayer(
            BackdropFilterLayer(
              filter: ImageFilter.blur(
                sigmaX: _style.blurSigma,
                sigmaY: _style.blurSigma,
              ),
            ),
            _paintContents,
            offset,
          );
        } else {
          _paintContents(context, offset);
        }
      },
    );
  }

  void _paintContents(PaintingContext context, Offset offset) {
    context.canvas.drawRect(
      offset & size,
      Paint()..color = _theme.resolvedGlassTint,
    );
    final child = this.child;
    if (child != null) {
      context.paintChild(child, offset + _shift);
    }
    if (_style.borderWidth <= 0) {
      return;
    }
    context.canvas.save();
    context.canvas.translate(offset.dx, offset.dy);
    GlassRimPainter(
      borderRadius: _borderRadius,
      color: _theme.borderColor,
      width: _style.borderWidth,
    ).paint(context.canvas, size);
    context.canvas.restore();
  }

  @override
  bool get alwaysNeedsCompositing => _style.blurSigma > 0;
}
