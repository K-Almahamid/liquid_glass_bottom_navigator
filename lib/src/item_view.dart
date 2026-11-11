import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'badge.dart';
import 'item.dart';
import 'navigation_layout.dart';
import 'options.dart';
import 'style.dart';
import 'theme.dart';

/// One tappable destination, including its semantics and badge overlay.
class LiquidNavigationItemView extends StatelessWidget {
  /// Creates an item view.
  const LiquidNavigationItemView({
    required this.item,
    required this.index,
    required this.count,
    required this.selected,
    required this.labelMode,
    required this.reserveLabelLine,
    required this.matchLabeledCapsule,
    required this.labelAnimation,
    required this.labelFrom,
    required this.labelTo,
    required this.style,
    required this.theme,
    required this.onTap,
    super.key,
  });

  /// Destination configuration.
  final LiquidGlassNavigationItem item;

  /// Position in the bar.
  final int index;

  /// Number of destinations.
  final int count;

  /// Whether this destination is selected.
  final bool selected;

  /// Label visibility policy.
  final LiquidGlassLabelMode labelMode;

  /// Whether every item keeps a label line under the icon.
  ///
  /// True in [LiquidGlassLabelMode.always] when any destination has a label.
  ///
  /// Icon-only destinations in that mode keep the band so every icon stays on
  /// one line. The other modes do not reserve it.
  final bool reserveLabelLine;

  /// Icons-only capsule uses the labeled column's size. The icon stays centered.
  final bool matchLabeledCapsule;

  /// Selection spring. Selected-only labels grow and fade with this value.
  final Animation<double> labelAnimation;

  /// Destination that was selected when the current spring started.
  final int? labelFrom;

  /// Destination the current spring is settling on.
  final int? labelTo;

  /// Shared dimensions.
  final LiquidGlassNavigationStyle style;

  /// Resolved colors.
  final LiquidGlassNavigationTheme theme;

  /// Selection handler.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = item.label?.trim();
    final hasLabel = label != null && label.isNotEmpty;
    final showLabelText =
        hasLabel &&
        labelMode != LiquidGlassLabelMode.hidden &&
        (labelMode == LiquidGlassLabelMode.always || selected);
    final foreground =
        item.foregroundColor ??
        (selected ? theme.selectedForeground : theme.unselectedForeground);
    final semantics = liquidGlassItemSemantics(item, index);

    return Semantics(
      role: SemanticsRole.tab,
      selected: selected,
      label: semantics,
      hint: '${index + 1} of $count',
      onTap: onTap,
      excludeSemantics: true,
      child: _ItemControl(
        onTap: onTap,
        ringColor: foreground,
        radius: style.indicatorRadius.resolve(Directionality.of(context)),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: style.minTouchTarget),
          child: _body(
            context,
            foreground: foreground,
            label: label,
            showLabelText: showLabelText,
          ),
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context, {
    required Color foreground,
    required String? label,
    required bool showLabelText,
  }) {
    final Widget? visual =
        item.child ??
        (item.icon == null
            ? null
            : Icon(item.icon, size: style.iconSize, color: foreground));
    final badge = item.badge;
    final revealLabel =
        labelMode == LiquidGlassLabelMode.selected &&
        label != null &&
        label.isNotEmpty;
    final labelHeight = reserveLabelLine || revealLabel
        ? _labelSlotHeight(context, foreground)
        : 0.0;
    final direction = Directionality.of(context);
    final margins = liquidCapsuleMargins(
      style.indicatorInset.resolve(direction),
    );
    return _ClusterFrame(
      anchor: _anchor,
      barPadding: style.padding.resolve(direction),
      itemPadding: style.itemPadding.resolve(direction),
      breathX: margins.horizontal,
      breathY: margins.vertical,
      iconExtent: style.iconSize,
      textDirection: direction,
      child: NavigationContent(
        child: _matchCapsule(
          context,
          foreground: foreground,
          label: label,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              _IconBand(
                height: style.iconSize,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: <Widget>[
                    ?visual,
                    if (badge != null && badge.isVisible)
                      _badgePosition(
                        badge,
                        style.badgeOffset,
                        _BadgeOverlay(
                          child: _BadgeView(
                            badge: badge,
                            style: style,
                            theme: theme,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (reserveLabelLine) ...<Widget>[
                SizedBox(height: style.labelSpacing),
                SizedBox(
                  height: labelHeight,
                  width:
                      label == null || labelMode == LiquidGlassLabelMode.hidden
                      ? null
                      : _labelSlotWidth(context, label, foreground),
                  child:
                      label == null || labelMode == LiquidGlassLabelMode.hidden
                      ? null
                      : Opacity(
                          opacity: showLabelText ? 1 : 0,
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: _labelStyle(foreground),
                          ),
                        ),
                ),
              ] else if (revealLabel)
                _LabelSlot(
                  animation: labelAnimation,
                  index: index,
                  fromIndex: labelFrom,
                  toIndex: labelTo,
                  bandWidth: _labelSlotWidth(context, label, foreground),
                  bandHeight: style.labelSpacing + labelHeight,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      SizedBox(height: style.labelSpacing),
                      SizedBox(
                        height: labelHeight,
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: _labelStyle(foreground),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Icons-only capsule box. The child stays the icon, centered in the size
  /// the labeled column would have used.
  Widget _matchCapsule(
    BuildContext context, {
    required Color foreground,
    required String? label,
    required Widget child,
  }) {
    if (!matchLabeledCapsule) {
      return child;
    }
    final labelWidth = label != null && label.isNotEmpty
        ? _labelSlotWidth(context, label, foreground)
        : 0.0;
    return _LabeledExtent(
      minWidth: labelWidth,
      extraHeight: style.labelSpacing + _labelSlotHeight(context, foreground),
      child: child,
    );
  }

  /// A lone destination stays centered. Ends sit on the outer glass inset.
  _SlotAnchor get _anchor {
    if (count <= 1) {
      return _SlotAnchor.center;
    }
    if (index == 0) {
      return _SlotAnchor.start;
    }
    if (index == count - 1) {
      return _SlotAnchor.end;
    }
    return _SlotAnchor.center;
  }

  double _labelSlotHeight(BuildContext context, Color foreground) {
    final direction = Directionality.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    final selectedHeight = _lineHeight(
      _labelStyle(foreground, selected: true),
      scaler,
      direction,
    );
    final idleHeight = _lineHeight(
      _labelStyle(foreground, selected: false),
      scaler,
      direction,
    );
    return math.max(selectedHeight, idleHeight);
  }

  /// Wider of the selected and idle styles, so a selection change does not
  /// resize the column.
  double _labelSlotWidth(BuildContext context, String label, Color foreground) {
    final direction = Directionality.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    final defaults = DefaultTextStyle.of(context).style;
    return math.max(
      _textWidth(
        _resolvedLabelStyle(_labelStyle(foreground, selected: true), defaults),
        label,
        scaler,
        direction,
      ),
      _textWidth(
        _resolvedLabelStyle(_labelStyle(foreground, selected: false), defaults),
        label,
        scaler,
        direction,
      ),
    );
  }

  TextStyle _resolvedLabelStyle(TextStyle style, TextStyle defaults) {
    return style.inherit ? defaults.merge(style) : style;
  }

  double _textWidth(
    TextStyle style,
    String text,
    TextScaler scaler,
    TextDirection direction,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: direction,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }

  double _lineHeight(
    TextStyle style,
    TextScaler scaler,
    TextDirection direction,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: 'Ag', style: style),
      textDirection: direction,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    final height = painter.height;
    painter.dispose();
    return height;
  }

  TextStyle _labelStyle(Color foreground, {bool? selected}) {
    final isSelected = selected ?? this.selected;
    final base = TextStyle(
      fontSize: 11,
      height: 1.1,
      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      color: foreground,
    );
    return base
        .merge(style.labelStyle)
        .merge(
          isSelected ? style.selectedLabelStyle : style.unselectedLabelStyle,
        )
        .copyWith(color: foreground);
  }
}

/// Grows the selected-only label with the bar's selection spring.
///
/// The slot reports a fraction of the full label band, so the icon column
/// moves with the same animation as the capsule. At rest an unselected slot
/// has zero size and does not shift the icon. Paint is clipped to the
/// capsule that is already drawn this frame, so a growing label cannot
/// appear outside the bubble while the capsule is still traveling.
class _LabelSlot extends SingleChildRenderObjectWidget {
  const _LabelSlot({
    required this.animation,
    required this.index,
    required this.fromIndex,
    required this.toIndex,
    required this.bandWidth,
    required this.bandHeight,
    super.child,
  });

  final Animation<double> animation;
  final int index;
  final int? fromIndex;
  final int? toIndex;
  final double bandWidth;
  final double bandHeight;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderLabelSlot(
      animation: animation,
      index: index,
      fromIndex: fromIndex,
      toIndex: toIndex,
      bandWidth: bandWidth,
      bandHeight: bandHeight,
    );
  }

  @override
  void updateRenderObject(BuildContext context, _RenderLabelSlot renderObject) {
    renderObject
      ..animation = animation
      ..index = index
      ..bandWidth = bandWidth
      ..bandHeight = bandHeight
      ..setMotion(fromIndex, toIndex);
  }
}

class _RenderLabelSlot extends RenderProxyBox {
  _RenderLabelSlot({
    required this._animation,
    required this._index,
    required this._fromIndex,
    required this._toIndex,
    required this._bandWidth,
    required this._bandHeight,
  });

  Animation<double> _animation;
  int _index;
  int? _fromIndex;
  int? _toIndex;
  double _bandWidth;
  double _bandHeight;

  /// Reveal at the start of the current spring, so a second tap mid-flight
  /// continues from the visible label instead of jumping.
  double _startFactor = 0;
  double _displayed = 0;

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
  }

  set index(int value) {
    if (_index == value) {
      return;
    }
    _index = value;
    markNeedsLayout();
  }

  set bandWidth(double value) {
    if (_bandWidth == value) {
      return;
    }
    _bandWidth = value;
    markNeedsLayout();
  }

  set bandHeight(double value) {
    if (_bandHeight == value) {
      return;
    }
    _bandHeight = value;
    markNeedsLayout();
  }

  void setMotion(int? from, int? to) {
    if (_fromIndex == from && _toIndex == to) {
      return;
    }
    _startFactor = _displayed;
    _fromIndex = from;
    _toIndex = to;
    markNeedsLayout();
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
    markNeedsLayout();
  }

  double _factor() {
    final target = _index == _toIndex ? 1.0 : 0.0;
    if (_fromIndex == null) {
      return target;
    }
    final t = _animation.value.clamp(0.0, 1.0);
    return _startFactor + (target - _startFactor) * t;
  }

  @override
  void performLayout() {
    final factor = _factor().clamp(0.0, 1.0);
    _displayed = factor;
    final child = this.child;
    final maxWidth = constraints.maxWidth.isFinite
        ? constraints.maxWidth
        : math.max(0.0, _bandWidth);
    final width = math.min(math.max(0.0, _bandWidth), maxWidth);
    final height = math.max(0.0, _bandHeight);
    if (child == null) {
      size = constraints.constrain(Size.zero);
      return;
    }
    child.layout(
      BoxConstraints.tightFor(width: width, height: height),
      parentUsesSize: true,
    );
    size = constraints.constrain(Size(width * factor, height * factor));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null || _displayed <= 0.001 || size.isEmpty) {
      return;
    }
    final alpha = (_displayed * 255).round().clamp(0, 255);
    var clip = Offset.zero & size;
    final capsule = _capsuleInLocal();
    if (capsule != null) {
      clip = clip.intersect(capsule);
    }
    if (clip.isEmpty) {
      return;
    }
    final shift = Offset((size.width - child.size.width) / 2, 0);
    context.pushClipRect(true, offset, clip, (
      PaintingContext context,
      Offset offset,
    ) {
      context.pushOpacity(offset, alpha, (
        PaintingContext context,
        Offset offset,
      ) {
        context.paintChild(child, offset + shift);
      });
    });
  }

  /// Capsule painted by the row this frame, in this box's coordinates.
  Rect? _capsuleInLocal() {
    var node = parent;
    RenderLiquidNavigation? row;
    while (node != null) {
      if (node is RenderLiquidNavigation) {
        row = node;
        break;
      }
      node = node.parent;
    }
    final painted = row?.debugIndicatorRect;
    if (row == null || painted == null) {
      return null;
    }
    final topLeft = globalToLocal(row.localToGlobal(painted.topLeft));
    final bottomRight = globalToLocal(row.localToGlobal(painted.bottomRight));
    return Rect.fromPoints(topLeft, bottomRight);
  }
}

/// Where a destination sits inside its slot.
enum _SlotAnchor { start, center, end }

/// Places the icon and label cluster.
///
/// The column is whatever this destination is showing: icon and label in
/// all-labels mode, the icon alone in icons-only mode, and in selected-only
/// mode the icon plus a label band that grows with the selection spring.
/// The column is placed so the capsule around it has the same gap above,
/// below, and, for the first and last destinations, on the outer side.
/// [breathX] and [breathY] are those capsule margins. An icon-sized column
/// is treated as wider when the capsule would otherwise be round, and the
/// icon stays centered in that width. [iconExtent] is the icon-band height.
/// A column that does not fit the inset stays inside the slot.
class _ClusterFrame extends SingleChildRenderObjectWidget {
  const _ClusterFrame({
    required this.anchor,
    required this.barPadding,
    required this.itemPadding,
    required this.breathX,
    required this.breathY,
    required this.iconExtent,
    required this.textDirection,
    super.child,
  });

  final _SlotAnchor anchor;
  final EdgeInsets barPadding;
  final EdgeInsets itemPadding;
  final double breathX;
  final double breathY;
  final double iconExtent;
  final TextDirection textDirection;

  @override
  _RenderClusterFrame createRenderObject(BuildContext context) {
    return _RenderClusterFrame(
      anchor: anchor,
      barPadding: barPadding,
      itemPadding: itemPadding,
      breathX: breathX,
      breathY: breathY,
      iconExtent: iconExtent,
      textDirection: textDirection,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderClusterFrame renderObject,
  ) {
    renderObject
      ..anchor = anchor
      ..barPadding = barPadding
      ..itemPadding = itemPadding
      ..breathX = breathX
      ..breathY = breathY
      ..iconExtent = iconExtent
      ..textDirection = textDirection;
  }
}

class _RenderClusterFrame extends RenderBox
    with RenderObjectWithChildMixin<RenderBox> {
  _RenderClusterFrame({
    required this._anchor,
    required this._barPadding,
    required this._itemPadding,
    required this._breathX,
    required this._breathY,
    required this._iconExtent,
    required this._textDirection,
  });

  _SlotAnchor _anchor;
  EdgeInsets _barPadding;
  EdgeInsets _itemPadding;
  double _breathX;
  double _breathY;
  double _iconExtent;
  TextDirection _textDirection;

  set anchor(_SlotAnchor value) {
    if (_anchor == value) {
      return;
    }
    _anchor = value;
    markNeedsLayout();
  }

  set barPadding(EdgeInsets value) {
    if (_barPadding == value) {
      return;
    }
    _barPadding = value;
    markNeedsLayout();
  }

  set itemPadding(EdgeInsets value) {
    if (_itemPadding == value) {
      return;
    }
    _itemPadding = value;
    markNeedsLayout();
  }

  set breathX(double value) {
    if (_breathX == value) {
      return;
    }
    _breathX = value;
    markNeedsLayout();
  }

  set breathY(double value) {
    if (_breathY == value) {
      return;
    }
    _breathY = value;
    markNeedsLayout();
  }

  set iconExtent(double value) {
    if (_iconExtent == value) {
      return;
    }
    _iconExtent = value;
    markNeedsLayout();
  }

  set textDirection(TextDirection value) {
    if (_textDirection == value) {
      return;
    }
    _textDirection = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! BoxParentData) {
      child.parentData = BoxParentData();
    }
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    final child = this.child;
    if (child == null) {
      return _itemPadding.horizontal;
    }
    return child.getMinIntrinsicWidth(height) + _itemPadding.horizontal;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    final child = this.child;
    if (child == null) {
      return _itemPadding.horizontal;
    }
    return child.getMaxIntrinsicWidth(height) + _itemPadding.horizontal;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    final child = this.child;
    if (child == null) {
      return 0;
    }
    return child.getMinIntrinsicHeight(
      math.max(0, width - _itemPadding.horizontal),
    );
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    final child = this.child;
    if (child == null) {
      return 0;
    }
    return child.getMaxIntrinsicHeight(
      math.max(0, width - _itemPadding.horizontal),
    );
  }

  @override
  void performLayout() {
    final child = this.child;
    final maxWidth = constraints.maxWidth.isFinite ? constraints.maxWidth : 0.0;
    if (child == null) {
      size = constraints.constrain(Size(maxWidth, constraints.minHeight));
      return;
    }
    final innerWidth = constraints.maxWidth.isFinite
        ? math.max(0.0, constraints.maxWidth - _itemPadding.horizontal)
        : double.infinity;
    child.layout(BoxConstraints(maxWidth: innerWidth), parentUsesSize: true);
    final width = constraints.maxWidth.isFinite
        ? constraints.maxWidth
        : child.size.width + _itemPadding.horizontal;
    final height = constraints.hasTightHeight
        ? constraints.maxHeight
        : math.max(constraints.minHeight, child.size.height);
    size = constraints.constrain(Size(width, height));

    final glassHeight = size.height + _barPadding.vertical;
    final column = child.size.height;
    final room = (glassHeight - column) / 2;
    final breathY = room <= 0 ? 0.0 : math.min(_breathY, room);
    final capsuleHeight = column + breathY * 2;
    final gap = math.max(0.0, (glassHeight - capsuleHeight) / 2);
    // Place the whole column, not the icon alone. A taller column (an icon
    // with its label) sits higher so the group, not the icon, is centered.
    final dy = column >= glassHeight
        ? (glassHeight - column) / 2 - _barPadding.top
        : gap + breathY - _barPadding.top;
    final visualWidth = _visualWidth(child.size.width, capsuleHeight);
    final dx = _dx(visualWidth, column, breathY, glassHeight);
    final childDx = dx + (visualWidth - child.size.width) / 2;
    final parentData = child.parentData! as BoxParentData;
    parentData.offset = Offset(childDx, dy);
  }

  /// Content width the capsule uses for edge placement.
  ///
  /// A cluster narrower than [liquidMinCapsuleAspect] times the capsule height
  /// is widened, and the icon stays centered in that width. The indicator uses
  /// the same ratio.
  double _visualWidth(double childWidth, double capsuleHeight) {
    final minContent = math.max(
      0.0,
      capsuleHeight * liquidMinCapsuleAspect - _breathX * 2,
    );
    return math.max(childWidth, minContent);
  }

  /// Horizontal origin of the cluster inside this slot.
  ///
  /// End destinations are shifted so the capsule's outer edge matches its
  /// top and bottom gaps. The capsule height is the column plus [breathY] on
  /// both sides. The horizontal margin is [_breathX]. A slot that cannot hold
  /// that inset keeps the cluster inside the slot.
  double _dx(
    double childWidth,
    double columnHeight,
    double breathY,
    double glassHeight,
  ) {
    final breathX = _breathX;
    if (childWidth + breathX * 2 > size.width) {
      return math.max(0.0, (size.width - childWidth) / 2);
    }
    final capsuleHeight = columnHeight + breathY * 2;
    final gap = math.max(0.0, (glassHeight - capsuleHeight) / 2);
    final double dx;
    switch (_anchor) {
      case _SlotAnchor.center:
        dx = (size.width - childWidth) / 2;
      case _SlotAnchor.start:
        dx = _textDirection == TextDirection.ltr
            ? -_barPadding.left + gap + breathX
            : size.width + _barPadding.right - gap - breathX - childWidth;
      case _SlotAnchor.end:
        dx = _textDirection == TextDirection.ltr
            ? size.width + _barPadding.right - gap - breathX - childWidth
            : -_barPadding.left + gap + breathX;
    }
    final minDx = breathX;
    final maxDx = size.width - childWidth - breathX;
    if (dx < minDx) {
      return minDx;
    }
    if (dx > maxDx) {
      return maxDx;
    }
    return dx;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null) {
      return;
    }
    final parentData = child.parentData! as BoxParentData;
    context.paintChild(child, offset + parentData.offset);
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    final parentData = child.parentData! as BoxParentData;
    transform.translateByDouble(
      parentData.offset.dx,
      parentData.offset.dy,
      0,
      1,
    );
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final child = this.child;
    if (child == null) {
      return false;
    }
    final parentData = child.parentData! as BoxParentData;
    return result.addWithPaintOffset(
      offset: parentData.offset,
      position: position,
      hitTest: (BoxHitTestResult result, Offset transformed) {
        return child.hitTest(result, position: transformed);
      },
    );
  }
}

/// Reports the labeled column size and centers the icon inside it.
///
/// Width is the wider of the icon and the measured label. Height adds the
/// label band. No text is built, so the icon stays on the capsule center.
class _LabeledExtent extends SingleChildRenderObjectWidget {
  const _LabeledExtent({
    required this.minWidth,
    required this.extraHeight,
    super.child,
  });

  final double minWidth;
  final double extraHeight;

  @override
  _RenderLabeledExtent createRenderObject(BuildContext context) {
    return _RenderLabeledExtent(minWidth: minWidth, extraHeight: extraHeight);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderLabeledExtent renderObject,
  ) {
    renderObject
      ..minWidth = minWidth
      ..extraHeight = extraHeight;
  }
}

class _RenderLabeledExtent extends RenderBox
    with RenderObjectWithChildMixin<RenderBox> {
  _RenderLabeledExtent({required this._minWidth, required this._extraHeight});

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! BoxParentData) {
      child.parentData = BoxParentData();
    }
  }

  double _minWidth;
  double _extraHeight;

  double get minWidth => _minWidth;

  set minWidth(double value) {
    if (_minWidth == value) {
      return;
    }
    _minWidth = value;
    markNeedsLayout();
  }

  double get extraHeight => _extraHeight;

  set extraHeight(double value) {
    if (_extraHeight == value) {
      return;
    }
    _extraHeight = value;
    markNeedsLayout();
  }

  @override
  double computeMinIntrinsicWidth(double height) => _extentWidth(height);

  @override
  double computeMaxIntrinsicWidth(double height) => _extentWidth(height);

  double _extentWidth(double height) {
    final childWidth = child?.getMaxIntrinsicWidth(height) ?? 0;
    return math.max(childWidth, _minWidth);
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    return (child?.getMinIntrinsicHeight(width) ?? 0) + _extraHeight;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return (child?.getMaxIntrinsicHeight(width) ?? 0) + _extraHeight;
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.constrain(Size(_minWidth, _extraHeight));
      return;
    }
    child.layout(
      BoxConstraints(maxWidth: constraints.maxWidth),
      parentUsesSize: true,
    );
    final width = math.max(child.size.width, _minWidth);
    final height = child.size.height + _extraHeight;
    size = constraints.constrain(Size(width, height));
    final parentData = child.parentData! as BoxParentData;
    parentData.offset = Offset(
      (size.width - child.size.width) / 2,
      (size.height - child.size.height) / 2,
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null) {
      return;
    }
    final parentData = child.parentData! as BoxParentData;
    context.paintChild(child, offset + parentData.offset);
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    final parentData = child.parentData! as BoxParentData;
    transform.translateByDouble(
      parentData.offset.dx,
      parentData.offset.dy,
      0,
      1,
    );
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final child = this.child;
    if (child == null) {
      return false;
    }
    final parentData = child.parentData! as BoxParentData;
    return result.addWithPaintOffset(
      offset: parentData.offset,
      position: position,
      hitTest: (BoxHitTestResult result, Offset transformed) {
        return child.hitTest(result, position: transformed);
      },
    );
  }
}

/// Fixed-height icon slot.
///
/// The slot width follows the visual. A taller custom child stays centered
/// in the slot and may paint outside it. The slot moves with the column.
class _IconBand extends SingleChildRenderObjectWidget {
  const _IconBand({required this.height, super.child});

  final double height;

  @override
  RenderIconBand createRenderObject(BuildContext context) {
    return RenderIconBand(height: height);
  }

  @override
  void updateRenderObject(BuildContext context, RenderIconBand renderObject) {
    renderObject.height = height;
  }
}

class RenderIconBand extends RenderIconAnchor
    with RenderObjectWithChildMixin<RenderBox> {
  RenderIconBand({required this._height});

  double _height;

  double get height => _height;

  set height(double value) {
    if (_height == value) {
      return;
    }
    _height = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! BoxParentData) {
      child.parentData = BoxParentData();
    }
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    return child?.getMinIntrinsicWidth(double.infinity) ?? 0;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    return child?.getMaxIntrinsicWidth(double.infinity) ?? 0;
  }

  @override
  double computeMinIntrinsicHeight(double width) => _height;

  @override
  double computeMaxIntrinsicHeight(double width) => _height;

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.constrain(Size(0, _height));
      return;
    }
    child.layout(
      BoxConstraints(maxWidth: constraints.maxWidth),
      parentUsesSize: true,
    );
    size = constraints.constrain(Size(child.size.width, _height));
    final parentData = child.parentData! as BoxParentData;
    parentData.offset = Offset(0, (_height - child.size.height) / 2);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null) {
      return;
    }
    final parentData = child.parentData! as BoxParentData;
    context.paintChild(child, offset + parentData.offset);
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    final parentData = child.parentData! as BoxParentData;
    transform.translateByDouble(
      parentData.offset.dx,
      parentData.offset.dy,
      0,
      1,
    );
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final child = this.child;
    if (child == null) {
      return false;
    }
    final parentData = child.parentData! as BoxParentData;
    return result.addWithPaintOffset(
      offset: parentData.offset,
      position: position,
      hitTest: (BoxHitTestResult result, Offset transformed) {
        return child.hitTest(result, position: transformed);
      },
    );
  }
}

/// Keyboard focus and Enter/Space activation for one destination.
///
/// [Focus.includeSemantics] is false so the tab semantics stay on the parent
/// node instead of creating a second button.
class _ItemControl extends StatefulWidget {
  const _ItemControl({
    required this.onTap,
    required this.ringColor,
    required this.radius,
    required this.child,
  });

  final VoidCallback onTap;
  final Color ringColor;
  final BorderRadius radius;
  final Widget child;

  @override
  State<_ItemControl> createState() => _ItemControlState();
}

class _ItemControlState extends State<_ItemControl> {
  late final FocusNode _focus = FocusNode(
    debugLabel: 'LiquidGlassNavigationItem',
  )..addListener(_onFocus);

  void _onFocus() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _focus
      ..removeListener(_onFocus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Actions(
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (ActivateIntent intent) {
            widget.onTap();
            return null;
          },
        ),
      },
      child: Focus(
        focusNode: _focus,
        includeSemantics: false,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: widget.radius,
              border: _focus.hasFocus
                  ? Border.all(color: widget.ringColor, width: 1.5)
                  : null,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Count hangs off the upper trailing corner. A dot hangs off the lower one.
/// [shift] is [LiquidGlassNavigationStyle.badgeOffset]: positive x moves
/// outward, positive y moves down.
Widget _badgePosition(LiquidGlassBadge badge, Offset shift, Widget child) {
  final end = -(shift.dx);
  return switch (badge.kind) {
    LiquidGlassBadgeKind.dot => PositionedDirectional(
      bottom: -2 - shift.dy,
      end: end - 10,
      child: child,
    ),
    LiquidGlassBadgeKind.count => PositionedDirectional(
      top: -6 + shift.dy,
      end: end - 14,
      child: child,
    ),
    LiquidGlassBadgeKind.custom => PositionedDirectional(
      top: shift.dy,
      end: end,
      child: child,
    ),
  };
}

class _BadgeOverlay extends SingleChildRenderObjectWidget {
  const _BadgeOverlay({required super.child});

  @override
  RenderBadgeOverlay createRenderObject(BuildContext context) {
    return RenderBadgeOverlay();
  }
}

class _BadgeView extends StatelessWidget {
  const _BadgeView({
    required this.badge,
    required this.style,
    required this.theme,
  });

  final LiquidGlassBadge badge;
  final LiquidGlassNavigationStyle style;
  final LiquidGlassNavigationTheme theme;

  @override
  Widget build(BuildContext context) {
    final background = badge.backgroundColor ?? theme.badgeBackground;
    final foreground = badge.foregroundColor ?? theme.badgeForeground;
    return switch (badge.kind) {
      LiquidGlassBadgeKind.dot => _dot(background),
      LiquidGlassBadgeKind.count => _count(background, foreground),
      LiquidGlassBadgeKind.custom => badge.child ?? const SizedBox.shrink(),
    };
  }

  Border _badgeRing(Color fill) {
    final ink = fill.computeLuminance() > 0.55
        ? const Color(0xCC1A1A1A)
        : const Color(0xE6FFFFFF);
    return Border.all(color: ink, width: 1);
  }

  Widget _dot(Color background) {
    final diameter = badge.size ?? 8;
    return SizedBox.square(
      dimension: diameter,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
          border: _badgeRing(background),
        ),
      ),
    );
  }

  Widget _count(Color background, Color foreground) {
    final minExtent = math.max(
      style.badgeMinSize,
      badge.size ?? style.badgeMinSize,
    );
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: minExtent, minHeight: minExtent),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(minExtent),
          border: _badgeRing(background),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Center(
            child: Text(
              badge.displayCount,
              maxLines: 1,
              style:
                  (badge.textStyle ??
                          const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            height: 1,
                          ))
                      .copyWith(color: foreground),
            ),
          ),
        ),
      ),
    );
  }
}
