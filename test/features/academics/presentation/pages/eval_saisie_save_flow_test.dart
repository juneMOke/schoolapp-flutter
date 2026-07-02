import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/note_eleve.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/note_evaluation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/saisir_note_request.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_note.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/type_evaluation.dart';
import 'package:school_app_flutter/features/academics/domain/usecases/get_notes_eleves_usecase.dart';
import 'package:school_app_flutter/features/academics/domain/usecases/saisir_note_usecase.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/saisie_notes_bloc.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/academics_notation_visuals.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/cours_notation_view_model.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/eval_detail_args.dart';
import 'package:school_app_flutter/features/academics/presentation/pages/eval_saisie_page.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockGetNotes extends Mock implements GetNotesElevesUseCase {}

class _MockSaisir extends Mock implements SaisirNoteUseCase {}

void main() {
  final getIt = GetIt.instance;
  late _MockGetNotes mockGet;
  late _MockSaisir mockSaisir;

  setUpAll(() {
    registerFallbackValue(
      SaisirNoteRequest.forStatut(studentId: 'x', statut: StatutNote.enAttente),
    );
  });

  setUp(() {
    mockGet = _MockGetNotes();
    mockSaisir = _MockSaisir();
    getIt.registerFactory<SaisieNotesBloc>(
      () => SaisieNotesBloc(
        getNotesElevesUseCase: mockGet,
        saisirNoteUseCase: mockSaisir,
      ),
    );
  });

  tearDown(() => getIt.reset());

  final args = EvalDetailArgs(
    brancheNom: 'Mathématiques',
    classroomName: '6e A',
    rattachementLabel: 'Période 1 · Sous-période 1',
    eval: EvalVm(
      id: 'e1',
      type: TypeEvaluation.interro,
      nom: 'Interrogation 1',
      chapitres: const [],
      date: DateTime(2026, 6, 12),
      maxPoints: 10,
      poids: 1,
      state: EvalState.upcoming,
      pourcentageSaisie: 0,
      saisies: 0,
      total: 2,
    ),
  );

  Widget host() => MaterialApp(
    locale: const Locale('fr'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: EvalSaisiePage(args: args, onBack: () {}),
  );

  testWidgets(
    'enregistrement de 2 lignes (réponses instantanées) : les deux sont '
    'validées et le toast récapitule 2 notées (pas de finalize prématuré)',
    (tester) async {
      // Grille : deux élèves sans note.
      when(() => mockGet('e1')).thenAnswer(
        (_) async => const Right<Failure, List<NoteEleve>>([
          NoteEleve(studentId: 's1', firstName: 'Daniel', lastName: 'Kabongo'),
          NoteEleve(studentId: 's2', firstName: 'Grâce', lastName: 'Tshala'),
        ]),
      );
      // saisirNote résout IMMÉDIATEMENT (Future.value) → exerce la course qui
      // faisait finaliser le lot avant que la 2e ligne ne démarre.
      when(() => mockSaisir(any(), any())).thenAnswer((invocation) async {
        final req = invocation.positionalArguments[1] as SaisirNoteRequest;
        return Right<Failure, NoteEvaluation>(
          NoteEvaluation(
            id: 'n-${req.studentId}',
            evaluationId: 'e1',
            studentId: req.studentId,
            statut: req.statut,
            pointsObtenus: req.pointsObtenus,
          ),
        );
      });

      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      // Saisit une note valide sur chaque ligne.
      final fields = find.byType(TextField);
      expect(fields, findsNWidgets(2));
      await tester.enterText(fields.at(0), '8');
      await tester.enterText(fields.at(1), '9');
      await tester.pump();

      await tester.tap(find.text('Enregistrer les notes'));
      await tester.pumpAndSettle();

      // Les deux lignes ont bien été envoyées.
      verify(() => mockSaisir('e1', any())).called(2);
      // Toast récapitulatif EXACT : 2 notées (et non 1, ce qui trahirait un
      // finalize prématuré laissant la 2e ligne non validée).
      expect(
        find.text('Notes enregistrées — 2 notées · 0 en attente'),
        findsOneWidget,
      );
    },
  );
}
