import 'package:flutter/material.dart';
import 'package:liquid_glass_bottom_navigator/liquid_glass_bottom_navigator.dart';

/// Motion presets shown in the appearance sheet.
enum GalleryMotionPreset {
  /// Default liquid spring.
  spring,

  /// Short spring with little stretch.
  snappy,

  /// Slow spring.
  gentle,

  /// No interpolation.
  none,
}

/// Maps a gallery preset to the package motion value and its label.
extension GalleryMotionPresetValue on GalleryMotionPreset {
  /// Package motion for this preset.
  LiquidGlassMotion get value => switch (this) {
    GalleryMotionPreset.spring => const LiquidGlassMotion.spring(),
    GalleryMotionPreset.snappy => const LiquidGlassMotion.snappy(),
    GalleryMotionPreset.gentle => const LiquidGlassMotion.gentle(),
    GalleryMotionPreset.none => const LiquidGlassMotion.none(),
  };

  /// Short label used in the segmented control.
  String get label => switch (this) {
    GalleryMotionPreset.spring => 'Spring',
    GalleryMotionPreset.snappy => 'Snappy',
    GalleryMotionPreset.gentle => 'Gentle',
    GalleryMotionPreset.none => 'None',
  };
}

/// Backdrop painted behind the gallery pages.
enum GalleryBackdrop {
  /// The ordinary gallery canvas.
  page,

  /// A flat light field.
  light,

  /// A flat dark field.
  dark,

  /// A two-stop color gradient.
  gradient,

  /// A saturated gradient.
  saturated,

  /// A detailed painted field with text and shapes.
  pattern,
}

/// Every option the appearance sheet can change.
@immutable
class ExampleControls {
  /// Creates controls. Defaults match a calm phone bar with drag enabled.
  const ExampleControls({
    this.themeMode = ThemeMode.system,
    this.labelMode = LiquidGlassLabelMode.always,
    this.indicatorStyle = LiquidGlassIndicatorStyle.morphingPill,
    this.motion = GalleryMotionPreset.spring,
    this.haptics = true,
    this.reducedMotion = false,
    this.rtl = false,
    this.includeLabels = true,
    this.blur = 18,
    this.height = 58,
    this.radius = 32,
    this.margin = 16,
    this.padding = 6,
    this.itemSpacing = 0,
    this.itemCount = 5,
    this.compactWidth = false,
    this.equalSlots = true,
    this.respectSafeArea = true,
    this.dragSelection = true,
    this.scrollCollapse = false,
    this.glassMode = LiquidGlassRenderMode.classic,
    this.glassVariant = LiquidGlassMaterialVariant.regular,
    this.refractionStrength = 0.35,
    this.edgeThickness = 0.22,
    this.highlightIntensity = 0.28,
    this.adaptiveTint = true,
    this.backdrop = GalleryBackdrop.page,
  });

  /// Light, dark, or the platform setting.
  final ThemeMode themeMode;

  /// Which destination labels the bar shows.
  final LiquidGlassLabelMode labelMode;

  /// Sliding or morphing capsule.
  final LiquidGlassIndicatorStyle indicatorStyle;

  /// Spring, snappy, gentle, or none.
  final GalleryMotionPreset motion;

  /// Whether selection may play haptics.
  final bool haptics;

  /// Forces [MediaQueryData.disableAnimations].
  final bool reducedMotion;

  /// Lays the gallery out from right to left.
  final bool rtl;

  /// Whether destination items include text labels.
  final bool includeLabels;

  /// Backdrop blur. Zero is clear glass.
  final double blur;

  /// Minimum glass height.
  final double height;

  /// Outer corner radius of the glass.
  final double radius;

  /// Horizontal margin of the floating bar.
  final double margin;

  /// Inner padding on every side of the glass.
  final double padding;

  /// Gap between destination slots.
  final double itemSpacing;

  /// How many destinations are in the bar, from two to five.
  final int itemCount;

  /// Locks the bar to 280 logical pixels.
  final bool compactWidth;

  /// Equal slots when true, intrinsic widths when false.
  final bool equalSlots;

  /// Adds the bottom safe inset to the bar margin.
  final bool respectSafeArea;

  /// Horizontal drag from the selected destination.
  final bool dragSelection;

  /// Whether the active page can collapse the bar while scrolling.
  final bool scrollCollapse;

  /// Classic blur, enhanced veil, or refractive sampling.
  final LiquidGlassRenderMode glassMode;

  /// Regular navigation fill, or a clearer fill.
  final LiquidGlassMaterialVariant glassVariant;

  /// Edge displacement for refractive mode, from 0 to 1.
  final double refractionStrength;

  /// Width of the curved edge band, from 0 to 1.
  final double edgeThickness;

  /// Soft edge highlight, from 0 to 1.
  final double highlightIntensity;

  /// Whether refractive glass may follow backdrop luminance.
  final bool adaptiveTint;

  /// What sits behind the pages so the glass can be compared.
  final GalleryBackdrop backdrop;

  /// Material passed to the navigation bar.
  LiquidGlassMaterial get material {
    return LiquidGlassMaterial(
      mode: glassMode,
      variant: glassVariant,
      refractionStrength: refractionStrength,
      edgeThickness: edgeThickness,
      highlightIntensity: highlightIntensity,
      adaptiveTint: adaptiveTint,
    );
  }

  /// Returns a copy with the given fields replaced.
  ExampleControls copyWith({
    ThemeMode? themeMode,
    LiquidGlassLabelMode? labelMode,
    LiquidGlassIndicatorStyle? indicatorStyle,
    GalleryMotionPreset? motion,
    bool? haptics,
    bool? reducedMotion,
    bool? rtl,
    bool? includeLabels,
    double? blur,
    double? height,
    double? radius,
    double? margin,
    double? padding,
    double? itemSpacing,
    int? itemCount,
    bool? compactWidth,
    bool? equalSlots,
    bool? respectSafeArea,
    bool? dragSelection,
    bool? scrollCollapse,
    LiquidGlassRenderMode? glassMode,
    LiquidGlassMaterialVariant? glassVariant,
    double? refractionStrength,
    double? edgeThickness,
    double? highlightIntensity,
    bool? adaptiveTint,
    GalleryBackdrop? backdrop,
  }) {
    return ExampleControls(
      themeMode: themeMode ?? this.themeMode,
      labelMode: labelMode ?? this.labelMode,
      indicatorStyle: indicatorStyle ?? this.indicatorStyle,
      motion: motion ?? this.motion,
      haptics: haptics ?? this.haptics,
      reducedMotion: reducedMotion ?? this.reducedMotion,
      rtl: rtl ?? this.rtl,
      includeLabels: includeLabels ?? this.includeLabels,
      blur: blur ?? this.blur,
      height: height ?? this.height,
      radius: radius ?? this.radius,
      margin: margin ?? this.margin,
      padding: padding ?? this.padding,
      itemSpacing: itemSpacing ?? this.itemSpacing,
      itemCount: itemCount ?? this.itemCount,
      compactWidth: compactWidth ?? this.compactWidth,
      equalSlots: equalSlots ?? this.equalSlots,
      respectSafeArea: respectSafeArea ?? this.respectSafeArea,
      dragSelection: dragSelection ?? this.dragSelection,
      scrollCollapse: scrollCollapse ?? this.scrollCollapse,
      glassMode: glassMode ?? this.glassMode,
      glassVariant: glassVariant ?? this.glassVariant,
      refractionStrength: refractionStrength ?? this.refractionStrength,
      edgeThickness: edgeThickness ?? this.edgeThickness,
      highlightIntensity: highlightIntensity ?? this.highlightIntensity,
      adaptiveTint: adaptiveTint ?? this.adaptiveTint,
      backdrop: backdrop ?? this.backdrop,
    );
  }
}
