import 'dart:async';

import 'package:flutter/material.dart';
import 'package:liquid_glass_bottom_navigator/liquid_glass_bottom_navigator.dart';

/// Fixed scrolling scene used to compare blur costs.
///
/// The feed does not change when the selection changes, so a sigma 0 run and a
/// sigma 18 run do the same scroll and the same index switches. This widget is
/// not part of the package public API.
class BlurProfileWorkload extends StatefulWidget {
  /// Creates a workload that runs for [warmup] plus [recorded].
  const BlurProfileWorkload({
    required this.blurSigma,
    required this.includeBar,
    required this.onRecordStart,
    required this.onFinished,
    this.warmup = const Duration(seconds: 2),
    this.recorded = const Duration(seconds: 10),
    super.key,
  });

  /// Backdrop sigma. Ignored when [includeBar] is false.
  final double blurSigma;

  /// Whether the navigation bar is in the scene.
  final bool includeBar;

  /// Frames before this are warmup and should not be recorded.
  final Duration warmup;

  /// Recorded portion. The same scroll and switches continue through it.
  final Duration recorded;

  /// Called once when the recorded window starts.
  final VoidCallback onRecordStart;

  /// Called once when the recorded window ends. The argument is how many
  /// selection changes happened during that window.
  final ValueChanged<int> onFinished;

  @override
  State<BlurProfileWorkload> createState() => _BlurProfileWorkloadState();
}

class _BlurProfileWorkloadState extends State<BlurProfileWorkload> {
  final ScrollController _scroll = ScrollController();
  Timer? _switchTimer;
  Timer? _recordTimer;
  Timer? _doneTimer;
  int _index = 0;
  int _recordedSwitches = 0;
  bool _recording = false;
  bool _alive = true;

  static const _items = <LiquidGlassNavigationItem>[
    LiquidGlassNavigationItem(icon: Icons.home_rounded, label: 'Home'),
    LiquidGlassNavigationItem(icon: Icons.search_rounded, label: 'Search'),
    LiquidGlassNavigationItem(
      icon: Icons.inbox_outlined,
      label: 'Inbox',
      badge: LiquidGlassBadge.count(4),
    ),
    LiquidGlassNavigationItem(
      icon: Icons.bookmark_outline_rounded,
      label: 'Saved',
      badge: LiquidGlassBadge.dot(),
    ),
    LiquidGlassNavigationItem(
      icon: Icons.person_outline_rounded,
      label: 'Profile',
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_alive) {
        unawaited(_loopScroll());
      }
    });
    if (widget.includeBar) {
      _switchTimer = Timer.periodic(const Duration(milliseconds: 400), (_) {
        if (!mounted) {
          return;
        }
        setState(() => _index = _index == 0 ? 4 : 0);
        if (_recording) {
          _recordedSwitches += 1;
        }
      });
    }
    _recordTimer = Timer(widget.warmup, () {
      _recording = true;
      widget.onRecordStart();
    });
    _doneTimer = Timer(widget.warmup + widget.recorded, () {
      _recording = false;
      widget.onFinished(_recordedSwitches);
    });
  }

  Future<void> _loopScroll() async {
    while (_alive && mounted) {
      if (!_scroll.hasClients || !_scroll.position.hasContentDimensions) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        continue;
      }
      final max = _scroll.position.maxScrollExtent;
      if (max <= 0) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        continue;
      }
      try {
        await _scroll.animateTo(
          max,
          duration: const Duration(seconds: 4),
          curve: Curves.linear,
        );
        if (!_alive || !mounted) {
          return;
        }
        await _scroll.animateTo(
          0,
          duration: const Duration(seconds: 4),
          curve: Curves.linear,
        );
      } on Exception {
        return;
      }
    }
  }

  @override
  void dispose() {
    _alive = false;
    _switchTimer?.cancel();
    _recordTimer?.cancel();
    _doneTimer?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF1F6F6A),
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      home: Scaffold(
        body: Stack(
          children: [
            ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
              itemCount: 40,
              itemBuilder: (context, index) {
                final color = Color.lerp(
                  const Color(0xFF1F6F6A),
                  const Color(0xFF8A3E2F),
                  (index % 8) / 7,
                )!;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  height: 88,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      colors: [color, color.withValues(alpha: 0.45)],
                    ),
                  ),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Note ${index + 1}  ·  detail line for the backdrop',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
            if (widget.includeBar)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: LiquidGlassNavigationBar(
                  key: const Key('profile-bar'),
                  currentIndex: _index,
                  onIndexChanged: (_) {},
                  items: _items,
                  labelMode: LiquidGlassLabelMode.always,
                  indicatorStyle: LiquidGlassIndicatorStyle.morphingPill,
                  hapticsEnabled: false,
                  style: LiquidGlassNavigationStyle(
                    blurSigma: widget.blurSigma,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
