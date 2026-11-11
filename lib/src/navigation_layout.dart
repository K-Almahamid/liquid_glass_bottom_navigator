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
    required this.barPadding,
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

  /// Resolved glass padding around this row.
  ///
  /// The capsule's top, bottom, and outer-end gaps are measured from the
  /// glass, so the row needs the padding that sits outside it.
  final EdgeInsets barPadding;

  /// Even breathing room around the selected content. The smallest side is used.
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
      barPadding: barPadding,
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
      ..barPadding = barPadding
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
    required this._barPadding,
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
  EdgeInsets _barPadding;
  EdgeInsets _indicatorInset;
  BorderRadius _indicatorRadius;
  Color _indicatorColor;
  Color _indicatorBorderColor;
  double _indicatorBorderWidth;
  bool _morph;
  double _morphIntensity;
  Rect? _from;
  List<Rect> _itemRects = const <Rect>[];
  List<Rect> _contentRects = const <Rect>[];
  bool _contentDirty = true;
  Rect? _paintedIndicator;
  Path? _paintedPath;
  Rect? _dragRect;
  double _dragBlob = 0;
  bool? _dragTravelRight;

  /// Slot rectangles from the latest layout, in local coordinates.
  List<Rect> get debugItemRects => List<Rect>.unmodifiable(_itemRects);

  /// Capsule rectangle from the latest paint, in local coordinates.
  Rect? get debugIndicatorRect => _paintedIndicator;

  /// Capsule path from the latest paint, in local coordinates.
  Path? get debugIndicatorPath => _paintedPath;

  /// Resting indicator rectangles, one per slot, in local coordinates.
  List<Rect> get indicatorRects {
    return <Rect>[for (var i = 0; i < _itemRects.length; i++) _rectFor(i)!];
  }

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
  /// A direction change drops an in-flight origin and any drag preview. The
  /// capsule uses the new slot geometry instead of a rectangle measured in
  /// the previous direction.
  set textDirection(TextDirection value) {
    if (_textDirection == value) {
      return;
    }
    _textDirection = value;
    _from = null;
    _clearDrag();
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

  /// Glass padding outside this row.
  set barPadding(EdgeInsets value) {
    if (_barPadding == value) {
      return;
    }
    _barPadding = value;
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

  /// Shows [rect] while a drag is active. This only repaints.
  ///
  /// [blob] and [travelRight] drive the droplet. They are ignored once the
  /// drag ends through [beginTransition], [jumpTo], or [snap].
  void showDrag(Rect rect, {required double blob, required bool travelRight}) {
    _dragRect = rect;
    _dragBlob = blob.clamp(0.0, 1.0);
    _dragTravelRight = travelRight;
    markNeedsPaint();
  }

  /// Starts a transition from the capsule's current rectangle to [index].
  ///
  /// Call this before resetting [animation] so the origin is the in-flight
  /// position, including a drag preview, rather than the previous destination.
  void beginTransition(int? index) {
    final dragging = _dragRect != null;
    final visual = _visualRect();
    _clearDrag();
    if (index == _targetIndex && _from == null && !dragging) {
      return;
    }
    _from = visual;
    _targetIndex = index;
    markNeedsPaint();
  }

  /// Drops any in-flight origin and shows [index] directly.
  void jumpTo(int? index) {
    _clearDrag();
    _from = null;
    _targetIndex = index;
    markNeedsPaint();
  }

  /// Drops the in-flight origin. The resting position is [targetIndex].
  void snap() {
    _clearDrag();
    _from = null;
    markNeedsPaint();
  }

  void _clearDrag() {
    _dragRect = null;
    _dragBlob = 0;
    _dragTravelRight = null;
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
      _contentRects = const <Rect>[];
      _contentDirty = false;
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
    _contentDirty = true;
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
    _ensureContentRects();
    final slot = _itemRects[index];
    final slotLimit = _deflateForStroke(slot);
    if (index >= _contentRects.length) {
      return slotLimit;
    }
    final content = _contentRects[index];
    if (content.width <= 0 || content.height <= 0) {
      return slotLimit;
    }
    // The pill wraps the laid-out icon and label, plus the inset. Badges are
    // left out of [content]. End items are placed so the glass gap matches on
    // the top, the bottom, and the outer side when the slot can hold that inset.
    final margins = _marginsFor(content);
    final hugged = Rect.fromLTRB(
      content.left - margins.horizontal,
      content.top - margins.vertical,
      content.right + margins.horizontal,
      content.bottom + margins.vertical,
    );
    final rect = hugged.intersect(slotLimit);
    if (rect.width <= 0 || rect.height <= 0) {
      return slotLimit;
    }
    return rect;
  }

  ({double horizontal, double vertical}) _marginsFor(Rect content) {
    final preferred = liquidCapsuleMargins(_indicatorInset);
    final glassHeight = size.height + _barPadding.vertical;
    final room = (glassHeight - content.height) / 2;
    final vertical = room <= 0 ? 0.0 : math.min(preferred.vertical, room);
    return (horizontal: preferred.horizontal, vertical: vertical);
  }

  Rect _deflateForStroke(Rect slot) {
    final pad = _indicatorBorderWidth > 0 ? _indicatorBorderWidth / 2 : 0.0;
    final rect = slot.deflate(pad);
    if (rect.width <= 0 || rect.height <= 0) {
      return slot;
    }
    return rect;
  }

  void _ensureContentRects() {
    if (!_contentDirty) {
      return;
    }
    final children = _children;
    _contentRects = <Rect>[for (final child in children) _contentInRow(child)];
    _contentDirty = false;
  }

  Rect _contentInRow(RenderBox slotChild) {
    final content = _findContent(slotChild);
    if (content == null || !content.hasSize) {
      final parentData = slotChild.parentData! as _NavParentData;
      return parentData.offset & slotChild.size;
    }
    final origin = _offsetWithin(this, content);
    return _paintBounds(content).shift(origin);
  }

  RenderNavigationContent? _findContent(RenderObject node) {
    if (node is RenderNavigationContent) {
      return node;
    }
    RenderNavigationContent? found;
    node.visitChildren((RenderObject child) {
      if (found != null) {
        return;
      }
      found = _findContent(child);
    });
    return found;
  }

  Rect _paintBounds(RenderBox root) {
    var bounds = Offset.zero & root.size;
    void visit(RenderBox box) {
      if (box is RenderBadgeOverlay) {
        return;
      }
      if (box != root &&
          box.hasSize &&
          box.size.width > 0 &&
          box.size.height > 0) {
        bounds = bounds.expandToInclude(_offsetWithin(root, box) & box.size);
      }
      box.visitChildren((RenderObject child) {
        if (child is RenderBox) {
          visit(child);
        }
      });
    }

    visit(root);
    return bounds;
  }

  Offset _offsetWithin(RenderBox ancestor, RenderBox box) {
    var offset = Offset.zero;
    RenderBox? current = box;
    while (current != null && current != ancestor) {
      final parentData = current.parentData;
      if (parentData is BoxParentData) {
        offset += parentData.offset;
      }
      final parent = current.parent;
      if (parent is! RenderBox) {
        break;
      }
      current = parent;
    }
    return offset;
  }

  double _blobAmount() {
    if (_dragRect != null) {
      return _dragBlob;
    }
    if (!_morph || _morphIntensity <= 0 || _from == null) {
      return 0;
    }
    final progress = _animation.value.clamp(0.0, 1.0);
    return math.sin(progress * math.pi) * _morphIntensity;
  }

  bool _travelRight() {
    final dragged = _dragTravelRight;
    if (_dragRect != null && dragged != null) {
      return dragged;
    }
    final from = _from;
    final target = _rectFor(_targetIndex);
    if (from == null || target == null) {
      return true;
    }
    return target.center.dx >= from.center.dx;
  }

  double _cornerRadius(Rect rect) {
    return math.min(
      _indicatorRadius.topLeft.x,
      math.min(rect.width, rect.height) / 2,
    );
  }

  Rect? _visualRect() {
    final dragged = _dragRect;
    if (dragged != null) {
      return _fitInsidePaintArea(dragged);
    }
    final target = _rectFor(_targetIndex);
    final from = _from;
    if (target == null) {
      return null;
    }
    final raw = from == null
        ? target
        : liquidIndicatorRect(
            from: from,
            to: target,
            t: _animation.value,
            morphIntensity: _morphIntensity,
            morph: _morph,
          );
    return _fitInsidePaintArea(raw);
  }

  /// Keeps the stretched bubble, including a centered stroke, inside this row
  /// so the glass clip cannot slice an end.
  Rect _fitInsidePaintArea(Rect rect) {
    if (!hasSize || size.isEmpty) {
      return rect;
    }
    final pad = _indicatorBorderWidth > 0 ? _indicatorBorderWidth / 2 : 0.0;
    final bounds = Rect.fromLTRB(
      pad,
      pad,
      math.max(pad, size.width - pad),
      math.max(pad, size.height - pad),
    );
    if (bounds.width <= 0 || bounds.height <= 0) {
      return rect;
    }
    final fitted = rect.intersect(bounds);
    if (fitted.width <= 0 || fitted.height <= 0) {
      return rect;
    }
    return fitted;
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final indicator = _visualRect();
    _paintedIndicator = indicator;
    _paintedPath = null;
    if (indicator != null) {
      final radius = _cornerRadius(indicator);
      final amount = _blobAmount();
      final travelRight = _travelRight();
      final local = liquidBubblePath(
        rect: indicator,
        cornerRadius: radius,
        blob: amount,
        travelRight: travelRight,
      );
      _paintedPath = local;
      final bubble = local.shift(offset);
      _fill.color = _indicatorColor;
      context.canvas.drawPath(bubble, _fill);
      if (_indicatorBorderWidth > 0 && _indicatorBorderColor.a > 0) {
        _stroke
          ..color = _indicatorBorderColor
          ..strokeWidth = _indicatorBorderWidth;
        context.canvas.drawPath(bubble, _stroke);
      }
    }
    defaultPaint(context, offset);
  }
}

/// Shared icon line. The capsule's vertical bounds follow this box, not the
/// label under it.
abstract class RenderIconAnchor extends RenderBox {}

/// Badge paint that must not widen or shift the selection capsule.
class RenderBadgeOverlay extends RenderProxyBox {}

/// Horizontal and vertical capsule margins from [inset].
///
/// Each axis uses its smaller side. A wide horizontal inset and a short
/// vertical inset produce a flat pill. Callers still place end items so the
/// outer glass gap matches the top and bottom gaps.
({double horizontal, double vertical}) liquidCapsuleMargins(EdgeInsets inset) {
  return (
    horizontal: math.max(0.0, math.min(inset.left, inset.right)),
    vertical: math.max(0.0, math.min(inset.top, inset.bottom)),
  );
}

/// Icon, label, and badge cluster measured for the selection capsule.
///
/// Middle clusters are centered in the slot. End clusters sit on the shared
/// glass inset. The size does not include the free space around the cluster.
class NavigationContent extends SingleChildRenderObjectWidget {
  /// Creates a measurable content cluster.
  const NavigationContent({super.key, super.child});

  @override
  RenderNavigationContent createRenderObject(BuildContext context) {
    return RenderNavigationContent();
  }
}

/// Render object for [NavigationContent].
class RenderNavigationContent extends RenderProxyBox {}
