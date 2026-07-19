import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:examprep/app/theme.dart';

void main() {
  testWidgets('Light and dark themes build', (tester) async {
    // Sanity check that the theme data is constructible.
    expect(AppTheme.light.useMaterial3, isTrue);
    expect(AppTheme.dark.brightness, Brightness.dark);
  });
}
