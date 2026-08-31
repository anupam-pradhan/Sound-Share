import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundshare/app/app.dart';

void main() {
  testWidgets('SoundShare smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: SoundShareApp()),
    );
    // Just verifies the app builds without throwing
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
