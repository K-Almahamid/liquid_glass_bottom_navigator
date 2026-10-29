# liquid_glass_bottom_navigator example

A gallery that depends on the local package. Scroll the notes to see the blur, then use the tune button for theme, labels, motion, haptics, reduced motion, RTL, and size. The skip button changes the selection without a tap on the bar.

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

The app prints one `PROFILE_RESULT` JSON object and exits. The iOS simulator cannot build profile mode. A physical device can be substituted for `macos` only when you intend to install the example on it.
