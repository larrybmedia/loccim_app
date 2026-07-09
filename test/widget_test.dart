// This is a corrected Flutter widget test for the LOCCIM Application.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loccim_app/main.dart';

void main() {
  testWidgets('LOCCIM App initialization smoke test', (
    WidgetTester tester,
  ) async {
    // 1. Build our LOCCIM app and trigger a frame rendering loop.
    await tester.pumpWidget(const LOCCIMApp());

    // 2. Allow any initial state loaders or splash configurations to settle.
    await tester.pump();

    // 3. Verify that MaterialApp or basic core widgets initialize successfully.
    // This confirms the root widget tree structure is valid and healthy.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
