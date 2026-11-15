import 'package:flutter/widgets.dart';

import 'collapse_controller.dart';

/// Connects vertical user scrolling to a [LiquidGlassCollapseController].
///
/// Place this above the page that should drive the bar. The bar does not
/// need to be an ancestor, and the scrollable does not need to hand over its
/// [ScrollController].
///
/// Scrolling down, toward the end of an ordinary vertical list, requests
/// collapse. Scrolling up requests expansion. Movement in one direction has
/// to accumulate [threshold] logical pixels before the controller is asked
/// to change, and the accumulator resets when the direction changes. A
/// request for the state the controller already has does not notify.
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
/// counts. [ScrollController.jumpTo] and [ScrollController.animateTo] do not,
/// except that a user scroll which is already within [topExpandExtent] of
/// the top expands the bar. Pulling down while overscrolled at the top also
/// expands. Overscroll in the other direction does not collapse.
class LiquidGlassScrollObserver extends StatefulWidget {
  /// Creates an observer for [controller].
  const LiquidGlassScrollObserver({
    required this.controller,
    required this.child,
    this.threshold = 48,
    this.topExpandExtent = 12,
    this.notificationPredicate,
    super.key,
  }) : assert(threshold > 0),
       assert(topExpandExtent >= 0);

  /// Collapse target updated by accepted scrolls.
  final LiquidGlassCollapseController controller;

  /// Scrollable page. Nested scrollables bubble through this child.
  final Widget child;

  /// Accumulated movement, in logical pixels, required to change state.
  final double threshold;

  /// Distance from the top, in logical pixels, that expands the bar.
  final double topExpandExtent;

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
        widget.controller.expand();
        _accumulated = 0;
      }
      return;
    }
    if ((metrics.pixels - metrics.minScrollExtent) <= widget.topExpandExtent &&
        !visualDown) {
      widget.controller.expand();
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
    if (_accumulated < widget.threshold) {
      return;
    }
    _accumulated = 0;
    if (visualDown) {
      widget.controller.collapse();
    } else {
      widget.controller.expand();
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
