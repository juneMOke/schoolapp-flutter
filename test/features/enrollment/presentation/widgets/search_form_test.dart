import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select/eteelo_select_field.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select/eteelo_select_option_tile.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_listing_page_contracts.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/search_form.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

void main() {
  Widget buildHarness(Widget child) {
    return MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(child: SizedBox(width: 420, child: child)),
      ),
    );
  }

  testWidgets(
    'le bouton Effacer vide les champs même juste après une recherche',
    (tester) async {
      final dispatched = <EnrollmentSearchCommand>[];
      await tester.pumpWidget(
        buildHarness(
          SearchForm(
            academicYearId: '2025',
            status: 'IN_PROGRESS',
            isLoading: false,
            dispatch: dispatched.add,
          ),
        ),
      );

      await tester.enterText(find.byType(TextField).at(0), 'Jean');
      await tester.enterText(find.byType(TextField).at(1), 'Dupont');
      await tester.enterText(find.byType(TextField).at(2), 'Alain');
      await tester.pump();

      // Enchaîne Rechercher puis Effacer sans laisser s'écouler le cooldown
      // anti-double-clic : les deux actions sont indépendantes, l'une ne doit
      // jamais verrouiller l'autre.
      await tester.tap(find.text('Rechercher'));
      await tester.tap(find.text('Effacer'));
      await tester.pump();

      expect(
        tester.widget<TextField>(find.byType(TextField).at(0)).controller!.text,
        isEmpty,
      );
      expect(
        tester.widget<TextField>(find.byType(TextField).at(1)).controller!.text,
        isEmpty,
      );
      expect(
        tester.widget<TextField>(find.byType(TextField).at(2)).controller!.text,
        isEmpty,
      );

      final lastCommand = dispatched.last as StandardSearchCommand;
      expect(lastCommand.firstName, isNull);
      expect(lastCommand.status, 'IN_PROGRESS');
    },
  );

  testWidgets('changer de statut conserve les critères nom/date déjà saisis', (
    tester,
  ) async {
    final dispatched = <EnrollmentSearchCommand>[];
    String? notifiedStatus;
    await tester.pumpWidget(
      buildHarness(
        SearchForm(
          academicYearId: '2025',
          status: 'IN_PROGRESS',
          isLoading: false,
          dispatch: dispatched.add,
          showStatusFilter: true,
          onStatusChanged: (status) => notifiedStatus = status,
        ),
      ),
    );

    await tester.enterText(find.byType(TextField).at(0), 'Jean');
    await tester.enterText(find.byType(TextField).at(1), 'Dupont');
    await tester.enterText(find.byType(TextField).at(2), 'Alain');
    await tester.pump();

    await tester.tap(find.byType(EteeloSelectField));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(EteeloSelectOptionTile<String>).last);
    await tester.pumpAndSettle();

    expect(notifiedStatus, isNotNull);
    expect(notifiedStatus, isNot('IN_PROGRESS'));

    final lastCommand = dispatched.last as StandardSearchCommand;
    expect(lastCommand.firstName, 'Jean');
    expect(lastCommand.lastName, 'Dupont');
    expect(lastCommand.surname, 'Alain');
    expect(lastCommand.status, notifiedStatus);
  });
}
