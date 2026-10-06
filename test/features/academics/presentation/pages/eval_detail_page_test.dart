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
import 'package:school_app_flutter/features/academics/presentation/bloc/eval_detail/eval_detail_bloc.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/academics_notation_visuals.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/cours_notation_view_model.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/eval_detail_args.dart';
import 'package:school_app_flutter/features/academics/presentation/pages/eval_detail_page.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockGetSujet extends Mock implements GetEvaluationSujetUseCase {}

class _MockGetNotes extends Mock implements GetNotesElevesUseCase {}

void main() {
  final getIt = GetIt.instance;
  late _MockGetSujet getSujet;
  late _MockGetNotes getNotes;

  setUp(() {
    getSujet = _MockGetSujet();
    getNotes = _MockGetNotes();
    getIt.registerFactory<EvalDetailBloc>(
      () => EvalDetailBloc(
        getEvaluationSujetUseCase: getSujet,
        getNotesElevesUseCase: getNotes,
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
            onOpenSaisie: () => opened = true,
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
}
