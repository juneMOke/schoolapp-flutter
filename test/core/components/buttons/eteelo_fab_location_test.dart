import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/buttons/eteelo_fab_location.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';

void main() {
  testWidgets('decale le FAB de 12 px vs endFloat (28 au lieu de 16)', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(420, 840));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    Future<Offset> pumpAndGetFabTopLeft(
      FloatingActionButtonLocation location,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButton: FloatingActionButton(
              onPressed: () {},
              child: const Icon(Icons.add),
            ),
            floatingActionButtonLocation: location,
            body: const SizedBox.expand(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return tester.getTopLeft(find.byType(FloatingActionButton));
    }

    final defaultOffset = await pumpAndGetFabTopLeft(
      FloatingActionButtonLocation.endFloat,
    );
    final customOffset = await pumpAndGetFabTopLeft(
      const EndFloatEdgeOffsetFabLocation(),
    );

    final expectedDelta = AppDimensions.fabEdgeOffset - 16.0;

    expect(defaultOffset.dx - customOffset.dx, expectedDelta);
    expect(defaultOffset.dy - customOffset.dy, expectedDelta);
  });
}
