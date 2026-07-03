import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/cours_notation_detail.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/periode_notation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/sous_periode_notation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_periode.dart';
import 'package:school_app_flutter/features/academics/domain/usecases/create_evaluation_usecase.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/create_evaluation_bloc.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/eval/eval_creation_form.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class MockCreateEvaluationUseCase extends Mock
    implements CreateEvaluationUseCase {}

void main() {
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
}
