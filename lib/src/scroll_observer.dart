import 'package:flutter/widgets.dart';

import 'visibility_controller.dart';

/// Connects vertical user scrolling to a [LiquidGlassVisibilityController].
///
/// Place this above the page that should drive the bar. The bar does not
/// need to be an ancestor, and the scrollable does not need to hand over its
/// [ScrollController].
///
/// Scrolling down, toward the end of an ordinary vertical list, requests
/// hide after [hideThreshold] logical pixels. Scrolling up requests show
/// after [showThreshold], which is shorter so the bar returns quickly. The
/// accumulator resets when the direction changes. A request for the state
/// the controller already has does not notify.
///
/// The default predicate accepts a vertical notification at depth 0. A
/// horizontal list, including one nested in the vertical page, does not
/// change the bar. A nested vertical scrollable is ignored until a custom
/// [notificationPredicate] accepts its depth. For a [NestedScrollView], wrap
/// the inner scroll view so its notifications arrive at depth 0, or pass a
/// predicate that accepts that depth.
///
/// Notifications are not consumed. The listener always returns false.
///
/// Finger drags count. A ballistic scroll that continues a finger drag
/// counts. [ScrollController.jumpTo] and [ScrollController.animateTo] do not.
/// A user scroll that reaches [topShowExtent] of the top shows the bar.
/// Pulling down while overscrolled at the top also shows it. Overscroll at
/// the bottom does not hide it.
class LiquidGlassScrollObserver extends StatefulWidget {
  /// Creates an observer for [controller].
  const LiquidGlassScrollObserver({
    required this.controller,
    required this.child,
    this.hideThreshold = 40,
    this.showThreshold = 12,
    this.topShowExtent = 12,
    this.enabled = true,
    this.notificationPredicate,
    super.key,
  }) : assert(hideThreshold > 0),
       assert(showThreshold > 0),
       assert(topShowExtent >= 0);

  /// Visibility target updated by accepted scrolls.
  final LiquidGlassVisibilityController controller;

  /// Scrollable page. Nested scrollables bubble through this child.
  final Widget child;

  /// Downward movement, in logical pixels, required before a hide.
  final double hideThreshold;

  /// Upward movement, in logical pixels, required before a show.
  final double showThreshold;

  /// Distance from the top, in logical pixels, that shows the bar.
  final double topShowExtent;

  /// Whether this observer may change [controller].
  ///
  /// False keeps the child mounted and drops its notifications. Use that for
  /// a page that stays alive in an [IndexedStack] while another page is
  /// showing, so the idle page does not hide the bar and its scroll offset
  /// is not recreated on every destination change.
  final bool enabled;

  /// Which notifications are eligible. Null uses vertical depth 0.
  final bool Function(ScrollNotification notification)? notificationPredicate;

  /// Default filter: vertical notifications from the nearest scrollable.
  static bool defaultPredicate(ScrollNotification notification) {
    return notification.metrics.axis == Axis.vertical &&
        notification.depth == 0;
  }

  @override
  State<LiquidGlassScrollObserver> createState() =>
      _LiquidGlassScrollObserverState();
}

class _LiquidGlassScrollObserverState extends State<LiquidGlassScrollObserver> {
  double _accumulated = 0;
  bool? _down;
  bool _followUser = false;
  bool _programmatic = false;
  bool _ballistic = false;
  int _endGeneration = 0;

  bool _onNotification(ScrollNotification notification) {
    if (!widget.enabled) {
      return false;
    }
    final allow =
        widget.notificationPredicate?.call(notification) ??
        LiquidGlassScrollObserver.defaultPredicate(notification);
    if (!allow) {
      return false;
    }
    if (notification is ScrollStartNotification) {
      if (notification.dragDetails != null) {
        _followUser = true;
        _programmatic = false;
        _ballistic = false;
      } else if (_followUser) {
        _ballistic = true;
        _programmatic = false;
      } else {
        _programmatic = true;
      }
      return false;
    }
    if (notification is ScrollEndNotification) {
      if (_programmatic || _ballistic) {
        _followUser = false;
        _programmatic = false;
        _ballistic = false;
        _accumulated = 0;
        _down = null;
        return false;
      }
      final generation = ++_endGeneration;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || generation != _endGeneration || _ballistic) {
          return;
        }
        _followUser = false;
        _accumulated = 0;
        _down = null;
      });
      return false;
    }
    if (notification is ScrollUpdateNotification &&
        _followUser &&
        !_programmatic) {
      _applyUpdate(notification);
    }
    return false;
  }

  void _applyUpdate(ScrollUpdateNotification notification) {
    final metrics = notification.metrics;
    final delta = notification.scrollDelta ?? 0;
    final visualDown = switch (metrics.axisDirection) {
      AxisDirection.down => delta > 0,
      AxisDirection.up => delta < 0,
      AxisDirection.left || AxisDirection.right => false,
    };
    final overscrolled =
        metrics.pixels < metrics.minScrollExtent ||
        metrics.pixels > metrics.maxScrollExtent;
    if (overscrolled) {
      if (!visualDown && metrics.pixels <= metrics.minScrollExtent) {
        widget.controller.show();
        _accumulated = 0;
      }
      return;
    }
    if ((metrics.pixels - metrics.minScrollExtent) <= widget.topShowExtent &&
        !visualDown) {
      widget.controller.show();
      _accumulated = 0;
      _down = false;
      return;
    }
    if (delta == 0) {
      return;
    }
    if (_down != visualDown) {
      _accumulated = 0;
      _down = visualDown;
    }
    _accumulated += delta.abs();
    final limit = visualDown ? widget.hideThreshold : widget.showThreshold;
    if (_accumulated < limit) {
      return;
    }
    _accumulated = 0;
    if (visualDown) {
      widget.controller.hide();
    } else {
      widget.controller.show();
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onNotification,
      child: widget.child,
    );
  }
}
