import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:liquid_glass_bottom_navigator/liquid_glass_bottom_navigator.dart';
import 'package:liquid_glass_bottom_navigator_example/profile_workload.dart';

/// Profile entry point. It is not the gallery and it is not part of the
/// package API.
///
/// From `example/`:
///
/// ```bash
/// flutter run --profile -d macos -t lib/profile_main.dart
/// ```
///
/// Prints one `PROFILE_RESULT` JSON object and exits. iOS profile builds are
/// rejected for the simulator by the Flutter tool, so this target is macOS
/// unless a physical device is chosen explicitly.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _ProfileApp());
}

class _ProfileApp extends StatefulWidget {
  const _ProfileApp();

  @override
  State<_ProfileApp> createState() => _ProfileAppState();
}

class _ProfileAppState extends State<_ProfileApp> {
  static const _budget = Duration(milliseconds: 16);
  final _scenarios = <String, dynamic>{};
  Widget _child = const SizedBox.shrink();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_run());
    });
  }

  Future<void> _run() async {
    if (!kProfileMode) {
      debugPrint(
        'PROFILE_RESULT ${jsonEncode({'error': 'not profile mode', 'mode': kReleaseMode ? 'release' : 'debug'})}',
      );
      exit(1);
    }

    _scenarios['idle_sigma_18'] = await _measure(
      blurSigma: 18,
      includeBar: true,
      animate: false,
      warmup: const Duration(milliseconds: 600),
      recorded: const Duration(seconds: 2),
    );
    _scenarios['scroll_only'] = await _measure(blurSigma: 0, includeBar: false);
    _scenarios['sigma_0'] = await _measure(blurSigma: 0, includeBar: true);
    _scenarios['sigma_18'] = await _measure(blurSigma: 18, includeBar: true);
    _scenarios['slide_sigma_18'] = await _measure(
      blurSigma: 18,
      includeBar: true,
      indicatorStyle: LiquidGlassIndicatorStyle.slidingPill,
      warmup: const Duration(seconds: 1),
      recorded: const Duration(seconds: 4),
    );
    _scenarios['memory_cycles'] = await _memoryCycles();

    final result = <String, dynamic>{
      'mode': 'profile',
      'platform': Platform.operatingSystem,
      'platform_version': Platform.operatingSystemVersion,
      'warmup_seconds': 2,
      'recorded_seconds': 10,
      'flush_wait_seconds': 2,
      'switch_interval_ms': 400,
      'switch_indices': <int>[0, 4],
      'frame_budget_ms': _budget.inMilliseconds,
      'scenarios': _scenarios,
    };
    debugPrint('PROFILE_RESULT ${jsonEncode(result)}');
    exit(0);
  }

  Future<Map<String, dynamic>> _memoryCycles() async {
    final before = ProcessInfo.currentRss;
    const cycles = 80;
    for (var i = 0; i < cycles; i++) {
      final done = Completer<int>();
      setState(() {
        _child = BlurProfileWorkload(
          key: UniqueKey(),
          blurSigma: 18,
          includeBar: true,
          animate: false,
          warmup: const Duration(milliseconds: 16),
          recorded: const Duration(milliseconds: 32),
          onRecordStart: () {},
          onFinished: done.complete,
        );
      });
      await done.future;
      setState(() => _child = const SizedBox.shrink());
      await WidgetsBinding.instance.endOfFrame;
    }
    final after = ProcessInfo.currentRss;
    await Future<void>.delayed(const Duration(seconds: 1));
    return <String, dynamic>{
      'cycles': cycles,
      'rss_bytes_before': before,
      'rss_bytes_after_cycles': after,
      'rss_bytes_after_pause': ProcessInfo.currentRss,
    };
  }

  Future<Map<String, dynamic>> _measure({
    required double blurSigma,
    required bool includeBar,
    bool animate = true,
    Duration warmup = const Duration(seconds: 2),
    Duration recorded = const Duration(seconds: 10),
    LiquidGlassIndicatorStyle indicatorStyle =
        LiquidGlassIndicatorStyle.morphingPill,
  }) async {
    final timings = <FrameTiming>[];
    final done = Completer<int>();
    var recording = false;
    void collect(List<FrameTiming> frames) {
      if (recording) {
        timings.addAll(frames);
      }
    }

    WidgetsBinding.instance.addTimingsCallback(collect);
    final rssBefore = ProcessInfo.currentRss;
    var rssAtRecordStart = rssBefore;
    setState(() {
      _child = BlurProfileWorkload(
        key: UniqueKey(),
        blurSigma: blurSigma,
        includeBar: includeBar,
        animate: animate,
        warmup: warmup,
        recorded: recorded,
        indicatorStyle: indicatorStyle,
        onRecordStart: () {
          recording = true;
          rssAtRecordStart = ProcessInfo.currentRss;
        },
        onFinished: done.complete,
      );
    });
    final switches = await done.future;
    await Future<void>.delayed(const Duration(seconds: 2));
    recording = false;
    WidgetsBinding.instance.removeTimingsCallback(collect);

    return _summarize(
      timings: timings,
      blurSigma: blurSigma,
      includeBar: includeBar,
      switches: switches,
      rssBefore: rssBefore,
      rssAtRecordStart: rssAtRecordStart,
      rssAfter: ProcessInfo.currentRss,
    );
  }

  Map<String, dynamic> _summarize({
    required List<FrameTiming> timings,
    required double blurSigma,
    required bool includeBar,
    required int switches,
    required int rssBefore,
    required int rssAtRecordStart,
    required int rssAfter,
  }) {
    if (timings.isEmpty) {
      return <String, dynamic>{
        'frame_count': 0,
        'blur_sigma': blurSigma,
        'include_bar': includeBar,
        'recorded_selection_changes': switches,
        'rss_bytes_before_warmup': rssBefore,
        'rss_bytes_at_record_start': rssAtRecordStart,
        'rss_bytes_after': rssAfter,
      };
    }
    final build = timings.map((frame) => frame.buildDuration).toList()..sort();
    final raster = timings.map((frame) => frame.rasterDuration).toList()
      ..sort();
    var buildMisses = 0;
    var rasterMisses = 0;
    var combinedMisses = 0;
    for (final frame in timings) {
      if (frame.buildDuration > _budget) {
        buildMisses += 1;
      }
      if (frame.rasterDuration > _budget) {
        rasterMisses += 1;
      }
      if (frame.buildDuration + frame.rasterDuration > _budget) {
        combinedMisses += 1;
      }
    }
    int layerBytes(FrameTiming frame) => frame.layerCacheBytes;
    int pictureBytes(FrameTiming frame) => frame.pictureCacheBytes;
    final layers = timings.map(layerBytes).toList()..sort();
    final pictures = timings.map(pictureBytes).toList()..sort();

    double millis(Duration duration) => duration.inMicroseconds / 1000;
    return <String, dynamic>{
      'blur_sigma': blurSigma,
      'include_bar': includeBar,
      'frame_count': timings.length,
      'recorded_selection_changes': switches,
      'average_frame_build_time_millis': millis(_average(build)),
      'p50_frame_build_time_millis': millis(_percentile(build, 0.50)),
      'p90_frame_build_time_millis': millis(_percentile(build, 0.90)),
      'p99_frame_build_time_millis': millis(_percentile(build, 0.99)),
      'worst_frame_build_time_millis': millis(build.last),
      'missed_frame_build_budget_count': buildMisses,
      'average_frame_rasterizer_time_millis': millis(_average(raster)),
      'p50_frame_rasterizer_time_millis': millis(_percentile(raster, 0.50)),
      'p90_frame_rasterizer_time_millis': millis(_percentile(raster, 0.90)),
      'p99_frame_rasterizer_time_millis': millis(_percentile(raster, 0.99)),
      'worst_frame_rasterizer_time_millis': millis(raster.last),
      'missed_frame_rasterizer_budget_count': rasterMisses,
      'frames_whose_build_plus_raster_exceeded_16ms': combinedMisses,
      'average_layer_cache_bytes':
          layers.reduce((a, b) => a + b) / layers.length,
      'worst_layer_cache_bytes': layers.last,
      'average_picture_cache_bytes':
          pictures.reduce((a, b) => a + b) / pictures.length,
      'worst_picture_cache_bytes': pictures.last,
      'rss_bytes_before_warmup': rssBefore,
      'rss_bytes_at_record_start': rssAtRecordStart,
      'rss_bytes_after': rssAfter,
    };
  }

  Duration _average(List<Duration> sorted) {
    var micros = 0;
    for (final duration in sorted) {
      micros += duration.inMicroseconds;
    }
    return Duration(microseconds: micros ~/ sorted.length);
  }

  Duration _percentile(List<Duration> sorted, double percentile) {
    final index = math.min(
      sorted.length - 1,
      math.max(0, ((sorted.length - 1) * percentile).round()),
    );
    return sorted[index];
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(textDirection: TextDirection.ltr, child: _child);
  }
}
