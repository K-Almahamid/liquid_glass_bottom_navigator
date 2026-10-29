import 'package:flutter/material.dart';

/// Colors for the glass surface, indicator, labels, and badges.
///
/// Use [LiquidGlassNavigationTheme.adaptive] to follow the ambient
/// [ThemeData.brightness] and [ColorScheme]. Use [light] or [dark] for a fixed
/// appearance. Pass an explicit instance to ignore the ambient theme.
@immutable
class LiquidGlassNavigationTheme {
  /// Creates an explicit theme. It does not change with the ambient brightness.
  const LiquidGlassNavigationTheme({
    required this.glassTint,
    this.glassOpacity = 0.72,
    required this.borderColor,
    required this.highlightColor,
    required this.shadowColor,
    required this.indicatorColor,
    required this.indicatorBorderColor,
    required this.selectedForeground,
    required this.unselectedForeground,
    required this.badgeBackground,
    required this.badgeForeground,
  }) : assert(glassOpacity >= 0 && glassOpacity <= 1),
       adaptive = false;

  const LiquidGlassNavigationTheme._({
    required this.glassTint,
    required this.glassOpacity,
    required this.borderColor,
    required this.highlightColor,
    required this.shadowColor,
    required this.indicatorColor,
    required this.indicatorBorderColor,
    required this.selectedForeground,
    required this.unselectedForeground,
    required this.badgeBackground,
    required this.badgeForeground,
    required this.adaptive,
  });

  /// Follows the surrounding [Theme] brightness and color scheme.
  const LiquidGlassNavigationTheme.adaptive()
    : glassTint = const Color(0x00000000),
      glassOpacity = 0,
      borderColor = const Color(0x00000000),
      highlightColor = const Color(0x00000000),
      shadowColor = const Color(0x00000000),
      indicatorColor = const Color(0x00000000),
      indicatorBorderColor = const Color(0x00000000),
      selectedForeground = const Color(0x00000000),
      unselectedForeground = const Color(0x00000000),
      badgeBackground = const Color(0x00000000),
      badgeForeground = const Color(0x00000000),
      adaptive = true;

  /// Warm light glass. Independent of the ambient theme.
  static const LiquidGlassNavigationTheme light = LiquidGlassNavigationTheme._(
    adaptive: false,
    glassTint: Color(0xFFF7F4EF),
    glassOpacity: 0.42,
    borderColor: Color(0x14000000),
    highlightColor: Color(0x5CFFFFFF),
    shadowColor: Color(0x1A161616),
    indicatorColor: Color(0x24145E59),
    indicatorBorderColor: Color(0x2E145E59),
    selectedForeground: Color(0xFF145E59),
    unselectedForeground: Color(0xC23A4444),
    badgeBackground: Color(0xFFB42318),
    badgeForeground: Color(0xFFFFFFFF),
  );

  /// Dark glass. Independent of the ambient theme.
  static const LiquidGlassNavigationTheme dark = LiquidGlassNavigationTheme._(
    adaptive: false,
    glassTint: Color(0xFF12161A),
    glassOpacity: 0.34,
    borderColor: Color(0x1AFFFFFF),
    highlightColor: Color(0x24FFFFFF),
    shadowColor: Color(0x59000000),
    indicatorColor: Color(0x338FE3D6),
    indicatorBorderColor: Color(0x408FE3D6),
    selectedForeground: Color(0xFFBFF6EE),
    unselectedForeground: Color(0xB3FFFFFF),
    badgeBackground: Color(0xFFFF6B5A),
    badgeForeground: Color(0xFF2A0C08),
  );

  /// Whether [resolve] reads the ambient theme.
  final bool adaptive;

  /// Glass fill before [glassOpacity] is applied.
  final Color glassTint;

  /// Alpha used for [glassTint]. `1` is opaque and `0` is clear.
  final double glassOpacity;

  /// Hairline border color.
  final Color borderColor;

  /// Top-edge sheen. This is a gradient, not a second blur.
  final Color highlightColor;

  /// Outer shadow color.
  final Color shadowColor;

  /// Selection capsule fill.
  final Color indicatorColor;

  /// Selection capsule stroke.
  final Color indicatorBorderColor;

  /// Icon and label color for the selected item.
  final Color selectedForeground;

  /// Icon and label color for unselected items.
  final Color unselectedForeground;

  /// Default badge fill.
  final Color badgeBackground;

  /// Default badge label color.
  final Color badgeForeground;

  /// Tint actually painted, with [glassOpacity] applied.
  Color get resolvedGlassTint => glassTint.withValues(alpha: glassOpacity);

  /// Resolves [adaptive] themes from [theme]. Explicit themes return themselves.
  LiquidGlassNavigationTheme resolve(ThemeData theme) {
    if (!adaptive) {
      return this;
    }
    final scheme = theme.colorScheme;
    final darkTheme = theme.brightness == Brightness.dark;
    final base = darkTheme ? dark : light;
    return base.copyWith(
      glassTint: darkTheme ? const Color(0xFF12161A) : const Color(0xFFF6F7F6),
      selectedForeground: scheme.primary,
      indicatorColor: scheme.primary.withValues(alpha: darkTheme ? 0.22 : 0.14),
      indicatorBorderColor: scheme.primary.withValues(
        alpha: darkTheme ? 0.36 : 0.22,
      ),
      unselectedForeground: scheme.onSurface.withValues(
        alpha: darkTheme ? 0.74 : 0.7,
      ),
      badgeBackground: scheme.error,
      badgeForeground: scheme.onError,
    );
  }

  /// Returns a copy with the given fields replaced.
  LiquidGlassNavigationTheme copyWith({
    Color? glassTint,
    double? glassOpacity,
    Color? borderColor,
    Color? highlightColor,
    Color? shadowColor,
    Color? indicatorColor,
    Color? indicatorBorderColor,
    Color? selectedForeground,
    Color? unselectedForeground,
    Color? badgeBackground,
    Color? badgeForeground,
  }) {
    return LiquidGlassNavigationTheme._(
      adaptive: false,
      glassTint: glassTint ?? this.glassTint,
      glassOpacity: glassOpacity ?? this.glassOpacity,
      borderColor: borderColor ?? this.borderColor,
      highlightColor: highlightColor ?? this.highlightColor,
      shadowColor: shadowColor ?? this.shadowColor,
      indicatorColor: indicatorColor ?? this.indicatorColor,
      indicatorBorderColor: indicatorBorderColor ?? this.indicatorBorderColor,
      selectedForeground: selectedForeground ?? this.selectedForeground,
      unselectedForeground: unselectedForeground ?? this.unselectedForeground,
      badgeBackground: badgeBackground ?? this.badgeBackground,
      badgeForeground: badgeForeground ?? this.badgeForeground,
    );
  }
}
