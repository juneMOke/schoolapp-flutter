import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/note_eleve.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_note.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/type_evaluation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/evaluation_cadre.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/evaluation_sujet.dart';
import 'package:school_app_flutter/features/academics/domain/usecases/get_notes_eleves_usecase.dart';
import 'package:school_app_flutter/features/academics/domain/usecases/sujet/get_evaluation_sujet_usecase.dart';
import 'package:school_app_flutter/features/academics/domain/usecases/sujet/resend_sujet_without_max_usecase.dart';
import 'package:school_app_flutter/features/academics/domain/usecases/sujet/save_evaluation_sujet_usecase.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/sujet_question.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:uuid/uuid.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/eval_detail/eval_detail_bloc.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/copie/copie_bloc.dart';
import 'package:school_app_flutter/features/academics/domain/usecases/sujet/get_copie_log_usecase.dart';
import 'package:school_app_flutter/features/academics/domain/usecases/sujet/log_copie_diffusion_usecase.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/academics_notation_visuals.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/cours_notation_view_model.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/eval_detail_args.dart';
import 'package:school_app_flutter/features/academics/presentation/pages/eval_detail_page.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockGetSujet extends Mock implements GetEvaluationSujetUseCase {}

class _MockGetNotes extends Mock implements GetNotesElevesUseCase {}

class _MockSaveSujet extends Mock implements SaveEvaluationSujetUseCase {}

class _MockResend extends Mock implements ResendSujetWithoutMaxUseCase {}

class _MockGetLog extends Mock implements GetCopieLogUseCase {}

class _MockLog extends Mock implements LogCopieDiffusionUseCase {}

void main() {
  final getIt = GetIt.instance;
  late _MockGetSujet getSujet;
  late _MockGetNotes getNotes;
  late _MockSaveSujet saveSujet;

  setUp(() {
    getSujet = _MockGetSujet();
    getNotes = _MockGetNotes();
    saveSujet = _MockSaveSujet();
    getIt.registerFactory<EvalDetailBloc>(
      () => EvalDetailBloc(
        getEvaluationSujetUseCase: getSujet,
        getNotesElevesUseCase: getNotes,
        saveEvaluationSujetUseCase: saveSujet,
        resendSujetWithoutMaxUseCase: _MockResend(),
      ),
    );
    getIt.registerSingleton<IdGenerator>(const IdGenerator(Uuid()));
    final getLog = _MockGetLog();
    when(() => getLog(any())).thenAnswer((_) async => const Right([]));
    getIt.registerFactory<CopieBloc>(
      () => CopieBloc(
        getCopieLogUseCase: getLog,
        logCopieDiffusionUseCase: _MockLog(),
      ),
    );
  });
  tearDown(() => getIt.reset());

  final args = EvalDetailArgs(
    brancheNom: 'Chimie',
    classroomName: '7e A',
    rattachementLabel: 'Semestre 1 · Période 2',
    eval: EvalVm(
      id: 'e1',
      type: TypeEvaluation.interro,
      nom: 'Interrogation 2',
      chapitres: const [],
      date: DateTime(2026, 6, 18),
      maxPoints: 10,
      poids: 1,
      state: EvalState.upcoming,
      pourcentageSaisie: 0,
      saisies: 0,
      total: 2,
    ),
  );

  testWidgets(
    'en-tête avec la durée, avancement relu, ouverture de la saisie',
    (tester) async {
      when(() => getSujet('e1')).thenAnswer(
        (_) async => const Right(
          EvaluationSujet(cadre: EvaluationCadre(dureeMinutes: 30)),
        ),
      );
      when(() => getNotes('e1')).thenAnswer(
        (_) async => const Right([
          NoteEleve(
            studentId: 's1',
            firstName: 'Daniel',
            lastName: 'Kabongo',
            statut: StatutNote.notee,
            pointsObtenus: 8,
          ),
          NoteEleve(studentId: 's2', firstName: 'Grâce', lastName: 'Tshala'),
        ]),
      );
      var opened = false;
      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

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
          home: EvalDetailPage(
            args: args,
            onBack: () {},
            onOpenSaisie: (_) => opened = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Durée : 30 min'), findsOneWidget);
      expect(find.text('1 / 2 notes saisies'), findsOneWidget);

      await tester.tap(find.text('Saisie des notes'));
      expect(opened, isTrue);
    },
  );

  testWidgets(
    'rédiger le sujet : une question, enregistrer, retour en lecture',
    (tester) async {
      registerFallbackValue(const EvaluationCadre());
      when(
        () => getSujet('e1'),
      ).thenAnswer((_) async => const Right(EvaluationSujet()));
      when(() => getNotes('e1')).thenAnswer((_) async => const Right([]));
      when(
        () => saveSujet(
          'e1',
          cadre: any(named: 'cadre'),
          questions: any(named: 'questions'),
          maxPoints: any(named: 'maxPoints'),
        ),
      ).thenAnswer((invocation) async {
        final questions =
            invocation.namedArguments[#questions] as List<SujetQuestion>;
        return Right(EvaluationSujet(questions: questions));
      });
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

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
          home: EvalDetailPage(args: args, onBack: () {}, onOpenSaisie: (_) {}),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Rédiger le sujet'));
      await tester.pumpAndSettle();
      // Rien n'est modifié : « Fermer », et l'enregistrement est désactivé.
      expect(find.text('Fermer'), findsOneWidget);

      await tester.tap(find.text('Ajouter la première question'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.bySemanticsLabel('Énoncé de la question 1'),
        'Équilibrez la réaction.',
      );
      await tester.enterText(
        find.bySemanticsLabel('Points de la question 1'),
        '10',
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Barème complet'), findsOneWidget);

      await tester.tap(find.text('Enregistrer le sujet'));
      await tester.pumpAndSettle();

      final captured =
          verify(
                () => saveSujet(
                  'e1',
                  cadre: any(named: 'cadre'),
                  questions: captureAny(named: 'questions'),
                  maxPoints: any(named: 'maxPoints'),
                ),
              ).captured.single
              as List<SujetQuestion>;
      expect(captured.single.enonce, 'Équilibrez la réaction.');
      expect(captured.single.points, 10);
      // Retour en lecture, toast récapitulatif.
      expect(find.text('Modifier'), findsOneWidget);
      expect(
        find.text('Sujet enregistré — 1 question · 10 / 10 pts'),
        findsOneWidget,
      );
    },
  );
}
