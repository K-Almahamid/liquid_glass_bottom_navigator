import 'package:flutter/foundation.dart';

/// Which glass implementation [LiquidGlassNavigationBar] paints.
///
/// [classic] is the 1.1.0 backdrop blur, tint, and painted rim.
/// [enhanced] keeps that blur and adds a theme-driven veil and highlight.
/// It does not sample the backdrop in a shader.
/// [refractive] samples and displaces the backdrop when Impeller accepts
/// an image-filter shader. Other backends paint [enhanced] instead.
enum LiquidGlassRenderMode {
  /// Backdrop blur, tint, and the painted rim.
  classic,

  /// Classic blur plus a theme-driven veil. No backdrop shader.
  enhanced,

  /// Backdrop texture displacement where [ImageFilter.shader] is supported.
  refractive,
}

/// Density of the glass fill.
///
/// [regular] is the navigation default. [clear] keeps more of the backdrop
/// visible and is meant for photography or video behind the bar.
enum LiquidGlassMaterialVariant {
  /// Balanced translucency for ordinary navigation.
  regular,

  /// Higher transparency for image-rich backgrounds.
  clear,
}

/// Rendering options for the navigation glass.
///
/// This does not replace [LiquidGlassNavigationStyle] or
/// [LiquidGlassNavigationTheme]. Style still owns size, blur, and radius.
/// Theme still owns the tint and foreground colors. This object only selects
/// how those values are painted.
///
/// The default is [LiquidGlassRenderMode.classic], which keeps the 1.1.0
/// appearance. Strengths are fractions from 0 to 1.
@immutable
class LiquidGlassMaterial {
  /// Creates a material description.
  const LiquidGlassMaterial({
    this.mode = LiquidGlassRenderMode.classic,
    this.variant = LiquidGlassMaterialVariant.regular,
    this.refractionStrength = 0.35,
    this.edgeThickness = 0.22,
    this.highlightIntensity = 0.28,
    this.adaptiveTint = true,
  }) : assert(
         refractionStrength >= 0 && refractionStrength <= 1,
         'refractionStrength must be between 0 and 1',
       ),
       assert(
         edgeThickness >= 0 && edgeThickness <= 1,
         'edgeThickness must be between 0 and 1',
       ),
       assert(
         highlightIntensity >= 0 && highlightIntensity <= 1,
         'highlightIntensity must be between 0 and 1',
       );

  /// The 1.1.0 blur and rim. No shader.
  static const LiquidGlassMaterial classic = LiquidGlassMaterial();

  /// Refractive glass tuned so the edge effect is visible without maxing it.
  ///
  /// This is a starting point for demos. The default constructor stays
  /// [classic], so existing callers are unchanged. The shader still falls
  /// back to enhanced glass when the backend cannot sample the backdrop.
  static const LiquidGlassMaterial refractive = LiquidGlassMaterial(
    mode: LiquidGlassRenderMode.refractive,
    variant: LiquidGlassMaterialVariant.regular,
    refractionStrength: 0.58,
    edgeThickness: 0.52,
    highlightIntensity: 0.36,
  );

  /// Backdrop blur, or the refractive shader when the backend allows it.
  final LiquidGlassRenderMode mode;

  /// Regular navigation glass, or a clearer fill over imagery.
  final LiquidGlassMaterialVariant variant;

  /// How far edge samples move, from 0 to 1.
  ///
  /// Used by [LiquidGlassRenderMode.refractive]. The center of the glass
  /// stays nearly still. 0 disables the shift. The filter is clipped to the
  /// glass shape, and the shader reads only that backdrop. One sample moves
  /// a few pixels along the rim normal. A tight blur around that same point
  /// softens the interior and keeps the page color. Clear reaches a little
  /// farther and stays more transparent than regular. The full blur sigma
  /// is not applied first.
  final double refractionStrength;

  /// How wide the curved edge band is, from 0 to 1.
  final double edgeThickness;

  /// Strength of the soft edge highlight, from 0 to 1.
  final double highlightIntensity;

  /// Whether refractive sampling may shift the veil with backdrop luminance.
  ///
  /// This changes the glass fill. It does not recolor icons or labels.
  /// Those stay on the navigation theme.
  final bool adaptiveTint;

  /// Returns a copy with the given fields replaced.
  LiquidGlassMaterial copyWith({
    LiquidGlassRenderMode? mode,
    LiquidGlassMaterialVariant? variant,
    double? refractionStrength,
    double? edgeThickness,
    double? highlightIntensity,
    bool? adaptiveTint,
  }) {
    return LiquidGlassMaterial(
      mode: mode ?? this.mode,
      variant: variant ?? this.variant,
      refractionStrength: refractionStrength ?? this.refractionStrength,
      edgeThickness: edgeThickness ?? this.edgeThickness,
      highlightIntensity: highlightIntensity ?? this.highlightIntensity,
      adaptiveTint: adaptiveTint ?? this.adaptiveTint,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is LiquidGlassMaterial &&
        other.mode == mode &&
        other.variant == variant &&
        other.refractionStrength == refractionStrength &&
        other.edgeThickness == edgeThickness &&
        other.highlightIntensity == highlightIntensity &&
        other.adaptiveTint == adaptiveTint;
  }

  @override
  int get hashCode => Object.hash(
    mode,
    variant,
    refractionStrength,
    edgeThickness,
    highlightIntensity,
    adaptiveTint,
  );
}
