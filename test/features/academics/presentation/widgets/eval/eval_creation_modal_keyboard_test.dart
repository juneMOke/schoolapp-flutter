import 'package:dartz/dartz.dart' hide Evaluation;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart' hide Evaluation;
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/cours_notation_detail.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/create_evaluation_request.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/evaluation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/periode_notation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/sous_periode_notation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_periode.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/type_evaluation.dart';
import 'package:school_app_flutter/features/academics/domain/usecases/create_evaluation_usecase.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/create_evaluation_bloc.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/eval/eval_creation_modal.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class MockUC extends Mock implements CreateEvaluationUseCase {}

/// Cette modale ne débordait PAS — et ce test est là pour qu'elle continue.
///
/// Sa forme la protège : son en-tête est sa seule zone figée, tout le reste (y
/// compris ses boutons) vit dans le défilement. Elle n'a donc pas eu besoin de
/// passer par [EteeloDialogBody] comme ses voisines, dont l'en-tête ET le pied
/// étaient ancrés et débordaient ensemble dès que le clavier montait.
///
/// Le jour où un pied ancré lui sera ajouté, ces tailles vireront au rouge —
/// c'est exactement ce qu'on leur demande.

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

  SousPeriodeNotation sp(String id, int ordre) => SousPeriodeNotation(
    sousPeriodeId: id,
    ordre: ordre,
    statut: StatutPeriode.ouverte,
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
    ],
  );

  late MockUC uc;
  setUp(() {
    uc = MockUC();
    when(() => uc(any(), any())).thenAnswer(
      (_) async => const Left<Failure, Evaluation>(ServerFailure('x')),
    );
    getIt.registerFactory<CreateEvaluationBloc>(
      () => CreateEvaluationBloc(createEvaluationUseCase: uc),
    );
  });
  tearDown(() async => getIt.reset());

  for (final s in const [Size(640, 360), Size(731, 411), Size(411, 731)]) {
    for (final inset in const [0.0, 300.0, 340.0, 500.0]) {
      testWidgets('$s, clavier $inset dp : rien ne déborde', (tester) async {
        await tester.binding.setSurfaceSize(s);
        addTearDown(() => tester.binding.setSurfaceSize(null));
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
            home: Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(viewInsets: EdgeInsets.only(bottom: inset)),
                child: Builder(
                  builder: (inner) => TextButton(
                    onPressed: () => showEvalCreationModal(
                      inner,
                      detail: detail,
                      brancheNom: 'Mathématiques',
                      classroomName: '6e A',
                    ),
                    child: const Text('ouvrir'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('ouvrir'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
