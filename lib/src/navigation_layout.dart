import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'indicator_geometry.dart';
import 'options.dart';

/// Lays out navigation items and paints the selection capsule behind them.
///
/// The capsule listens to [animation] and repaints without rebuilding items.
class LiquidNavigationLayout extends MultiChildRenderObjectWidget {
  /// Creates the item row.
  const LiquidNavigationLayout({
    required this.targetIndex,
    required this.animation,
    required this.textDirection,
    required this.itemLayout,
    required this.itemSpacing,
    required this.minHeight,
    required this.maxHeight,
    required this.indicatorInset,
    required this.indicatorRadius,
    required this.indicatorColor,
    required this.indicatorBorderColor,
    required this.indicatorBorderWidth,
    required this.morph,
    required this.morphIntensity,
    required super.children,
    super.key,
  });

  /// Selected item, or null when the index is not usable.
  final int? targetIndex;

  /// Selection progress. `1` means the capsule is resting on [targetIndex].
  final Animation<double> animation;

  /// Layout direction.
  final TextDirection textDirection;

  /// Equal or intrinsic item widths.
  final LiquidGlassItemLayout itemLayout;

  /// Gap between slots.
  final double itemSpacing;

  /// Minimum row height.
  final double minHeight;

  /// Maximum row height.
  final double maxHeight;

  /// Inset of the capsule inside a slot.
  final EdgeInsets indicatorInset;

  /// Capsule radius.
  final BorderRadius indicatorRadius;

  /// Capsule fill.
  final Color indicatorColor;

  /// Capsule stroke.
  final Color indicatorBorderColor;

  /// Capsule stroke width.
  final double indicatorBorderWidth;

  /// Whether the capsule stretches during the transition.
  final bool morph;

  /// Stretch amount from `0` to `1`.
  final double morphIntensity;

  @override
  RenderLiquidNavigation createRenderObject(BuildContext context) {
    return RenderLiquidNavigation(
      targetIndex: targetIndex,
      animation: animation,
      textDirection: textDirection,
      itemLayout: itemLayout,
      itemSpacing: itemSpacing,
      minHeight: minHeight,
      maxHeight: maxHeight,
      indicatorInset: indicatorInset,
      indicatorRadius: indicatorRadius,
      indicatorColor: indicatorColor,
      indicatorBorderColor: indicatorBorderColor,
      indicatorBorderWidth: indicatorBorderWidth,
      morph: morph,
      morphIntensity: morphIntensity,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderLiquidNavigation renderObject,
  ) {
    renderObject
      ..targetIndex = targetIndex
      ..animation = animation
      ..textDirection = textDirection
      ..itemLayout = itemLayout
      ..itemSpacing = itemSpacing
      ..minHeight = minHeight
      ..maxHeight = maxHeight
      ..indicatorInset = indicatorInset
      ..indicatorRadius = indicatorRadius
      ..indicatorColor = indicatorColor
      ..indicatorBorderColor = indicatorBorderColor
      ..indicatorBorderWidth = indicatorBorderWidth
      ..morph = morph
      ..morphIntensity = morphIntensity;
  }
}

class _NavParentData extends ContainerBoxParentData<RenderBox> {}

/// Render object for [LiquidNavigationLayout].
class RenderLiquidNavigation extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _NavParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _NavParentData> {
  /// Creates a navigation row.
  RenderLiquidNavigation({
    required this._targetIndex,
    required this._animation,
    required this._textDirection,
    required this._itemLayout,
    required this._itemSpacing,
    required this._minHeight,
    required this._maxHeight,
    required this._indicatorInset,
    required this._indicatorRadius,
    required this._indicatorColor,
    required this._indicatorBorderColor,
    required this._indicatorBorderWidth,
    required this._morph,
    required this._morphIntensity,
  }) {
    _animation.addListener(_handleTick);
  }

  final Paint _fill = Paint()..isAntiAlias = true;
  final Paint _stroke = Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke;

  int? _targetIndex;
  Animation<double> _animation;
  TextDirection _textDirection;
  LiquidGlassItemLayout _itemLayout;
  double _itemSpacing;
  double _minHeight;
  double _maxHeight;
  EdgeInsets _indicatorInset;
  BorderRadius _indicatorRadius;
  Color _indicatorColor;
  Color _indicatorBorderColor;
  double _indicatorBorderWidth;
  bool _morph;
  double _morphIntensity;
  Rect? _from;
  List<Rect> _itemRects = const <Rect>[];
  Rect? _paintedIndicator;

  /// Slot rectangles from the latest layout, in local coordinates.
  List<Rect> get debugItemRects => List<Rect>.unmodifiable(_itemRects);

  /// Capsule rectangle from the latest paint, in local coordinates.
  Rect? get debugIndicatorRect => _paintedIndicator;

  /// Selected slot.
  int? get targetIndex => _targetIndex;

  set targetIndex(int? value) {
    if (_targetIndex == value) {
      return;
    }
    _targetIndex = value;
    markNeedsPaint();
  }

  /// Progress animation. Replaced only when the instance changes.
  Animation<double> get animation => _animation;

  set animation(Animation<double> value) {
    if (identical(_animation, value)) {
      return;
    }
    _animation.removeListener(_handleTick);
    _animation = value;
    _animation.addListener(_handleTick);
    markNeedsPaint();
  }

  /// Layout direction.
  ///
  /// A direction change drops an in-flight origin. The capsule uses the new
  /// slot geometry instead of a rectangle measured in the previous direction.
  set textDirection(TextDirection value) {
    if (_textDirection == value) {
      return;
    }
    _textDirection = value;
    _from = null;
    markNeedsLayout();
  }

  /// Item width policy.
  set itemLayout(LiquidGlassItemLayout value) {
    if (_itemLayout == value) {
      return;
    }
    _itemLayout = value;
    markNeedsLayout();
  }

  /// Gap between slots.
  set itemSpacing(double value) {
    if (_itemSpacing == value) {
      return;
    }
    _itemSpacing = value;
    markNeedsLayout();
  }

  /// Minimum row height.
  set minHeight(double value) {
    if (_minHeight == value) {
      return;
    }
    _minHeight = value;
    markNeedsLayout();
  }

  /// Maximum row height.
  set maxHeight(double value) {
    if (_maxHeight == value) {
      return;
    }
    _maxHeight = value;
    markNeedsLayout();
  }

  /// Capsule inset.
  set indicatorInset(EdgeInsets value) {
    if (_indicatorInset == value) {
      return;
    }
    _indicatorInset = value;
    markNeedsPaint();
  }

  /// Capsule radius.
  set indicatorRadius(BorderRadius value) {
    if (_indicatorRadius == value) {
      return;
    }
    _indicatorRadius = value;
    markNeedsPaint();
  }

  /// Capsule fill.
  set indicatorColor(Color value) {
    if (_indicatorColor == value) {
      return;
    }
    _indicatorColor = value;
    markNeedsPaint();
  }

  /// Capsule stroke.
  set indicatorBorderColor(Color value) {
    if (_indicatorBorderColor == value) {
      return;
    }
    _indicatorBorderColor = value;
    markNeedsPaint();
  }

  /// Capsule stroke width.
  set indicatorBorderWidth(double value) {
    if (_indicatorBorderWidth == value) {
      return;
    }
    _indicatorBorderWidth = value;
    markNeedsPaint();
  }

  /// Whether the current transition stretches.
  set morph(bool value) {
    if (_morph == value) {
      return;
    }
    _morph = value;
    markNeedsPaint();
  }

  /// Stretch amount.
  set morphIntensity(double value) {
    if (_morphIntensity == value) {
      return;
    }
    _morphIntensity = value;
    markNeedsPaint();
  }

  /// Starts a transition from the capsule's current rectangle to [index].
  ///
  /// Call this before resetting [animation] so the origin is the in-flight
  /// position rather than the previous destination.
  void beginTransition(int? index) {
    if (index == _targetIndex && _from == null) {
      return;
    }
    _from = _visualRect();
    _targetIndex = index;
    markNeedsPaint();
  }

  /// Drops any in-flight origin and shows [index] directly.
  void jumpTo(int? index) {
    _from = null;
    _targetIndex = index;
    markNeedsPaint();
  }

  /// Drops the in-flight origin. The resting position is [targetIndex].
  void snap() {
    _from = null;
    markNeedsPaint();
  }

  void _handleTick() {
    markNeedsPaint();
  }

  @override
  void dispose() {
    _animation.removeListener(_handleTick);
    super.dispose();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _NavParentData) {
      child.parentData = _NavParentData();
    }
  }

  List<RenderBox> get _children {
    final children = <RenderBox>[];
    var child = firstChild;
    while (child != null) {
      children.add(child);
      child = childAfter(child);
    }
    return children;
  }

  @override
  void performLayout() {
    final previousSize = hasSize ? size : Size.zero;
    final children = _children;
    final count = children.length;
    final incomingMaxWidth = constraints.maxWidth;
    final boundedWidth = incomingMaxWidth.isFinite;
    final heightLimit = math.min(
      _maxHeight,
      constraints.maxHeight.isFinite ? constraints.maxHeight : double.infinity,
    );
    final minHeight = _minHeight.clamp(
      0.0,
      heightLimit.isFinite ? heightLimit : _minHeight,
    );

    if (count == 0) {
      final width = boundedWidth ? incomingMaxWidth : 0.0;
      size = constraints.constrain(Size(width, minHeight.toDouble()));
      _itemRects = const <Rect>[];
      _remapFrom(previousSize);
      return;
    }

    final spacing = _itemSpacing;
    final gapTotal = spacing * (count - 1);
    final available = boundedWidth
        ? math.max(0.0, incomingMaxWidth - gapTotal)
        : double.infinity;
    var equal =
        _itemLayout == LiquidGlassItemLayout.equal && available.isFinite;
    var widths = <double>[];

    if (!equal) {
      widths = <double>[
        for (final child in children)
          child
              .getMaxIntrinsicWidth(heightLimit)
              .clamp(0.0, available.isFinite ? available : double.infinity),
      ];
      final sum = widths.fold<double>(0, (total, width) => total + width);
      if (available.isFinite && sum > available + 0.1) {
        equal = true;
      }
    }

    if (equal) {
      final each = available / count;
      widths = List<double>.filled(count, each);
      final consumed = each * count;
      final remainder = available - consumed;
      widths[count - 1] = each + remainder;
    }

    final looseHeight = double.infinity;
    var contentHeight = minHeight.toDouble();
    for (var i = 0; i < count; i++) {
      children[i].layout(
        BoxConstraints(
          minWidth: widths[i],
          maxWidth: widths[i],
          minHeight: 0,
          maxHeight: looseHeight,
        ),
        parentUsesSize: true,
      );
      contentHeight = math.max(contentHeight, children[i].size.height);
    }
    if (heightLimit.isFinite) {
      contentHeight = math.min(contentHeight, heightLimit);
    }

    final contentWidth =
        widths.fold<double>(0, (total, width) => total + width) + gapTotal;
    size = constraints.constrain(
      Size(boundedWidth ? incomingMaxWidth : contentWidth, contentHeight),
    );

    for (var i = 0; i < count; i++) {
      children[i].layout(
        BoxConstraints.tightFor(width: widths[i], height: size.height),
      );
    }

    final rects = List<Rect>.filled(count, Rect.zero);
    if (_textDirection == TextDirection.rtl) {
      var cursor = size.width;
      if (!equal && contentWidth < size.width) {
        cursor = size.width;
      }
      for (var i = 0; i < count; i++) {
        cursor -= widths[i];
        final parentData = children[i].parentData! as _NavParentData;
        parentData.offset = Offset(cursor, 0);
        rects[i] = Offset(cursor, 0) & Size(widths[i], size.height);
        cursor -= spacing;
      }
    } else {
      var cursor = 0.0;
      for (var i = 0; i < count; i++) {
        final parentData = children[i].parentData! as _NavParentData;
        parentData.offset = Offset(cursor, 0);
        rects[i] = Offset(cursor, 0) & Size(widths[i], size.height);
        cursor += widths[i] + spacing;
      }
    }

    _itemRects = rects;
    _remapFrom(previousSize);
  }

  void _remapFrom(Size previousSize) {
    final from = _from;
    if (from == null || previousSize.width <= 0 || previousSize.height <= 0) {
      return;
    }
    if (previousSize == size) {
      return;
    }
    _from = Rect.fromLTRB(
      from.left / previousSize.width * size.width,
      from.top / previousSize.height * size.height,
      from.right / previousSize.width * size.width,
      from.bottom / previousSize.height * size.height,
    );
  }

  Rect? _rectFor(int? index) {
    if (index == null || index < 0 || index >= _itemRects.length) {
      return null;
    }
    final raw = _itemRects[index];
    final rect = Rect.fromLTRB(
      raw.left + _indicatorInset.left,
      raw.top + _indicatorInset.top,
      raw.right - _indicatorInset.right,
      raw.bottom - _indicatorInset.bottom,
    );
    if (rect.width <= 0 || rect.height <= 0) {
      return raw;
    }
    return rect;
  }

  Rect? _visualRect() {
    final target = _rectFor(_targetIndex);
    final from = _from;
    if (target == null) {
      return null;
    }
    if (from == null) {
      return target;
    }
    return liquidIndicatorRect(
      from: from,
      to: target,
      t: _animation.value,
      morphIntensity: _morphIntensity,
      morph: _morph,
    );
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final indicator = _visualRect();
    _paintedIndicator = indicator;
    if (indicator != null) {
      final rect = indicator.shift(offset);
      final rrect = _indicatorRadius.toRRect(rect);
      _fill.color = _indicatorColor;
      context.canvas.drawRRect(rrect, _fill);
      if (_indicatorBorderWidth > 0 && _indicatorBorderColor.a > 0) {
        _stroke
          ..color = _indicatorBorderColor
          ..strokeWidth = _indicatorBorderWidth;
        context.canvas.drawRRect(
          rrect.deflate(_indicatorBorderWidth / 2),
          _stroke,
        );
      }
    }
    defaultPaint(context, offset);
  }
}
