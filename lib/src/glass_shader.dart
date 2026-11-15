import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'material.dart';
import 'style.dart';
import 'theme.dart';

/// Mutable radii for a live refraction shader.
///
/// The navigation morph changes corner radii every paint without rebuilding
/// the filter. [applyRadius] writes those uniforms on the shader the filter
/// already holds.
class GlassFilterControls {
  ui.FragmentShader? _shader;
  double _devicePixelRatio = 1;

  /// Records the shader and the pixel ratio used to build [filter].
  void bind(ui.FragmentShader shader, double devicePixelRatio) {
    _shader = shader;
    _devicePixelRatio = devicePixelRatio;
  }

  /// Writes [radius] in physical pixels. No-op before the shader exists.
  void applyRadius(BorderRadius radius) {
    final shader = _shader;
    if (shader == null) {
      return;
    }
    final dpr = _devicePixelRatio;
    shader
      ..setFloat(2, radius.topLeft.x * dpr)
      ..setFloat(3, radius.topRight.x * dpr)
      ..setFloat(4, radius.bottomRight.x * dpr)
      ..setFloat(5, radius.bottomLeft.x * dpr);
  }
}

/// Loads the refraction program once and builds a backdrop [ui.ImageFilter].
///
/// The first vec2 and the sampler are filled by the engine. Floats starting
/// at index 2 are the corner radii and the material controls. A failed load
/// or a backend without shader filters leaves [filter] null so the bar can
/// paint the enhanced fallback.
class RefractiveGlassFilter extends StatefulWidget {
  /// Creates a loader for [material] over a surface of [borderRadius].
  const RefractiveGlassFilter({
    required this.material,
    required this.style,
    required this.theme,
    required this.borderRadius,
    required this.builder,
    this.controls,
    super.key,
  });

  /// Requested refractive settings.
  final LiquidGlassMaterial material;

  /// Blur sigma. Refractive uses only a small soften after the shader.
  final LiquidGlassNavigationStyle style;

  /// Tint mixed inside the shader.
  final LiquidGlassNavigationTheme theme;

  /// Corner radii in logical pixels.
  final BorderRadius borderRadius;

  /// Receives the composed filter, or null while loading or unsupported.
  final Widget Function(BuildContext context, ui.ImageFilter? filter) builder;

  /// Optional live uniform target. The morph updates radii during paint.
  final GlassFilterControls? controls;

  /// Package asset path used by applications that depend on this package.
  static const asset =
      'packages/liquid_glass_bottom_navigator/shaders/liquid_glass_refraction.frag';

  /// Path used when this package is the root bundle, including its own tests.
  static const localAsset = 'shaders/liquid_glass_refraction.frag';

  /// Program shared by every glass surface. Null until the first load.
  static ui.FragmentProgram? program;

  /// Set when [program] cannot be loaded. Later surfaces skip the request.
  static Object? loadError;

  static Future<void>? _loading;

  /// Starts the program load if it has not already finished or failed.
  static Future<void> ensureLoaded() {
    if (program != null || loadError != null) {
      return Future<void>.value();
    }
    _loading ??= () async {
      try {
        program = await ui.FragmentProgram.fromAsset(asset);
      } catch (error) {
        if ('$error'.contains('not found')) {
          try {
            program = await ui.FragmentProgram.fromAsset(localAsset);
            return;
          } catch (localError) {
            loadError = localError;
            debugPrint('Liquid glass shader failed: $localError');
            return;
          }
        }
        loadError = error;
        debugPrint('Liquid glass shader failed: $error');
      }
    }();
    return _loading!;
  }

  @override
  State<RefractiveGlassFilter> createState() => _RefractiveGlassFilterState();
}

/// Logical pixels of backdrop kept around the painted glass.
///
/// The shader reads this margin and discards it, so the bar's layout size
/// does not change. Classic glass does not use it.
const double refractiveLensMargin = 18;

/// Outward normal of a rounded rectangle.
///
/// Y grows downward, so the top edge is `(0, -1)` and the bottom edge is
/// `(0, 1)`. This matches [surface_normal] in the refraction shader.
@visibleForTesting
Offset refractiveSurfaceNormal(Offset pixel, Size size, double radius) {
  double box(Offset point) {
    final limit = math.min(size.width, size.height) / 2;
    final r = radius.clamp(0.0, limit);
    final half = Offset(size.width / 2, size.height / 2);
    final q = Offset(
      point.dx.abs() - half.dx + r,
      point.dy.abs() - half.dy + r,
    );
    final outside = Offset(math.max(q.dx, 0), math.max(q.dy, 0));
    return math.min(math.max(q.dx, q.dy), 0) + outside.distance - r;
  }

  final point = pixel - Offset(size.width / 2, size.height / 2);
  const delta = 1.0;
  final dx =
      box(point + const Offset(delta, 0)) - box(point - const Offset(delta, 0));
  final dy =
      box(point + const Offset(0, delta)) - box(point - const Offset(0, delta));
  final len = math.sqrt(dx * dx + dy * dy);
  if (len < 0.0001) {
    return const Offset(0, -1);
  }
  return Offset(dx / len, dy / len);
}

/// Blur applied after the refractive shader.
///
/// Interior diffusion lives in the shader, so a second blur would soften the
/// rim. The parameter remains so callers can pass the style sigma. Classic
/// glass does not use this function.
@visibleForTesting
double refractiveSoftenSigma(double blurSigma) {
  if (blurSigma.isNaN) {
    return 0;
  }
  return 0;
}

class _RefractiveGlassFilterState extends State<RefractiveGlassFilter> {
  ui.FragmentShader? _shader;
  ui.ImageFilter? _cached;
  String? _cacheKey;
  static bool _reported = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!ui.ImageFilter.isShaderFilterSupported) {
      return;
    }
    await RefractiveGlassFilter.ensureLoaded();
    if (!mounted || RefractiveGlassFilter.program == null) {
      return;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _shader?.dispose();
    super.dispose();
  }

  ui.ImageFilter? _filter() {
    final program = RefractiveGlassFilter.program;
    if (!ui.ImageFilter.isShaderFilterSupported || program == null) {
      // The first frame runs before the asset load finishes. Only report
      // a fallback after that load has actually failed.
      final failed =
          !ui.ImageFilter.isShaderFilterSupported ||
          RefractiveGlassFilter.loadError != null;
      if (failed && !_reported && !kReleaseMode) {
        _reported = true;
        debugPrint(
          'Liquid glass refractive fallback. '
          'shaderFilter=${ui.ImageFilter.isShaderFilterSupported} '
          'error=${RefractiveGlassFilter.loadError}',
        );
      }
      return null;
    }
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final radius = widget.borderRadius;
    final tint = widget.theme.resolvedGlassTint;
    final material = widget.material;
    final key =
        '${radius.topLeft.x}:${radius.topRight.x}:'
        '${radius.bottomRight.x}:${radius.bottomLeft.x}:'
        '${material.refractionStrength}:${material.edgeThickness}:'
        '${material.highlightIntensity}:${material.variant}:'
        '${material.adaptiveTint}:${tint.r},${tint.g},${tint.b},${tint.a}:'
        '${widget.style.blurSigma}:$dpr:$refractiveLensMargin';
    if (_cached != null && _cacheKey == key) {
      return _cached;
    }
    _shader?.dispose();
    final shader = program.fragmentShader();
    _shader = shader;
    shader
      ..setFloat(2, radius.topLeft.x * dpr)
      ..setFloat(3, radius.topRight.x * dpr)
      ..setFloat(4, radius.bottomRight.x * dpr)
      ..setFloat(5, radius.bottomLeft.x * dpr)
      ..setFloat(6, material.refractionStrength)
      ..setFloat(7, material.edgeThickness)
      ..setFloat(8, material.highlightIntensity)
      ..setFloat(9, tint.r)
      ..setFloat(10, tint.g)
      ..setFloat(11, tint.b)
      ..setFloat(12, tint.a)
      ..setFloat(
        13,
        material.variant == LiquidGlassMaterialVariant.clear ? 1 : 0,
      )
      ..setFloat(14, material.adaptiveTint ? 1 : 0)
      ..setFloat(15, 0.2)
      ..setFloat(16, -1)
      ..setFloat(17, refractiveLensMargin * dpr);
    final ui.ImageFilter filtered;
    try {
      filtered = ui.ImageFilter.shader(shader);
    } catch (error) {
      debugPrint('Liquid glass refractive fallback: $error');
      _shader?.dispose();
      _shader = null;
      return null;
    }
    if (!_reported && !kReleaseMode) {
      _reported = true;
      debugPrint(
        'Liquid glass refractive shader active. '
        'refraction=${material.refractionStrength} '
        'edge=${material.edgeThickness} '
        'highlight=${material.highlightIntensity} '
        'variant=${material.variant.name}',
      );
    }
    // The shader diffuses its own interior. A blur around it would wash
    // the rim. Classic still blurs on its own path.
    final soften = refractiveSoftenSigma(widget.style.blurSigma);
    final filter = soften < 0.2
        ? filtered
        : ui.ImageFilter.compose(
            outer: ui.ImageFilter.blur(sigmaX: soften, sigmaY: soften),
            inner: filtered,
          );
    _cacheKey = key;
    _cached = filter;
    widget.controls?.bind(shader, dpr);
    return filter;
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _filter());
  }
}
