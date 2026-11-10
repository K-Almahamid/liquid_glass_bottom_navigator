import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'tolerant_golden_comparator.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  goldenFileComparator = TolerantGoldenFileComparator(
    Uri.parse('test/'),
    // Ubuntu CI and macOS hosts differ slightly in glyph rasterization.
    precisionTolerance: 0.02,
  );
  await testMain();
}
