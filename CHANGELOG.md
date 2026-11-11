## 1.1.0

* Adds `enableDragSelection`. It defaults to false, so 1.0.0 callers stay tap-only.
* When dragging is enabled, a horizontal drag from the selected destination moves the liquid indicator. `onIndexChanged` runs once on release over a different destination. Gaps and misses spring back. `currentIndex` stays parent-owned.
* Dragging respects RTL slot geometry, reduced motion, haptic settings, and both indicator styles. Pointer movement repaints the indicator and does not rebuild the items.
* The selection capsule wraps the visible icon and label, plus `indicatorInset` (default 14 by 3). `hidden` keeps that capsule height and the same icon line, and its width follows the icon while staying a horizontal pill. A badge does not change those bounds. A short bar reduces the vertical margin so the content still fits.
* At the first and last destinations, the gap from the capsule to the glass is the same on the top, the bottom, and the outer side. The default glass padding is 6 on every side. The default glass height is 58. The default `maxWidth` is 520, so a phone uses the width left after the margin and a wider parent stops at 520. Pass `double.infinity` for a full-width bar. A slot that is too narrow to hold the inset keeps the capsule inside the slot and centered on the icon and label. The outer gap then yields to that center.
* The default elevation is 0. The glass rim is one stroke, lighter on the top edge than on the bottom. Set `elevation` to opt into a shadow.
* A drag preview follows the finger continuously. Stretch grows both sides of the grabbed center. The droplet eases through a plain pill when the finger slows or reverses, then points in the new direction. Width eases between destination capsules instead of stepping at slot edges.
* A count badge sits above the icon's trailing corner. A dot sits below that corner. `badgeOffset` defaults to zero and shifts either badge: positive x moves outward, positive y moves down.
* Navigation icons share one vertical center in every label mode. Changing the selected destination or the label mode does not move that line. `hidden` keeps the label line in the layout and does not paint it. The example opens on `always`.

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
