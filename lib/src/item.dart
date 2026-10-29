import 'package:flutter/widgets.dart';

import 'badge.dart';

/// One destination in a [LiquidGlassNavigationBar].
///
/// Provide an [icon], a [child], or both, plus an optional [label].
/// A [child] replaces the icon and is not tinted by the bar. The label stays
/// optional and is controlled separately by [LiquidGlassLabelMode].
///
/// An item with only a label is invalid. At least [icon] or [child] is
/// required. In debug mode that combination throws an assertion.
@immutable
class LiquidGlassNavigationItem {
  /// Creates a navigation destination.
  const LiquidGlassNavigationItem({
    this.icon,
    this.label,
    this.child,
    this.badge,
    this.semanticLabel,
    this.foregroundColor,
  }) : assert(
         icon != null || child != null,
         'LiquidGlassNavigationItem needs an icon or a child. A label alone is not a destination.',
       );

  /// Icon drawn when [child] is null.
  final IconData? icon;

  /// Optional text label. It can be hidden by the bar's label mode.
  final String? label;

  /// Arbitrary destination content, such as an avatar or an SVG widget.
  ///
  /// When set, it replaces [icon]. The package does not import an SVG or
  /// image package; pass any widget the application already knows how to build.
  ///
  /// The bar handles selection taps. A child that wins the gesture arena, such
  /// as its own button, can block that tap.
  final Widget? child;

  /// Optional notification marker. It does not change the item's layout size.
  final LiquidGlassBadge? badge;

  /// Spoken name for this destination.
  ///
  /// Used as-is when set. Otherwise the bar uses [label], then `Tab N`.
  /// A selected custom child with no visible text still needs a name, so set
  /// this when [child] has no [label].
  final String? semanticLabel;

  /// Foreground color for the icon and label.
  ///
  /// When null, the resolved navigation theme supplies selected and unselected
  /// colors. Custom children paint themselves.
  final Color? foregroundColor;

  /// Whether the item has anything to say to a screen reader besides a
  /// generated tab number.
  bool get hasExplicitSemantics {
    final explicit = semanticLabel?.trim();
    if (explicit != null && explicit.isNotEmpty) {
      return true;
    }
    final text = label?.trim();
    return text != null && text.isNotEmpty;
  }
}

/// Spoken label for [item], including a badge phrase when one is visible.
String liquidGlassItemSemantics(LiquidGlassNavigationItem item, int index) {
  final explicit = item.semanticLabel?.trim();
  final text = item.label?.trim();
  final base = (explicit != null && explicit.isNotEmpty)
      ? explicit
      : (text != null && text.isNotEmpty)
      ? text
      : 'Tab ${index + 1}';
  final suffix = item.badge?.semanticsSuffix;
  if (suffix == null || suffix.isEmpty) {
    return base;
  }
  return '$base, $suffix';
}
