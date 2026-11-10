# Contributing

Issues and pull requests are welcome at https://github.com/K-Almahamid/liquid_glass_bottom_navigator/issues.

## Project structure

* `lib/liquid_glass_bottom_navigator.dart` exports the public API.
* `lib/src/` holds the bar, item layout, indicator geometry, glass surface, theme, and motion. Render objects in `src/` are not exported.
* `example/` is the gallery. It is not published as the package.
* `test/` covers interaction, layout, motion, accessibility, and goldens.
* `screenshots/` holds the README captures.

## Example

From `example/`:

```bash
flutter pub get
flutter run
```

Appearance includes drag selection. The package default is off. The example default is on.

## Tests

From the package root, with Flutter `>=3.47.0`:

```bash
flutter test
```

From `example/`:

```bash
flutter test
```

Widget tests drive real pointer gestures. Do not loosen an assertion to make a drag test pass. Do not regenerate goldens to hide a paint change. Goldens use `blurSigma: 0`. `test/navigation_golden_test.dart` allows up to 2% pixel variance so Ubuntu CI and local hosts can share the same PNGs; real layout regressions are still much larger than that.

## Coding guidelines

* `currentIndex` is the only selection. `onIndexChanged` requests a change. Do not keep a second selected index inside the package.
* Dragging is a preview. It defaults to off so 1.0.0 apps stay tap-only.
* Keep the public surface small. Prefer a private helper over a new public type.
* Do not add a runtime dependency. Flutter SDK and the existing dev dependencies are the set.
* The glass effect is one clipped `BackdropFilter` plus a tint. Do not describe it as optical refraction, and do not add a shader for drag.
* Dispose animation controllers, focus nodes, and recognizers with the state that created them.
* Match the surrounding style. `dart format` is the formatter.

## Compatibility

1.1.0 is backward compatible with 1.0.0. New behavior is behind `enableDragSelection: false`. Do not change the default, the tap callback timing, or the resting indicator geometry without a major version.

The SDK floor stays Dart `^3.13.4` and Flutter `>=3.47.0` because the spring uses `SpringDescription.withDurationAndBounce`.

## Workflow

Open an issue or a pull request against `main`. Keep the change focused. Run the checks below before asking for review. Do not publish the package from a pull request. `dart pub publish` without `--dry-run` is a maintainer step. Do not force-push `main`.

## Checks

From the package root, with Flutter `>=3.47.0`:

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
dart pub publish --dry-run
```

From `example/`:

```bash
flutter analyze
flutter test
```

Do not publish the package from a pull request. `dart pub publish` without `--dry-run` is a maintainer step.

## Design limits

The glass effect is one clipped `BackdropFilter` plus a tint. It is not optical refraction. Do not add a refraction shader or a second blur without a measured reason. Do not invent frame timings.
