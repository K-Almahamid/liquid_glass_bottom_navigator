## 0.1.0

* Initial implementation of a controlled liquid-glass bottom navigation bar.
* Adds equal and intrinsic item layout, optional labels, custom item children, badges, haptics, light and dark themes, RTL, and reduced-motion behavior.
* The selection indicator moves with a spring. `slidingPill` keeps a rigid capsule. `morphingPill` stretches it while it travels. The glass effect is a clipped backdrop blur, not optical refraction.
* Style colors override the resolved theme. A destination needs an icon or a child. `LiquidGlassBadge.child` overlays custom badge content. The bar accepts a `semanticsLabel`.
* The backdrop blur is clipped to the bar and samples content behind it. The item row, not the whole bar, is the repaint boundary. A direction change drops an in-flight indicator origin.
* The glass is a clipped backdrop blur plus a neutral tint. It does not paint a top sheen or a second blur, and it does not refract the page.
* `morphingPill` stretches into a liquid bubble while it travels: the leading end moves ahead and the trailing end narrows, then it settles into a pill. `slidingPill` stays rigid.
