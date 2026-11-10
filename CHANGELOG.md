## 1.1.0

* Adds `enableDragSelection`. It defaults to false, so 1.0.0 callers stay tap-only.
* When dragging is enabled, a horizontal drag from the selected destination moves the liquid indicator. `onIndexChanged` runs once on release over a different destination. Gaps and misses spring back. `currentIndex` stays parent-owned.
* Dragging respects RTL slot geometry, reduced motion, haptic settings, and both indicator styles. Pointer movement repaints the indicator and does not rebuild the items.
* The selection capsule hugs the selected icon, label, badge, and custom child instead of filling the slot. `indicatorInset` is the even breathing room around that content. The smallest side is used, and a short bar reduces it so the content still fits.
* At the first and last destinations, the gap from the capsule to the glass is the same on the top, the bottom, and the outer side. The default glass padding is 6 on every side. A slot that is too narrow to hold that inset keeps the capsule inside the slot.
* Navigation icons share one vertical center. Showing or hiding a label, or changing the selected destination, does not move them. The label sits under that center.

## 1.0.0

* First stable release of the controlled liquid-glass bottom navigation bar.
* Removes the unused `highlightColor` theme field. The glass does not paint a top sheen.
* Destinations accept keyboard focus. Enter and Space activate the focused item, and a hairline shows focus.
* Badge outlines contrast with the badge fill instead of the glass tint.
* The indicator stroke is kept inside the row so a centered stroke is not clipped by the bar.
* The example can switch equal and intrinsic slots, and can turn safe-area padding off.

## 0.1.0

* Initial implementation of a controlled liquid-glass bottom navigation bar.
* Adds equal and intrinsic item layout, optional labels, custom item children, badges, haptics, light and dark themes, RTL, and reduced-motion behavior.
* The selection indicator moves with a spring. `slidingPill` keeps a rigid capsule. `morphingPill` stretches it while it travels. The glass effect is a clipped backdrop blur, not optical refraction.
* Style colors override the resolved theme. A destination needs an icon or a child. `LiquidGlassBadge.child` overlays custom badge content. The bar accepts a `semanticsLabel`.
* The backdrop blur is clipped to the bar and samples content behind it. The item row, not the whole bar, is the repaint boundary. A direction change drops an in-flight indicator origin.
* The glass is a clipped backdrop blur plus a neutral tint. It does not paint a top sheen or a second blur, and it does not refract the page.
* `morphingPill` stretches into a liquid bubble while it travels: the leading end moves ahead and the trailing end narrows, then it settles into a pill. `slidingPill` stays rigid.
