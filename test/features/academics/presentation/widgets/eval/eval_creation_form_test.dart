import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select_input.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/chapitre_option.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/cours_notation_detail.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/create_evaluation_request.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/evaluation_groupe.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/evaluation_summary.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/examen_notation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/ligne_bareme_plafonds.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/periode_notation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/sous_periode_notation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_periode.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_saisie_evaluation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/type_evaluation.dart';
import 'package:school_app_flutter/features/academics/domain/usecases/create_evaluation_usecase.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/create_evaluation_bloc.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/eval/eval_creation_form.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class MockCreateEvaluationUseCase extends Mock
    implements CreateEvaluationUseCase {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      CreateEvaluationRequest.journaliere(
        type: TypeEvaluation.interro,
        date: DateTime.utc(2026, 1, 1),
        maxPoints: 10,
        sousPeriodeId: 'sp1',
      ),
    );
  });

  SousPeriodeNotation sp(
    String id,
    int ordre, {
    StatutPeriode statut = StatutPeriode.ouverte,
  }) => SousPeriodeNotation(
    sousPeriodeId: id,
    ordre: ordre,
    statut: statut,
    nombreElevesNotes: 0,
    nombreEleves50: 0,
    moyennesEleves: const [],
    evaluationsParType: const [],
  );

  final detail = CoursNotationDetail(
    coursId: 'c1',
    classroomId: 'cl1',
    brancheNom: 'Mathématiques',
    effectif: 28,
    periodes: [
      PeriodeNotation(
        periodeScolaireId: 'p1',
        ordre: 1,
        statut: StatutPeriode.ouverte,
        sousPeriodes: [sp('sp1', 1), sp('sp2', 2)],
      ),
      PeriodeNotation(
        periodeScolaireId: 'p2',
        ordre: 2,
        statut: StatutPeriode.ouverte,
        sousPeriodes: [sp('sp3', 1), sp('sp4', 2)],
      ),
    ],
  );

  Widget host([CoursNotationDetail? override]) => MaterialApp(
    locale: const Locale('fr'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SingleChildScrollView(
        child: BlocProvider<CreateEvaluationBloc>(
          create: (_) => CreateEvaluationBloc(
            createEvaluationUseCase: MockCreateEvaluationUseCase(),
          ),
          child: EvalCreationForm(
            detail: override ?? detail,
            classroomName: '6e A',
          ),
        ),
      ),
    ),
  );

  testWidgets('défauts INTERRO (max 10) + accroche effectif', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    expect(find.text('10'), findsOneWidget); // max par défaut interro
    expect(find.textContaining('28 élèves de 6e A'), findsOneWidget);
    // Sous-période active par défaut.
    expect(find.text('Examen semestriel'), findsNothing);
  });

  testWidgets(
    'EXAMEN : applique max 40 et désactive la sous-période (placeholder)',
    (tester) async {
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Examen'));
      await tester.pumpAndSettle();

      expect(find.text('40'), findsOneWidget); // défaut examen
      expect(find.text('Examen semestriel'), findsOneWidget);
    },
  );

  const closedError =
      "Période clôturée : impossible d'y ajouter une évaluation.";

  CoursNotationDetail detailWith(
    StatutPeriode periodeStatut,
    StatutPeriode sousPeriodeStatut,
  ) => CoursNotationDetail(
    coursId: 'c1',
    classroomId: 'cl1',
    brancheNom: 'Mathématiques',
    effectif: 28,
    periodes: [
      PeriodeNotation(
        periodeScolaireId: 'p1',
        ordre: 1,
        statut: periodeStatut,
        sousPeriodes: [sp('sp1', 1, statut: sousPeriodeStatut)],
      ),
    ],
  );

  EteeloButton submitButton(WidgetTester tester) => tester.widget<EteeloButton>(
    find.widgetWithText(EteeloButton, "Créer l'évaluation"),
  );

  testWidgets('période scolaire clôturée : bloque + message', (tester) async {
    await tester.pumpWidget(
      host(detailWith(StatutPeriode.cloturee, StatutPeriode.cloturee)),
    );
    await tester.pumpAndSettle();

    expect(find.text(closedError), findsOneWidget);
    expect(submitButton(tester).onPressed, isNull);
  });

  testWidgets('sous-période clôturée (période ouverte) : bloque aussi', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(detailWith(StatutPeriode.ouverte, StatutPeriode.cloturee)),
    );
    await tester.pumpAndSettle();

    expect(find.text(closedError), findsOneWidget);
    expect(submitButton(tester).onPressed, isNull);
  });

  testWidgets('tout ouvert + champs valides : bouton actif, aucun blocage', (
    tester,
  ) async {
    await tester.pumpWidget(host()); // détail par défaut : périodes ouvertes
    await tester.pumpAndSettle();

    expect(find.text(closedError), findsNothing);
    expect(submitButton(tester).onPressed, isNotNull);
  });

  testWidgets('période CLOTUREE : item du picker grisé (enabled=false), pas '
      'seulement bloqué après coup par errorText/submit', (tester) async {
    await tester.pumpWidget(
      host(detailWith(StatutPeriode.cloturee, StatutPeriode.ouverte)),
    );
    await tester.pumpAndSettle();

    final periodeInput = tester
        .widgetList<EteeloSelectInput<String>>(
          find.byType(EteeloSelectInput<String>),
        )
        .first;
    expect(periodeInput.items.single.enabled, isFalse);
  });

  testWidgets(
    'sous-période CLOTUREE (période ouverte) : item du picker grisé',
    (tester) async {
      await tester.pumpWidget(
        host(detailWith(StatutPeriode.ouverte, StatutPeriode.cloturee)),
      );
      await tester.pumpAndSettle();

      final sousPeriodeInput = tester
          .widgetList<EteeloSelectInput<String>>(
            find.byType(EteeloSelectInput<String>),
          )
          .last;
      expect(sousPeriodeInput.items.single.enabled, isFalse);
    },
  );

  testWidgets('tout ouvert : items du picker restent activés', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    final inputs = tester.widgetList<EteeloSelectInput<String>>(
      find.byType(EteeloSelectInput<String>),
    );
    for (final input in inputs) {
      for (final item in input.items) {
        expect(item.enabled, isTrue);
      }
    }
  });

  group('chapitres (bundle grades-referential)', () {
    testWidgets('bundle sans chapitre pour ce cours : message vide', (
      tester,
    ) async {
      await tester.pumpWidget(host()); // détail par défaut : aucun chapitre
      await tester.pumpAndSettle();

      expect(
        find.text('Aucun chapitre disponible pour ce cours'),
        findsOneWidget,
      );
      expect(find.byType(FilterChip), findsNothing);
    });

    testWidgets('chapitres disponibles : cochables, sélection transmise à la '
        'soumission', (tester) async {
      final useCase = MockCreateEvaluationUseCase();
      when(
        () => useCase.call(any(), any()),
      ).thenAnswer((_) async => const Left(ServerFailure('n/a')));

      final detailWithChapitres = CoursNotationDetail(
        coursId: 'c1',
        classroomId: 'cl1',
        brancheNom: 'Mathématiques',
        effectif: 28,
        periodes: detail.periodes,
        chapitresDisponibles: const [
          ChapitreOption(id: 'ch1', titre: 'Fractions', ordre: 1),
          ChapitreOption(id: 'ch2', titre: 'Géométrie', ordre: 2),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: BlocProvider<CreateEvaluationBloc>(
                create: (_) =>
                    CreateEvaluationBloc(createEvaluationUseCase: useCase),
                child: EvalCreationForm(
                  detail: detailWithChapitres,
                  classroomName: '6e A',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FilterChip), findsNWidgets(2));
      await tester.tap(find.text('Fractions'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(EteeloButton, "Créer l'évaluation"));
      await tester.pumpAndSettle();

      final captured =
          verify(() => useCase.call(any(), captureAny())).captured.single
              as CreateEvaluationRequest;
      expect(captured.chapitreIds, ['ch1']);
    });
  });

  group('prévention plafonds (bundle grades-referential)', () {
    testWidgets(
      'EXAMEN grisé si maxExamenParPeriodeScolaire est null (branche sans '
      'examen) : le tap ne bascule pas le type',
      (tester) async {
        final detailNoExamen = CoursNotationDetail(
          coursId: 'c1',
          classroomId: 'cl1',
          effectif: 28,
          periodes: detail.periodes,
          plafonds: const LigneBaremePlafonds(maxJournalierParSousPeriode: 5),
        );
        await tester.pumpWidget(host(detailNoExamen));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Examen'));
        await tester.pumpAndSettle();

        // Toujours sur INTERRO : le placeholder examen n'apparaît pas, le
        // défaut de barème reste celui de l'interro (10).
        expect(find.text('Examen semestriel'), findsNothing);
        expect(find.text('10'), findsOneWidget);
      },
    );

    testWidgets(
      'plafond journalier atteint : blocage + message, indépendant de la '
      'clôture',
      (tester) async {
        final today = DateTime.now();
        final todayUtc = DateTime.utc(today.year, today.month, today.day);
        final detailAtCap = CoursNotationDetail(
          coursId: 'c1',
          classroomId: 'cl1',
          effectif: 28,
          plafonds: const LigneBaremePlafonds(maxJournalierParSousPeriode: 1),
          periodes: [
            PeriodeNotation(
              periodeScolaireId: 'p1',
              ordre: 1,
              statut: StatutPeriode.ouverte,
              sousPeriodes: [
                SousPeriodeNotation(
                  sousPeriodeId: 'sp1',
                  ordre: 1,
                  statut: StatutPeriode.ouverte,
                  nombreElevesNotes: 0,
                  nombreEleves50: 0,
                  moyennesEleves: const [],
                  evaluationsParType: [
                    EvaluationGroupe(
                      type: TypeEvaluation.interro,
                      evaluations: [
                        EvaluationSummary(
                          id: 'ev-existing',
                          type: TypeEvaluation.interro,
                          nom: 'Interro 1',
                          chapitres: const [],
                          date: todayUtc,
                          maxPoints: 10,
                          poids: 1,
                          statutSaisie: StatutSaisieEvaluation.nonSaisie,
                          pourcentageSaisie: 0,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        );

        await tester.pumpWidget(host(detailAtCap));
        await tester.pumpAndSettle();

        expect(
          find.text('Plafond de saisie atteint pour cette date.'),
          findsOneWidget,
        );
        expect(submitButton(tester).onPressed, isNull);
      },
    );

    testWidgets(
      'plafond examen atteint (un examen déjà rattaché à la période)',
      (tester) async {
        final detailExamCap = CoursNotationDetail(
          coursId: 'c1',
          classroomId: 'cl1',
          effectif: 28,
          plafonds: const LigneBaremePlafonds(
            maxJournalierParSousPeriode: 5,
            maxExamenParPeriodeScolaire: 1,
          ),
          periodes: [
            PeriodeNotation(
              periodeScolaireId: 'p1',
              ordre: 1,
              statut: StatutPeriode.ouverte,
              sousPeriodes: [sp('sp1', 1)],
              examen: ExamenNotation(
                evaluationId: 'ev-exam',
                nom: 'Examen',
                date: DateTime.utc(2026, 1, 1),
                poids: 1,
                maxPoints: 40,
                statutSaisie: StatutSaisieEvaluation.nonSaisie,
                pourcentageSaisie: 0,
              ),
            ),
          ],
        );

        await tester.pumpWidget(host(detailExamCap));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Examen'));
        await tester.pumpAndSettle();

        expect(
          find.text('Plafond de saisie atteint pour cette date.'),
          findsOneWidget,
        );
        expect(submitButton(tester).onPressed, isNull);
      },
    );
  });
}
