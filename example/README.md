# liquid_glass_bottom_navigator example

A gallery for the local package. Home, Search, Inbox, Saved, and Profile scroll behind the floating `LiquidGlassNavigationBar`, so the blur samples calm cards instead of a flat color. Inbox shows four unread messages, the same count as the badge. Saved carries a dot. Profile uses a custom avatar child.

The tune button opens Appearance. The controls are grouped and none of the previous options are removed:

- Appearance: theme, label mode, indicator style
- Motion: spring, snappy, gentle, none, drag selection, haptics, reduced motion
- Layout: equal or intrinsic slots, compact width, safe area, right to left, labels, item count
- Dimensions: blur, height, radius, margin, padding, item spacing

Drag the selected destination when drag selection is on. The bar stays fixed while the page scrolls.

```bash
flutter pub get
flutter run
flutter analyze
flutter test
```

Profile the bar with a fixed scrolling list and selection switches between the first and last items. Warmup is 2 seconds and is not recorded. The next 10 seconds are recorded, then the app waits 2 seconds so batched frame timings can arrive. From `example/`:

```bash
flutter run --profile -d macos -t lib/profile_main.dart
```

The app prints one `PROFILE_RESULT` JSON object and exits. The run includes an idle window, a scrolling list with and without the bar, morphing and sliding capsules at blur sigma 18, and 80 mount and unmount cycles that report resident memory. The iOS simulator cannot build profile mode. A physical device can be substituted for `macos` only when you intend to install the example on it.

Still screenshots of the gallery can be captured with `--dart-define=CAPTURE=true`. A normal `flutter run` does not start that tour.
