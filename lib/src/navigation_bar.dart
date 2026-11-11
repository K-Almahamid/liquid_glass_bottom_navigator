import 'dart:ui' show SemanticsRole;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import 'glass_surface.dart';
import 'indicator_geometry.dart';
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
/// [onIndexChanged] reports taps, and drag releases when
/// [enableDragSelection] is true, that request a different item. It does not
/// own a navigation stack and does not depend on a state-management package.
///
/// Dragging previews the indicator only. [currentIndex] stays the selection
/// until the parent changes it. A drag that ends on the current item, in a
/// gap, or outside every destination does not call [onIndexChanged].
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
    this.enableDragSelection = false,
    this.semanticsLabel,
    super.key,
  });

  /// Destinations, from start to end.
  final List<LiquidGlassNavigationItem> items;

  /// Selected destination. Ignored when it does not point at an item.
  final int currentIndex;

  /// Called when a tap or a completed drag requests a different index.
  ///
  /// The parent should set [currentIndex] to the reported value. The bar does
  /// not change its own selection. A drag calls this once, on release, and
  /// only when the finger is inside a different destination. If the parent
  /// keeps the old index, the indicator returns to it.
  ///
  /// Indicator frames and label springs do not call this. A programmatic
  /// [currentIndex] change does not call this either.
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

  /// Whether a horizontal drag from the selected item can request a new index.
  ///
  /// Defaults to false, so existing bars stay tap-only. When true, the drag
  /// starts on the selected destination, follows the finger, and calls
  /// [onIndexChanged] once if released over a different destination. Taps,
  /// keyboard activation, and vertical scrolling are unchanged. The drag is
  /// a preview: [currentIndex] remains the parent's value.
  final bool enableDragSelection;

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
  bool _disposed = false;
  TextDirection? _direction;

  /// Pointer-down hit the selected slot, so a later horizontal drag may track.
  bool _dragArmed = false;

  /// The pointer moved far enough horizontally and the indicator is following.
  bool _dragging = false;

  /// The active pointer, so a second finger cannot retarget the preview.
  int? _pointer;
  Offset? _downLocal;

  /// Index requested on release, until the parent commits or the preview ends.
  int? _claimedIndex;
  Rect? _dragOrigin;
  double _grabDx = 0;

  /// Last preview center, so a reverse move updates direction immediately.
  double? _lastPreviewCenter;

  /// Index whose label was showing before the current selection spring.
  ///
  /// [currentIndex] flips as soon as the parent rebuilds, while the spring is
  /// still at the previous item. Selected-only labels read this so the old
  /// icon can settle down and the new one can rise with that same spring.
  int? _labelFrom;

  /// Smoothed drag direction, from -1 (left) through 0 (neutral) to 1 (right).
  ///
  /// The value eases toward the latest movement and decays when the finger
  /// slows, so the droplet relaxes before it points the other way.
  double _flow = 0;
  bool _movingRight = true;

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
    final direction = Directionality.of(context);
    final directionChanged = _direction != null && _direction != direction;
    _direction = direction;
    final next = _resolveReducedMotion();
    final becameReduced = next && !_reduceMotion;
    _reduceMotion = next;
    if (becameReduced) {
      _endDragTracking();
      _controller.stop();
      _controller.value = 1;
      _render?.snap();
    } else if (directionChanged) {
      // The render object drops the drag preview when direction changes.
      _endDragTracking();
    }
  }

  @override
  void didUpdateWidget(LiquidGlassNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _reduceMotion = _resolveReducedMotion();
    final itemsChanged = widget.items.length != oldWidget.items.length;
    final indexChanged = widget.currentIndex != oldWidget.currentIndex;
    final dragDisabled =
        oldWidget.enableDragSelection && !widget.enableDragSelection;
    if (!itemsChanged && !indexChanged) {
      if (dragDisabled && _dragging) {
        _endDragTracking();
        _settleToAuthority();
      }
      return;
    }
    // Parent index and item count win over an in-flight preview.
    _endDragTracking();
    if (itemsChanged) {
      _labelFrom = null;
    } else if (indexChanged) {
      _labelFrom = _indexOf(oldWidget);
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

  int? _indexOf(LiquidGlassNavigationBar bar) {
    if (bar.currentIndex < 0 || bar.currentIndex >= bar.items.length) {
      return null;
    }
    return bar.currentIndex;
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

  bool get _canStretch {
    return widget.indicatorStyle == LiquidGlassIndicatorStyle.morphingPill &&
        !_reduceMotion &&
        widget.motion.morphIntensity > 0;
  }

  void _endDragTracking() {
    _dragArmed = false;
    _dragging = false;
    _claimedIndex = null;
    _dragOrigin = null;
    _pointer = null;
    _downLocal = null;
    _lastPreviewCenter = null;
    _flow = 0;
  }

  /// Records the grab offset only when the pointer starts on the selection.
  ///
  /// This listener does not enter the gesture arena. A tap still belongs to
  /// the item, and a vertical move still belongs to a surrounding scroll view.
  /// Tracking starts only after [kTouchSlop], and only when that movement is
  /// more horizontal than vertical.
  void _onPointerDown(PointerDownEvent event) {
    if (_pointer != null) {
      return;
    }
    final render = _render;
    final index = _effectiveIndex;
    _pointer = event.pointer;
    _downLocal = event.localPosition;
    _dragging = false;
    if (render == null || index == null) {
      _dragArmed = false;
      return;
    }
    final slots = render.debugItemRects;
    if (index >= slots.length || !slots[index].contains(event.localPosition)) {
      _dragArmed = false;
      return;
    }
    final origin = render.debugIndicatorRect ?? render.indicatorRects[index];
    _dragArmed = true;
    _dragOrigin = origin;
    _grabDx = event.localPosition.dx - origin.center.dx;
    _lastPreviewCenter = origin.center.dx;
    _movingRight = true;
    _flow = 0;
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (event.pointer != _pointer || !_dragArmed || _downLocal == null) {
      return;
    }
    if (!_dragging) {
      final delta = event.localPosition - _downLocal!;
      if (delta.distance <= kTouchSlop) {
        return;
      }
      if (delta.dx.abs() < delta.dy.abs()) {
        _dragArmed = false;
        return;
      }
    }
    _trackDrag(event.localPosition);
  }

  void _onPointerUp(PointerUpEvent event) {
    if (event.pointer != _pointer) {
      return;
    }
    if (_dragging) {
      _finishDrag(event.localPosition);
      return;
    }
    _endDragTracking();
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (event.pointer != _pointer) {
      return;
    }
    final wasDragging = _dragging;
    _endDragTracking();
    if (wasDragging) {
      _settleToAuthority();
    }
  }

  void _trackDrag(Offset local) {
    if (!_dragArmed || _dragOrigin == null || _disposed) {
      return;
    }
    final render = _render;
    final origin = _dragOrigin;
    if (render == null || origin == null || !render.attached) {
      return;
    }
    if (!_dragging) {
      _dragging = true;
      _controller.stop();
    }
    final centerX = local.dx - _grabDx;
    final previous = _lastPreviewCenter ?? centerX;
    final delta = centerX - previous;
    if (delta.abs() < 0.4) {
      _flow *= 0.45;
    } else {
      final impulse = (delta / 16).clamp(-1.0, 1.0);
      _flow = (_flow * 0.55 + impulse * 0.45).clamp(-1.0, 1.0);
    }
    _movingRight = _flow >= 0;
    _lastPreviewCenter = centerX;
    final placement = liquidDragPlacement(
      slots: render.indicatorRects,
      origin: origin,
      centerX: centerX,
      stretch: _canStretch,
      morphIntensity: widget.motion.morphIntensity,
      movingRight: _movingRight,
      flow: _canStretch ? _flow : 0,
    );
    render.showDrag(
      placement.rect,
      blob: placement.blob,
      travelRight: placement.travelRight,
    );
  }

  /// Resolves the release against slot rectangles, not the nearest center.
  void _finishDrag(Offset local) {
    if (!_dragging || _disposed) {
      _endDragTracking();
      return;
    }
    final render = _render;
    final originIndex = widget.currentIndex;
    _dragArmed = false;
    _dragging = false;
    _dragOrigin = null;
    _pointer = null;
    _downLocal = null;
    _lastPreviewCenter = null;
    _flow = 0;
    if (render == null || !render.attached) {
      _claimedIndex = null;
      return;
    }
    final index = liquidSlotAt(render.debugItemRects, local);
    final callback = widget.onIndexChanged;
    final eligible =
        index != null &&
        index != originIndex &&
        index >= 0 &&
        index < widget.items.length &&
        callback != null;
    if (!eligible) {
      _claimedIndex = null;
      _settleToAuthority();
      return;
    }
    _claimedIndex = index;
    if (widget.hapticsEnabled) {
      _playHaptic();
    }
    callback(index);
    if (_claimedIndex != index || !mounted) {
      return;
    }
    // The callback above may have scheduled the parent's update. This frame
    // is the earliest moment that update is visible. scheduleFrame is required
    // because a post-frame callback alone does not request one.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_disposed || !mounted) {
        return;
      }
      if (_claimedIndex == index && widget.currentIndex != index) {
        _claimedIndex = null;
        _settleToAuthority();
      }
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  /// Springs from the current preview back to [currentIndex].
  void _settleToAuthority() {
    if (_disposed || !mounted) {
      return;
    }
    final render = _render;
    if (render == null || !render.attached) {
      return;
    }
    render.beginTransition(_effectiveIndex);
    _runMotion();
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
    // Children unmount before State.dispose. The row removes its animation
    // listener while this controller is still alive. This method then releases
    // the one ticker this state owns.
    _disposed = true;
    _endDragTracking();
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

    // All-labels mode keeps one label band on every destination, including
    // destinations that have no label, so those icons stay on one line.
    // Icons-only uses that band's measured size for the capsule only. The
    // icon stays centered, and no label is built.
    final anyLabel = widget.items.any(_hasLabel);
    final reserveLabelLine =
        widget.labelMode == LiquidGlassLabelMode.always && anyLabel;
    final matchLabeledCapsule =
        widget.labelMode == LiquidGlassLabelMode.hidden && anyLabel;
    final layoutChild = LiquidNavigationLayout(
      key: _layoutKey,
      targetIndex: _effectiveIndex,
      animation: _controller,
      textDirection: direction,
      itemLayout: style.itemLayout,
      itemSpacing: style.itemSpacing,
      minHeight: bounds.min,
      maxHeight: bounds.max,
      barPadding: padding,
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
            reserveLabelLine: reserveLabelLine,
            matchLabeledCapsule: matchLabeledCapsule,
            labelAnimation: _controller,
            labelFrom: _labelFrom,
            labelTo: _effectiveIndex,
            style: style,
            theme: theme,
            onTap: () => _handleTap(i),
          ),
      ],
    );
    final layout = widget.enableDragSelection
        ? Listener(
            behavior: HitTestBehavior.deferToChild,
            onPointerDown: _onPointerDown,
            onPointerMove: _onPointerMove,
            onPointerUp: _onPointerUp,
            onPointerCancel: _onPointerCancel,
            child: layoutChild,
          )
        : layoutChild;

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

bool _hasLabel(LiquidGlassNavigationItem item) {
  final label = item.label?.trim();
  return label != null && label.isNotEmpty;
}
