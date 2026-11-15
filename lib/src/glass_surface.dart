import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/widgets.dart';

import 'material.dart';
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
    this.material = const LiquidGlassMaterial(),
    this.refractiveFilter,
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

  /// Classic, enhanced, or refractive. Classic keeps the 1.1.0 paint.
  final LiquidGlassMaterial material;

  /// Composed backdrop shader. Null uses blur, or the enhanced fallback.
  final ImageFilter? refractiveFilter;

  bool get _classic =>
      material.mode == LiquidGlassRenderMode.classic &&
      refractiveFilter == null;

  @override
  Widget build(BuildContext context) {
    if (_classic) {
      return _classicTree();
    }
    final highContrast = MediaQuery.highContrastOf(context);
    final shader = refractiveFilter;
    final fill = glassFillTint(
      material,
      theme.resolvedGlassTint,
      shaderActive: shader != null,
      highContrast: highContrast,
    );
    final blurredChild = _surface(child, fill: fill, veil: shader == null);
    final filter =
        shader ??
        (style.blurSigma <= 0
            ? null
            : ImageFilter.blur(
                sigmaX: style.blurSigma,
                sigmaY: style.blurSigma,
              ));
    return DecoratedBox(
      decoration: _shadow(),
      child: ClipRRect(
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: filter == null
            ? blurredChild
            : BackdropFilter(filter: filter, child: blurredChild),
      ),
    );
  }

  Widget _classicTree() {
    final blurredChild = _surface(child, fill: theme.resolvedGlassTint);
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

  BoxDecoration _shadow() {
    return BoxDecoration(
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
    );
  }

  Widget _surface(Widget child, {required Color fill, bool veil = false}) {
    return Stack(
      children: <Widget>[
        Positioned.fill(child: ColoredBox(color: fill)),
        if (veil)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: GlassVeilPainter(
                  borderRadius: borderRadius,
                  clear: material.variant == LiquidGlassMaterialVariant.clear,
                ),
              ),
            ),
          ),
        RepaintBoundary(child: child),
        if (style.borderWidth > 0)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: GlassRimPainter(
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

/// Tint used for enhanced glass, and a lighter veil over a live shader.
Color glassFillTint(
  LiquidGlassMaterial material,
  Color resolved, {
  required bool shaderActive,
  required bool highContrast,
}) {
  if (material.mode == LiquidGlassRenderMode.classic && !shaderActive) {
    return resolved;
  }
  var alpha = resolved.a;
  if (material.variant == LiquidGlassMaterialVariant.clear) {
    alpha *= 0.45;
  } else {
    alpha *= 0.82;
  }
  if (shaderActive) {
    // The shader already diffuses the interior. Regular keeps a stronger
    // wash so body text does not stay readable. Clear stays lighter.
    alpha *= material.variant == LiquidGlassMaterialVariant.clear ? 0.14 : 0.62;
  }
  if (highContrast) {
    alpha = math.max(alpha, 0.9);
  }
  return resolved.withValues(alpha: alpha.clamp(0.0, 1.0));
}

/// Theme-driven top light and bottom shade. This does not sample the backdrop.
class GlassVeilPainter extends CustomPainter {
  /// Creates the enhanced veil.
  const GlassVeilPainter({required this.borderRadius, required this.clear});

  final BorderRadius borderRadius;
  final bool clear;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }
    final rect = Offset.zero & size;
    final strength = clear ? 0.45 : 1.0;
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          const Color(0xFFFFFFFF).withValues(alpha: 0.16 * strength),
          const Color(0x00FFFFFF),
          const Color(0xFF000000).withValues(alpha: 0.06 * strength),
        ],
        stops: const <double>[0, 0.46, 1],
      ).createShader(rect);
    canvas.drawRRect(borderRadius.toRRect(rect), paint);
  }

  @override
  bool shouldRepaint(GlassVeilPainter oldDelegate) {
    return oldDelegate.borderRadius != borderRadius ||
        oldDelegate.clear != clear;
  }
}

/// One stroke whose highlight sits on the top edge and fades toward the bottom.
class GlassRimPainter extends CustomPainter {
  /// Creates the glass rim stroke.
  const GlassRimPainter({
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
  bool shouldRepaint(GlassRimPainter oldDelegate) {
    return oldDelegate.borderRadius != borderRadius ||
        oldDelegate.color != color ||
        oldDelegate.width != width;
  }
}
