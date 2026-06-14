import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/disciplinary_dossier_tabs.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/disciplinary_student_compact_header.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

Widget _wrap(Widget child, {double width = 600}) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('fr'),
  builder: (context, widget) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: true),
    child: widget!,
  ),
  home: Scaffold(
    body: Center(
      child: SizedBox(width: width, child: child),
    ),
  ),
);

void main() {
  group('DisciplinaryDossierTabs', () {
    testWidgets(
      'rend les 2 onglets + badge cas ouverts, bascule sans exception',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            DefaultTabController(
              length: 2,
              child: Builder(
                builder: (context) => DisciplinaryDossierTabs(
                  controller: DefaultTabController.of(context),
                  openCasesCount: 2,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Discipline'), findsOneWidget);
        expect(find.text('Présence'), findsOneWidget);
        expect(find.text('Cas, sanctions & suivi'), findsOneWidget);
        expect(find.text('2'), findsOneWidget); // badge cas ouverts

        await tester.tap(find.text('Présence'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('aucun badge quand 0 cas ouvert', (tester) async {
      await tester.pumpWidget(
        _wrap(
          DefaultTabController(
            length: 2,
            child: Builder(
              builder: (context) => DisciplinaryDossierTabs(
                controller: DefaultTabController.of(context),
                openCasesCount: 0,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('0'), findsNothing);
    });
  });

  group('DisciplinaryStudentCompactHeader', () {
    DisciplinaryStudentCompactHeader header({int? openCasesCount}) =>
        DisciplinaryStudentCompactHeader(
          studentId: 's1',
          firstName: 'Daniel',
          lastName: 'Kabongo',
          middleName: 'Mwamba',
          gender: 'MALE',
          levelName: '5ème primaire',
          classroomName: '5e B',
          openCasesCount: openCasesCount,
        );

    testWidgets('chip masqué tant que le compte est inconnu (null)', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(header()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Aucun cas ouvert'), findsNothing);
    });

    testWidgets('0 cas -> chip vert « Aucun cas ouvert »', (tester) async {
      await tester.pumpWidget(_wrap(header(openCasesCount: 0)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Aucun cas ouvert'), findsOneWidget);
    });

    testWidgets('2 cas -> chip rouge « 2 cas ouverts » + méta avec genre', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(header(openCasesCount: 2)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('2 cas ouverts'), findsOneWidget);
      expect(find.textContaining('Masculin'), findsOneWidget);
    });

    testWidgets(
      'rendu téléphone étroit (chip sous l\'identité) sans exception',
      (tester) async {
        await tester.pumpWidget(_wrap(header(openCasesCount: 2), width: 360));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('2 cas ouverts'), findsOneWidget);
      },
    );
  });
}
