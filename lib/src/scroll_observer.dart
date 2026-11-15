import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'collapse_controller.dart';

/// Optional recorder for scroll-collapse diagnostics.
///
/// Leave this null on a production bar. When it is set, the observer records
/// phase changes, ignored updates, and collapse or expand requests. It does
/// not store every scroll delta.
class LiquidGlassScrollTrace {
  /// Phase changes and requests. Capped so a long drag cannot grow it.
  final List<String> events = <String>[];

  /// Scroll updates that were eligible to move the accumulator.
  int updates = 0;

  /// Eligible notifications that did not move the accumulator.
  int ignored = 0;

  /// Collapse or expand calls that changed the controller.
  int requests = 0;

  /// Times the tracked direction flipped during one finger drag.
  int reversals = 0;

  /// `idle`, `drag`, `ballistic`, or `programmatic`.
  String phase = 'idle';

  /// Movement accumulated toward the current direction, in logical pixels.
  double accumulated = 0;

  /// Why the latest eligible notification was ignored, if it was.
  String? lastIgnore;

  void _event(String event) {
    if (events.length < 48) {
      events.add(event);
    }
  }
}

/// Connects vertical user scrolling to a [LiquidGlassCollapseController].
///
/// Place this above the page that should drive the bar. The bar does not
/// need to be an ancestor, and the scrollable does not need to hand over its
/// [ScrollController].
///
/// Scrolling down, toward the end of an ordinary vertical list, requests
/// collapse after [collapseThreshold] logical pixels. Scrolling up requests
/// expand after [expandThreshold], which is shorter so the full bar returns
/// on a small reversal. The accumulator resets when the finger reverses, and
/// it never grows past the larger threshold. A request for the state the
/// controller already has does not notify.
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
/// A finger drag counts, including a direction change in that same drag.
/// Movement toward [ScrollMetrics.maxScrollExtent] collapses, for both
/// [AxisDirection.down] and [AxisDirection.up]. Movement back toward the
/// start expands. A ballistic scroll continues the drag's direction and does
/// not treat the bounce-back as a new request. A finger that lands during
/// that ballistic scroll is a new drag, so a short upward move can expand.
/// Overscroll past the bottom does not collapse, but the in-range part of a
/// drag that crosses the bottom still counts. A user scroll within
/// [topShowExtent] of the top, or a pull past the top, expands.
/// [ScrollController.jumpTo] and [ScrollController.animateTo] do not.
///
/// Set [trace] to record the phase machine. Compile with
/// `--dart-define=LIQUID_GLASS_SCROLL_TRACE=true` to print phase changes in
/// debug and profile builds. Neither path prints per-frame deltas.
class LiquidGlassScrollObserver extends StatefulWidget {
  /// Creates an observer for [controller].
  const LiquidGlassScrollObserver({
    required this.controller,
    required this.child,
    this.collapseThreshold = 12,
    this.expandThreshold = 4,
    this.topShowExtent = 12,
    this.enabled = true,
    this.notificationPredicate,
    this.trace,
    super.key,
  }) : assert(collapseThreshold > 0),
       assert(expandThreshold > 0),
       assert(topShowExtent >= 0);

  /// Collapse target updated by accepted scrolls.
  final LiquidGlassCollapseController controller;

  /// Scrollable page. Nested scrollables bubble through this child.
  final Widget child;

  /// Downward movement, in logical pixels, required before a collapse.
  final double collapseThreshold;

  /// Upward movement, in logical pixels, required before an expand.
  final double expandThreshold;

  /// Distance from the top, in logical pixels, that expands the bar.
  final double topShowExtent;

  /// Whether this observer may change [controller].
  ///
  /// False keeps the child mounted and drops its notifications. Use that for
  /// a page that stays alive in an [IndexedStack] while another page is
  /// showing, so the idle page does not collapse the bar and its scroll
  /// offset is not recreated on every destination change.
  final bool enabled;

  /// Which notifications are eligible. Null uses vertical depth 0.
  final bool Function(ScrollNotification notification)? notificationPredicate;

  /// Diagnostic recorder. Null in production.
  final LiquidGlassScrollTrace? trace;

  /// Prints phase changes when built with `LIQUID_GLASS_SCROLL_TRACE`.
  static const bool debugLog = bool.fromEnvironment(
    'LIQUID_GLASS_SCROLL_TRACE',
  );

  /// Default filter: vertical notifications from the nearest scrollable.
  static bool defaultPredicate(ScrollNotification notification) {
    return notification.metrics.axis == Axis.vertical &&
        notification.depth == 0;
  }

  @override
  State<LiquidGlassScrollObserver> createState() =>
      _LiquidGlassScrollObserverState();
}

enum _ScrollPhase { idle, drag, ballistic, programmatic }

class _LiquidGlassScrollObserverState extends State<LiquidGlassScrollObserver> {
  _ScrollPhase _phase = _ScrollPhase.idle;
  double _accumulated = 0;
  bool? _down;

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
      _onStart(notification);
    } else if (notification is ScrollUpdateNotification) {
      _onUpdate(notification);
    } else if (notification is OverscrollNotification) {
      _onOverscroll(notification);
    } else if (notification is UserScrollNotification) {
      _note('user ${notification.direction.name}');
    } else if (notification is ScrollEndNotification) {
      _setPhase(_ScrollPhase.idle, 'end');
      _accumulated = 0;
      _down = null;
      _publish();
    }
    return false;
  }

  void _onStart(ScrollStartNotification notification) {
    if (notification.dragDetails != null) {
      _setPhase(_ScrollPhase.drag, 'start drag');
      _accumulated = 0;
      _down = null;
      _publish();
      return;
    }
    if (_phase == _ScrollPhase.drag || _phase == _ScrollPhase.ballistic) {
      _setPhase(_ScrollPhase.ballistic, 'start ballistic');
      return;
    }
    _setPhase(_ScrollPhase.programmatic, 'start programmatic');
    _accumulated = 0;
    _down = null;
    _publish();
  }

  void _onUpdate(ScrollUpdateNotification notification) {
    final finger = notification.dragDetails != null;
    if (finger) {
      if (_phase != _ScrollPhase.drag) {
        _setPhase(_ScrollPhase.drag, 'drag update');
        _accumulated = 0;
        _down = null;
      }
      _apply(notification.scrollDelta ?? 0, notification.metrics, finger: true);
      return;
    }
    if (_phase == _ScrollPhase.drag) {
      _setPhase(_ScrollPhase.ballistic, 'ballistic update');
    }
    if (_phase == _ScrollPhase.ballistic) {
      _apply(
        notification.scrollDelta ?? 0,
        notification.metrics,
        finger: false,
      );
      return;
    }
    _ignore('programmatic update');
  }

  void _onOverscroll(OverscrollNotification notification) {
    if (_phase != _ScrollPhase.drag && _phase != _ScrollPhase.ballistic) {
      _ignore('programmatic overscroll');
      return;
    }
    _apply(
      notification.overscroll,
      notification.metrics,
      finger: notification.dragDetails != null || _phase == _ScrollPhase.drag,
    );
  }

  void _apply(double delta, ScrollMetrics metrics, {required bool finger}) {
    widget.trace?.updates++;
    if (delta == 0) {
      _ignore('zero delta');
      return;
    }
    final visualDown = delta > 0;
    final pastStart = metrics.pixels < metrics.minScrollExtent;
    final pastEnd = metrics.pixels > metrics.maxScrollExtent;
    if (pastStart && !visualDown) {
      if (finger) {
        _requestExpand('top overscroll');
      } else {
        _ignore('top bounce');
      }
      return;
    }
    if (pastEnd && !visualDown) {
      if (finger) {
        _requestExpand('leave bottom overscroll');
      } else {
        _ignore('bottom bounce');
      }
      return;
    }
    var applied = delta;
    if (pastEnd && visualDown) {
      final overshoot = metrics.pixels - metrics.maxScrollExtent;
      final inRange = applied.abs() - overshoot;
      if (inRange <= 0.5) {
        _ignore('bottom overscroll');
        return;
      }
      applied = applied.sign * inRange;
    }
    final nearTop =
        metrics.pixels - metrics.minScrollExtent <= widget.topShowExtent;
    if (finger && nearTop && !visualDown && !pastEnd) {
      _requestExpand('near top');
      return;
    }
    if (!finger && _down != null && _down != visualDown) {
      _ignore('ballistic reversal');
      return;
    }
    if (_down != visualDown) {
      _accumulated = 0;
      _down = visualDown;
      widget.trace?.reversals++;
      _note(visualDown ? 'direction down' : 'direction up');
    }
    final cap = widget.collapseThreshold > widget.expandThreshold
        ? widget.collapseThreshold
        : widget.expandThreshold;
    _accumulated += applied.abs();
    if (_accumulated > cap) {
      _accumulated = cap;
    }
    _publish();
    if (visualDown) {
      if (_accumulated >= widget.collapseThreshold) {
        _requestCollapse('threshold');
      }
      return;
    }
    if (_accumulated >= widget.expandThreshold) {
      _requestExpand('threshold');
    }
  }

  void _requestCollapse(String reason) {
    if (widget.controller.isCollapsed) {
      return;
    }
    widget.trace?.requests++;
    _note('collapse $reason');
    widget.controller.collapse();
  }

  void _requestExpand(String reason) {
    if (!widget.controller.isCollapsed) {
      _accumulated = 0;
      _down = false;
      _publish();
      return;
    }
    widget.trace?.requests++;
    _note('expand $reason');
    widget.controller.expand();
    _accumulated = 0;
    _down = false;
    _publish();
  }

  void _setPhase(_ScrollPhase phase, String reason) {
    if (_phase == phase) {
      return;
    }
    _phase = phase;
    _note(reason);
    _publish();
  }

  void _ignore(String reason) {
    final trace = widget.trace;
    if (trace != null) {
      trace.ignored++;
      trace.lastIgnore = reason;
    }
  }

  void _note(String event) {
    widget.trace?._event(event);
    if (LiquidGlassScrollObserver.debugLog && !kReleaseMode) {
      debugPrint('LiquidGlassScroll: $event');
    }
  }

  void _publish() {
    final trace = widget.trace;
    if (trace == null) {
      return;
    }
    trace.phase = _phase.name;
    trace.accumulated = _accumulated;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onNotification,
      child: widget.child,
    );
  }
}
