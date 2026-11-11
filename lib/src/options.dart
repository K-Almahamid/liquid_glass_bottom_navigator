/// How item labels are shown inside [LiquidGlassNavigationBar].
///
/// Items without a label stay valid in every mode. The bar reserves the label
/// line whenever any item has a label, including [hidden]. That keeps one icon
/// line and one capsule height. [hidden] does not paint the label, so the
/// capsule width follows the icon and stays a horizontal pill. Changing the
/// selection does not change the bar height.
enum LiquidGlassLabelMode {
  /// Hide every label, including items that provide one.
  ///
  /// The label line stays in the layout so the icon and the capsule height
  /// match [always]. The capsule width follows the icon. Spoken labels stay
  /// on the semantics node.
  hidden,

  /// Show every item that provides a label.
  ///
  /// The selected capsule wraps that item's icon and label.
  always,

  /// Show a label only on the selected item. Other labels keep their layout
  /// space and are not visible, so the icon line does not move.
  ///
  /// The selected capsule wraps that item's icon and label.
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
