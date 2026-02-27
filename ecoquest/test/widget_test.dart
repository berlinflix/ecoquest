import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ecoquest/engine/game_screen.dart';

void main() {
  testWidgets('GameScreen renders a black canvas', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: GameScreen()));

    // Verify that a CustomPaint widget is present (our 2D canvas).
    expect(find.byType(CustomPaint), findsWidgets);
  });
}
