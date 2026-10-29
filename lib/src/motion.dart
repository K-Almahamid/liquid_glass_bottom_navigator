import 'package:flutter/foundation.dart';
import 'package:flutter/physics.dart';

/// Spring and morph settings for the selection indicator.
///
/// Ordinary apps can use a preset ([LiquidGlassMotion.spring],
/// [LiquidGlassMotion.snappy], [LiquidGlassMotion.gentle], or
/// [LiquidGlassMotion.none]) and leave the numeric fields alone.
@immutable
class LiquidGlassMotion {
  /// Creates motion settings.
  ///
  /// [duration] and [bounce] describe the spring used for selection changes.
  /// They match [SpringDescription.withDurationAndBounce]: [duration] is the
  /// perceptual pace, and [bounce] is `0` for no overshoot, between `0` and
  /// `1` for a small settle, and negative for a slower overdamped glide.
  ///
  /// [morphIntensity] controls how far morphing-pill motion stretches while
  /// the indicator travels. `0` keeps a rigid capsule. `1` is the strongest
  /// stretch this package draws. Plain pill motion ignores this value.
  const LiquidGlassMotion({
    this.enabled = true,
    this.duration = const Duration(milliseconds: 480),
    this.bounce = 0.06,
    this.morphIntensity = 0.35,
    this.respectReducedMotion = true,
  }) : assert(morphIntensity >= 0 && morphIntensity <= 1),
       assert(bounce <= 1);

  /// Restrained spring with a slight stretch. This is the default.
  const LiquidGlassMotion.spring() : this();

  /// Faster spring with little stretch.
  const LiquidGlassMotion.snappy()
    : this(
        duration: const Duration(milliseconds: 280),
        bounce: 0,
        morphIntensity: 0.15,
      );

  /// Slower spring with a slightly wider stretch.
  const LiquidGlassMotion.gentle()
    : this(
        duration: const Duration(milliseconds: 640),
        bounce: 0.1,
        morphIntensity: 0.45,
      );

  /// Snap the indicator to the selected item with no interpolation.
  const LiquidGlassMotion.none()
    : this(enabled: false, morphIntensity: 0, bounce: 0);

  /// Whether selection changes interpolate.
  ///
  /// When false, the indicator moves immediately. Reduced motion also skips
  /// interpolation when [respectReducedMotion] is true.
  final bool enabled;

  /// Perceptual spring duration.
  final Duration duration;

  /// Spring bounce forwarded to [SpringDescription.withDurationAndBounce].
  final double bounce;

  /// Stretch amount for morphing-pill motion, from `0` to `1`.
  final double morphIntensity;

  /// Whether [MediaQueryData.disableAnimations] replaces this motion with an
  /// immediate jump.
  final bool respectReducedMotion;

  /// Spring used to drive the indicator from `0` to `1`.
  SpringDescription get spring {
    final motionDuration = duration <= Duration.zero
        ? const Duration(milliseconds: 1)
        : duration;
    return SpringDescription.withDurationAndBounce(
      duration: motionDuration,
      bounce: bounce.clamp(-0.99, 1),
    );
  }

  /// Returns a copy with the given fields replaced.
  LiquidGlassMotion copyWith({
    bool? enabled,
    Duration? duration,
    double? bounce,
    double? morphIntensity,
    bool? respectReducedMotion,
  }) {
    return LiquidGlassMotion(
      enabled: enabled ?? this.enabled,
      duration: duration ?? this.duration,
      bounce: bounce ?? this.bounce,
      morphIntensity: morphIntensity ?? this.morphIntensity,
      respectReducedMotion: respectReducedMotion ?? this.respectReducedMotion,
    );
  }
}
