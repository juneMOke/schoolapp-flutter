import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/cours_notation_detail.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/evaluation_groupe.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/evaluation_summary.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/periode_notation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/sous_periode_notation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_periode.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_saisie_evaluation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/type_evaluation.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/cours_notation_bloc.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/cours_notation_event.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/cours_notation_state.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/academics_class_visual.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/cours_detail_args.dart';
import 'package:school_app_flutter/features/academics/presentation/pages/cours_notation_detail_page.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/detail/cours_bucket_panel.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

class _MockCoursNotationBloc
    extends MockBloc<CoursNotationEvent, CoursNotationState>
    implements CoursNotationBloc {}

/// ADR-015 §6-B, second niveau — la grille de saisie est NOMINATIVE : elle liste
/// chaque élève de la classe et ses notes. Elle n'était gardée que sur
/// l'ÉCRITURE (`academics.grade.write` sur le FAB et le bouton Enregistrer) ;
/// rien ne gardait sa LECTURE.
///
/// La garde est posée sur la page partagée, donc elle protège les DEUX portes
/// d'entrée : « Mes cours » et l'emploi du temps.
void main() {
  const enseignant = <String>['academics.course.read', 'academics.grade.read'];
  const sansNotes = <String>['academics.course.read'];

  final detail = CoursNotationDetail(
    coursId: 'cours-1',
    classroomId: 'class-1',
    brancheNom: 'Mathématiques',
    effectif: 30,
    periodes: [
      PeriodeNotation(
        periodeScolaireId: 'per-1',
        ordre: 1,
        statut: StatutPeriode.ouverte,
        sousPeriodes: [
          SousPeriodeNotation(
            sousPeriodeId: 'sp-1',
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
                    id: 'eval-1',
                    type: TypeEvaluation.interro,
                    nom: 'Interrogation du 2026-05-04',
                    chapitres: const [],
                    date: DateTime(2026, 5, 4),
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

  late _MockCoursNotationBloc coursBloc;

  setUp(() {
    coursBloc = _MockCoursNotationBloc();
    final state = CoursNotationState(
      status: CoursNotationStatus.success,
      detail: detail,
    );
    when(() => coursBloc.state).thenReturn(state);
    whenListen(
      coursBloc,
      Stream<CoursNotationState>.value(state),
      initialState: state,
    );
    GetIt.I.registerFactory<CoursNotationBloc>(() => coursBloc);
  });

  tearDown(() => GetIt.I.reset());

  Widget host(List<String> permissions) {
    final authBloc = _MockAuthBloc();
    final authState = AuthState(
      status: AuthStatus.authenticated,
      permissions: permissions,
    );
    when(() => authBloc.state).thenReturn(authState);
    whenListen(
      authBloc,
      Stream<AuthState>.value(authState),
      initialState: authState,
    );

    return MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: CoursNotationDetailPage(
          args: CoursDetailArgs(
            coursId: 'cours-1',
            brancheNom: 'Mathématiques',
            classroomName: '6e A',
            visual: AcademicsClassVisual.forIndex(0),
          ),
          onBack: () {},
        ),
      ),
    );
  }

  testWidgets('avec academics.grade.read : la ligne ouvre la saisie', (
    tester,
  ) async {
    await tester.pumpWidget(host(enseignant));
    await tester.pump();

    final panel = tester.widget<CoursBucketPanel>(
      find.byType(CoursBucketPanel),
    );
    expect(panel.onOpenEval, isNotNull);
  });

  testWidgets('sans academics.grade.read : les évaluations restent listées, '
      'mais aucune ne mène à la grille nominative', (tester) async {
    await tester.pumpWidget(host(sansNotes));
    await tester.pump();

    // Le panneau est bien rendu — on ne prive pas le profil du détail du cours…
    final panel = tester.widget<CoursBucketPanel>(
      find.byType(CoursBucketPanel),
    );
    // … mais la porte vers la saisie est fermée.
    expect(panel.onOpenEval, isNull);
  });
}
