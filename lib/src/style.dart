import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'options.dart';
import 'theme.dart';

/// Layout, glass, and indicator dimensions for the navigation bar.
///
/// Colors live on the navigation theme. Motion lives on the motion settings.
@immutable
class LiquidGlassNavigationStyle {
  /// Creates style settings.
  ///
  /// [height] is the minimum outer height of the glass surface, excluding
  /// [margin] and any safe-area inset. When [expandForTextScale] is true, the
  /// bar may grow for larger text up to [maxHeight]. Set
  /// [expandForTextScale] to false to lock the bar at [height].
  ///
  /// [width] null lets the bar take the parent's width after [margin], up to
  /// [maxWidth]. A narrow parent produces a narrow bar. An unbounded parent
  /// sizes the bar to its items, still capped by [maxWidth].
  const LiquidGlassNavigationStyle({
    this.width,
    this.minWidth,
    this.maxWidth = 520,
    this.height = 58,
    this.maxHeight,
    this.expandForTextScale = true,
    this.margin = const EdgeInsets.fromLTRB(16, 0, 16, 12),
    this.padding = const EdgeInsets.all(6),
    this.itemSpacing = 0,
    this.itemPadding = const EdgeInsets.symmetric(horizontal: 2),
    this.itemLayout = LiquidGlassItemLayout.equal,
    this.borderRadius = const BorderRadius.all(Radius.circular(32)),
    this.indicatorInset = const EdgeInsets.symmetric(
      horizontal: 14,
      vertical: 3,
    ),
    this.indicatorRadius = const BorderRadius.all(Radius.circular(24)),
    this.indicatorBorderWidth = 1,
    this.iconSize = 24,
    this.labelSpacing = 3,
    this.labelStyle,
    this.selectedLabelStyle,
    this.unselectedLabelStyle,
    this.blurSigma = 18,
    this.borderWidth = 1,
    this.elevation = 0,
    this.shadowBlurRadius,
    this.shadowOffset,
    this.minTouchTarget = 48,
    this.respectSafeArea = true,
    this.badgeOffset = Offset.zero,
    this.badgeMinSize = 16,
    this.backgroundColor,
    this.backgroundOpacity,
    this.borderColor,
    this.indicatorColor,
    this.selectedForeground,
    this.unselectedForeground,
  }) : assert(height > 0),
       assert(maxHeight == null || maxHeight >= height),
       assert(width == null || width > 0),
       assert(minWidth == null || minWidth >= 0),
       assert(maxWidth == null || maxWidth > 0),
       assert(blurSigma >= 0),
       assert(borderWidth >= 0),
       assert(indicatorBorderWidth >= 0),
       assert(iconSize > 0),
       assert(itemSpacing >= 0),
       assert(labelSpacing >= 0),
       assert(elevation >= 0),
       assert(minTouchTarget >= 0),
       assert(badgeMinSize > 0),
       assert(
         backgroundOpacity == null ||
             (backgroundOpacity >= 0 && backgroundOpacity <= 1),
       );

  /// Explicit glass width. Null uses the parent's available width.
  final double? width;

  /// Smallest glass width after [margin].
  final double? minWidth;

  /// Largest glass width after [margin].
  ///
  /// The default is 520. A phone uses the width left after [margin], because
  /// that width is below the cap. A wider parent stops at 520 so the bar does
  /// not stretch across a tablet. Pass [double.infinity] for the full parent.
  final double? maxWidth;

  /// Minimum outer height of the glass surface, excluding margin.
  final double height;

  /// Maximum outer height of the glass surface when text scale grows it.
  final double? maxHeight;

  /// Whether large text can grow the bar past [height].
  final bool expandForTextScale;

  /// Space outside the glass. Directional values are resolved for RTL.
  final EdgeInsetsGeometry margin;

  /// Space inside the glass, around the items.
  ///
  /// The default is 6 on every side. At the first and last destinations the
  /// capsule's distance to the glass matches on the top, the bottom, and the
  /// outer side.
  final EdgeInsetsGeometry padding;

  /// Gap between item slots.
  final double itemSpacing;

  /// Padding inside each item slot, around its icon and label.
  final EdgeInsetsGeometry itemPadding;

  /// Equal slots or intrinsic item widths.
  final LiquidGlassItemLayout itemLayout;

  /// Outer corner radius of the glass.
  final BorderRadiusGeometry borderRadius;

  /// Breathing room around the selected icon, label, and custom child.
  ///
  /// Horizontal and vertical insets are independent. The smaller of the two
  /// horizontal sides is the side margin, and the smaller of the two vertical
  /// sides is the top and bottom margin. The default is 14 by 3. The capsule
  /// wraps the visible icon and label, then adds this margin. A badge does not
  /// change those bounds. At the first and last destinations, the gap from the
  /// capsule to the glass matches the gap above and below it when the slot can
  /// hold that inset. A shorter bar reduces the vertical margin so the content
  /// still fits. Large text or a wide child can use the whole slot instead.
  final EdgeInsetsGeometry indicatorInset;

  /// Corner radius of the selection capsule.
  final BorderRadiusGeometry indicatorRadius;

  /// Stroke width of the selection capsule. Zero removes the stroke.
  final double indicatorBorderWidth;

  /// Icon size for items that use an icon rather than a custom child.
  final double iconSize;

  /// Vertical gap between the icon (or custom child) and the label.
  final double labelSpacing;

  /// Base label style. Color is supplied by the theme.
  final TextStyle? labelStyle;

  /// Extra style merged for the selected label.
  final TextStyle? selectedLabelStyle;

  /// Extra style merged for unselected labels.
  final TextStyle? unselectedLabelStyle;

  /// Backdrop blur sigma. Zero disables the blur and keeps the tinted surface.
  ///
  /// Blur samples the pixels behind the bar and is the most expensive part of
  /// the glass. Prefer one modest sigma over stacking additional filters.
  final double blurSigma;

  /// Width of the hairline border around the glass.
  final double borderWidth;

  /// Shadow strength. The default is zero, so the bar has no drop shadow.
  /// Set a positive value to opt into one. Zero removes the outer shadow.
  ///
  /// When [shadowBlurRadius] or [shadowOffset] is null, the shadow is derived
  /// from this elevation.
  final double elevation;

  /// Explicit shadow blur. Null derives `elevation * 2.2`.
  final double? shadowBlurRadius;

  /// Explicit shadow offset. Null derives `(0, elevation * 0.55)`.
  final Offset? shadowOffset;

  /// Minimum width and height requested for each item's hit target.
  ///
  /// The bar honors this when the slot is large enough. A shorter [height] or
  /// a very narrow bar wins over the target so the layout stays finite.
  final double minTouchTarget;

  /// Whether the bottom [MediaQueryData.padding] is added under the glass.
  final bool respectSafeArea;

  /// Extra shift applied after the badge's own anchor.
  ///
  /// A count sits above the trailing corner of the icon. A dot sits below that
  /// corner. Positive x moves further outside the end edge (right in LTR, left
  /// in RTL). Positive y moves downward. The default is zero, so each kind
  /// keeps its own anchor. A custom badge uses this offset from the top-end
  /// corner.
  final Offset badgeOffset;

  /// Minimum width and height of a count badge.
  final double badgeMinSize;

  /// Glass tint that replaces the theme tint when set.
  ///
  /// The painted alpha is [backgroundOpacity] when that field is set, and the
  /// theme opacity otherwise. The color's own alpha is not reused. An adaptive
  /// theme cannot replace a value set here.
  final Color? backgroundColor;

  /// Painted alpha for the glass tint. Null keeps the theme opacity.
  final double? backgroundOpacity;

  /// Hairline color. Null keeps the theme border color.
  final Color? borderColor;

  /// Selection capsule fill. Null keeps the theme indicator color.
  final Color? indicatorColor;

  /// Selected icon and label color. Null keeps the theme color.
  ///
  /// An item [LiquidGlassNavigationItem.foregroundColor] still wins over this.
  final Color? selectedForeground;

  /// Unselected icon and label color. Null keeps the theme color.
  final Color? unselectedForeground;

  /// Applies explicit colors from this style on top of [theme].
  ///
  /// Null style colors leave the theme value unchanged. Call this after
  /// [LiquidGlassNavigationTheme.resolve] so adaptive colors are the base and
  /// these fields are the final override.
  LiquidGlassNavigationTheme overrideTheme(LiquidGlassNavigationTheme theme) {
    return theme.copyWith(
      glassTint: backgroundColor,
      glassOpacity: backgroundOpacity,
      borderColor: borderColor,
      indicatorColor: indicatorColor,
      selectedForeground: selectedForeground,
      unselectedForeground: unselectedForeground,
    );
  }

  /// Resolved shadow blur.
  double get effectiveShadowBlur {
    if (elevation == 0) {
      return 0;
    }
    return shadowBlurRadius ?? elevation * 2.2;
  }

  /// Resolved shadow offset.
  Offset get effectiveShadowOffset {
    if (elevation == 0) {
      return Offset.zero;
    }
    return shadowOffset ?? Offset(0, elevation * 0.55);
  }

  /// Outer glass height limits after removing vertical padding.
  ({double min, double max}) innerHeightBounds(EdgeInsets resolvedPadding) {
    final vertical = resolvedPadding.vertical;
    final min = math.max(0.0, height - vertical);
    if (!expandForTextScale) {
      return (min: min, max: min);
    }
    final max = maxHeight == null
        ? double.infinity
        : math.max(min, maxHeight! - vertical);
    return (min: min, max: max);
  }

  /// Returns a copy with the given fields replaced.
  LiquidGlassNavigationStyle copyWith({
    double? width,
    double? minWidth,
    double? maxWidth,
    double? height,
    double? maxHeight,
    bool? expandForTextScale,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
    double? itemSpacing,
    EdgeInsetsGeometry? itemPadding,
    LiquidGlassItemLayout? itemLayout,
    BorderRadiusGeometry? borderRadius,
    EdgeInsetsGeometry? indicatorInset,
    BorderRadiusGeometry? indicatorRadius,
    double? indicatorBorderWidth,
    double? iconSize,
    double? labelSpacing,
    TextStyle? labelStyle,
    TextStyle? selectedLabelStyle,
    TextStyle? unselectedLabelStyle,
    double? blurSigma,
    double? borderWidth,
    double? elevation,
    double? shadowBlurRadius,
    Offset? shadowOffset,
    double? minTouchTarget,
    bool? respectSafeArea,
    Offset? badgeOffset,
    double? badgeMinSize,
    Color? backgroundColor,
    double? backgroundOpacity,
    Color? borderColor,
    Color? indicatorColor,
    Color? selectedForeground,
    Color? unselectedForeground,
    bool clearWidth = false,
    bool clearMaxHeight = false,
  }) {
    return LiquidGlassNavigationStyle(
      width: clearWidth ? null : width ?? this.width,
      minWidth: minWidth ?? this.minWidth,
      maxWidth: maxWidth ?? this.maxWidth,
      height: height ?? this.height,
      maxHeight: clearMaxHeight ? null : maxHeight ?? this.maxHeight,
      expandForTextScale: expandForTextScale ?? this.expandForTextScale,
      margin: margin ?? this.margin,
      padding: padding ?? this.padding,
      itemSpacing: itemSpacing ?? this.itemSpacing,
      itemPadding: itemPadding ?? this.itemPadding,
      itemLayout: itemLayout ?? this.itemLayout,
      borderRadius: borderRadius ?? this.borderRadius,
      indicatorInset: indicatorInset ?? this.indicatorInset,
      indicatorRadius: indicatorRadius ?? this.indicatorRadius,
      indicatorBorderWidth: indicatorBorderWidth ?? this.indicatorBorderWidth,
      iconSize: iconSize ?? this.iconSize,
      labelSpacing: labelSpacing ?? this.labelSpacing,
      labelStyle: labelStyle ?? this.labelStyle,
      selectedLabelStyle: selectedLabelStyle ?? this.selectedLabelStyle,
      unselectedLabelStyle: unselectedLabelStyle ?? this.unselectedLabelStyle,
      blurSigma: blurSigma ?? this.blurSigma,
      borderWidth: borderWidth ?? this.borderWidth,
      elevation: elevation ?? this.elevation,
      shadowBlurRadius: shadowBlurRadius ?? this.shadowBlurRadius,
      shadowOffset: shadowOffset ?? this.shadowOffset,
      minTouchTarget: minTouchTarget ?? this.minTouchTarget,
      respectSafeArea: respectSafeArea ?? this.respectSafeArea,
      badgeOffset: badgeOffset ?? this.badgeOffset,
      badgeMinSize: badgeMinSize ?? this.badgeMinSize,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      backgroundOpacity: backgroundOpacity ?? this.backgroundOpacity,
      borderColor: borderColor ?? this.borderColor,
      indicatorColor: indicatorColor ?? this.indicatorColor,
      selectedForeground: selectedForeground ?? this.selectedForeground,
      unselectedForeground: unselectedForeground ?? this.unselectedForeground,
    );
  }
}
