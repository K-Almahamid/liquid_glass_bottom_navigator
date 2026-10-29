import 'package:flutter/widgets.dart';

/// What a [LiquidGlassBadge] draws.
enum LiquidGlassBadgeKind {
  /// A small dot with no count.
  dot,

  /// A numeric count, clamped to a maximum such as `99+`.
  count,

  /// An arbitrary badge widget supplied by the application.
  custom,
}

/// Notification marker drawn over a navigation item without affecting its width.
@immutable
class LiquidGlassBadge {
  /// A dot badge.
  const LiquidGlassBadge.dot({this.backgroundColor, this.size = 8})
    : kind = LiquidGlassBadgeKind.dot,
      count = 0,
      maxCount = 99,
      child = null,
      foregroundColor = null,
      textStyle = null,
      semanticLabel = null;

  /// A numeric badge.
  ///
  /// Counts of `0` or below are not drawn. Counts above [maxCount] render as
  /// `maxCount+`.
  const LiquidGlassBadge.count(
    this.count, {
    this.maxCount = 99,
    this.backgroundColor,
    this.foregroundColor,
    this.textStyle,
    this.size,
  }) : assert(maxCount >= 1),
       kind = LiquidGlassBadgeKind.count,
       child = null,
       semanticLabel = null;

  /// An arbitrary badge child, such as a custom icon.
  ///
  /// The child is overlaid on the item and does not participate in item sizing.
  /// Prefer this name at call sites. [LiquidGlassBadge.custom] is the same
  /// constructor.
  const LiquidGlassBadge.child(
    Widget child, {
    String? semanticLabel,
    Color? backgroundColor,
    double? size,
  }) : this.custom(
         child,
         semanticLabel: semanticLabel,
         backgroundColor: backgroundColor,
         size: size,
       );

  /// An arbitrary badge child, such as a custom icon.
  ///
  /// Same configuration as [LiquidGlassBadge.child].
  const LiquidGlassBadge.custom(
    this.child, {
    this.semanticLabel,
    this.backgroundColor,
    this.size,
  }) : kind = LiquidGlassBadgeKind.custom,
       count = 0,
       maxCount = 99,
       foregroundColor = null,
       textStyle = null;

  /// Which badge presentation this configuration uses.
  final LiquidGlassBadgeKind kind;

  /// Numeric count for [LiquidGlassBadge.count].
  final int count;

  /// Largest count rendered before the label switches to `maxCount+`.
  final int maxCount;

  /// Child used by [LiquidGlassBadge.custom].
  final Widget? child;

  /// Badge fill. Falls back to the navigation theme when null.
  final Color? backgroundColor;

  /// Badge label color. Falls back to the navigation theme when null.
  final Color? foregroundColor;

  /// Count text style. Size and weight fall back to the bar defaults.
  final TextStyle? textStyle;

  /// Dot diameter, or the minimum extent of a count badge when set.
  final double? size;

  /// Spoken description for a custom badge. Count and dot badges build their
  /// own descriptions.
  final String? semanticLabel;

  /// Whether this badge should be painted.
  bool get isVisible {
    return switch (kind) {
      LiquidGlassBadgeKind.dot => true,
      LiquidGlassBadgeKind.count => count > 0,
      LiquidGlassBadgeKind.custom => child != null,
    };
  }

  /// Short phrase appended to the parent item's semantic label.
  String? get semanticsSuffix {
    if (!isVisible) {
      return null;
    }
    return switch (kind) {
      LiquidGlassBadgeKind.dot => 'new notification',
      LiquidGlassBadgeKind.count =>
        '${count > maxCount ? '$maxCount or more' : count} notifications',
      LiquidGlassBadgeKind.custom => semanticLabel,
    };
  }

  /// The count string users see, such as `12` or `99+`.
  String get displayCount {
    if (count > maxCount) {
      return '$maxCount+';
    }
    return '$count';
  }
}
