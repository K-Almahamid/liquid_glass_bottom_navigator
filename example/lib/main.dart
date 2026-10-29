import 'package:flutter/material.dart';
import 'package:liquid_glass_bottom_navigator/liquid_glass_bottom_navigator.dart';

void main() {
  runApp(const LiquidGlassExampleApp());
}

/// Interactive gallery for the local package.
class LiquidGlassExampleApp extends StatefulWidget {
  /// Creates the example app.
  const LiquidGlassExampleApp({super.key});

  @override
  State<LiquidGlassExampleApp> createState() => _LiquidGlassExampleAppState();
}

class _LiquidGlassExampleAppState extends State<LiquidGlassExampleApp> {
  int _index = 0;
  ThemeMode _themeMode = ThemeMode.system;
  LiquidGlassLabelMode _labelMode = LiquidGlassLabelMode.selected;
  LiquidGlassIndicatorStyle _indicatorStyle =
      LiquidGlassIndicatorStyle.morphingPill;
  LiquidGlassMotion _motion = const LiquidGlassMotion.spring();
  bool _haptics = true;
  bool _reducedMotion = false;
  bool _rtl = false;
  bool _includeLabels = true;
  double _blur = 18;
  double _height = 68;
  double _radius = 32;
  double _margin = 16;
  double _padding = 8;
  double _itemSpacing = 0;
  int _itemCount = 5;
  bool _compactWidth = false;

  static const _pages = <_Page>[
    _Page(
      'Home',
      Icons.home_rounded,
      Color(0xFF1F6F6A),
      'A quiet room, a long table, and light moving across the wall.',
    ),
    _Page(
      'Search',
      Icons.search_rounded,
      Color(0xFF2457A6),
      'Look through notes, places, and the small things you meant to keep.',
    ),
    _Page(
      'Inbox',
      Icons.inbox_outlined,
      Color(0xFF8A3E2F),
      'Four messages are waiting. The badge stays out of the item width.',
    ),
    _Page(
      'Saved',
      Icons.bookmark_outline_rounded,
      Color(0xFF6B4C2A),
      'A short list of pages worth returning to.',
    ),
    _Page(
      'Profile',
      Icons.person_outline_rounded,
      Color(0xFF3E3A6D),
      'The last item is a custom avatar, not an icon font.',
    ),
  ];

  void _select(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final pages = _pages.take(_itemCount).toList();
    final page = pages[_index];
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF1F6F6A),
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: const Color(0xFF8FE3D6),
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: Builder(
        builder: (context) {
          return MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(disableAnimations: _reducedMotion),
            child: Directionality(
              textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
              child: Builder(
                builder: (context) {
                  return Scaffold(
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    body: Stack(
                      children: [
                        _Feed(
                          page: page,
                          pages: pages,
                          bottomSpace: _height + _margin + 36,
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: LiquidGlassNavigationBar(
                            currentIndex: _index,
                            onIndexChanged: _select,
                            semanticsLabel: 'Main',
                            labelMode: _labelMode,
                            indicatorStyle: _indicatorStyle,
                            motion: _motion,
                            hapticsEnabled: _haptics,
                            items: _items(),
                            style: LiquidGlassNavigationStyle(
                              blurSigma: _blur,
                              height: _height,
                              width: _compactWidth ? 280 : null,
                              margin: EdgeInsets.fromLTRB(
                                _margin,
                                0,
                                _margin,
                                12,
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: _padding,
                                vertical: 6,
                              ),
                              itemSpacing: _itemSpacing,
                              borderRadius: BorderRadius.circular(_radius),
                              indicatorRadius: BorderRadius.circular(
                                _radius - 8,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    floatingActionButtonLocation:
                        FloatingActionButtonLocation.endTop,
                    floatingActionButton: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FloatingActionButton.small(
                            heroTag: 'next',
                            tooltip: 'Select the next item',
                            onPressed: () => _select((_index + 1) % _itemCount),
                            child: const Icon(Icons.skip_next_rounded),
                          ),
                          const SizedBox(width: 8),
                          FloatingActionButton.small(
                            heroTag: 'tune',
                            tooltip: 'Open appearance controls',
                            onPressed: () => _openControls(context),
                            child: const Icon(Icons.tune_rounded),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  List<LiquidGlassNavigationItem> _items() {
    return [
      for (final page in _pages.take(_itemCount))
        if (page.title == 'Profile')
          LiquidGlassNavigationItem(
            label: _includeLabels ? page.title : null,
            semanticLabel: 'Profile',
            child: const CircleAvatar(
              radius: 14,
              backgroundColor: Color(0xFF1F6F6A),
              child: Text(
                'K',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          )
        else
          LiquidGlassNavigationItem(
            icon: page.icon,
            label: _includeLabels ? page.title : null,
            badge: switch (page.title) {
              'Inbox' => const LiquidGlassBadge.count(4),
              'Saved' => const LiquidGlassBadge.dot(),
              _ => null,
            },
          ),
    ];
  }

  Future<void> _openControls(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheet) {
            void update(VoidCallback change) {
              setState(change);
              setSheet(() {});
            }

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              child: ListView(
                shrinkWrap: true,
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Back',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      Text(
                        'Appearance',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text('Light'),
                      ),
                      ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text('System'),
                      ),
                    ],
                    selected: {_themeMode},
                    onSelectionChanged: (value) =>
                        update(() => _themeMode = value.first),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<LiquidGlassLabelMode>(
                    segments: const [
                      ButtonSegment(
                        value: LiquidGlassLabelMode.hidden,
                        label: Text('Hidden'),
                      ),
                      ButtonSegment(
                        value: LiquidGlassLabelMode.selected,
                        label: Text('Selected'),
                      ),
                      ButtonSegment(
                        value: LiquidGlassLabelMode.always,
                        label: Text('Always'),
                      ),
                    ],
                    selected: {_labelMode},
                    onSelectionChanged: (value) =>
                        update(() => _labelMode = value.first),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<LiquidGlassIndicatorStyle>(
                    segments: const [
                      ButtonSegment(
                        value: LiquidGlassIndicatorStyle.slidingPill,
                        label: Text('Slide'),
                      ),
                      ButtonSegment(
                        value: LiquidGlassIndicatorStyle.morphingPill,
                        label: Text('Morph'),
                      ),
                    ],
                    selected: {_indicatorStyle},
                    onSelectionChanged: (value) =>
                        update(() => _indicatorStyle = value.first),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final preset in const [
                        LiquidGlassMotion.spring(),
                        LiquidGlassMotion.snappy(),
                        LiquidGlassMotion.gentle(),
                        LiquidGlassMotion.none(),
                      ])
                        ChoiceChip(
                          label: Text(switch (preset.duration.inMilliseconds) {
                            280 => 'Snappy',
                            640 => 'Gentle',
                            _ => preset.enabled ? 'Spring' : 'None',
                          }),
                          selected:
                              _motion.duration == preset.duration &&
                              _motion.enabled == preset.enabled,
                          onSelected: (_) => update(() => _motion = preset),
                        ),
                    ],
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Labels'),
                    value: _includeLabels,
                    onChanged: (value) => update(() => _includeLabels = value),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Haptics'),
                    value: _haptics,
                    onChanged: (value) => update(() => _haptics = value),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Reduced motion'),
                    value: _reducedMotion,
                    onChanged: (value) => update(() => _reducedMotion = value),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Right to left'),
                    value: _rtl,
                    onChanged: (value) => update(() => _rtl = value),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Compact width'),
                    value: _compactWidth,
                    onChanged: (value) => update(() => _compactWidth = value),
                  ),
                  Text('Blur ${_blur.round()}'),
                  Slider(
                    min: 0,
                    max: 30,
                    value: _blur,
                    onChanged: (value) => update(() => _blur = value),
                  ),
                  Text('Height ${_height.round()}'),
                  Slider(
                    min: 56,
                    max: 96,
                    value: _height,
                    onChanged: (value) => update(() => _height = value),
                  ),
                  Text('Radius ${_radius.round()}'),
                  Slider(
                    min: 12,
                    max: 40,
                    value: _radius,
                    onChanged: (value) => update(() => _radius = value),
                  ),
                  Text('Margin ${_margin.round()}'),
                  Slider(
                    min: 0,
                    max: 32,
                    value: _margin,
                    onChanged: (value) => update(() => _margin = value),
                  ),
                  Text('Padding ${_padding.round()}'),
                  Slider(
                    min: 0,
                    max: 20,
                    value: _padding,
                    onChanged: (value) => update(() => _padding = value),
                  ),
                  Text('Item spacing ${_itemSpacing.round()}'),
                  Slider(
                    min: 0,
                    max: 16,
                    value: _itemSpacing,
                    onChanged: (value) => update(() => _itemSpacing = value),
                  ),
                  Text('Items $_itemCount'),
                  Slider(
                    min: 2,
                    max: 5,
                    divisions: 3,
                    value: _itemCount.toDouble(),
                    onChanged: (value) => update(() {
                      _itemCount = value.round();
                      if (_index >= _itemCount) {
                        _index = _itemCount - 1;
                      }
                    }),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _Feed extends StatelessWidget {
  const _Feed({
    required this.page,
    required this.pages,
    required this.bottomSpace,
  });

  final _Page page;
  final List<_Page> pages;
  final double bottomSpace;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            page.color.withValues(alpha: 0.85),
            scheme.surface,
            page.color.withValues(alpha: 0.35),
          ],
        ),
      ),
      child: ListView(
        padding: EdgeInsets.fromLTRB(20, 72, 20, bottomSpace),
        children: [
          Text(
            page.title,
            key: const Key('page-title'),
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 8),
          Text(page.caption, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 24),
          for (var i = 0; i < 6; i++)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: scheme.surface.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Text(
                '${pages[(page == pages.first ? i : i + 1) % pages.length].title} note ${i + 1}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
        ],
      ),
    );
  }
}

class _Page {
  const _Page(this.title, this.icon, this.color, this.caption);

  final String title;
  final IconData icon;
  final Color color;
  final String caption;
}
