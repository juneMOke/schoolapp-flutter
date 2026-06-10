import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/widgets/eteelo_date_input.dart';

void main() {
  group('EteeloDateInput', () {
    BoxDecoration fieldDecoration(WidgetTester tester) {
      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      return container.decoration! as BoxDecoration;
    }

    testWidgets('en lecture (readOnly) : fond editable + date affichee', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          home: Scaffold(
            body: EteeloDateInput(
              label: 'Date de naissance',
              value: DateTime(2012, 5, 20),
              readOnly: true,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      // Pas de couleur particulière en lecture : fond = surface.
      expect(fieldDecoration(tester).color, equals(AppColors.surface));
      // La date reste affichée.
      expect(find.text('20/05/2012'), findsOneWidget);
    });

    testWidgets('desactive sans readOnly : garde le fond grise (surfaceAlt)', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          home: Scaffold(
            body: EteeloDateInput(
              label: 'Date de naissance',
              value: DateTime(2012, 5, 20),
              enabled: false,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(fieldDecoration(tester).color, equals(AppColors.surfaceAlt));
    });
  });
}
