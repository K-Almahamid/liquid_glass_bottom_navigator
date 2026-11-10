# Contributing

Issues and pull requests are welcome at https://github.com/K-Almahamid/liquid_glass_bottom_navigator/issues.

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
