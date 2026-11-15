import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:liquid_glass_bottom_navigator/liquid_glass_bottom_navigator.dart';

import 'appearance_sheet.dart';
import 'destination_pages.dart';
import 'gallery_controls.dart';
import 'gallery_theme.dart';

void main() {
  runApp(const LiquidGlassExampleApp());
}

/// Gallery for the local liquid-glass bar.
class LiquidGlassExampleApp extends StatefulWidget {
  /// Creates the example app.
  const LiquidGlassExampleApp({super.key});

  @override
  State<LiquidGlassExampleApp> createState() => _LiquidGlassExampleAppState();
}

class _DestinationSpec {
  const _DestinationSpec(this.title, this.icon);

  final String title;
  final IconData icon;
}

class _LiquidGlassExampleAppState extends State<LiquidGlassExampleApp> {
  static const _destinations = <_DestinationSpec>[
    _DestinationSpec('Home', Icons.home_rounded),
    _DestinationSpec('Search', Icons.search_rounded),
    _DestinationSpec('Inbox', Icons.inbox_outlined),
    _DestinationSpec('Saved', Icons.bookmark_outline_rounded),
    _DestinationSpec('Profile', Icons.person_outline_rounded),
  ];

  static const _capture = bool.fromEnvironment('CAPTURE');
  static const _captureAutoHide = bool.fromEnvironment('CAPTURE_AUTOHIDE');
  static const _glassCapture = String.fromEnvironment('GLASS_CAPTURE');

  int _index = 0;
  ExampleControls _controls = switch (_glassCapture) {
    'classic' => const ExampleControls(backdrop: GalleryBackdrop.pattern),
    'enhanced' => const ExampleControls(
      glassMode: LiquidGlassRenderMode.enhanced,
      backdrop: GalleryBackdrop.pattern,
    ),
    'refractive' => const ExampleControls(
      glassMode: LiquidGlassRenderMode.refractive,
      backdrop: GalleryBackdrop.pattern,
    ),
    _ => const ExampleControls(),
  };
  final LiquidGlassCollapseController _collapse =
      LiquidGlassCollapseController();

  @override
  void dispose() {
    _collapse.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (_captureAutoHide) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _captureAutoHideTour();
      });
    } else if (_glassCapture == 'tour') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _captureGlassTour();
      });
    } else if (_capture) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _captureTour();
      });
    }
  }

  /// Settled stills, then a short programmatic morph. Used only with
  /// `--dart-define=CAPTURE=true`. It does not run in a normal gallery launch.
  Future<void> _captureTour() async {
    const light = ExampleControls(themeMode: ThemeMode.light);
    Future<void> still(String name, ExampleControls controls, int index) async {
      setState(() {
        _controls = controls;
        _index = index;
      });
      await Future<void>.delayed(const Duration(milliseconds: 1700));
      debugPrint('CAPTURE $name');
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }

    await still('light-always-inbox', light, 2);
    await still(
      'dark-always-inbox',
      light.copyWith(themeMode: ThemeMode.dark),
      2,
    );
    await still(
      'light-hidden-home',
      light.copyWith(labelMode: LiquidGlassLabelMode.hidden),
      0,
    );
    await still(
      'light-selected-inbox',
      light.copyWith(labelMode: LiquidGlassLabelMode.selected),
      2,
    );
    await still(
      'dark-selected-profile',
      light.copyWith(
        themeMode: ThemeMode.dark,
        labelMode: LiquidGlassLabelMode.selected,
      ),
      4,
    );

    setState(() {
      _controls = light.copyWith(
        indicatorStyle: LiquidGlassIndicatorStyle.morphingPill,
      );
      _index = 0;
    });
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    debugPrint('CAPTURE gif-start');
    for (final index in <int>[2, 4, 0, 2]) {
      await Future<void>.delayed(const Duration(milliseconds: 900));
      setState(() => _index = index);
    }
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    debugPrint('CAPTURE gif-end');
  }

  /// Morph stills driven by the collapse controller.
  ///
  /// Used only with `--dart-define=CAPTURE_AUTOHIDE=true`. These frames are
  /// the same animation a scroll would start. They are not a finger scroll.
  Future<void> _captureAutoHideTour() async {
    const light = ExampleControls(
      themeMode: ThemeMode.light,
      scrollCollapse: true,
    );
    Future<void> show(
      String name,
      ExampleControls controls,
      int index, {
      bool? collapsed,
    }) async {
      setState(() {
        _controls = controls;
        _index = index;
      });
      if (collapsed == true) {
        _collapse.collapse();
      } else if (collapsed == false) {
        _collapse.expand();
      }
      await Future<void>.delayed(const Duration(milliseconds: 400));
      debugPrint('CAPTURE $name');
      await Future<void>.delayed(const Duration(milliseconds: 1800));
    }

    await show('collapse-expanded', light, 0, collapsed: false);
    try {
      timeDilation = 12;
      _collapse.collapse();
      await Future<void>.delayed(const Duration(milliseconds: 700));
      debugPrint('CAPTURE collapse-early');
      await Future<void>.delayed(const Duration(milliseconds: 1400));
      debugPrint('CAPTURE collapse-mid');
      await Future<void>.delayed(const Duration(milliseconds: 1800));
      timeDilation = 1;
      await Future<void>.delayed(const Duration(milliseconds: 500));
      debugPrint('CAPTURE collapse-compact');
      await Future<void>.delayed(const Duration(milliseconds: 1800));
      timeDilation = 10;
      _collapse.expand();
      await Future<void>.delayed(const Duration(milliseconds: 800));
      _collapse.collapse();
      await Future<void>.delayed(const Duration(milliseconds: 900));
      debugPrint('CAPTURE collapse-reversal');
      await Future<void>.delayed(const Duration(milliseconds: 1800));
      timeDilation = 1;
      await Future<void>.delayed(const Duration(milliseconds: 400));
      setState(() => _index = 2);
      await Future<void>.delayed(const Duration(milliseconds: 400));
      debugPrint('CAPTURE collapse-inbox');
      await Future<void>.delayed(const Duration(milliseconds: 1800));
      timeDilation = 12;
      _collapse.expand();
      await Future<void>.delayed(const Duration(milliseconds: 700));
      debugPrint('CAPTURE collapse-early-expand');
      await Future<void>.delayed(const Duration(milliseconds: 1600));
      debugPrint('CAPTURE collapse-mid-expand');
      await Future<void>.delayed(const Duration(milliseconds: 1800));
      timeDilation = 1;
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await show('collapse-restored', light, 2, collapsed: false);
      await show(
        'collapse-dark',
        light.copyWith(themeMode: ThemeMode.dark),
        0,
        collapsed: true,
      );
      await show(
        'collapse-refractive',
        light.copyWith(glassMode: LiquidGlassRenderMode.refractive),
        0,
        collapsed: true,
      );
      await show(
        'collapse-icons',
        light.copyWith(labelMode: LiquidGlassLabelMode.hidden),
        0,
        collapsed: false,
      );
      await show(
        'collapse-selected',
        light.copyWith(labelMode: LiquidGlassLabelMode.selected),
        2,
        collapsed: false,
      );
      await show('collapse-rtl', light.copyWith(rtl: true), 0, collapsed: true);
      debugPrint('CAPTURE collapse-done');
    } finally {
      timeDilation = 1;
    }
  }

  /// Still comparison of the three glass modes. Used only with
  /// `--dart-define=GLASS_CAPTURE=tour`.
  Future<void> _captureGlassTour() async {
    debugPrint('CAPTURE shader-filter ${ImageFilter.isShaderFilterSupported}');
    const pattern = GalleryBackdrop.pattern;
    Future<void> still(String name, ExampleControls controls) async {
      setState(() => _controls = controls);
      await Future<void>.delayed(const Duration(milliseconds: 1600));
      debugPrint('CAPTURE $name');
      await Future<void>.delayed(const Duration(milliseconds: 400));
    }

    await still(
      'glass-classic-pattern',
      const ExampleControls(backdrop: pattern),
    );
    await still(
      'glass-enhanced-pattern',
      const ExampleControls(
        glassMode: LiquidGlassRenderMode.enhanced,
        backdrop: pattern,
      ),
    );
    await still(
      'glass-refractive-pattern',
      const ExampleControls(
        glassMode: LiquidGlassRenderMode.refractive,
        backdrop: pattern,
      ),
    );
    await still(
      'glass-refractive-clear',
      const ExampleControls(
        glassMode: LiquidGlassRenderMode.refractive,
        glassVariant: LiquidGlassMaterialVariant.clear,
        backdrop: pattern,
      ),
    );
    await still(
      'glass-refractive-gradient',
      const ExampleControls(
        glassMode: LiquidGlassRenderMode.refractive,
        backdrop: GalleryBackdrop.gradient,
      ),
    );
    await still(
      'glass-refractive-ink',
      const ExampleControls(
        glassMode: LiquidGlassRenderMode.refractive,
        backdrop: GalleryBackdrop.dark,
      ),
    );
    debugPrint('CAPTURE glass-done');
  }

  void _select(int index) {
    _collapse.expand();
    setState(() => _index = index);
  }

  void _apply(ExampleControls next) {
    if (!next.scrollCollapse) {
      _collapse.expand();
    }
    setState(() {
      _controls = next;
      if (_index >= next.itemCount) {
        _index = next.itemCount - 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: _controls.themeMode,
      theme: GalleryTheme.light(),
      darkTheme: GalleryTheme.dark(),
      home: Builder(
        builder: (context) {
          return MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(disableAnimations: _controls.reducedMotion),
            child: Directionality(
              textDirection: _controls.rtl
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: _GalleryShell(
                index: _index,
                controls: _controls,
                readControls: () => _controls,
                onSelect: _select,
                onApply: _apply,
                visibility: _collapse,
                items: _items(context),
              ),
            ),
          );
        },
      ),
    );
  }

  List<LiquidGlassNavigationItem> _items(BuildContext context) {
    final colors = GalleryColors.of(context);
    return [
      for (final destination in _destinations.take(_controls.itemCount))
        if (destination.title == 'Profile')
          LiquidGlassNavigationItem(
            label: _controls.includeLabels ? destination.title : null,
            semanticLabel: destination.title,
            child: CircleAvatar(
              radius: 14,
              backgroundColor: colors.accent,
              child: Text(
                'K',
                style: TextStyle(
                  color: colors.onAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          )
        else
          LiquidGlassNavigationItem(
            icon: destination.icon,
            label: _controls.includeLabels ? destination.title : null,
            semanticLabel: destination.title,
            badge: switch (destination.title) {
              'Inbox' => const LiquidGlassBadge.count(4),
              'Saved' => const LiquidGlassBadge.dot(),
              _ => null,
            },
          ),
    ];
  }
}

class _GalleryShell extends StatelessWidget {
  const _GalleryShell({
    required this.index,
    required this.controls,
    required this.readControls,
    required this.onSelect,
    required this.onApply,
    required this.visibility,
    required this.items,
  });

  final int index;
  final ExampleControls controls;
  final ExampleControls Function() readControls;
  final ValueChanged<int> onSelect;
  final ValueChanged<ExampleControls> onApply;
  final LiquidGlassCollapseController visibility;
  final List<LiquidGlassNavigationItem> items;

  @override
  Widget build(BuildContext context) {
    final colors = GalleryColors.of(context);
    final inset = _bottomInset(context);
    return Scaffold(
      backgroundColor: colors.canvas,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          if (controls.backdrop != GalleryBackdrop.page)
            Positioned.fill(child: _GalleryBackdrop(kind: controls.backdrop)),
          // Kept alive so each destination holds its own scroll offset.
          IndexedStack(
            index: index,
            sizing: StackFit.expand,
            children: [
              _observed(
                0,
                HomeDestination(
                  bottomInset: inset,
                  active: index == 0,
                  dragEnabled: controls.dragSelection,
                ),
              ),
              _observed(
                1,
                SearchDestination(bottomInset: inset, active: index == 1),
              ),
              _observed(
                2,
                InboxDestination(bottomInset: inset, active: index == 2),
              ),
              _observed(
                3,
                SavedDestination(
                  key: const ValueKey('saved-page'),
                  bottomInset: inset,
                  active: index == 3,
                ),
              ),
              _observed(
                4,
                ProfileDestination(bottomInset: inset, active: index == 4),
              ),
            ],
          ),
          PositionedDirectional(
            top: 0,
            end: 0,
            child: SafeArea(
              bottom: false,
              left: false,
              right: false,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(top: 4, end: 8),
                child: Material(
                  color: colors.card.withValues(alpha: 0.94),
                  shape: CircleBorder(side: BorderSide(color: colors.hairline)),
                  clipBehavior: Clip.antiAlias,
                  child: IconButton(
                    tooltip: 'Open appearance controls',
                    onPressed: () => showAppearanceSheet(
                      context: context,
                      controls: readControls,
                      onChanged: onApply,
                    ),
                    color: colors.ink,
                    icon: const Icon(Icons.tune_rounded),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: LiquidGlassNavigationBar(
              currentIndex: index,
              onIndexChanged: onSelect,
              semanticsLabel: 'Main',
              labelMode: controls.labelMode,
              indicatorStyle: controls.indicatorStyle,
              motion: controls.motion.value,
              hapticsEnabled: controls.haptics,
              enableDragSelection: controls.dragSelection,
              enableScrollCollapse: controls.scrollCollapse,
              collapseController: visibility,
              material: controls.material,
              items: items,
              style: LiquidGlassNavigationStyle(
                blurSigma: controls.blur,
                height: controls.height,
                width: controls.compactWidth ? 280 : null,
                margin: EdgeInsets.fromLTRB(
                  controls.margin,
                  0,
                  controls.margin,
                  12,
                ),
                padding: EdgeInsets.all(controls.padding),
                itemSpacing: controls.itemSpacing,
                itemLayout: controls.equalSlots
                    ? LiquidGlassItemLayout.equal
                    : LiquidGlassItemLayout.intrinsic,
                respectSafeArea: controls.respectSafeArea,
                borderRadius: BorderRadius.circular(controls.radius),
                indicatorRadius: BorderRadius.circular(
                  (controls.radius - 8).clamp(8, 40).toDouble(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _observed(int page, Widget child) {
    if (!controls.scrollCollapse) {
      return child;
    }
    return LiquidGlassScrollObserver(
      controller: visibility,
      enabled: index == page,
      child: child,
    );
  }

  double _bottomInset(BuildContext context) {
    final scaled = MediaQuery.textScalerOf(context).scale(controls.height);
    final safe = controls.respectSafeArea
        ? MediaQuery.paddingOf(context).bottom
        : 0.0;
    return scaled + 12 + safe + 28;
  }
}

class _GalleryBackdrop extends StatelessWidget {
  const _GalleryBackdrop({required this.kind});

  final GalleryBackdrop kind;

  @override
  Widget build(BuildContext context) {
    return switch (kind) {
      GalleryBackdrop.page => const SizedBox.shrink(),
      GalleryBackdrop.light => const ColoredBox(color: Color(0xFFF4F7F6)),
      GalleryBackdrop.dark => const ColoredBox(color: Color(0xFF12171C)),
      GalleryBackdrop.gradient => const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFFD7E7E2), Color(0xFFE7D7C4)],
          ),
        ),
      ),
      GalleryBackdrop.saturated => const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[Color(0xFF1F4D8F), Color(0xFFC4493A)],
          ),
        ),
      ),
      GalleryBackdrop.pattern => const CustomPaint(painter: _PatternPainter()),
    };
  }
}

class _PatternPainter extends CustomPainter {
  const _PatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFE7EEEA),
    );
    final paint = Paint()..color = const Color(0xFF2F6F62);
    for (var i = 0; i < 8; i++) {
      canvas.drawCircle(
        Offset(size.width * (0.15 + (i % 4) * 0.22), 80.0 + i * 70),
        28,
        paint
          ..color = Color.lerp(
            const Color(0xFF2F6F62),
            const Color(0xFFC46A3A),
            i / 7,
          )!,
      );
    }
    final text = TextPainter(
      text: const TextSpan(
        text: 'behind the glass',
        style: TextStyle(
          color: Color(0xFF1C2A28),
          fontSize: 28,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    text.paint(canvas, Offset(24, size.height - 120));
  }

  @override
  bool shouldRepaint(covariant _PatternPainter oldDelegate) => false;
}
