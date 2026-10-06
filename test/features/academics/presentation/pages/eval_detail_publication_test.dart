import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/note_eleve.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_note.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/type_evaluation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/evaluation_publication.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/evaluation_sujet.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/publication_context.dart';
import 'package:school_app_flutter/features/academics/domain/usecases/get_notes_eleves_usecase.dart';
import 'package:school_app_flutter/features/academics/domain/usecases/sujet/get_copie_log_usecase.dart';
import 'package:school_app_flutter/features/academics/domain/usecases/sujet/get_evaluation_sujet_usecase.dart';
import 'package:school_app_flutter/features/academics/domain/usecases/sujet/log_copie_diffusion_usecase.dart';
import 'package:school_app_flutter/features/academics/domain/usecases/sujet/publication_usecases.dart';
import 'package:school_app_flutter/features/academics/domain/usecases/sujet/resend_sujet_without_max_usecase.dart';
import 'package:school_app_flutter/features/academics/domain/usecases/sujet/save_evaluation_sujet_usecase.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/copie/copie_bloc.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/eval_detail/eval_detail_bloc.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/publication/publication_bloc.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/academics_notation_visuals.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/cours_notation_view_model.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/eval_detail_args.dart';
import 'package:school_app_flutter/features/academics/presentation/pages/eval_detail_page.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _GetSujet extends Mock implements GetEvaluationSujetUseCase {}

class _GetNotes extends Mock implements GetNotesElevesUseCase {}

class _GetLog extends Mock implements GetCopieLogUseCase {}

class _GetContext extends Mock implements GetPublicationContextUseCase {}

class _Publish extends Mock implements PublishEvaluationUseCase {}

void main() {
  final getIt = GetIt.instance;
  late _GetNotes getNotes;
  late _GetContext getContext;
  late _Publish publish;

  setUpAll(() => registerFallbackValue(PublicationKind.notes));

  setUp(() {
    final getSujet = _GetSujet();
    when(
      () => getSujet(any()),
    ).thenAnswer((_) async => const Right(EvaluationSujet()));
    getNotes = _GetNotes();
    getContext = _GetContext();
    publish = _Publish();
    final getLog = _GetLog();
    when(() => getLog(any())).thenAnswer((_) async => const Right([]));
    getIt
      ..registerFactory<EvalDetailBloc>(
        () => EvalDetailBloc(
          getEvaluationSujetUseCase: getSujet,
          getNotesElevesUseCase: getNotes,
          saveEvaluationSujetUseCase: _Save(),
          resendSujetWithoutMaxUseCase: _Resend(),
        ),
      )
      ..registerFactory<CopieBloc>(
        () => CopieBloc(
          getCopieLogUseCase: getLog,
          logCopieDiffusionUseCase: _Log(),
        ),
      )
      ..registerFactory<PublicationBloc>(
        () => PublicationBloc(
          getPublicationContextUseCase: getContext,
          publishEvaluationUseCase: publish,
          withdrawPublicationUseCase: _Withdraw(),
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
      state: EvalState.complete,
      pourcentageSaisie: 100,
      saisies: 2,
      total: 2,
    ),
  );

  Future<void> pump(WidgetTester tester) async {
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
  }

  void allNotesEntered() => when(() => getNotes('e1')).thenAnswer(
    (_) async => const Right([
      NoteEleve(
        studentId: 's1',
        firstName: 'A',
        lastName: 'B',
        statut: StatutNote.notee,
      ),
      NoteEleve(
        studentId: 's2',
        firstName: 'C',
        lastName: 'D',
        statut: StatutNote.absentJustifie,
      ),
    ]),
  );

  testWidgets('toutes les notes posées : confirmer puis « Notes publiées »', (
    tester,
  ) async {
    allNotesEntered();
    when(
      () => getContext('e1'),
    ).thenAnswer((_) async => const Right(PublicationContext()));
    when(() => publish('e1', PublicationKind.notes)).thenAnswer(
      (_) async =>
          Right(PublicationEtat(publishedAt: DateTime.utc(2026, 10, 6))),
    );
    await pump(tester);

    expect(find.text('Prêtes à être publiées'), findsOneWidget);
    await tester.tap(find.text('Publier les notes'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('aux parents des 2 élèves de 7e A'),
      findsOneWidget,
    );
    await tester.tap(find.text('Publier').last);
    await tester.pumpAndSettle();

    verify(() => publish('e1', PublicationKind.notes)).called(1);
    expect(find.text('Notes publiées'), findsOneWidget);
  });

  testWidgets('des notes en file : la publication attend', (tester) async {
    allNotesEntered();
    when(() => getContext('e1')).thenAnswer(
      (_) async => const Right(PublicationContext(notesPending: true)),
    );
    await pump(tester);

    await tester.tap(find.text('Publier les notes'));
    await tester.pumpAndSettle();
    verifyNever(() => publish(any(), any()));
  });
}

class _Save extends Mock implements SaveEvaluationSujetUseCase {}

class _Resend extends Mock implements ResendSujetWithoutMaxUseCase {}

class _Log extends Mock implements LogCopieDiffusionUseCase {}

class _Withdraw extends Mock implements WithdrawPublicationUseCase {}
