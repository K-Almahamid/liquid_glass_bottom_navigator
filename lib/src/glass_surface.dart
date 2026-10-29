import 'dart:ui';

import 'package:flutter/widgets.dart';

import 'style.dart';
import 'theme.dart';

/// Frosted surface: one optional backdrop blur, a translucent tint, and a
/// hairline border.
///
/// The blur is clipped to [borderRadius]. Sigma `0` skips [BackdropFilter]
/// and leaves the tint. The item row sits in its own [RepaintBoundary] inside
/// the filter, so the filter still samples the page and indicator frames stay
/// inside that row. [BackdropFilter] softens the backdrop. It does not
/// displace pixels the way optical refraction would.
class GlassSurface extends StatelessWidget {
  /// Creates a glass surface around [child].
  const GlassSurface({
    required this.style,
    required this.theme,
    required this.borderRadius,
    required this.child,
    super.key,
  });

  /// Dimensions, blur, and shadow.
  final LiquidGlassNavigationStyle style;

  /// Resolved colors.
  final LiquidGlassNavigationTheme theme;

  /// Radius already resolved for the current direction.
  final BorderRadius borderRadius;

  /// Item layout painted inside the glass.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final blurredChild = _surface(child);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: style.effectiveShadowBlur <= 0
            ? const <BoxShadow>[]
            : <BoxShadow>[
                BoxShadow(
                  color: theme.shadowColor,
                  blurRadius: style.effectiveShadowBlur,
                  offset: style.effectiveShadowOffset,
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: style.blurSigma <= 0
            ? blurredChild
            : BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: style.blurSigma,
                  sigmaY: style.blurSigma,
                ),
                child: blurredChild,
              ),
      ),
    );
  }

  Widget _surface(Widget child) {
    return Stack(
      children: <Widget>[
        Positioned.fill(child: ColoredBox(color: theme.resolvedGlassTint)),
        RepaintBoundary(child: child),
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: borderRadius,
                border: style.borderWidth <= 0
                    ? null
                    : Border.all(
                        color: theme.borderColor,
                        width: style.borderWidth,
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
