import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/gender.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_day_entries_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/dashboard/enrollment_day_entries_section.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockBloc
    extends MockBloc<EnrollmentDayEntriesEvent, EnrollmentDayEntriesState>
    implements EnrollmentDayEntriesBloc {}

DayEnrollmentEntry _entry({
  String id = 'e1',
  Gender gender = Gender.female,
  bool formerStudent = false,
  DateTime? enrollmentDate,
  DateTime? createdAt,
  String? recordedBy = 'M. Ilunga',
}) => DayEnrollmentEntry(
  enrollmentId: id,
  studentId: 's-$id',
  firstName: 'Amina',
  lastName: 'KABILA',
  surname: 'Nsimba',
  gender: gender,
  schoolLevelId: 'lvl',
  schoolLevel: '6e année',
  cycle: 'PRIMARY',
  formerStudent: formerStudent,
  enrollmentDate: enrollmentDate ?? DateTime(2026, 9, 5),
  createdAt: createdAt ?? DateTime(2026, 9, 5, 9, 30),
  recordedBy: recordedBy,
);

Future<void> _pump(
  WidgetTester tester,
  EnrollmentDayEntriesState state, {
  double width = 1000,
  String? schoolYear = '2026-2027',
  DateTime? generatedAt,
}) async {
  final bloc = _MockBloc();
  whenListen(
    bloc,
    const Stream<EnrollmentDayEntriesState>.empty(),
    initialState: state,
  );
  addTearDown(bloc.close);

  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('fr'),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(
            width: width,
            child: BlocProvider<EnrollmentDayEntriesBloc>.value(
              value: bloc,
              child: EnrollmentDayEntriesSection(
                schoolYear: schoolYear,
                generatedAt: generatedAt ?? DateTime(2026, 9, 5),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

EnrollmentDayEntriesState _loaded(List<DayEnrollmentEntry> entries) =>
    EnrollmentDayEntriesState(
      status: EnrollmentDayEntriesStatus.success,
      day: DateTime(2026, 9, 5),
      entries: entries,
      totalElements: entries.length,
      totalPages: 1,
    );

void main() {
  group('exports de la carte du jour', () {
    testWidgets('la carte porte SES DEUX boutons, PDF et CSV', (tester) async {
      await _pump(tester, _loaded([_entry()]));

      expect(find.text('PDF'), findsOneWidget);
      expect(find.text('CSV'), findsOneWidget);
    });

    testWidgets('les deux glyphes restent distincts', (tester) async {
      // Le porteur produit veut le glyphe de téléchargement sur le PDF ; le
      // CSV garde son tableur. Deux glyphes identiques auraient refait
      // l'erreur des cinq calendriers des onglets de période.
      await _pump(tester, _loaded([_entry()]));

      expect(find.byIcon(Icons.download_outlined), findsOneWidget);
      expect(find.byIcon(Icons.table_view_outlined), findsOneWidget);
    });

    testWidgets('sans année scolaire, le PDF ne s\'offre pas', (tester) async {
      // Le pied du document porte le périmètre : une feuille nominative sans
      // année ni date ne dit plus de quoi elle parle.
      await _pump(tester, _loaded([_entry()]), schoolYear: null);

      expect(find.text('PDF'), findsNothing);
      expect(find.text('CSV'), findsOneWidget);
    });
  });
  testWidgets('le sexe est ÉCRIT, jamais porté par la seule couleur', (
    tester,
  ) async {
    await _pump(tester, _loaded([_entry(gender: Gender.female)]));

    expect(find.text('KABILA Nsimba Amina'), findsOneWidget);
    expect(find.text('Filles'), findsOneWidget);
  });

  testWidgets('le type est une pastille lisible, pas une teinte', (
    tester,
  ) async {
    await _pump(tester, _loaded([_entry(formerStudent: true)]));

    expect(find.text('Réinscription'), findsOneWidget);
  });

  group('l\'heure vient de createdAt, et se tait quand elle mentirait', () {
    testWidgets('même jour : l\'heure s\'affiche', (tester) async {
      await _pump(
        tester,
        _loaded([
          _entry(
            enrollmentDate: DateTime(2026, 9, 5),
            createdAt: DateTime(2026, 9, 5, 9, 30),
          ),
        ]),
      );

      expect(find.textContaining('09:30'), findsOneWidget);
    });

    testWidgets('dossier antidaté : un tiret, jamais une heure fausse', (
      tester,
    ) async {
      // Saisi le 6 au soir pour une inscription datée du 5 : l'heure de saisie
      // ne dit rien de la journée que la liste prétend montrer.
      await _pump(
        tester,
        _loaded([
          _entry(
            enrollmentDate: DateTime(2026, 9, 5),
            createdAt: DateTime(2026, 9, 6, 21, 15),
          ),
        ]),
      );

      expect(find.textContaining('21:15'), findsNothing);
      expect(find.text('—'), findsOneWidget);
    });
  });

  testWidgets('agent inconnu : un tiret, pas une attribution inventée', (
    tester,
  ) async {
    await _pump(tester, _loaded([_entry(recordedBy: null)]));

    expect(find.text('—'), findsOneWidget);
  });

  testWidgets('agent connu : son NOM, pas son identifiant', (tester) async {
    await _pump(tester, _loaded([_entry(recordedBy: 'M. Ilunga')]));

    expect(find.text('M. Ilunga'), findsOneWidget);
  });

  group('la carte n\'existe pas toujours', () {
    testWidgets('journée sans inscription : rien du tout', (tester) async {
      await _pump(
        tester,
        const EnrollmentDayEntriesState(
          status: EnrollmentDayEntriesStatus.empty,
        ),
      );

      expect(find.text('Liste nominative du jour'), findsNothing);
    });

    testWidgets('état initial : rien non plus', (tester) async {
      await _pump(tester, const EnrollmentDayEntriesState());

      expect(find.text('Liste nominative du jour'), findsNothing);
    });
  });

  group('l\'erreur de la liste reste DANS la carte', () {
    testWidgets('403 : le message dit que le pilotage reste accessible', (
      tester,
    ) async {
      // Un utilisateur qui a le pilotage mais pas la lecture des dossiers :
      // l'agrégat lui a répondu 200, seule cette liste lui est refusée.
      await _pump(
        tester,
        const EnrollmentDayEntriesState(
          status: EnrollmentDayEntriesStatus.error,
          failure: UnauthorizedFailure('403'),
        ),
      );

      expect(find.text('Liste nominative du jour'), findsOneWidget);
      expect(
        find.textContaining('Le pilotage reste accessible'),
        findsOneWidget,
      );
    });

    testWidgets('panne réseau : un message distinct du refus de droit', (
      tester,
    ) async {
      await _pump(
        tester,
        const EnrollmentDayEntriesState(
          status: EnrollmentDayEntriesStatus.error,
          failure: NetworkFailure('coupure'),
        ),
      );

      expect(find.textContaining('n\'a pas pu être chargée'), findsOneWidget);
      expect(find.textContaining('pilotage reste accessible'), findsNothing);
    });
  });

  testWidgets('une seule page : aucune pagination affichée', (tester) async {
    await _pump(tester, _loaded([_entry()]));

    expect(find.byIcon(Icons.chevron_right), findsNothing);
  });
}
