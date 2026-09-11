import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/gender.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_entries_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/dashboard/enrollment_entries_section.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockBloc extends MockBloc<EnrollmentEntriesEvent, EnrollmentEntriesState>
    implements EnrollmentEntriesBloc {}

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

Future<_MockBloc> _pump(
  WidgetTester tester,
  EnrollmentEntriesState state, {
  String? schoolYear = '2026-2027',
}) async {
  final bloc = _MockBloc();
  whenListen(
    bloc,
    const Stream<EnrollmentEntriesState>.empty(),
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
            width: 1000,
            child: BlocProvider<EnrollmentEntriesBloc>.value(
              value: bloc,
              child: EnrollmentEntriesSection(schoolYear: schoolYear),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return bloc;
}

EnrollmentEntriesState _loaded(
  List<DayEnrollmentEntry> entries, {
  EnrollmentStatsWindow? window,
  int page = 0,
  int totalPages = 1,
  int? totalElements,
}) => EnrollmentEntriesState(
  status: EnrollmentEntriesStatus.success,
  window: window ?? EnrollmentStatsWindow.day(DateTime(2026, 9, 5)),
  entries: entries,
  page: page,
  totalElements: totalElements ?? entries.length,
  totalPages: totalPages,
);

void main() {
  group('la carte suit TOUTES les fenêtres', () {
    testWidgets('une semaine se liste, et se nomme', (tester) async {
      await _pump(
        tester,
        _loaded([_entry()], window: const EnrollmentStatsWindow.week()),
      );

      expect(find.text('Liste nominative des inscrits'), findsOneWidget);
      expect(find.text('Élèves inscrits cette semaine'), findsOneWidget);
    });

    testWidgets('le mois se nomme', (tester) async {
      await _pump(
        tester,
        _loaded([_entry()], window: const EnrollmentStatsWindow.month()),
      );

      expect(find.text('Élèves inscrits ce mois-ci'), findsOneWidget);
    });

    testWidgets('l\'année se NOMME, elle ne se borne pas', (tester) async {
      // La liste s'y cadre par année scolaire, pas par dates : deux bornes
      // annonceraient un périmètre qu'elle ne respecte pas.
      await _pump(
        tester,
        _loaded([_entry()], window: const EnrollmentStatsWindow.year()),
      );

      expect(
        find.text('Élèves inscrits sur l\'année scolaire 2026-2027'),
        findsOneWidget,
      );
    });

    testWidgets('sans année connue : depuis l\'ouverture', (tester) async {
      await _pump(
        tester,
        _loaded([_entry()], window: const EnrollmentStatsWindow.year()),
        schoolYear: null,
      );

      expect(
        find.text('Élèves inscrits depuis l\'ouverture des inscriptions'),
        findsOneWidget,
      );
    });

    testWidgets('une journée se nomme en toutes lettres', (tester) async {
      await _pump(tester, _loaded([_entry()]));

      expect(find.textContaining('Élèves inscrits le'), findsOneWidget);
      expect(find.textContaining('5 septembre 2026'), findsOneWidget);
    });

    testWidgets('une période libre porte ses deux bornes', (tester) async {
      await _pump(
        tester,
        _loaded(
          [_entry()],
          window: EnrollmentStatsWindow.custom(
            from: DateTime(2026, 9, 1),
            to: DateTime(2026, 9, 7),
          ),
        ),
      );

      expect(find.textContaining('Élèves inscrits du'), findsOneWidget);
    });

    testWidgets('une période libre d\'un seul jour se lit comme un jour', (
      tester,
    ) async {
      await _pump(
        tester,
        _loaded(
          [_entry()],
          window: EnrollmentStatsWindow.custom(
            from: DateTime(2026, 9, 5),
            to: DateTime(2026, 9, 5),
          ),
        ),
      );

      expect(find.textContaining('Élèves inscrits le'), findsOneWidget);
      expect(find.text('HEURE'), findsOneWidget);
    });
  });

  group('l\'heure sur un jour, la date au-delà', () {
    testWidgets('sur un jour : la colonne dit l\'heure', (tester) async {
      await _pump(tester, _loaded([_entry()]));

      expect(find.text('HEURE'), findsOneWidget);
      expect(find.text('DATE'), findsNothing);
      expect(find.textContaining('09:30'), findsOneWidget);
    });

    testWidgets('sur une semaine : la date administrative', (tester) async {
      // L'heure seule ne situerait plus la ligne sur sept jours.
      await _pump(
        tester,
        _loaded([
          _entry(
            enrollmentDate: DateTime(2026, 9, 3),
            createdAt: DateTime(2026, 9, 3, 9, 30),
          ),
        ], window: const EnrollmentStatsWindow.week()),
      );

      expect(find.text('DATE'), findsOneWidget);
      expect(find.text('HEURE'), findsNothing);
      expect(find.text('03/09/2026'), findsOneWidget);
      expect(find.textContaining('09:30'), findsNothing);
    });

    testWidgets('dossier antidaté sur un jour : un tiret, pas une heure', (
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

  testWidgets('plus de sortie locale : elle ne portait que la page visible', (
    tester,
  ) async {
    // Sur une année, le CSV aurait copié huit lignes sur des centaines, sans
    // rien qui le dise.
    await _pump(
      tester,
      _loaded([_entry()], window: const EnrollmentStatsWindow.month()),
    );

    expect(find.text('CSV'), findsNothing);
    expect(find.text('PDF'), findsNothing);
  });

  group('la pagination', () {
    testWidgets('l\'indicateur suit la page de l\'état', (tester) async {
      await _pump(
        tester,
        _loaded(
          [_entry()],
          window: const EnrollmentStatsWindow.year(),
          page: 1,
          totalPages: 3,
          totalElements: 20,
        ),
      );

      expect(find.text('Page 2 / 3'), findsOneWidget);
    });

    testWidgets('« suivant » demande la page d\'après', (tester) async {
      final bloc = await _pump(
        tester,
        _loaded(
          [_entry()],
          window: const EnrollmentStatsWindow.year(),
          page: 1,
          totalPages: 3,
          totalElements: 20,
        ),
      );

      await tester.tap(find.byTooltip('Page suivante'));

      verify(() => bloc.add(const EnrollmentEntriesPageChanged(2))).called(1);
    });

    testWidgets('« précédent » demande la page d\'avant', (tester) async {
      final bloc = await _pump(
        tester,
        _loaded(
          [_entry()],
          window: const EnrollmentStatsWindow.year(),
          page: 1,
          totalPages: 3,
          totalElements: 20,
        ),
      );

      await tester.tap(find.byTooltip('Page précédente'));

      verify(() => bloc.add(const EnrollmentEntriesPageChanged(0))).called(1);
    });

    testWidgets('une seule page : aucune pagination affichée', (tester) async {
      await _pump(tester, _loaded([_entry()]));

      expect(find.byTooltip('Page suivante'), findsNothing);
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
    testWidgets('fenêtre sans inscription : rien du tout', (tester) async {
      await _pump(
        tester,
        const EnrollmentEntriesState(status: EnrollmentEntriesStatus.empty),
      );

      expect(find.text('Liste nominative des inscrits'), findsNothing);
    });

    testWidgets('état initial : rien non plus', (tester) async {
      await _pump(tester, const EnrollmentEntriesState());

      expect(find.text('Liste nominative des inscrits'), findsNothing);
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
        const EnrollmentEntriesState(
          status: EnrollmentEntriesStatus.error,
          window: EnrollmentStatsWindow.week(),
          failure: UnauthorizedFailure('403'),
        ),
      );

      expect(find.text('Liste nominative des inscrits'), findsOneWidget);
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
        const EnrollmentEntriesState(
          status: EnrollmentEntriesStatus.error,
          window: EnrollmentStatsWindow.week(),
          failure: NetworkFailure('coupure'),
        ),
      );

      expect(find.textContaining('n\'a pas pu être chargée'), findsOneWidget);
      expect(find.textContaining('pilotage reste accessible'), findsNothing);
    });
  });
}
