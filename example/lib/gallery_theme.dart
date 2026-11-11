import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';

/// Calm colors for the example gallery.
///
/// Light is a warm off-white. Dark is a deep charcoal. [accent] is the only
/// chromatic color, so the glass bar is what carries the material.
@immutable
class GalleryColors extends ThemeExtension<GalleryColors> {
  /// Creates gallery colors.
  const GalleryColors({
    required this.canvas,
    required this.card,
    required this.wash,
    required this.ink,
    required this.secondary,
    required this.hairline,
    required this.accent,
    required this.onAccent,
    required this.track,
  });

  /// Soft warm off-white gallery.
  static const light = GalleryColors(
    canvas: Color(0xFFF3F1EC),
    card: Color(0xFFFFFCF8),
    wash: Color(0xFFE6F0EC),
    ink: Color(0xFF1C1C1E),
    secondary: Color(0xFF6F6B66),
    hairline: Color(0x1A1C1C1E),
    accent: Color(0xFF3E6B5E),
    onAccent: Color(0xFFFFFFFF),
    track: Color(0xFFE4E1DB),
  );

  /// Deep charcoal gallery.
  static const dark = GalleryColors(
    canvas: Color(0xFF141416),
    card: Color(0xFF242428),
    wash: Color(0xFF1C2A26),
    ink: Color(0xFFF4F2EE),
    secondary: Color(0xFFA9A59F),
    hairline: Color(0x2EFFFFFF),
    accent: Color(0xFF8FB8AA),
    onAccent: Color(0xFF12211C),
    track: Color(0xFF2C2C30),
  );

  /// Page background behind the cards.
  final Color canvas;

  /// Raised card and grouped section fill.
  final Color card;

  /// Quiet accent wash for featured surfaces and icon wells.
  final Color wash;

  /// Primary text.
  final Color ink;

  /// Secondary text.
  final Color secondary;

  /// Hairline used between rows and around cards.
  final Color hairline;

  /// The single accent.
  final Color accent;

  /// Text and icons drawn on [accent].
  final Color onAccent;

  /// Track behind a segmented control.
  final Color track;

  /// Colors for the ambient [Theme].
  static GalleryColors of(BuildContext context) {
    final colors = Theme.of(context).extension<GalleryColors>();
    assert(colors != null, 'GalleryColors is missing from ThemeData.');
    return colors!;
  }

  @override
  GalleryColors copyWith({
    Color? canvas,
    Color? card,
    Color? wash,
    Color? ink,
    Color? secondary,
    Color? hairline,
    Color? accent,
    Color? onAccent,
    Color? track,
  }) {
    return GalleryColors(
      canvas: canvas ?? this.canvas,
      card: card ?? this.card,
      wash: wash ?? this.wash,
      ink: ink ?? this.ink,
      secondary: secondary ?? this.secondary,
      hairline: hairline ?? this.hairline,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      track: track ?? this.track,
    );
  }

  @override
  GalleryColors lerp(ThemeExtension<GalleryColors>? other, double t) {
    if (other is! GalleryColors) {
      return this;
    }
    return GalleryColors(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      card: Color.lerp(card, other.card, t)!,
      wash: Color.lerp(wash, other.wash, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      track: Color.lerp(track, other.track, t)!,
    );
  }
}

/// Light and dark [ThemeData] for the example app.
abstract final class GalleryTheme {
  /// Warm light theme.
  static ThemeData light() => _theme(Brightness.light, GalleryColors.light);

  /// Charcoal dark theme.
  static ThemeData dark() => _theme(Brightness.dark, GalleryColors.dark);

  /// Resolves [mode] against the platform brightness.
  static ThemeData forMode(ThemeMode mode, Brightness platform) {
    final useDark = switch (mode) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system => platform == Brightness.dark,
    };
    return useDark ? dark() : light();
  }
}

ThemeData _theme(Brightness brightness, GalleryColors colors) {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: colors.accent,
        brightness: brightness,
        dynamicSchemeVariant: DynamicSchemeVariant.neutral,
      ).copyWith(
        primary: colors.accent,
        onPrimary: colors.onAccent,
        secondary: colors.accent,
        onSecondary: colors.onAccent,
        surface: colors.canvas,
        onSurface: colors.ink,
        onSurfaceVariant: colors.secondary,
        outline: colors.hairline,
        outlineVariant: colors.hairline,
        surfaceTint: Colors.transparent,
        error: brightness == Brightness.light
            ? const Color(0xFFB42318)
            : const Color(0xFFFF8A7A),
        onError: brightness == Brightness.light
            ? const Color(0xFFFFFFFF)
            : const Color(0xFF2A0C08),
      );
  final base = brightness == Brightness.light
      ? Typography.material2021(platform: defaultTargetPlatform).black
      : Typography.material2021(platform: defaultTargetPlatform).white;

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: colors.canvas,
    canvasColor: colors.canvas,
    dividerColor: colors.hairline,
    splashFactory: InkRipple.splashFactory,
    fontFamily: _appleFont(),
    extensions: [colors],
    textTheme: base.apply(
      bodyColor: colors.ink,
      displayColor: colors.ink,
      fontFamily: _appleFont(),
    ),
    iconTheme: IconThemeData(color: colors.ink),
    cupertinoOverrideTheme: CupertinoThemeData(
      brightness: brightness,
      primaryColor: colors.accent,
      applyThemeToAll: true,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colors.canvas,
      surfaceTintColor: Colors.transparent,
      dragHandleColor: colors.secondary.withValues(alpha: 0.45),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return colors.onAccent;
        }
        return colors.card;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return colors.accent;
        }
        return colors.track;
      }),
    ),
  );
}

String? _appleFont() {
  switch (defaultTargetPlatform) {
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      return '.AppleSystemUIFont';
    case TargetPlatform.android:
    case TargetPlatform.fuchsia:
    case TargetPlatform.linux:
    case TargetPlatform.windows:
      return null;
  }
}
