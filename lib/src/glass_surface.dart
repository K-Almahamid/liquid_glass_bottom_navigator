import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/widgets.dart';

import 'style.dart';
import 'theme.dart';

/// Frosted surface: one optional backdrop blur, a translucent tint, and a
/// soft glass rim.
///
/// The rim is one stroke. Its top edge is lighter than its bottom edge, so
/// the surface reads as glass rather than a uniform outline. There is no
/// second blur and no drop shadow unless [LiquidGlassNavigationStyle.elevation]
/// is set.
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
        if (style.borderWidth > 0)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _GlassRimPainter(
                  borderRadius: borderRadius,
                  color: theme.borderColor,
                  width: style.borderWidth,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// One stroke whose highlight sits on the top edge and fades toward the bottom.
class _GlassRimPainter extends CustomPainter {
  const _GlassRimPainter({
    required this.borderRadius,
    required this.color,
    required this.width,
  });

  final BorderRadius borderRadius;
  final Color color;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    if (width <= 0 || size.isEmpty) {
      return;
    }
    final rect = Offset.zero & size;
    final deflated = width / 2;
    final rrect = borderRadius.toRRect(rect).deflate(deflated);
    if (rrect.width <= 0 || rrect.height <= 0) {
      return;
    }
    final topAlpha = math.max(color.a, 0.38);
    final bottomAlpha = math.min(color.a, 0.14);
    final top = Color.lerp(
      color,
      const Color(0xFFFFFFFF),
      0.78,
    )!.withValues(alpha: topAlpha);
    final middle = color.withValues(alpha: (topAlpha + bottomAlpha) / 2);
    final bottom = color.withValues(alpha: bottomAlpha);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[top, middle, bottom],
        stops: const <double>[0, 0.42, 1],
      ).createShader(rect);
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(_GlassRimPainter oldDelegate) {
    return oldDelegate.borderRadius != borderRadius ||
        oldDelegate.color != color ||
        oldDelegate.width != width;
  }
}
