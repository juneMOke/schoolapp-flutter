import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';

void main() {
  group('AppPageBackground', () {
    testWidgets('forwarde le floatingActionButton au Scaffold interne', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AppPageBackground(
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
            floatingActionButton: FloatingActionButton(
              onPressed: () {},
              child: const Icon(Icons.add),
            ),
            child: const SizedBox.shrink(),
          ),
        ),
      );

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });
  });
}
