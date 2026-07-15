import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:real_liquid_glass_demo/main.dart';

void main() {
  testWidgets('only the control layer uses backdrop glass', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              GlassPanel(child: Text('control')),
              ContentPanel(child: Text('content')),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(find.text('control'), findsOneWidget);
    expect(find.text('content'), findsOneWidget);
  });

  testWidgets('toolbar glass keeps a 48 point touch target', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: IosToolbarButton(
            icon: Icons.add,
            tooltip: '添加',
            onPressed: () {},
          ),
        ),
      ),
    );

    final size = tester.getSize(find.byType(IosToolbarButton));
    expect(size.width, inInclusiveRange(48, 52));
    expect(size.height, inInclusiveRange(48, 52));
  });
}
