import 'package:flutter/material.dart';
import 'package:liquid_glass_bottom_navigator/liquid_glass_bottom_navigator.dart';

import 'gallery_controls.dart';
import 'gallery_theme.dart';
import 'gallery_widgets.dart';

/// Opens the grouped appearance sheet.
///
/// [controls] is read again after every change so the sheet follows the
/// parent state, including theme and layout direction.
Future<void> showAppearanceSheet({
  required BuildContext context,
  required ExampleControls Function() controls,
  required LiquidGlassCollapseController collapse,
  required ValueChanged<ExampleControls> onChanged,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (sheetContext, setSheet) {
          final current = controls();
          return Theme(
            data: GalleryTheme.forMode(
              current.themeMode,
              MediaQuery.platformBrightnessOf(sheetContext),
            ),
            child: MediaQuery(
              data: MediaQuery.of(sheetContext)
                  .copyWith(disableAnimations: current.reducedMotion),
              child: Directionality(
                textDirection: current.rtl
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                child: AppearanceSheet(
                  controls: current,
                  collapse: collapse,
                  onChanged: (next) {
                    onChanged(next);
                    setSheet(() {});
                  },
                  onClose: () => Navigator.of(sheetContext).pop(),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

/// Grouped controls for theme, motion, layout, and dimensions.
class AppearanceSheet extends StatelessWidget {
  /// Creates the sheet body.
  const AppearanceSheet({
    required this.controls,
    required this.collapse,
    required this.onChanged,
    required this.onClose,
    super.key,
  });

  /// Current values.
  final ExampleControls controls;

  /// Shared with the active page so the sheet can preview collapse.
  final LiquidGlassCollapseController collapse;

  /// Applies a new value and refreshes the sheet.
  final ValueChanged<ExampleControls> onChanged;

  /// Dismisses the sheet.
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = GalleryColors.of(context);
    final media = MediaQuery.of(context);
    final available = media.size.height - media.padding.top - 8;
    final proposed = media.size.height * 0.88;
    final height = proposed < available ? proposed : available;
    return SizedBox(
      height: height,
      child: Column(
        children: [
          Row(
            children: [
              BackButton(onPressed: onClose),
              Expanded(
                child: Text(
                  'Appearance',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.ink,
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: ListView(
              key: const Key('appearance-scroll'),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                GallerySection(
                  title: 'Appearance',
                  children: [
                    _Labeled(
                      label: 'Theme',
                      child: GallerySegmented<ThemeMode>(
                        values: const [
                          ThemeMode.light,
                          ThemeMode.dark,
                          ThemeMode.system,
                        ],
                        selected: controls.themeMode,
                        labelOf: (mode) => switch (mode) {
                          ThemeMode.light => 'Light',
                          ThemeMode.dark => 'Dark',
                          ThemeMode.system => 'System',
                        },
                        onChanged: (mode) =>
                            onChanged(controls.copyWith(themeMode: mode)),
                      ),
                    ),
                    _Labeled(
                      label: 'Label mode',
                      child: GallerySegmented<LiquidGlassLabelMode>(
                        values: const [
                          LiquidGlassLabelMode.hidden,
                          LiquidGlassLabelMode.selected,
                          LiquidGlassLabelMode.always,
                        ],
                        selected: controls.labelMode,
                        labelOf: (mode) => switch (mode) {
                          LiquidGlassLabelMode.hidden => 'Icons only',
                          LiquidGlassLabelMode.selected => 'Selected',
                          LiquidGlassLabelMode.always => 'All labels',
                        },
                        onChanged: (mode) =>
                            onChanged(controls.copyWith(labelMode: mode)),
                      ),
                    ),
                    _Labeled(
                      label: 'Indicator',
                      child: GallerySegmented<LiquidGlassIndicatorStyle>(
                        values: const [
                          LiquidGlassIndicatorStyle.slidingPill,
                          LiquidGlassIndicatorStyle.morphingPill,
                        ],
                        selected: controls.indicatorStyle,
                        labelOf: (style) => switch (style) {
                          LiquidGlassIndicatorStyle.slidingPill => 'Slide',
                          LiquidGlassIndicatorStyle.morphingPill => 'Morph',
                        },
                        onChanged: (style) =>
                            onChanged(controls.copyWith(indicatorStyle: style)),
                      ),
                    ),
                  ],
                ),
                GallerySection(
                  title: 'Motion',
                  footer: 'Reduced motion jumps the indicator instead of springing it.',
                  children: [
                    _Labeled(
                      label: 'Pace',
                      child: GallerySegmented<GalleryMotionPreset>(
                        values: GalleryMotionPreset.values,
                        selected: controls.motion,
                        labelOf: (preset) => preset.label,
                        onChanged: (preset) =>
                            onChanged(controls.copyWith(motion: preset)),
                      ),
                    ),
                    GallerySettingRow(
                      title: 'Drag selection',
                      value: controls.dragSelection,
                      onChanged: (value) =>
                          onChanged(controls.copyWith(dragSelection: value)),
                    ),
                    GallerySettingRow(
                      title: 'Scroll collapse',
                      value: controls.scrollCollapse,
                      onChanged: (value) =>
                          onChanged(controls.copyWith(scrollCollapse: value)),
                    ),
                    GallerySettingRow(
                      title: 'Collapsed',
                      value: collapse.isCollapsed,
                      onChanged: (value) {
                        if (value) {
                          collapse.collapse();
                          onChanged(controls.copyWith(scrollCollapse: true));
                        } else {
                          collapse.expand();
                          onChanged(controls);
                        }
                      },
                    ),
                    GallerySettingRow(
                      title: 'Haptics',
                      value: controls.haptics,
                      onChanged: (value) =>
                          onChanged(controls.copyWith(haptics: value)),
                    ),
                    GallerySettingRow(
                      title: 'Reduced motion',
                      value: controls.reducedMotion,
                      onChanged: (value) =>
                          onChanged(controls.copyWith(reducedMotion: value)),
                    ),
                  ],
                ),
                GallerySection(
                  title: 'Glass',
                  footer: 'Classic is the original blur. Enhanced is a theme veil. Refractive samples the backdrop where the renderer supports it.',
                  children: [
                    _Labeled(
                      label: 'Mode',
                      child: GallerySegmented<LiquidGlassRenderMode>(
                        values: LiquidGlassRenderMode.values,
                        selected: controls.glassMode,
                        labelOf: (mode) => switch (mode) {
                          LiquidGlassRenderMode.classic => 'Classic',
                          LiquidGlassRenderMode.enhanced => 'Enhanced',
                          LiquidGlassRenderMode.refractive => 'Refractive',
                        },
                        onChanged: (mode) =>
                            onChanged(controls.copyWith(glassMode: mode)),
                      ),
                    ),
                    _Labeled(
                      label: 'Variant',
                      child: GallerySegmented<LiquidGlassMaterialVariant>(
                        values: LiquidGlassMaterialVariant.values,
                        selected: controls.glassVariant,
                        labelOf: (variant) => switch (variant) {
                          LiquidGlassMaterialVariant.regular => 'Regular',
                          LiquidGlassMaterialVariant.clear => 'Clear',
                        },
                        onChanged: (variant) =>
                            onChanged(controls.copyWith(glassVariant: variant)),
                      ),
                    ),
                    GallerySliderRow(
                      label: 'Refraction',
                      value: controls.refractionStrength,
                      min: 0,
                      max: 1,
                      divisions: 20,
                      onChanged: (value) => onChanged(
                        controls.copyWith(refractionStrength: value),
                      ),
                    ),
                    GallerySliderRow(
                      label: 'Edge',
                      value: controls.edgeThickness,
                      min: 0,
                      max: 1,
                      divisions: 20,
                      onChanged: (value) =>
                          onChanged(controls.copyWith(edgeThickness: value)),
                    ),
                    GallerySliderRow(
                      label: 'Highlight',
                      value: controls.highlightIntensity,
                      min: 0,
                      max: 1,
                      divisions: 20,
                      onChanged: (value) => onChanged(
                        controls.copyWith(highlightIntensity: value),
                      ),
                    ),
                    GallerySettingRow(
                      title: 'Adaptive tint',
                      value: controls.adaptiveTint,
                      onChanged: (value) =>
                          onChanged(controls.copyWith(adaptiveTint: value)),
                    ),
                    _Labeled(
                      label: 'Backdrop',
                      child: GallerySegmented<GalleryBackdrop>(
                        values: GalleryBackdrop.values,
                        selected: controls.backdrop,
                        labelOf: (backdrop) => switch (backdrop) {
                          GalleryBackdrop.page => 'Page',
                          GalleryBackdrop.light => 'White',
                          GalleryBackdrop.dark => 'Ink',
                          GalleryBackdrop.gradient => 'Gradient',
                          GalleryBackdrop.saturated => 'Color',
                          GalleryBackdrop.pattern => 'Pattern',
                        },
                        onChanged: (backdrop) =>
                            onChanged(controls.copyWith(backdrop: backdrop)),
                      ),
                    ),
                  ],
                ),
                GallerySection(
                  title: 'Layout',
                  children: [
                    GallerySettingRow(
                      title: 'Equal slots',
                      subtitle: 'Off uses intrinsic widths.',
                      value: controls.equalSlots,
                      onChanged: (value) =>
                          onChanged(controls.copyWith(equalSlots: value)),
                    ),
                    GallerySettingRow(
                      title: 'Compact width',
                      value: controls.compactWidth,
                      onChanged: (value) =>
                          onChanged(controls.copyWith(compactWidth: value)),
                    ),
                    GallerySettingRow(
                      title: 'Respect safe area',
                      value: controls.respectSafeArea,
                      onChanged: (value) =>
                          onChanged(controls.copyWith(respectSafeArea: value)),
                    ),
                    GallerySettingRow(
                      title: 'Right to left',
                      value: controls.rtl,
                      onChanged: (value) =>
                          onChanged(controls.copyWith(rtl: value)),
                    ),
                    GallerySettingRow(
                      title: 'Labels',
                      value: controls.includeLabels,
                      onChanged: (value) =>
                          onChanged(controls.copyWith(includeLabels: value)),
                    ),
                    GallerySliderRow(
                      label: 'Items',
                      value: controls.itemCount.toDouble(),
                      min: 2,
                      max: 5,
                      divisions: 3,
                      onChanged: (value) => onChanged(
                        controls.copyWith(itemCount: value.round()),
                      ),
                    ),
                  ],
                ),
                GallerySection(
                  title: 'Dimensions',
                  children: [
                    GallerySliderRow(
                      label: 'Blur',
                      sliderKey: const Key('blur-slider'),
                      value: controls.blur,
                      min: 0,
                      max: 30,
                      onChanged: (value) =>
                          onChanged(controls.copyWith(blur: value)),
                    ),
                    GallerySliderRow(
                      label: 'Height',
                      sliderKey: const Key('height-slider'),
                      value: controls.height,
                      min: 56,
                      max: 96,
                      onChanged: (value) =>
                          onChanged(controls.copyWith(height: value)),
                    ),
                    GallerySliderRow(
                      label: 'Radius',
                      value: controls.radius,
                      min: 12,
                      max: 40,
                      onChanged: (value) =>
                          onChanged(controls.copyWith(radius: value)),
                    ),
                    GallerySliderRow(
                      label: 'Margin',
                      value: controls.margin,
                      min: 0,
                      max: 32,
                      onChanged: (value) =>
                          onChanged(controls.copyWith(margin: value)),
                    ),
                    GallerySliderRow(
                      label: 'Padding',
                      value: controls.padding,
                      min: 0,
                      max: 20,
                      onChanged: (value) =>
                          onChanged(controls.copyWith(padding: value)),
                    ),
                    GallerySliderRow(
                      label: 'Item spacing',
                      value: controls.itemSpacing,
                      min: 0,
                      max: 16,
                      onChanged: (value) =>
                          onChanged(controls.copyWith(itemSpacing: value)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Labeled extends StatelessWidget {
  const _Labeled({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = GalleryColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: colors.secondary),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
