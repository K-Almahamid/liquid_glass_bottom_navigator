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
  /// True when this bar can show a label. Icon-only destinations keep the
  /// same line so their icons stay on the shared center.
  final bool reserveLabelLine;

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
    final labelHeight = reserveLabelLine
        ? _labelSlotHeight(context, foreground)
        : 0.0;
    final direction = Directionality.of(context);
    return _ClusterFrame(
      anchor: _anchor,
      barPadding: style.padding.resolve(direction),
      itemPadding: style.itemPadding.resolve(direction),
      breath: liquidCapsuleBreath(style.indicatorInset.resolve(direction)),
      textDirection: direction,
      child: NavigationContent(
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
                    PositionedDirectional(
                      top: style.badgeOffset.dy,
                      end: -style.badgeOffset.dx,
                      child: _BadgeView(
                        badge: badge,
                        style: style,
                        theme: theme,
                      ),
                    ),
                ],
              ),
            ),
            if (reserveLabelLine) ...<Widget>[
              SizedBox(height: style.labelSpacing),
              SizedBox(
                height: labelHeight,
                child: label == null
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
            ],
          ],
        ),
      ),
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

/// Where a destination sits inside its slot.
enum _SlotAnchor { start, center, end }

/// Places the icon and label cluster.
///
/// Every destination uses the same vertical center, so a label cannot move
/// the icon. The first and last destinations sit in from the glass by the
/// same amount as the capsule's top and bottom gaps. Middle destinations
/// stay centered in their slots.
class _ClusterFrame extends SingleChildRenderObjectWidget {
  const _ClusterFrame({
    required this.anchor,
    required this.barPadding,
    required this.itemPadding,
    required this.breath,
    required this.textDirection,
    super.child,
  });

  final _SlotAnchor anchor;
  final EdgeInsets barPadding;
  final EdgeInsets itemPadding;
  final double breath;
  final TextDirection textDirection;

  @override
  _RenderClusterFrame createRenderObject(BuildContext context) {
    return _RenderClusterFrame(
      anchor: anchor,
      barPadding: barPadding,
      itemPadding: itemPadding,
      breath: breath,
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
      ..breath = breath
      ..textDirection = textDirection;
  }
}

class _RenderClusterFrame extends RenderBox
    with RenderObjectWithChildMixin<RenderBox> {
  _RenderClusterFrame({
    required this._anchor,
    required this._barPadding,
    required this._itemPadding,
    required this._breath,
    required this._textDirection,
  });

  _SlotAnchor _anchor;
  EdgeInsets _barPadding;
  EdgeInsets _itemPadding;
  double _breath;
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

  set breath(double value) {
    if (_breath == value) {
      return;
    }
    _breath = value;
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
    final room = (glassHeight - child.size.height) / 2;
    final breath = room <= 0 ? 0.0 : math.min(_breath, room);
    final dy =
        (size.height - child.size.height) / 2 +
        (_barPadding.bottom - _barPadding.top) / 2;
    final dx = _dx(child.size.width, child.size.height, breath);
    final parentData = child.parentData! as BoxParentData;
    parentData.offset = Offset(dx, dy);
  }

  /// Horizontal origin of the cluster inside this slot.
  ///
  /// End destinations are shifted so the capsule's outer edge matches its
  /// top and bottom gaps. A slot that cannot hold that inset keeps the
  /// cluster inside the slot instead.
  double _dx(double childWidth, double childHeight, double breath) {
    if (childWidth + breath * 2 > size.width) {
      return math.max(0.0, (size.width - childWidth) / 2);
    }
    final glassHeight = size.height + _barPadding.vertical;
    final side = (glassHeight - childHeight) / 2;
    final double dx;
    switch (_anchor) {
      case _SlotAnchor.center:
        dx = (size.width - childWidth) / 2;
      case _SlotAnchor.start:
        dx = _textDirection == TextDirection.ltr
            ? -_barPadding.left + side
            : size.width + _barPadding.right - side - childWidth;
      case _SlotAnchor.end:
        dx = _textDirection == TextDirection.ltr
            ? size.width + _barPadding.right - side - childWidth
            : -_barPadding.left + side;
    }
    final minDx = breath;
    final maxDx = size.width - childWidth - breath;
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

/// Fixed-height icon slot.
///
/// The slot width follows the visual. A taller custom child stays centered
/// on the shared icon line and may paint outside the slot.
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

class RenderIconBand extends RenderBox
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
