## 1.2.0

* Adds `LiquidGlassMaterial`. The default mode is `classic`, which is the 1.1.0 backdrop blur, tint, and painted rim.
* `enhanced` keeps that blur and adds a theme-driven veil and capsule highlight. It does not sample backdrop pixels.
* `refractive` displaces the backdrop near the glass edge on Impeller, through `ImageFilter.shader` clipped to the glass. Other backends, a failed shader load, and the load itself paint `enhanced` instead. Icons and labels stay on the theme. High contrast makes the enhanced and refractive fills more opaque.
* `regular` and `clear` change how much of the backdrop the fill keeps. Clear is the lighter of the two.
* Adds optional scroll collapse. `enableScrollCollapse` defaults to false, so 1.1.0 bars stay expanded.
* `LiquidGlassCollapseController` holds the expanded or compact target. `collapse`, `expand`, and `toggle` do not notify when the target is already current. The bar owns the morph. It does not dispose a controller the caller passed in.
* `LiquidGlassScrollObserver` collapses after about 12 logical pixels of downward user scrolling and expands after about 4 of upward scrolling. A direction change in the same drag resets that distance. A fling keeps the drag's direction, and a finger that interrupts the fling can expand on a short upward move. A user scroll at the top expands the bar. The observer ignores horizontal lists, nested scrollables at depth greater than 0, bottom overscroll, ballistic bounce-back, and programmatic `jumpTo` or `animateTo`. `enabled` false keeps the child mounted and ignores it. The observer does not consume scroll notifications. Pass `trace` to record phase changes without per-frame logs.
* `LiquidGlassMaterial.refractive` is an opt-in preset (regular variant, refraction 0.58, edge 0.52, highlight 0.36). The default constructor remains classic.
* The scroll morph uses one continuous surface. Unselected labels and the selection capsule fade on a smooth curve instead of disappearing at a fixed progress. A full collapse takes about 420 ms and a full expand about 380 ms, scaled by the remaining distance, on an ease-in-out curve. A reversal starts from the current shape.
* The refractive wash is light again. A luminance veil and a heavier theme overlay had turned the bar gray. The shader keeps the page color, bends one sample along the rim, and softens that sample with a few nearby taps. The filter stays clipped to the glass. It is an approximation, not Apple's Liquid Glass.
* The refractive filter is clipped to the glass shape. An earlier margin around the bar painted filtered pixels outside the pill and mixed several displaced samples, which repeated text. The shader now uses one sample, shifted a few pixels along the rim, plus a 3-pixel blur around that sample. Regular still softens more than clear. It is an approximation, not Apple's Liquid Glass. The backdrop texture is only the clipped shape. A debug build prints once when the shader is active and once when it falls back to enhanced. The example starts on the refractive preset. Package blur and the classic path stay as they were. Non-page example backdrops are also painted in the band behind the bar, so the glass can sample them.
* The same glass surface contracts to a trailing compact button for the selected icon. It does not leave the screen or change `currentIndex`. A collapse requested during a destination drag waits until the drag ends. While the shape is moving or compact, hits follow the visible glass and hidden destinations leave the semantics tree. Tapping the compact button expands the bar without a selection callback. Reduced motion jumps to the target shape. Classic, enhanced, and refractive materials share that morph.
* While `enableScrollCollapse` is false, a controller whose target is collapsed is ignored and the bar stays expanded.

## 1.1.0

* Adds `enableDragSelection`. It defaults to false, so 1.0.0 callers stay tap-only.
* When dragging is enabled, a horizontal drag from the selected destination moves the liquid indicator. `onIndexChanged` runs once on release over a different destination. Gaps and misses spring back. `currentIndex` stays parent-owned.
* Dragging respects RTL slot geometry, reduced motion, haptic settings, and both indicator styles. Pointer movement repaints the indicator and does not rebuild the items.
* The selection capsule wraps the visible icon and label, plus `indicatorInset` (default 14 by 3). `hidden` draws no label and does not reserve one under the icon. Its selected capsule keeps the labeled size for that destination, and the icon is centered in the capsule and in the glass. A badge does not change those bounds. A short bar reduces the vertical margin so the content still fits.
* At the first and last destinations, the gap from the capsule to the glass is the same on the top, the bottom, and the outer side. The default glass padding is 6 on every side. The default glass height is 58. The default `maxWidth` is 520, so a phone uses the width left after the margin and a wider parent stops at 520. Pass `double.infinity` for a full-width bar. A slot that is too narrow to hold the inset keeps the capsule inside the slot and centered on the icon and label. The outer gap then yields to that center.
* The default elevation is 0. The glass rim is one stroke, lighter on the top edge than on the bottom. Set `elevation` to opt into a shadow.
* A drag preview follows the finger continuously. Stretch grows both sides of the grabbed center. The droplet eases through a plain pill when the finger slows or reverses, then points in the new direction. Width eases between destination capsules instead of stepping at slot edges.
* A count badge sits above the icon's trailing corner. A dot sits below that corner. `badgeOffset` defaults to zero and shifts either badge: positive x moves outward, positive y moves down.
* `always` keeps every icon on one vertical line. `hidden` centers every icon in a capsule that matches the labeled size. `selected` centers unselected icons and raises the selected icon so its label fits under it; that icon-plus-label group stays centered in the capsule. The raise and the label fade follow the selection spring, including reduced motion. The example opens on `always`.
* Indicator frames do not emit `onIndexChanged`. The bar owns one animation controller, and each selected-only label slot listens only while it is attached. Each paint measures destination content once; that measurement is not reused on the next paint.
* The README preview images were recaptured from the example on an iPhone 18 Pro Max simulator. The GIF is a recording of programmatic selection, not a finger drag.

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
