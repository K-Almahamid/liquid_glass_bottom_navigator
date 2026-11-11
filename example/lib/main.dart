import 'package:flutter/material.dart';
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

  int _index = 0;
  ExampleControls _controls = const ExampleControls();

  void _select(int index) => setState(() => _index = index);

  void _apply(ExampleControls next) {
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
    required this.items,
  });

  final int index;
  final ExampleControls controls;
  final ExampleControls Function() readControls;
  final ValueChanged<int> onSelect;
  final ValueChanged<ExampleControls> onApply;
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
          // Kept alive so each destination holds its own scroll offset.
          IndexedStack(
            index: index,
            sizing: StackFit.expand,
            children: [
              HomeDestination(
                bottomInset: inset,
                active: index == 0,
                dragEnabled: controls.dragSelection,
              ),
              SearchDestination(bottomInset: inset, active: index == 1),
              InboxDestination(bottomInset: inset, active: index == 2),
              SavedDestination(
                key: const ValueKey('saved-page'),
                bottomInset: inset,
                active: index == 3,
              ),
              ProfileDestination(bottomInset: inset, active: index == 4),
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

  double _bottomInset(BuildContext context) {
    final scaled = MediaQuery.textScalerOf(context).scale(controls.height);
    final safe = controls.respectSafeArea
        ? MediaQuery.paddingOf(context).bottom
        : 0.0;
    return scaled + 12 + safe + 28;
  }
}
