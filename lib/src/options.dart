/// How item labels are shown inside [LiquidGlassNavigationBar].
///
/// Items without a label stay valid in every mode. The bar height does not
/// change with the mode or the selection. Icon positions do: [hidden] centers
/// every icon in the glass, and [selected] centers unselected icons while the
/// selected icon rises to make room for its label. Hiding a label changes what
/// is drawn, not the selected capsule's size.
enum LiquidGlassLabelMode {
  /// Hide every label, including items that provide one.
  ///
  /// No label is built and none is reserved under the icon. The selected
  /// capsule keeps the size it would have with that destination's label, and
  /// the icon is centered in the capsule and in the glass. Spoken labels stay
  /// on the semantics node.
  hidden,

  /// Show every item that provides a label.
  ///
  /// Each icon and label is centered as one group. The selected capsule wraps
  /// that icon and label. Icons in this mode share one vertical line.
  always,

  /// Show a label only on the selected item.
  ///
  /// Unselected icons are centered in the glass. The selected icon moves up,
  /// the label appears under it, and that icon-plus-label group stays centered
  /// in the capsule and in the glass. The move follows the selection spring.
  /// A drag preview does not show a label on a destination the parent has not
  /// adopted.
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
