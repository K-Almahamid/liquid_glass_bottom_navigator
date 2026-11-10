import 'dart:math' as math;
import 'dart:ui' show SemanticsRole;

import 'package:flutter/widgets.dart';

import 'badge.dart';
import 'item.dart';
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
    final showLabelSlot = hasLabel && labelMode != LiquidGlassLabelMode.hidden;
    final showLabelText =
        showLabelSlot && (labelMode == LiquidGlassLabelMode.always || selected);
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
            foreground: foreground,
            label: label,
            showLabelSlot: showLabelSlot,
            showLabelText: showLabelText,
          ),
        ),
      ),
    );
  }

  Widget _body({
    required Color foreground,
    required String? label,
    required bool showLabelSlot,
    required bool showLabelText,
  }) {
    final Widget? visual =
        item.child ??
        (item.icon == null
            ? null
            : Icon(item.icon, size: style.iconSize, color: foreground));
    return Padding(
      padding: style.itemPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          if (visual != null)
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: <Widget>[
                visual,
                if (item.badge != null && item.badge!.isVisible)
                  PositionedDirectional(
                    top: style.badgeOffset.dy,
                    end: -style.badgeOffset.dx,
                    child: _BadgeView(
                      badge: item.badge!,
                      style: style,
                      theme: theme,
                    ),
                  ),
              ],
            ),
          if (showLabelSlot) ...<Widget>[
            SizedBox(height: style.labelSpacing),
            Opacity(
              opacity: showLabelText ? 1 : 0,
              child: Text(
                label!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: _labelStyle(foreground),
              ),
            ),
          ],
        ],
      ),
    );
  }

  TextStyle _labelStyle(Color foreground) {
    final base = TextStyle(
      fontSize: 11,
      height: 1.1,
      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
      color: foreground,
    );
    return base
        .merge(style.labelStyle)
        .merge(selected ? style.selectedLabelStyle : style.unselectedLabelStyle)
        .copyWith(color: foreground);
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
