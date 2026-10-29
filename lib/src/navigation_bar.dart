import 'dart:ui' show SemanticsRole;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import 'glass_surface.dart';
import 'item.dart';
import 'item_view.dart';
import 'motion.dart';
import 'navigation_layout.dart';
import 'options.dart';
import 'style.dart';
import 'theme.dart';

/// Floating liquid-glass bottom navigation bar.
///
/// The bar is a controlled widget. [currentIndex] is owned by the parent, and
/// [onIndexChanged] reports taps that request a different item. It does not
/// own a navigation stack and does not depend on a state-management package.
///
/// An empty [items] list renders the glass surface with no destinations. An
/// index outside `0 .. items.length - 1` selects nothing and still accepts
/// taps on real items. Tapping the already selected item does not call
/// [onIndexChanged] and does not play haptics. Initialization and rebuilds
/// do not call [onIndexChanged].
///
/// Changing the number of items cancels an in-flight transition and places
/// the indicator on [currentIndex] immediately. A same-length reorder does
/// not replay motion unless [currentIndex] also changes.
///
/// [LiquidGlassNavigationStyle.respectSafeArea] defaults to true and adds the
/// bottom view padding to the bar margin. Set it to false when the parent
/// already positions the bar inside the safe area.
class LiquidGlassNavigationBar extends StatefulWidget {
  /// Creates a liquid-glass navigation bar.
  const LiquidGlassNavigationBar({
    required this.items,
    required this.currentIndex,
    this.onIndexChanged,
    this.style = const LiquidGlassNavigationStyle(),
    this.theme = const LiquidGlassNavigationTheme.adaptive(),
    this.motion = const LiquidGlassMotion.spring(),
    this.labelMode = LiquidGlassLabelMode.selected,
    this.indicatorStyle = LiquidGlassIndicatorStyle.morphingPill,
    this.hapticsEnabled = true,
    this.haptic = LiquidGlassHaptic.selection,
    this.semanticsLabel,
    super.key,
  });

  /// Destinations, from start to end.
  final List<LiquidGlassNavigationItem> items;

  /// Selected destination. Ignored when it does not point at an item.
  final int currentIndex;

  /// Called when a tap requests a different index.
  ///
  /// The parent should set [currentIndex] to the reported value. The bar does
  /// not change its own selection.
  final ValueChanged<int>? onIndexChanged;

  /// Dimensions, blur, and indicator geometry.
  final LiquidGlassNavigationStyle style;

  /// Colors. [LiquidGlassNavigationTheme.adaptive] follows the ambient theme.
  final LiquidGlassNavigationTheme theme;

  /// Spring, morph intensity, and reduced-motion policy.
  final LiquidGlassMotion motion;

  /// Which labels are visible.
  final LiquidGlassLabelMode labelMode;

  /// Capsule motion. Morphing stretch is geometric, not a glass shader.
  final LiquidGlassIndicatorStyle indicatorStyle;

  /// Whether a user selection may play haptic feedback.
  ///
  /// Programmatic [currentIndex] changes never play haptics. Hardware support
  /// varies by device and platform.
  final bool hapticsEnabled;

  /// Which haptic to play when [hapticsEnabled] is true.
  final LiquidGlassHaptic haptic;

  /// Spoken name for the bar itself.
  ///
  /// Item names stay on each destination. This label names the tab bar and
  /// does not replace those item labels.
  final String? semanticsLabel;

  @override
  State<LiquidGlassNavigationBar> createState() =>
      _LiquidGlassNavigationBarState();
}

class _LiquidGlassNavigationBarState extends State<LiquidGlassNavigationBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final GlobalKey _layoutKey = GlobalKey();
  bool _reduceMotion = false;

  RenderLiquidNavigation? get _render {
    final object = _layoutKey.currentContext?.findRenderObject();
    if (object is RenderLiquidNavigation) {
      return object;
    }
    return null;
  }

  int? get _effectiveIndex {
    if (widget.currentIndex < 0 || widget.currentIndex >= widget.items.length) {
      return null;
    }
    return widget.currentIndex;
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, value: 1);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = _resolveReducedMotion();
    final becameReduced = next && !_reduceMotion;
    _reduceMotion = next;
    if (becameReduced) {
      _controller.stop();
      _controller.value = 1;
      _render?.snap();
    }
  }

  @override
  void didUpdateWidget(LiquidGlassNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _reduceMotion = _resolveReducedMotion();
    final itemsChanged = widget.items.length != oldWidget.items.length;
    final indexChanged = widget.currentIndex != oldWidget.currentIndex;
    if (!itemsChanged && !indexChanged) {
      return;
    }
    final render = _render;
    if (render == null) {
      return;
    }
    if (itemsChanged) {
      render.jumpTo(_effectiveIndex);
      _controller.stop();
      _controller.value = 1;
      return;
    }
    render.beginTransition(_effectiveIndex);
    _runMotion();
  }

  bool _resolveReducedMotion() {
    if (!widget.motion.enabled) {
      return true;
    }
    if (!widget.motion.respectReducedMotion) {
      return false;
    }
    return MediaQuery.disableAnimationsOf(context);
  }

  void _runMotion() {
    _controller.stop();
    if (_reduceMotion || _effectiveIndex == null) {
      _controller.value = 1;
      _render?.snap();
      return;
    }
    _controller.animateWith(
      SpringSimulation(widget.motion.spring, 0, 1, 0, snapToEnd: true),
    );
  }

  void _handleTap(int index) {
    if (index < 0 || index >= widget.items.length) {
      return;
    }
    if (index == widget.currentIndex) {
      return;
    }
    final callback = widget.onIndexChanged;
    if (callback == null) {
      return;
    }
    if (widget.hapticsEnabled) {
      _playHaptic();
    }
    callback(index);
  }

  void _playHaptic() {
    switch (widget.haptic) {
      case LiquidGlassHaptic.selection:
        HapticFeedback.selectionClick();
      case LiquidGlassHaptic.light:
        HapticFeedback.lightImpact();
      case LiquidGlassHaptic.medium:
        HapticFeedback.mediumImpact();
    }
  }

  @override
  void dispose() {
    _controller.stop();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final direction = Directionality.of(context);
    final theme = widget.style.overrideTheme(
      widget.theme.resolve(Theme.of(context)),
    );
    final style = widget.style;
    final padding = style.padding.resolve(direction);
    final margin = style.margin.resolve(direction);
    final safeBottom = style.respectSafeArea
        ? MediaQuery.paddingOf(context).bottom
        : 0.0;
    final resolvedMargin = margin.copyWith(bottom: margin.bottom + safeBottom);
    final bounds = style.innerHeightBounds(padding);
    final morph =
        widget.indicatorStyle == LiquidGlassIndicatorStyle.morphingPill &&
        !_reduceMotion &&
        widget.motion.morphIntensity > 0;
    final radius = style.borderRadius.resolve(direction);

    var width = style.width;
    if (width != null) {
      final minWidth = style.minWidth ?? 0;
      final maxWidth = style.maxWidth ?? double.infinity;
      width = width.clamp(minWidth, maxWidth).toDouble();
    }

    final layout = LiquidNavigationLayout(
      key: _layoutKey,
      targetIndex: _effectiveIndex,
      animation: _controller,
      textDirection: direction,
      itemLayout: style.itemLayout,
      itemSpacing: style.itemSpacing,
      minHeight: bounds.min,
      maxHeight: bounds.max,
      indicatorInset: style.indicatorInset.resolve(direction),
      indicatorRadius: style.indicatorRadius.resolve(direction),
      indicatorColor: theme.indicatorColor,
      indicatorBorderColor: theme.indicatorBorderColor,
      indicatorBorderWidth: style.indicatorBorderWidth,
      morph: morph,
      morphIntensity: widget.motion.morphIntensity,
      children: <Widget>[
        for (var i = 0; i < widget.items.length; i++)
          LiquidNavigationItemView(
            key: ValueKey<int>(i),
            item: widget.items[i],
            index: i,
            count: widget.items.length,
            selected: i == _effectiveIndex,
            labelMode: widget.labelMode,
            style: style,
            theme: theme,
            onTap: () => _handleTap(i),
          ),
      ],
    );

    final glass = GlassSurface(
      style: style,
      theme: theme,
      borderRadius: radius,
      child: Padding(padding: padding, child: layout),
    );

    final constrained = ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: style.minWidth ?? 0,
        maxWidth: style.maxWidth ?? double.infinity,
      ),
      child: width == null ? glass : SizedBox(width: width, child: glass),
    );

    return Semantics(
      role: widget.items.isEmpty ? SemanticsRole.none : SemanticsRole.tabBar,
      label: widget.semanticsLabel,
      container: true,
      explicitChildNodes: true,
      child: Padding(
        padding: resolvedMargin,
        child: Align(
          alignment: Alignment.bottomCenter,
          heightFactor: 1,
          child: constrained,
        ),
      ),
    );
  }
}
