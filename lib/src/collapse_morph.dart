import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'glass_shader.dart';
import 'glass_surface.dart';
import 'item_view.dart';
import 'material.dart';
import 'navigation_layout.dart';
import 'style.dart';
import 'theme.dart';

/// Shrinks the full glass bar toward a trailing compact button.
///
/// The child is the item row, laid out at the expanded size. This box keeps
/// that layout size, so the page does not reflow while the glass moves. Paint
/// clips one backdrop to the interpolated shape and shifts the row so the
/// selected icon stays inside that shape. Progress updates repaint only.
class CollapseMorph extends SingleChildRenderObjectWidget {
  /// Creates a morph around the expanded item row.
  const CollapseMorph({
    required this.animation,
    required this.selectedIndex,
    required this.direction,
    required this.style,
    required this.theme,
    required this.material,
    required this.expandedRadius,
    required this.fill,
    required this.veil,
    required this.filter,
    required this.filterControls,
    required super.child,
    super.key,
  });

  /// 0 is the full bar. 1 is the compact button.
  final Animation<double> animation;

  /// Selected destination, or null when the index is not valid.
  final int? selectedIndex;

  /// Trailing edge for the compact button.
  final TextDirection direction;

  /// Dimensions and blur. The child is still laid out with these limits.
  final LiquidGlassNavigationStyle style;

  /// Resolved colors for the tint, rim, and shadow.
  final LiquidGlassNavigationTheme theme;

  /// Classic, enhanced, or refractive paint.
  final LiquidGlassMaterial material;

  /// Radius of the expanded bar.
  final BorderRadius expandedRadius;

  /// Fill painted inside the current shape.
  final Color fill;

  /// Whether to paint the enhanced veil. False for classic and a live shader.
  final bool veil;

  /// Backdrop filter for the current material. Null uses blur or no filter.
  final ui.ImageFilter? filter;

  /// Live shader uniforms. Null for classic and the enhanced fallback.
  final GlassFilterControls? filterControls;

  @override
  RenderCollapseMorph createRenderObject(BuildContext context) {
    return RenderCollapseMorph(
      animation: animation,
      selectedIndex: selectedIndex,
      direction: direction,
      style: style,
      theme: theme,
      material: material,
      expandedRadius: expandedRadius,
      fill: fill,
      veil: veil,
      filter: filter,
      filterControls: filterControls,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderCollapseMorph renderObject,
  ) {
    renderObject
      ..animation = animation
      ..selectedIndex = selectedIndex
      ..direction = direction
      ..style = style
      ..theme = theme
      ..material = material
      ..expandedRadius = expandedRadius
      ..fill = fill
      ..veil = veil
      ..filter = filter
      ..filterControls = filterControls;
  }
}

/// Render object for [CollapseMorph].
class RenderCollapseMorph extends RenderProxyBox {
  /// Creates a morph. The child is attached by the widget.
  RenderCollapseMorph({
    required Animation<double> animation,
    required int? selectedIndex,
    required TextDirection direction,
    required LiquidGlassNavigationStyle style,
    required LiquidGlassNavigationTheme theme,
    required LiquidGlassMaterial material,
    required BorderRadius expandedRadius,
    required Color fill,
    required bool veil,
    required ui.ImageFilter? filter,
    required GlassFilterControls? filterControls,
  }) : _animation = animation, // ignore: prefer_initializing_formals
       _selectedIndex = selectedIndex, // ignore: prefer_initializing_formals
       _direction = direction, // ignore: prefer_initializing_formals
       _style = style, // ignore: prefer_initializing_formals
       _theme = theme, // ignore: prefer_initializing_formals
       _material = material, // ignore: prefer_initializing_formals
       _expandedRadius = expandedRadius, // ignore: prefer_initializing_formals
       _fill = fill, // ignore: prefer_initializing_formals
       _veil = veil, // ignore: prefer_initializing_formals
       _filter = filter, // ignore: prefer_initializing_formals
       _filterControls = filterControls; // ignore: prefer_initializing_formals

  Animation<double> _animation;
  int? _selectedIndex;
  TextDirection _direction;
  LiquidGlassNavigationStyle _style;
  LiquidGlassNavigationTheme _theme;
  LiquidGlassMaterial _material;
  BorderRadius _expandedRadius;
  Color _fill;
  bool _veil;
  ui.ImageFilter? _filter;
  GlassFilterControls? _filterControls;
  Offset _anchor = Offset.zero;

  /// Morph progress listened to for paint.
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

  set selectedIndex(int? value) {
    if (_selectedIndex == value) {
      return;
    }
    _selectedIndex = value;
    markNeedsPaint();
  }

  set direction(TextDirection value) {
    if (_direction == value) {
      return;
    }
    _direction = value;
    markNeedsPaint();
  }

  set style(LiquidGlassNavigationStyle value) {
    if (_style == value) {
      return;
    }
    _style = value;
    markNeedsPaint();
  }

  set theme(LiquidGlassNavigationTheme value) {
    if (_theme == value) {
      return;
    }
    _theme = value;
    markNeedsPaint();
  }

  set material(LiquidGlassMaterial value) {
    if (_material == value) {
      return;
    }
    _material = value;
    markNeedsPaint();
  }

  set expandedRadius(BorderRadius value) {
    if (_expandedRadius == value) {
      return;
    }
    _expandedRadius = value;
    markNeedsPaint();
  }

  set fill(Color value) {
    if (_fill == value) {
      return;
    }
    _fill = value;
    markNeedsPaint();
  }

  set veil(bool value) {
    if (_veil == value) {
      return;
    }
    _veil = value;
    markNeedsPaint();
  }

  set filter(ui.ImageFilter? value) {
    if (_filter == value) {
      return;
    }
    _filter = value;
    markNeedsPaint();
  }

  set filterControls(GlassFilterControls? value) {
    if (identical(_filterControls, value)) {
      return;
    }
    _filterControls = value;
    markNeedsPaint();
  }

  double get _t => _animation.value.clamp(0.0, 1.0);

  /// Morph progress. `0` is the expanded bar and `1` is the compact control.
  double get debugProgress => _t;

  /// Layout passes since this render object was created.
  int debugLayoutCount = 0;

  /// Paint passes since this render object was created.
  int debugPaintCount = 0;

  /// Glass bounds in this box, at the current animation value.
  Rect get debugVisual {
    if (!hasSize) {
      return Rect.zero;
    }
    return _visual(size);
  }

  double _extent(Size expanded) {
    final preferred = math.max(_style.minTouchTarget, _style.iconSize + 20);
    final limit = math.min(expanded.width, expanded.height);
    if (limit <= 0) {
      return preferred;
    }
    return math.min(preferred, limit);
  }

  Rect _visual(Size expanded) {
    final extent = _extent(expanded);
    final compactLeft = _direction == TextDirection.rtl
        ? 0.0
        : math.max(0.0, expanded.width - extent);
    final compactTop = math.max(0.0, expanded.height - extent);
    final compact = Rect.fromLTWH(compactLeft, compactTop, extent, extent);
    return Rect.lerp(Offset.zero & expanded, compact, _t)!;
  }

  BorderRadius _radius(Rect visual) {
    final cap = visual.shortestSide / 2;
    final compact = BorderRadius.circular(cap);
    final lerped = BorderRadius.lerp(_expandedRadius, compact, _t)!;
    Radius clampRadius(Radius radius) {
      return Radius.elliptical(
        math.min(radius.x, cap),
        math.min(radius.y, cap),
      );
    }

    return BorderRadius.only(
      topLeft: clampRadius(lerped.topLeft),
      topRight: clampRadius(lerped.topRight),
      bottomLeft: clampRadius(lerped.bottomLeft),
      bottomRight: clampRadius(lerped.bottomRight),
    );
  }

  /// Paint translation of the item row, in this box.
  ///
  /// Layout stays expanded. This is the offset applied while painting so the
  /// selected icon moves toward the compact center.
  Offset get debugShift {
    final child = this.child;
    if (child == null || !hasSize) {
      return Offset.zero;
    }
    _anchor = _resolveAnchor(child);
    return _shift;
  }

  Offset get _compactCenter {
    final expanded = size;
    final extent = _extent(expanded);
    final left = _direction == TextDirection.rtl
        ? 0.0
        : math.max(0.0, expanded.width - extent);
    final top = math.max(0.0, expanded.height - extent);
    return Offset(left + extent / 2, top + extent / 2);
  }

  Offset get _shift {
    if (_t <= 0 || !hasSize) {
      return Offset.zero;
    }
    return (_compactCenter - _anchor) * _t;
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

  @override
  void performLayout() {
    debugLayoutCount++;
    super.performLayout();
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    if (child.hasSize) {
      _anchor = _resolveAnchor(child);
    }
    final shift = _shift;
    transform.translateByDouble(shift.dx, shift.dy, 0, 1);
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!hasSize) {
      return false;
    }
    final visual = _visual(size);
    // Corners of the bounding box are outside the rounded glass. They must
    // not become a hit target while the bar is moving or compact.
    if (!_radius(visual).toRRect(visual).contains(position)) {
      return false;
    }
    if (_t <= 0) {
      return super.hitTest(result, position: position);
    }
    result.add(BoxHitTestEntry(this, position));
    return true;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    debugPaintCount++;
    final child = this.child;
    if (child == null || !child.hasSize || size.isEmpty) {
      return;
    }
    _anchor = _resolveAnchor(child);
    final visual = _visual(size);
    final radius = _radius(visual);
    _filterControls?.applyRadius(radius);
    final blur = _style.effectiveShadowBlur;
    if (blur > 0) {
      final shadow = radius
          .toRRect(visual)
          .shift(offset + _style.effectiveShadowOffset);
      context.canvas.drawRRect(
        shadow,
        Paint()
          ..color = _theme.shadowColor
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur),
      );
    }
    // The clip is the glass shape, and it is the parent of the backdrop
    // filter. A larger clip paints filtered pixels outside the pill.
    final local = Rect.fromLTWH(0, 0, visual.width, visual.height);
    final localRadius = radius;
    context.pushTransform(
      needsCompositing,
      offset,
      Matrix4.translationValues(visual.left, visual.top, 0),
      (PaintingContext context, Offset offset) {
        context.pushClipRRect(
          needsCompositing,
          offset,
          local,
          localRadius.toRRect(local),
          (PaintingContext context, Offset offset) {
            void contents(PaintingContext context, Offset offset) {
              _paintContents(context, offset, visual, localRadius);
            }

            final filter =
                _filter ??
                (_style.blurSigma <= 0
                    ? null
                    : ui.ImageFilter.blur(
                        sigmaX: _style.blurSigma,
                        sigmaY: _style.blurSigma,
                      ));
            if (filter == null) {
              contents(context, offset);
              return;
            }
            context.pushLayer(
              BackdropFilterLayer(filter: filter),
              contents,
              offset,
            );
          },
        );
      },
    );
  }

  void _paintContents(
    PaintingContext context,
    Offset offset,
    Rect visual,
    BorderRadius radius,
  ) {
    final glass = offset & visual.size;
    context.canvas.drawRect(glass, Paint()..color = _fill);
    if (_veil) {
      context.canvas.save();
      context.canvas.translate(offset.dx, offset.dy);
      GlassVeilPainter(
        borderRadius: radius,
        clear: _material.variant == LiquidGlassMaterialVariant.clear,
      ).paint(context.canvas, visual.size);
      context.canvas.restore();
    }
    final child = this.child;
    if (child != null) {
      context.paintChild(child, offset + _shift - visual.topLeft);
    }
    if (_style.borderWidth <= 0) {
      return;
    }
    context.canvas.save();
    context.canvas.translate(offset.dx, offset.dy);
    GlassRimPainter(
      borderRadius: radius,
      color: _theme.borderColor,
      width: _style.borderWidth,
    ).paint(context.canvas, visual.size);
    context.canvas.restore();
  }

  @override
  bool get alwaysNeedsCompositing => _style.blurSigma > 0 || _filter != null;
}
