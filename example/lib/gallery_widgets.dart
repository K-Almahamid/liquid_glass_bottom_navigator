import 'package:flutter/material.dart';

import 'gallery_theme.dart';

/// Large title and supporting line at the top of a destination.
class GalleryHeader extends StatelessWidget {
  /// Creates a scrolling page header.
  const GalleryHeader({
    required this.title,
    this.subtitle,
    this.showTitleKey = false,
    this.extra,
    super.key,
  });

  /// Large title.
  final String title;

  /// Short description under the title.
  final String? subtitle;

  /// Whether this header owns the active page-title key.
  final bool showTitleKey;

  /// Optional note under the subtitle, such as the drag hint.
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    final colors = GalleryColors.of(context);
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 64, bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            key: showTitleKey ? const Key('page-title') : null,
            style: text.headlineLarge?.copyWith(
              fontSize: 34,
              height: 1.12,
              letterSpacing: -0.6,
              fontWeight: FontWeight.w700,
              color: colors.ink,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: text.bodyLarge?.copyWith(
                fontSize: 17,
                height: 1.35,
                color: colors.secondary,
              ),
            ),
          ],
          if (extra != null) ...[const SizedBox(height: 10), extra!],
        ],
      ),
    );
  }
}

/// A calm surface that scrolls under the glass bar.
class GalleryCard extends StatelessWidget {
  /// Creates a card with [child].
  const GalleryCard({
    required this.child,
    this.color,
    this.padding = const EdgeInsets.all(18),
    super.key,
  });

  /// Card contents.
  final Widget child;

  /// Fill. Defaults to the gallery card color.
  final Color? color;

  /// Inner padding.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = GalleryColors.of(context);
    return Material(
      color: color ?? colors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colors.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: padding, child: child),
    );
  }
}

/// Grouped section: a quiet label and an inset card of rows.
class GallerySection extends StatelessWidget {
  /// Creates a labeled group.
  const GallerySection({
    required this.title,
    required this.children,
    this.footer,
    super.key,
  });

  /// Section name.
  final String title;

  /// Rows, sliders, or segmented controls.
  final List<Widget> children;

  /// Optional note under the group.
  final String? footer;

  @override
  Widget build(BuildContext context) {
    final colors = GalleryColors.of(context);
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              title,
              style: text.labelLarge?.copyWith(
                color: colors.secondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
          Material(
            color: colors.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: colors.hairline),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i != children.length - 1)
                    Divider(
                      height: 1,
                      thickness: 0.5,
                      indent: 16,
                      color: colors.hairline,
                    ),
                ],
              ],
            ),
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                footer!,
                style: text.bodySmall?.copyWith(
                  color: colors.secondary,
                  height: 1.35,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Title, subtitle, and optional leading or trailing widget.
class GalleryContentTile extends StatelessWidget {
  /// Creates a content row.
  const GalleryContentTile({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.emphasized = false,
    this.showDot = false,
    super.key,
  });

  /// Primary line.
  final String title;

  /// Secondary line.
  final String? subtitle;

  /// Icon or avatar.
  final Widget? leading;

  /// Time, value, or icon.
  final Widget? trailing;

  /// Draws the title in a heavier weight.
  final bool emphasized;

  /// Small accent dot before the title.
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    final colors = GalleryColors.of(context);
    final text = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      label: showDot ? 'Unread $title' : null,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 60),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 12)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (showDot) ...[
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: colors.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            title,
                            style: text.titleMedium?.copyWith(
                              fontWeight: emphasized
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: colors.ink,
                              height: 1.25,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: text.bodyMedium?.copyWith(
                          color: colors.secondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 12), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}

/// A settings value with no action, title on the start and value on the end.
class GalleryValueRow extends StatelessWidget {
  /// Creates a static settings row.
  const GalleryValueRow({required this.title, required this.value, super.key});

  /// Setting name.
  final String title;

  /// Current value.
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = GalleryColors.of(context);
    final text = Theme.of(context).textTheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: text.bodyLarge?.copyWith(color: colors.ink),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: text.bodyLarge?.copyWith(color: colors.secondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Switch row used by the appearance sheet.
class GallerySettingRow extends StatelessWidget {
  /// Creates a switch row.
  const GallerySettingRow({
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    super.key,
  });

  /// Control name. Tests and screen readers use this text.
  final String title;

  /// Optional explanation under the title.
  final String? subtitle;

  /// Current value.
  final bool value;

  /// Called when the row or switch changes.
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = GalleryColors.of(context);
    return SwitchListTile.adaptive(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      controlAffinity: ListTileControlAffinity.trailing,
      title: Text(title),
      subtitle: subtitle == null
          ? null
          : Text(subtitle!, style: TextStyle(color: colors.secondary)),
      value: value,
      onChanged: onChanged,
    );
  }
}

/// Equal-width segmented control that scales its labels down to fit.
class GallerySegmented<T> extends StatelessWidget {
  /// Creates a segmented control.
  const GallerySegmented({
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
    super.key,
  });

  /// Choices, in order.
  final List<T> values;

  /// Selected value.
  final T selected;

  /// Visible label for a value.
  final String Function(T value) labelOf;

  /// Called with the tapped value.
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = GalleryColors.of(context);
    final text = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.track,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Row(
          children: [
            for (final value in values)
              Expanded(
                child: _Segment(
                  label: labelOf(value),
                  selected: value == selected,
                  onTap: () => onChanged(value),
                  textStyle: text.labelLarge,
                  colors: colors,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.textStyle,
    required this.colors,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final TextStyle? textStyle;
  final GalleryColors colors;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected ? colors.card : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: SizedBox(
                height: 22,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: textStyle?.copyWith(
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected ? colors.ink : colors.secondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Labeled slider. The label stays a stable finder for tests.
class GallerySliderRow extends StatelessWidget {
  /// Creates a slider row.
  const GallerySliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.divisions,
    this.sliderKey,
    super.key,
  });

  /// Name shown beside the rounded value.
  final String label;

  /// Current value.
  final double value;

  /// Minimum.
  final double min;

  /// Maximum.
  final double max;

  /// Optional discrete steps.
  final int? divisions;

  /// Called as the slider moves.
  final ValueChanged<double> onChanged;

  /// Key for the slider itself.
  final Key? sliderKey;

  @override
  Widget build(BuildContext context) {
    final colors = GalleryColors.of(context);
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: text.bodyLarge?.copyWith(color: colors.ink),
                ),
              ),
              Text(
                '${value.round()}',
                style: text.bodyLarge?.copyWith(color: colors.secondary),
              ),
            ],
          ),
          Slider(
            key: sliderKey,
            min: min,
            max: max,
            divisions: divisions,
            value: value.clamp(min, max).toDouble(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// Scroll view for one destination.
///
/// Each destination keeps its own state, so an [IndexedStack] preserves the
/// offset when the bar changes tabs. Physics come from the platform, and the
/// view can still move when the content is short so cards can pass under the
/// glass.
class GalleryScrollView extends StatefulWidget {
  /// Creates a destination scroller.
  const GalleryScrollView({
    required this.bottomInset,
    required this.children,
    super.key,
  });

  /// Space so the last card can rest above the floating bar.
  final double bottomInset;

  /// Header and cards.
  final List<Widget> children;

  @override
  State<GalleryScrollView> createState() => _GalleryScrollViewState();
}

class _GalleryScrollViewState extends State<GalleryScrollView> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final platform = ScrollConfiguration.of(context).getScrollPhysics(context);
    final top = MediaQuery.paddingOf(context).top + 12;
    return ListView(
      controller: _controller,
      primary: false,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      physics: AlwaysScrollableScrollPhysics(parent: platform),
      padding: EdgeInsets.fromLTRB(20, top, 20, widget.bottomInset),
      children: widget.children,
    );
  }
}
