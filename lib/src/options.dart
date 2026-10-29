/// How item labels are shown inside [LiquidGlassNavigationBar].
///
/// Items without a label stay valid in every mode. The bar reserves label
/// space whenever a mode can show labels, so changing selection does not
/// change the bar height.
enum LiquidGlassLabelMode {
  /// Hide every label, including items that provide one.
  hidden,

  /// Show every item that provides a label.
  always,

  /// Show a label only on the selected item. Other labels keep their layout
  /// space and are not visible.
  selected,
}

/// Visual behavior of the selection indicator.
enum LiquidGlassIndicatorStyle {
  /// A capsule that slides and resizes to the destination item.
  ///
  /// Travel uses the bar's motion settings. This style does not add the extra
  /// stretch used by [morphingPill].
  slidingPill,

  /// A capsule that stretches toward the destination while it travels, then
  /// settles back to the item shape.
  ///
  /// This is a geometric motion treatment. It does not simulate optical
  /// refraction.
  morphingPill,
}

/// How navigation items share the bar's inner width.
enum LiquidGlassItemLayout {
  /// Give every item the same width and align the indicator to that slot.
  ///
  /// This is the default. When the incoming width is unbounded, items fall
  /// back to their intrinsic widths.
  equal,

  /// Size each item from its child, then pack the row from the start edge.
  ///
  /// The indicator uses those measured widths. If the intrinsic row is wider
  /// than the bar, items fall back to equal slots.
  intrinsic,
}

/// Hardware haptic played for a user selection.
///
/// Actual feedback depends on the platform, the device, and the user's system
/// settings. Programmatic `currentIndex` changes never play haptics.
enum LiquidGlassHaptic {
  /// A light selection tick. This is the default.
  selection,

  /// A light impact.
  light,

  /// A medium impact.
  medium,
}
