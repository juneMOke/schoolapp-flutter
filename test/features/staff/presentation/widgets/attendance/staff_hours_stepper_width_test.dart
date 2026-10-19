import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/register/staff_row_controls.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// « − » et « + » ont 48 dp de cible : le pas à pas des heures doit tenir
/// dans sa colonne, sans quoi le « + » déborde et ne reçoit plus les appuis.
void main() {
  for (final minutes in const [0, 150, 600]) {
    testWidgets('$minutes min : le pas à pas tient dans sa colonne', (
      tester,
    ) async {
      var steps = 0;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: AppDimensions.presenceMarkColHours,
                child: StaffHoursStepper(
                  minutes: minutes,
                  onStep: (_) => steps++,
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      if (minutes < 600) {
        await tester.tap(find.byIcon(Icons.add));
        expect(steps, 1);
      }
    });
  }
}
